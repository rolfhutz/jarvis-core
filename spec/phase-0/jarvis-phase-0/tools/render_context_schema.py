"""
JARVIS Phase 0 - Sicheres Rendern der Datenbankvorlagen.
Schliesst die technische Schuld TS-4.

Grundsatz: Es gibt keine freie Textersetzung. Schemaname, Kontextkennung und
Datenbankbenutzer werden ausschliesslich aus der Kontextkonfiguration
uebernommen und zusaetzlich gegen ein enges Muster geprueft. Ein Wert, der
nicht in der Konfiguration steht oder das Muster verletzt, fuehrt zum Abbruch.

Aufrufe:
    python3 tools/render_context_schema.py --list
    python3 tools/render_context_schema.py --context privat --out build/
    python3 tools/render_context_schema.py --ops --out build/
    python3 tools/render_context_schema.py --self-test

Das Skript erzeugt ausschliesslich SQL-Dateien. Es stellt keine Verbindung zu
einer Datenbank her und fuehrt nichts aus. Das Einspielen erfolgt bewusst
manuell und nachvollziehbar mit psql.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "templates" / "context_config.example.json"
DB_DIR = ROOT / "db"

SCHEMA_PATTERN = re.compile(r"^jarvis_[a-z0-9_]{2,40}$")
CONTEXT_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,31}$")
USER_PATTERN = re.compile(r"^jv_[a-z0-9_]{2,40}$")

RESERVED = {"public", "information_schema", "pg_catalog", "jarvis_ops"}


class RenderError(Exception):
    pass


def load_contexts(config_path: pathlib.Path = CONFIG) -> dict:
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    return {c["context_id"]: c for c in cfg["contexts"]}


def derive_db_user(context: dict) -> str:
    """
    Der Datenbankbenutzer wird aus der Credential-Referenz abgeleitet.
    Beispiel: jv_privat_postgres -> jv_privat_user
    """
    cred = context["persistence"]["credential_ref"]
    if not cred.endswith("_postgres"):
        raise RenderError(
            f"credential_ref '{cred}' folgt nicht der Konvention jv_<kontext>_postgres"
        )
    return cred[: -len("_postgres")] + "_user"


def validate_identifiers(context_id: str, schema: str, db_user: str) -> None:
    if not CONTEXT_PATTERN.match(context_id):
        raise RenderError(f"Unzulaessige Kontextkennung: {context_id!r}")
    if not SCHEMA_PATTERN.match(schema):
        raise RenderError(f"Unzulaessiger Schemaname: {schema!r}")
    if not USER_PATTERN.match(db_user):
        raise RenderError(f"Unzulaessiger Datenbankbenutzer: {db_user!r}")
    if schema in RESERVED:
        raise RenderError(f"Reserviertes Schema darf nicht verwendet werden: {schema!r}")


def render_context(context_id: str, contexts: dict) -> dict[str, str]:
    if context_id not in contexts:
        raise RenderError(
            f"Kontext {context_id!r} steht nicht in der Konfiguration. "
            f"Bekannt: {sorted(contexts)}"
        )
    ctx = contexts[context_id]
    schema = ctx["persistence"]["db_schema"]
    db_user = derive_db_user(ctx)
    validate_identifiers(context_id, schema, db_user)

    foreign = sorted(
        c["persistence"]["db_schema"] for cid, c in contexts.items() if cid != context_id
    )
    for f in foreign:
        if not SCHEMA_PATTERN.match(f):
            raise RenderError(f"Unzulaessiges fremdes Schema: {f!r}")

    revoke_block = "\n".join(
        f"REVOKE ALL ON SCHEMA {f} FROM {db_user};\n"
        f"REVOKE ALL ON ALL TABLES IN SCHEMA {f} FROM {db_user};\n"
        f"REVOKE ALL ON ALL SEQUENCES IN SCHEMA {f} FROM {db_user};"
        for f in foreign
    ) or "-- keine weiteren Kontexte vorhanden"

    values = {
        "{{SCHEMA}}": schema,
        "{{CONTEXT_ID}}": context_id,
        "{{DB_USER}}": db_user,
        "{{REVOKE_FOREIGN_BLOCK}}": revoke_block,
        "{{FOREIGN_SCHEMAS}}": ", ".join(foreign) or "-",
    }

    out = {}
    for name in ("001_context_schema_template.sql", "003_grants_and_isolation.sql"):
        text = (DB_DIR / name).read_text(encoding="utf-8")
        for key, value in values.items():
            text = text.replace(key, value)
        leftover = re.findall(r"\{\{[A-Z_]+\}\}", text)
        if leftover:
            raise RenderError(f"Nicht ersetzte Platzhalter in {name}: {sorted(set(leftover))}")
        target = name.replace("_template", "").replace(".sql", f".{context_id}.sql")
        out[target] = text
    return out


def render_ops() -> dict[str, str]:
    text = (DB_DIR / "002_ops_schema.sql").read_text(encoding="utf-8")
    leftover = re.findall(r"\{\{[A-Z_]+\}\}", text)
    if leftover:
        raise RenderError(f"002_ops_schema.sql enthaelt Platzhalter: {sorted(set(leftover))}")
    return {"002_ops_schema.sql": text}


def self_test() -> int:
    """Prueft, dass unzulaessige Eingaben abgewiesen werden."""
    print("Teil 1 - gueltige Kontexte werden gerendert")
    contexts = load_contexts()
    failures = []
    for cid in contexts:
        try:
            files = render_context(cid, contexts)
            assert all("{{" not in t for t in files.values())
            print(f"  ok  {cid:24s} -> {', '.join(sorted(files))}")
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{cid}: {exc}")
            print(f"  FEHLER {cid}: {exc}")
    try:
        render_ops()
        print("  ok  jarvis_ops             -> 002_ops_schema.sql")
    except Exception as exc:  # noqa: BLE001
        failures.append(f"ops: {exc}")
        print(f"  FEHLER ops: {exc}")

    print("\nTeil 2 - unzulaessige Eingaben werden abgewiesen")
    bad_cases = [
        ("Unbekannter Kontext", lambda: render_context("gibt_es_nicht", contexts)),
        ("SQL-Einschleusung im Kontextnamen",
         lambda: render_context("privat; DROP SCHEMA jarvis_visolva CASCADE; --", contexts)),
        ("Schemaname ohne Praefix",
         lambda: validate_identifiers("privat", "oeffentlich", "jv_privat_user")),
        ("Reserviertes Schema",
         lambda: validate_identifiers("privat", "jarvis_ops", "jv_privat_user")
         if "jarvis_ops" in RESERVED else None),
        ("Benutzername ohne Praefix",
         lambda: validate_identifiers("privat", "jarvis_privat", "postgres")),
        ("Anfuehrungszeichen im Schemanamen",
         lambda: validate_identifiers("privat", 'jarvis_privat"', "jv_privat_user")),
        ("credential_ref ohne Konvention",
         lambda: derive_db_user({"persistence": {"credential_ref": "irgendwas"}})),
    ]
    for label, call in bad_cases:
        try:
            call()
        except RenderError as exc:
            print(f"  ok  {label:38s} abgewiesen ({str(exc)[:60]})")
        except Exception as exc:  # noqa: BLE001
            print(f"  FEHLER {label:35s} falsche Fehlerart: {type(exc).__name__}")
            failures.append(label)
        else:
            print(f"  FEHLER {label:35s} wurde faelschlich akzeptiert")
            failures.append(label)

    print()
    if failures:
        print(f"FEHLGESCHLAGEN: {len(failures)} Befund(e)")
        return 1
    print("ERGEBNIS: alle Pruefungen bestanden")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Rendert die JARVIS-Datenbankvorlagen.")
    parser.add_argument("--context", help="Kontextkennung aus der Konfiguration")
    parser.add_argument("--ops", action="store_true", help="Gemeinsames technisches Schema rendern")
    parser.add_argument("--list", action="store_true", help="Bekannte Kontexte anzeigen")
    parser.add_argument("--self-test", action="store_true", help="Selbsttest ausfuehren")
    parser.add_argument("--out", default="build", help="Zielverzeichnis")
    args = parser.parse_args()

    if args.self_test:
        print("JARVIS Phase 0 - Selbsttest des Rendering-Skripts (TS-4)\n")
        return self_test()

    contexts = load_contexts()

    if args.list:
        for cid, ctx in contexts.items():
            print(f"{cid:24s} schema={ctx['persistence']['db_schema']:20s} user={derive_db_user(ctx)}")
        return 0

    if not args.context and not args.ops:
        parser.error("Bitte --context, --ops, --list oder --self-test angeben.")

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    files = {}
    if args.ops:
        files.update(render_ops())
    if args.context:
        files.update(render_context(args.context, contexts))

    for name, text in files.items():
        (out_dir / name).write_text(text, encoding="utf-8")
        print(f"geschrieben: {out_dir / name}")

    print("\nEinspielen anschliessend manuell, z. B.:")
    for name in sorted(files):
        print(f"  psql \"$JV_DB_URL\" -v ON_ERROR_STOP=1 -f {out_dir / name}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RenderError as exc:
        print(f"ABBRUCH: {exc}", file=sys.stderr)
        sys.exit(2)
