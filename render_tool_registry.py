"""
JARVIS Phase 1.0 - Erzeugung der Laufzeitkopie des Werkzeugregisters.

Entscheidung Variante A vom 10.09.2026: Das Werkzeugregister wird zur Laufzeit
aus jarvis_ops.tool_registry gelesen. Definitionsquelle bleiben die
Registerdateien im Repository. Dieses Skript ist der einzige zulaessige Weg
von den Dateien in die Datenbank.

Ablauf:
    1. Beide Registerdateien gegen tool_registry.schema.json validieren.
    2. Pruefen, dass kein Werkzeug in beiden Dateien steht (keine Doppelpflege).
    3. Je Werkzeug einen Pruefwert ueber die kanonische Definition bilden.
    4. Migration 0014 erzeugen: Einfuegen ohne Ueberschreiben, danach eine
       Pruefung, die bei abweichender Definition derselben Version abbricht.

Aufrufe:
    python3 tools/render_tool_registry.py --out db/migrations/
    python3 tools/render_tool_registry.py --check db/migrations/0014_tool_registry_seed.sql
    python3 tools/render_tool_registry.py --self-test

Das Skript stellt keine Datenbankverbindung her und fuehrt nichts aus.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

ROOT = pathlib.Path(__file__).resolve().parent.parent
PHASE0 = ROOT / "spec" / "phase-0" / "jarvis-phase-0"
PHASE1 = ROOT / "spec" / "phase-1" / "jarvis-phase-1"
SCHEMA_DIR = PHASE0 / "schemas"
REGISTRY_FILES = [
    PHASE0 / "registry" / "tool_registry.json",
    PHASE1 / "registry" / "tool_registry_phase1.json",
]
OUTPUT_NAME = "0014_tool_registry_seed.sql"

# Felder, die im Status nicht Teil der unveraenderlichen Definition sind.
MUTABLE_FIELDS = {"status"}


class RenderError(Exception):
    pass


def _schema_registry() -> Registry:
    resources = []
    for path in sorted(SCHEMA_DIR.glob("*.schema.json")):
        doc = json.loads(path.read_text(encoding="utf-8"))
        resources.append((doc["$id"], Resource.from_contents(doc)))
    return Registry().with_resources(resources)


def _validator() -> Draft202012Validator:
    schema = json.loads((SCHEMA_DIR / "tool_registry.schema.json").read_text(encoding="utf-8"))
    return Draft202012Validator(schema, registry=_schema_registry())


def _pg_jsonb_text(value) -> str:
    """Serialisiert exakt so, wie PostgreSQL jsonb::text ausgibt.

    jsonb speichert Objektschluessel nach Laenge (in Bytes) und danach binaer
    sortiert und trennt mit ", " und ": ". Dadurch kann die Datenbank den
    Pruefwert aus der gespeicherten Definition selbst nachrechnen und jede
    Abweichung zwischen Repository und Datenbank erkennen.
    """
    if isinstance(value, dict):
        keys = sorted(value, key=lambda k: (len(k.encode("utf-8")), k.encode("utf-8")))
        return "{" + ", ".join(json.dumps(k, ensure_ascii=False) + ": " + _pg_jsonb_text(value[k]) for k in keys) + "}"
    if isinstance(value, list):
        return "[" + ", ".join(_pg_jsonb_text(v) for v in value) + "]"
    if isinstance(value, float):
        raise RenderError("Gleitkommazahlen sind im Register nicht zulaessig")
    return json.dumps(value, ensure_ascii=False)


def canonical_definition(tool: dict) -> str:
    stripped = {k: v for k, v in tool.items() if k not in MUTABLE_FIELDS}
    return _pg_jsonb_text(stripped)


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def sql_text(value) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_array(values: list) -> str:
    return "ARRAY[" + ", ".join(sql_text(v) for v in values) + "]::text[]"


def sql_bool(value: bool) -> str:
    return "true" if value else "false"


def load_tools() -> list[dict]:
    validator = _validator()
    seen: dict[str, str] = {}
    rows = []
    for path in REGISTRY_FILES:
        raw = path.read_bytes()
        doc = json.loads(raw.decode("utf-8"))
        errors = sorted(validator.iter_errors(doc), key=lambda e: list(e.path))
        if errors:
            details = "; ".join(f"{list(e.path)}: {e.message}" for e in errors[:5])
            raise RenderError(f"{path.name} verletzt tool_registry.schema.json: {details}")
        rel = path.relative_to(ROOT).as_posix()
        file_hash = hashlib.sha256(raw).hexdigest()
        for tool in doc["tools"]:
            tid = tool["tool_id"]
            if tid in seen:
                raise RenderError(f"Doppelpflege: {tid} steht in {seen[tid]} und {rel}")
            seen[tid] = rel
            canon = canonical_definition(tool)
            rows.append({
                "tool": tool,
                "canonical": canon,
                "definition_sha256": sha256_text(canon),
                "source_file": rel,
                "source_sha256": file_hash,
            })
    return rows


def render(rows: list[dict]) -> str:
    out = [
        "-- =====================================================================",
        "-- JARVIS Phase 1.0 - Migration 0014 - Befuellung des Werkzeugregisters",
        "--",
        "-- ERZEUGT durch tools/render_tool_registry.py. Nicht von Hand bearbeiten.",
        "-- Quelle:",
    ]
    for f in REGISTRY_FILES:
        out.append(f"--   {f.relative_to(ROOT).as_posix()}")
    out += [
        "--",
        "-- Wiederholbar: Vorhandene Eintraege werden nie ueberschrieben. Der",
        "-- Freigabestatus in der Datenbank bleibt erhalten. Weicht die Definition",
        "-- einer bereits geladenen Version ab, bricht der Lauf ab: Eine geaenderte",
        "-- Definition erfordert eine neue Version.",
        f"-- Werkzeuge: {len(rows)}",
        "-- =====================================================================",
        "",
    ]
    for r in rows:
        t = r["tool"]
        ev = t["evidence"]
        out.append(
            "INSERT INTO jarvis_ops.tool_registry (tool_id, version, adapter_id, operation, external_effect, "
            "risk_class_default, reversibility, undo_tool_id, allowed_contexts, readback_supported, accepted_methods, "
            "evidence_limitation, timeout_seconds, dry_run_supported, status, definition, definition_sha256, "
            "source_file, source_sha256) VALUES ("
            + ", ".join([
                sql_text(t["tool_id"]), sql_text(t["version"]), sql_text(t["adapter_id"]),
                sql_text(t["operation"]), sql_text(t["external_effect"]), sql_text(t["risk_class_default"]),
                sql_text(t["reversibility"]), sql_text(t.get("undo_tool_id")),
                sql_array(t["allowed_contexts"]), sql_bool(ev["readback_supported"]),
                sql_array(ev["accepted_methods"]), sql_text(ev.get("limitation")),
                str(int(t["timeout_seconds"])), sql_bool(t["dry_run_supported"]), sql_text(t["status"]),
                sql_text(r["canonical"]) + "::jsonb", sql_text(r["definition_sha256"]),
                sql_text(r["source_file"]), sql_text(r["source_sha256"]),
            ])
            + ") ON CONFLICT (tool_id, version) DO NOTHING;"
        )
    out += ["", "-- Pruefung: Die Datenbank rechnet den Pruefwert aus der gespeicherten Definition nach.", "DO $$", "DECLARE", "    v_bad text;", "BEGIN", "    SELECT string_agg(e.tool_id || '@' || e.version, ', ') INTO v_bad", "    FROM (VALUES"]
    out.append(",\n".join(
        f"        ({sql_text(r['tool']['tool_id'])}, {sql_text(r['tool']['version'])}, {sql_text(r['definition_sha256'])})"
        for r in rows
    ))
    out += [
        "    ) AS e (tool_id, version, sha)",
        "    LEFT JOIN jarvis_ops.tool_registry t ON t.tool_id = e.tool_id AND t.version = e.version",
        "    WHERE t.definition_sha256 IS DISTINCT FROM e.sha",
        "       OR encode(sha256(convert_to(t.definition::text, 'UTF8')), 'hex') IS DISTINCT FROM e.sha",
        "       OR t.tool_id            IS DISTINCT FROM t.definition->>'tool_id'",
        "       OR t.version            IS DISTINCT FROM t.definition->>'version'",
        "       OR t.adapter_id         IS DISTINCT FROM t.definition->>'adapter_id'",
        "       OR t.operation          IS DISTINCT FROM t.definition->>'operation'",
        "       OR t.external_effect    IS DISTINCT FROM t.definition->>'external_effect'",
        "       OR t.risk_class_default::text IS DISTINCT FROM t.definition->>'risk_class_default'",
        "       OR t.reversibility      IS DISTINCT FROM t.definition->>'reversibility'",
        "       OR t.undo_tool_id       IS DISTINCT FROM t.definition->>'undo_tool_id'",
        "       OR t.timeout_seconds    IS DISTINCT FROM (t.definition->>'timeout_seconds')::int",
        "       OR t.dry_run_supported  IS DISTINCT FROM (t.definition->>'dry_run_supported')::boolean",
        "       OR t.readback_supported IS DISTINCT FROM (t.definition->'evidence'->>'readback_supported')::boolean",
        "       OR t.evidence_limitation IS DISTINCT FROM t.definition->'evidence'->>'limitation'",
        "       OR t.allowed_contexts   IS DISTINCT FROM ARRAY(SELECT jsonb_array_elements_text(t.definition->'allowed_contexts'))",
        "       OR t.accepted_methods   IS DISTINCT FROM ARRAY(SELECT jsonb_array_elements_text(t.definition->'evidence'->'accepted_methods'));",
        "    IF v_bad IS NOT NULL THEN",
        "        RAISE EXCEPTION 'registry_definition_mismatch: %', v_bad USING ERRCODE = '23514';",
        "    END IF;",
        "END",
        "$$;",
        "",
    ]
    return "\n".join(out)


def self_test() -> None:
    rows = load_tools()
    assert len(rows) == len({r["tool"]["tool_id"] for r in rows}), "tool_id nicht eindeutig"
    sql = render(rows)
    assert sql.count("INSERT INTO jarvis_ops.tool_registry") == len(rows)
    assert render(rows) == sql, "Ausgabe nicht deterministisch"
    # Gegenprobe: Doppelpflege wird erkannt
    dup = rows + [rows[0]]
    ids = [r["tool"]["tool_id"] for r in dup]
    assert len(ids) != len(set(ids))
    # Gegenprobe: Status gehoert nicht zur Definition
    t = dict(rows[0]["tool"]); t["status"] = "approved"
    assert canonical_definition(t) == rows[0]["canonical"]
    # Gegenprobe: jede Vertragsaenderung aendert den Pruefwert
    t2 = dict(rows[0]["tool"]); t2["risk_class_default"] = "C" if t2["risk_class_default"] != "C" else "B"
    assert sha256_text(canonical_definition(t2)) != rows[0]["definition_sha256"]
    # Gegenprobe: schemawidriger Eintrag wird abgewiesen
    bad = {"registry_version": "1.0.0", "tools": [dict(rows[0]["tool"], external_effect="financial", risk_class_default="A")]}
    assert list(_validator().iter_errors(bad)), "Schemaverstoss nicht erkannt"
    print(f"SELBSTTEST BESTANDEN: {len(rows)} Werkzeuge, 5 Gegenproben")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=pathlib.Path)
    ap.add_argument("--check", type=pathlib.Path)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    try:
        if a.self_test:
            self_test()
            return 0
        sql = render(load_tools())
        if a.check:
            if a.check.read_text(encoding="utf-8") != sql:
                print("ABWEICHUNG: Migration entspricht nicht den Registerdateien. Neu erzeugen.")
                return 1
            print("OK: Migration entspricht den Registerdateien.")
            return 0
        if a.out:
            a.out.mkdir(parents=True, exist_ok=True)
            target = a.out / OUTPUT_NAME
            target.write_text(sql, encoding="utf-8")
            print(f"geschrieben: {target}")
            return 0
        sys.stdout.write(sql)
        return 0
    except RenderError as exc:
        print(f"ABBRUCH: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
