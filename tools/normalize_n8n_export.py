"""
JARVIS - Normalisierung von n8n-Workflow-Exporten fuer das Repository.

Eingabe: Dateien aus n8n "Download" (ein Workflow je Datei).
Ausgabe: n8n/core/<Workflowname>.json im bestehenden Repo-Format
         {name, nodes, connections, settings, meta}.

Die Workflow-ID bleibt erhalten: Elternworkflows rufen Subworkflows ueber die
ID auf, eine Wiederherstellung muss sie deshalb unveraendert uebernehmen.
Entfernt werden instanzspezifische und fluechtige Angaben: versionId,
activeVersionId, pinData, staticData, active, tags, shared, triggerCount,
Zeitstempel und meta.instanceId.

Credential-Verweise behalten ID und Namen. Grund (Nachweis 1.0-A8, 10.09.2026):
Ohne ID ordnet n8n beim Import allen Knoten eines Typs das erste vorhandene
Credential zu. Die visolva-Knoten liefen dann mit dem privat-Zugang. IDs sind
keine Geheimnisse; Kennwoerter stehen nie im Export.

Das Skript bricht ab, wenn in einem Export etwas steht, das wie ein Geheimnis
aussieht (Verbindungszeichenfolge, Kennwort, Token, API-Schluessel).

Aufruf:
    python3 tools/normalize_n8n_export.py --in <ordner_mit_downloads> --out n8n/core --date 2026-09-10
    python3 tools/normalize_n8n_export.py --self-test
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

NAME_PATTERN = re.compile(r"^JV-(CORE|P[0-9])-(SUB|MAIN|ADP|OPS)-[a-z0-9_]+-v[0-9]+$")
SECRET_PATTERNS = [
    re.compile(r"postgres(ql)?://", re.I),
    re.compile(r"\b(password|passwort|secret|api[_-]?key|access[_-]?token|bearer)\b\s*[:=]\s*['\"]?[^'\"\s]{6,}", re.I),
    re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
    re.compile(r"\bsk-[A-Za-z0-9]{20,}"),
]
KEEP_SETTINGS = {"executionOrder", "callerPolicy", "errorWorkflow", "saveDataSuccessExecution",
                 "saveDataErrorExecution", "saveManualExecutions", "executionTimeout", "timezone"}
DROP_NODE_KEYS = {"webhookId"}


class ExportError(Exception):
    pass


def normalize(raw: dict, export_date: str, spec0: str = "1.1.0", spec1: str = "4.0.2") -> dict:
    name = raw.get("name", "")
    if not NAME_PATTERN.match(name):
        raise ExportError(f"Workflowname entspricht nicht der Konvention: {name!r}")
    nodes = []
    creds_needed = set()
    for n in raw.get("nodes", []):
        node = {k: v for k, v in n.items() if k not in DROP_NODE_KEYS}
        if "credentials" in node:
            clean = {}
            for ctype, ref in node["credentials"].items():
                cname = ref.get("name") if isinstance(ref, dict) else None
                cid = ref.get("id") if isinstance(ref, dict) else None
                if not cname or not cid:
                    raise ExportError(f"{name}: Credential ohne Namen oder ID am Knoten {node.get('name')!r}")
                clean[ctype] = {"id": cid, "name": cname}
                creds_needed.add((cid, cname))
            node["credentials"] = clean
        nodes.append(node)
    settings = {k: v for k, v in (raw.get("settings") or {}).items() if k in KEEP_SETTINGS}
    if not raw.get("id"):
        raise ExportError(f"{name}: Workflow-ID fehlt im Export")
    out = {
        "id": raw["id"],
        "name": name,
        "nodes": nodes,
        "connections": raw.get("connections", {}),
        "settings": settings,
        "meta": {
            "jarvis_source_workflow_id": raw.get("id"),
            "jarvis_phase": "1.0",
            "jarvis_spec_phase_0": spec0,
            "jarvis_spec_phase_1": spec1,
            "jarvis_exported_at": export_date,
            "jarvis_required_credentials": [{"id": i, "name": n} for i, n in sorted(creds_needed)],
        },
    }
    text = json.dumps(out, ensure_ascii=False)
    for pat in SECRET_PATTERNS:
        for m in pat.finditer(text):
            # Synthetische Testwerte sind ausdruecklich als SMOKE_FAKE gekennzeichnet.
            if "SMOKE_FAKE" in m.group(0):
                continue
            raise ExportError(f"{name}: moegliches Geheimnis im Export ({m.group(0)[:30]}...)")
    return out


def self_test() -> None:
    raw = {
        "id": "abc", "name": "JV-CORE-SUB-demo-v1", "active": False, "versionId": "x",
        "pinData": {"a": 1}, "meta": {"instanceId": "secret-instance"},
        "settings": {"executionOrder": "v1", "availableInMCP": True},
        "nodes": [{"name": "DB", "type": "n8n-nodes-base.postgres", "parameters": {"query": "SELECT 1"},
                   "credentials": {"postgres": {"id": "oCkj", "name": "jv_privat_postgres"}}}],
        "connections": {},
    }
    out = normalize(raw, "2026-09-10")
    assert out["id"] == "abc" and "pinData" not in out and "versionId" not in out
    assert out["nodes"][0]["credentials"] == {"postgres": {"id": "oCkj", "name": "jv_privat_postgres"}}
    assert out["settings"] == {"executionOrder": "v1"}
    assert out["meta"]["jarvis_required_credentials"] == [{"id": "oCkj", "name": "jv_privat_postgres"}]
    assert "instanceId" not in json.dumps(out)
    bad = dict(raw, nodes=[{"name": "X", "parameters": {"url": "postgres://u:p@h/db"}}])
    try:
        normalize(bad, "2026-09-10")
        raise AssertionError("Geheimnis nicht erkannt")
    except ExportError:
        pass
    try:
        normalize(dict(raw, name="Mein Workflow"), "2026-09-10")
        raise AssertionError("Namenskonvention nicht geprueft")
    except ExportError:
        pass
    print("SELBSTTEST BESTANDEN: 3 Pruefungen, 2 Gegenproben")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=pathlib.Path)
    ap.add_argument("--out", type=pathlib.Path)
    ap.add_argument("--date")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        self_test()
        return 0
    if not (a.inp and a.out and a.date):
        ap.error("--in, --out und --date sind erforderlich")
    a.out.mkdir(parents=True, exist_ok=True)
    try:
        for f in sorted(a.inp.glob("*.json")):
            out = normalize(json.loads(f.read_text(encoding="utf-8")), a.date)
            target = a.out / f"{out['name']}.json"
            target.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"{f.name} -> {target}")
    except ExportError as exc:
        print(f"ABBRUCH: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
