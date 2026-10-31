"""
JARVIS - Sicherung zurueckspielen (CR-19 / TS-13).

Spielt eine Sicherungsdatei aus `JV-CORE-OPS-db_sicherung-v1` (Format `jarvis-sicherung-1`,
Datei `JARVIS_Sicherung_<kontext>_<woche>.json.gz` aus `95_Sicherung` im Drive des Kontexts)
in eine Datenbank zurueck, deren Schema bereits aus `db/migrations/` aufgebaut ist.

Ablauf einer Wiederherstellung:
  1. leere Datenbank, Schema `extensions` anlegen (Supabase stellt es bereit)
  2. alle Migrationen aus db/migrations/ in Reihenfolge einspielen; die Freigabe-Migrationen
     0023 und 0026 scheitern dabei beabsichtigt (fail closed, Nachweis fehlt) - ihr Ergebnis
     steht in den gesicherten Daten
  3. python3 tools/sicherung_zurueckspielen.py --datei <sicherung.json.gz> --psql-args="..." --ersetzen
  4. das Skript vergleicht danach die Zeilenzahl jeder Tabelle mit der Sicherung

Regeln:
  - Zieltabellen muessen leer sein, sonst Abbruch (kein Vermischen mit Bestand). Nach einer
    frischen Migration enthalten einige Tabellen Startwerte; dann --ersetzen angeben.
  - Alles in einer Transaktion; bei einem Fehler bleibt die Datenbank unveraendert.
  - Trigger und Fremdschluessel werden waehrend des Einspielens ausgesetzt
    (session_replication_role = replica, erfordert Superuser). Grund: action_log ist
    append-only und die Tabellen verweisen gegenseitig aufeinander.
  - Generierte Spalten werden nicht eingespielt, sondern neu berechnet.
  - Sequenzen werden auf den hoechsten eingespielten Wert gesetzt.
  - Die Datei enthaelt personenbezogene Daten: nie ins Repository, nach dem Test loeschen.
"""
from __future__ import annotations

import argparse
import gzip
import json
import pathlib
import shlex
import subprocess
import sys
import tempfile

SCHEMAS = {"jarvis_privat", "jarvis_visolva", "jarvis_ops"}


def psql(args: str, sql: str) -> str:
    r = subprocess.run(["psql", *shlex.split(args), "-X", "-q", "-At", "-v", "ON_ERROR_STOP=1"],
                       input=sql, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit("psql-Fehler: " + r.stderr.strip()[:2000])
    return r.stdout


def lade(datei: pathlib.Path) -> dict:
    roh = datei.read_bytes()
    if datei.suffix == ".gz":
        roh = gzip.decompress(roh)
    d = json.loads(roh)
    if d.get("format") != "jarvis-sicherung-1":
        raise SystemExit("Unbekanntes Sicherungsformat: " + str(d.get("format")))
    for s in d.get("schemas", []):
        if s.get("schema") not in SCHEMAS:
            raise SystemExit("Schema nicht zulaessig: " + str(s.get("schema")))
    return d


def tag_fuer(text: str) -> str:
    n = 0
    while f"$jv{n}$" in text:
        n += 1
    return f"$jv{n}$"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--datei", required=True, type=pathlib.Path)
    ap.add_argument("--psql-args", required=True, help='z. B. "-h /tmp -p 55432 -U postgres -d jarvis"')
    ap.add_argument("--ersetzen", action="store_true",
                    help="Zieltabellen vorher leeren (nur fuer eine frisch migrierte Datenbank: Startwerte der Migrationen werden durch die Sicherung ersetzt)")
    a = ap.parse_args()
    d = lade(a.datei)

    spalten = {}
    for zeile in psql(a.psql_args, """select table_schema || '.' || table_name, column_name, is_generated, coalesce(identity_generation, '')
        from information_schema.columns where table_schema in ('jarvis_privat','jarvis_visolva','jarvis_ops') order by ordinal_position""").splitlines():
        t, c, gen, ident = zeile.split("|")
        spalten.setdefault(t, []).append((c, gen, ident))

    teile = ["begin;", "set local session_replication_role = replica;"]
    soll = {}
    for s in d["schemas"]:
        for tabelle, zeilen in s["tabellen"].items():
            voll = s["schema"] + "." + tabelle
            if voll not in spalten:
                raise SystemExit("Tabelle fehlt im Zielschema (Migrationen unvollstaendig?): " + voll)
            soll[voll] = len(zeilen)
            if a.ersetzen:
                teile.append(f"delete from {voll};")
            else:
                teile.append(f"do $p$ begin if exists (select 1 from {voll}) then raise exception 'Zieltabelle nicht leer: {voll}'; end if; end $p$;")
            if not zeilen:
                continue
            cols = [c for c, gen, _ in spalten[voll] if gen == "NEVER"]
            immer = any(ident == "ALWAYS" for _, _, ident in spalten[voll])
            liste = ", ".join('"' + c + '"' for c in cols)
            daten = json.dumps(zeilen, ensure_ascii=False)
            tag = tag_fuer(daten)
            teile.append(f"insert into {voll} ({liste}) {'overriding system value ' if immer else ''}"
                         f"select {liste} from jsonb_populate_recordset(null::{voll}, {tag}{daten}{tag}::jsonb);")
    teile.append("""do $p$ declare r record; m bigint; begin
  for r in select n.nspname s, c.relname t, a.attname col, pg_get_serial_sequence(quote_ident(n.nspname) || '.' || quote_ident(c.relname), a.attname) q
    from pg_attribute a join pg_class c on c.oid = a.attrelid join pg_namespace n on n.oid = c.relnamespace
    where n.nspname in ('jarvis_privat','jarvis_visolva','jarvis_ops') and c.relkind = 'r' and a.attnum > 0 and not a.attisdropped
  loop
    if r.q is not null then
      execute format('select max(%I) from %I.%I', r.col, r.s, r.t) into m;
      if m is not null then perform setval(r.q, m); end if;
    end if;
  end loop; end $p$;""")
    teile.append("commit;")
    with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=True, encoding="utf-8") as f:
        f.write("\n".join(teile))
        f.flush()
        r = subprocess.run(["psql", *shlex.split(a.psql_args), "-X", "-q", "-v", "ON_ERROR_STOP=1", "-f", f.name], capture_output=True, text=True)
        if r.returncode != 0:
            print("ABBRUCH, nichts eingespielt:", r.stderr.strip()[:2000], file=sys.stderr)
            return 2

    abw = []
    for voll, n in sorted(soll.items()):
        ist = int(psql(a.psql_args, f"select count(*) from {voll}").strip())
        if ist != n:
            abw.append(f"{voll}: {ist} statt {n}")
    print(json.dumps({"kontext": d.get("kontext"), "woche": d.get("woche"), "tabellen": len(soll), "zeilen": sum(soll.values())}))
    print("ERGEBNIS:", "BESTANDEN" if not abw else "NICHT BESTANDEN")
    for x in abw:
        print(" -", x)
    return 0 if not abw else 1


if __name__ == "__main__":
    sys.exit(main())
