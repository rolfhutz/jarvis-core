"""
JARVIS 1.1-A18 / TS-10 - statische Pruefung der n8n-Exporte auf Kontextwerte im Code.

Regel (TS10-E1, freigegeben 11.09.2026): Kontextnamen, Schemanamen, Bindungsschluessel,
Credential-Namen und env-Verweise stehen in keinem Code-, Set- oder If-Knoten. Einzige
Stelle mit Kontextnamen ist die Kontextweiche (Switch) mit ihren Postgres-Zweigen (TS-10b).
Jede Kontextweiche braucht einen Ausweichausgang, der verbunden ist (fail closed).

Die verbotenen Werte stehen nicht in diesem Skript. Sie werden gelesen aus:
  - config/intake_config.json          Kontext-IDs, Bindungsschluessel
  - db/migrations/0009_*.sql           Schemanamen und Datenbankbenutzer der Kontexte
  - meta.jarvis_required_credentials   Credential-Namen (aus den Exporten selbst)
  - festes Muster "env:JV_"            Verweise auf n8n-Variablen (ADR-001)

Ausnahmen (abschliessend):
  - Switch-Knoten, deren Regeln ausschliesslich Kontext-IDs pruefen (Kontextweiche, TS-10b)
  - Postgres-Knoten (Schema im SQL, Credential je Zweig, TS-10b)
  - Notizen (stickyNote)
  - Workflow JV-CORE-OPS-smoke_test-v1 (synthetische Testdaten mit Kontextnamen)

Aufruf:
    python3 tests/n8n/check_ts10.py --src n8n/core [--src n8n/phase-1]
    python3 tests/n8n/check_ts10.py --self-test
Rueckgabe 0 = bestanden, 1 = Befunde.
"""
from __future__ import annotations

import argparse
import glob
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
AUSNAHME_WORKFLOWS = {"JV-CORE-OPS-smoke_test-v1"}
FREIE_TYPEN = {"n8n-nodes-base.postgres", "n8n-nodes-base.stickyNote"}
PRUEF_TYPEN = {"n8n-nodes-base.code", "n8n-nodes-base.set", "n8n-nodes-base.if"}
SWITCH = "n8n-nodes-base.switch"


def verbotene_werte(root: pathlib.Path, workflows: list[dict]) -> tuple[set[str], set[str]]:
    cfg = json.loads((root / "config/intake_config.json").read_text(encoding="utf-8"))
    kontexte = set(cfg["contexts"])
    werte = set(kontexte)
    for ctx in cfg["contexts"].values():
        for b in ctx.get("source_bindings", []):
            werte.add(b["binding_key"])
    seed = next(iter(sorted((root / "db/migrations").glob("0009_*.sql"))))
    for zeile in seed.read_text(encoding="utf-8").splitlines():
        teile = re.findall(r"'([^']*)'", zeile)
        if len(teile) >= 5 and teile[0] in kontexte:
            werte.update({teile[3], teile[4]})          # db_schema, db_user
    for w in workflows:
        for c in (w.get("meta") or {}).get("jarvis_required_credentials", []):
            werte.add(c["name"])
    return kontexte, {v for v in werte if v}


def muster(werte: set[str]) -> re.Pattern:
    teile = sorted((re.escape(v) for v in werte), key=len, reverse=True)
    return re.compile(r"(?<![A-Za-z0-9])(" + "|".join(teile) + r")(?![A-Za-z0-9])|env:JV_")


def texte(obj):
    if isinstance(obj, str):
        yield obj
    elif isinstance(obj, dict):
        for v in obj.values():
            yield from texte(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from texte(v)


def switch_werte(node: dict) -> list[str]:
    return [c.get("rightValue") for r in node["parameters"].get("rules", {}).get("values", [])
            for c in r.get("conditions", {}).get("conditions", [])]


def pruefe(workflows: list[dict], kontexte: set[str], werte: set[str]) -> tuple[list[str], dict]:
    rx = muster(werte)
    befunde, z = [], {"workflows": 0, "ausnahmen": 0, "gepruefte_knoten": 0, "kontextweichen": 0}
    for w in sorted(workflows, key=lambda x: x["name"]):
        name = w["name"]
        if name in AUSNAHME_WORKFLOWS:
            z["ausnahmen"] += 1
            continue
        z["workflows"] += 1
        verb = w.get("connections", {})
        for n in w["nodes"]:
            typ = n["type"]
            if typ in FREIE_TYPEN:
                continue
            if typ == SWITCH:
                rv = [v for v in switch_werte(n) if isinstance(v, str)]
                if any(v in kontexte for v in rv):
                    z["kontextweichen"] += 1
                    rest = [v for v in rv if v not in kontexte and v not in ("dry_run", "invalid", "none")]
                    if rest:
                        befunde.append(f"{name}/{n['name']}: Kontextweiche prueft zusaetzlich {rest}")
                    opt = n["parameters"].get("options", {})
                    ausgaenge = verb.get(n["name"], {}).get("main", [])
                    idx = len(n["parameters"].get("rules", {}).get("values", []))
                    if opt.get("fallbackOutput") != "extra":
                        befunde.append(f"{name}/{n['name']}: Kontextweiche ohne Ausweichausgang")
                    elif len(ausgaenge) <= idx or not ausgaenge[idx]:
                        befunde.append(f"{name}/{n['name']}: Ausweichausgang nicht verbunden")
                continue
            if typ in PRUEF_TYPEN or typ.endswith(".code"):
                z["gepruefte_knoten"] += 1
                treffer = sorted({m.group(0) for t in texte(n["parameters"]) for m in rx.finditer(t)})
                if treffer:
                    befunde.append(f"{name}/{n['name']}: {', '.join(treffer)}")
    return befunde, z


def lade(ordner: list[str]) -> list[dict]:
    out = []
    for o in ordner:
        for f in sorted(glob.glob(str(pathlib.Path(o) / "*.json"))):
            out.append(json.loads(pathlib.Path(f).read_text(encoding="utf-8")))
    return out


def selbsttest() -> int:
    k, w = {"ctx_a", "ctx_b"}, {"ctx_a", "ctx_b", "schema_a", "bind_a"}
    def wf(nodes, conn=None):
        return {"name": "JV-CORE-SUB-test-v1", "nodes": nodes, "connections": conn or {}}
    code_ok = {"name": "C", "type": "n8n-nodes-base.code", "parameters": {"jsCode": "const x = /^[a-z]+$/;"}}
    code_bad = {"name": "C", "type": "n8n-nodes-base.code", "parameters": {"jsCode": "const K = ['ctx_a'];"}}
    code_env = {"name": "C", "type": "n8n-nodes-base.code", "parameters": {"jsCode": "x = 'env:JV_X';"}}
    regel = lambda v: {"conditions": {"conditions": [{"rightValue": v}]}}
    sw = lambda fb: {"name": "S", "type": SWITCH, "parameters": {"rules": {"values": [regel("ctx_a"), regel("ctx_b")]},
                                                                  "options": {"fallbackOutput": "extra"} if fb else {}}}
    conn_ok = {"S": {"main": [[{"node": "P"}], [{"node": "V"}], [{"node": "E"}]]}}
    faelle = [
        ("Code ohne Kontextwerte", wf([code_ok]), 0),
        ("Weiche mit verbundenem Ausweichausgang", wf([sw(True)], conn_ok), 0),
        ("Gegenprobe: Kontextliste im Code", wf([code_bad]), 1),
        ("Gegenprobe: env-Verweis im Code", wf([code_env]), 1),
        ("Gegenprobe: Weiche ohne Ausweichausgang", wf([sw(False)], conn_ok), 1),
        ("Gegenprobe: Ausweichausgang nicht verbunden", wf([sw(True)], {"S": {"main": [[{"node": "P"}], [{"node": "V"}]]}}), 1),
    ]
    fehler = 0
    for titel, w_, soll in faelle:
        b, _ = pruefe([w_], k, w)
        ok = (len(b) > 0) == (soll > 0)
        fehler += 0 if ok else 1
        print(("ok    " if ok else "FEHLER"), titel, b)
    print("SELBSTTEST", "BESTANDEN" if not fehler else "NICHT BESTANDEN", f": {len(faelle)} Faelle")
    return 0 if not fehler else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", action="append", default=[])
    ap.add_argument("--root", default=str(ROOT))
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return selbsttest()
    wfs = lade(a.src or [str(pathlib.Path(a.root) / "n8n/core")])
    kontexte, werte = verbotene_werte(pathlib.Path(a.root), wfs)
    befunde, z = pruefe(wfs, kontexte, werte)
    z["verbotene_werte"] = len(werte) + 1
    print(json.dumps(z))
    print("ERGEBNIS:", "BESTANDEN" if not befunde else "NICHT BESTANDEN")
    for b in befunde:
        print(" -", b)
    return 0 if not befunde else 1


if __name__ == "__main__":
    sys.exit(main())
