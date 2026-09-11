"""
JARVIS Phase 1.1 - Erzeugung der Laufzeitkonfiguration fuer den Eingang.

Entscheidung 1.1-E4 vom 10.09.2026: Kontextliste, Quellbindungen und
Dokumenteinstellungen werden zur Laufzeit aus jarvis_ops gelesen, nicht aus
Code-Knoten. Definitionsquelle ist config/intake_config.json. Dieses Skript
ist der einzige zulaessige Weg von der Datei in die Datenbank (analog ADR-002).

Pruefungen vor dem Erzeugen:
    K1  Datei gueltig gegen config/schemas/intake_config.schema.json
    K2  Jeder Kontext steht in der Kontextkonfiguration (keine freie Kennung)
    K3  binding_key global eindeutig
    K4  Eingangsbindung (purpose intake): Adapter = Speicheradapter des
        Kontexts, Ort = Eingang des Kontexts
    K5  Kein Ort wird von zwei Bindungen geteilt, ausser alle sind probe
    K6  Kein env-Verweis wird von zwei Kontexten verwendet (Ordnertrennung);
        ausgenommen ist der Ort von probe-Bindungen
    K7  Keine Gleitkommazahl in der Datei
    K8  Der Ort einer probe-Bindung ist nie ein konfigurierter Ordner eines
        Kontexts (der Nachweis K-07 beruehrt keinen produktiven Ordner)
    K9  Die Kontextwurzel (1.1b-E1) ist keiner der uebrigen Verweise des
        Kontexts (Eingang, Arbeit, Archiv, Entwuerfe, Berichte, Container)
    K10 Fuer die config_version der Datei ist eine Migrationsnummer
        zugeordnet (OUTPUT_BY_VERSION); jede neue Version bekommt eine neue
        Migration, eine eingespielte Migration wird nie neu erzeugt

Die Pruefung, dass alle Ordnerrollen tatsaechlich unter der Wurzel liegen,
ist nur zur Laufzeit moeglich (Werte stehen in n8n-Variablen) und erfolgt in
der Einrichtungspruefung der Speicheradapter.

Historie: Migration 0017 wurde aus config_version 1.0.0 erzeugt (Repo-Stand
d12f218) und ist durch 0021 abgeloest. 0017 nicht erneut ausfuehren; nach
0022 scheitert sie an der Pflichtspalte context_root_ref (fail closed).

Aufrufe:
    python3 tools/render_intake_config.py --out db/migrations/
    python3 tools/render_intake_config.py --check db/migrations/0021_intake_config_seed_1_1.sql
    python3 tools/render_intake_config.py --self-test

Das Skript stellt keine Datenbankverbindung her und fuehrt nichts aus.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import pathlib
import sys

from jsonschema import Draft202012Validator

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG_FILE = ROOT / "config" / "intake_config.json"
SCHEMA_FILE = ROOT / "config" / "schemas" / "intake_config.schema.json"
CONTEXT_CONFIG = ROOT / "spec" / "phase-0" / "jarvis-phase-0" / "templates" / "context_config.example.json"
# config_version -> (Migrationsnummer, Dateiname). Nur die aktuelle Version;
# 1.0.0 -> 0017 ist Historie (siehe Kopf).
OUTPUT_BY_VERSION = {
    "1.1.0": ("0021", "0021_intake_config_seed_1_1.sql"),
}

REF_FIELDS = ["storage_container_ref", "context_root_ref", "inbox_ref", "working_ref", "archive_root_ref",
              "drafts_ref", "reports_ref"]


class RenderError(Exception):
    pass


def known_contexts() -> set[str]:
    cfg = json.loads(CONTEXT_CONFIG.read_text(encoding="utf-8"))
    return {c["context_id"] for c in cfg["contexts"]}


def _no_floats(value, path="$") -> None:
    if isinstance(value, float):
        raise RenderError(f"K7: Gleitkommazahl unter {path}")
    if isinstance(value, dict):
        for k, v in value.items():
            _no_floats(v, f"{path}.{k}")
    if isinstance(value, list):
        for i, v in enumerate(value):
            _no_floats(v, f"{path}[{i}]")


def validate(doc: dict, contexts: set[str]) -> None:
    schema = json.loads(SCHEMA_FILE.read_text(encoding="utf-8"))
    errors = sorted(Draft202012Validator(schema).iter_errors(doc), key=lambda e: list(e.path))
    if errors:
        raise RenderError("K1: " + "; ".join(f"{list(e.path)}: {e.message}" for e in errors[:5]))
    _no_floats(doc)
    if doc["config_version"] not in OUTPUT_BY_VERSION:
        raise RenderError(f"K10: keine Migration fuer config_version {doc['config_version']} zugeordnet")
    keys: dict[str, str] = {}
    locations: dict[tuple[str, str], list[tuple[str, str]]] = {}
    ref_owner: dict[str, str] = {}
    for ctx, c in doc["contexts"].items():
        if ctx not in contexts:
            raise RenderError(f"K2: Kontext {ctx!r} steht nicht in der Kontextkonfiguration")
        ds = c["document_settings"]
        refs = [ds[f] for f in REF_FIELDS if ds[f] is not None]
        others = [ds[f] for f in REF_FIELDS if f != "context_root_ref" and ds[f] is not None]
        if ds["context_root_ref"] in others:
            raise RenderError(f"K9: Kontextwurzel von {ctx} ist zugleich ein anderer Ordnerverweis")
        for b in c["source_bindings"]:
            if b["binding_key"] in keys:
                raise RenderError(f"K3: binding_key {b['binding_key']} doppelt ({keys[b['binding_key']]}, {ctx})")
            keys[b["binding_key"]] = ctx
            if b["purpose"] == "intake":
                if b["adapter_id"] != ds["storage_adapter_id"]:
                    raise RenderError(f"K4: {b['binding_key']}: Adapter {b['adapter_id']} ist nicht der Speicheradapter von {ctx}")
                if b["location_ref"] != ds["inbox_ref"]:
                    raise RenderError(f"K4: {b['binding_key']}: Ort ist nicht der Eingang von {ctx}")
            locations.setdefault((b["adapter_id"], b["location_ref"]), []).append((b["binding_key"], b["purpose"]))
            if b["purpose"] == "intake":
                refs.append(b["location_ref"])
        for r in set(refs):
            if r in ref_owner and ref_owner[r] != ctx:
                raise RenderError(f"K6: env-Verweis {r} wird von {ref_owner[r]} und {ctx} verwendet")
            ref_owner[r] = ctx
    for loc, users in locations.items():
        if len(users) > 1 and any(p != "probe" for _, p in users):
            raise RenderError(f"K5: Ort {loc} wird geteilt von {[k for k, _ in users]}; nur probe-Bindungen duerfen einen Ort teilen")
    configured = {c["document_settings"][f] for c in doc["contexts"].values() for f in REF_FIELDS} - {None}
    for (adapter, loc), users in locations.items():
        if all(p == "probe" for _, p in users) and loc in configured:
            raise RenderError(f"K8: probe-Ort {loc} ist ein konfigurierter Ordner")


def sql_text(value) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sql_array(values: list) -> str:
    if not values:
        return "ARRAY[]::text[]"
    return "ARRAY[" + ", ".join(sql_text(v) for v in values) + "]::text[]"


def sql_bool(value: bool) -> str:
    return "true" if value else "false"


def render(raw: bytes, contexts: set[str] | None = None) -> str:
    doc = json.loads(raw.decode("utf-8"))
    validate(doc, contexts if contexts is not None else known_contexts())
    rel = CONFIG_FILE.relative_to(ROOT).as_posix()
    sha = hashlib.sha256(raw).hexdigest()
    ver = doc["config_version"]
    mig = OUTPUT_BY_VERSION[ver][0]
    out = [
        "-- =====================================================================",
        f"-- JARVIS Phase 1.1 - Migration {mig} - Laufzeitkonfiguration Eingang",
        "--",
        "-- ERZEUGT durch tools/render_intake_config.py. Nicht von Hand bearbeiten.",
        f"-- Quelle: {rel} (config_version {ver})",
        f"-- sha256: {sha}",
        "--",
        "-- Wiederholbar. Konfigurationsfelder werden auf den Stand der Datei gesetzt.",
        "-- Der Laufzeitzustand (halted_at, halt_reason, halted_by) bleibt unberuehrt.",
        "-- Bindungen, die nicht mehr in der Datei stehen, werden deaktiviert, nicht",
        "-- geloescht.",
        "-- =====================================================================",
        "",
    ]
    bindings = []
    for ctx in sorted(doc["contexts"]):
        c = doc["contexts"][ctx]
        ds = c["document_settings"]
        out.append(
            "INSERT INTO jarvis_ops.context_document_settings (context_id, config_version, storage_adapter_id, "
            "storage_container_ref, context_root_ref, inbox_ref, working_ref, archive_root_ref, drafts_ref, reports_ref, "
            "allowed_mime_types, max_file_size_mb, ocr_provider_allowlist, ocr_min_characters, "
            "ocr_min_mean_confidence, fingerprint_max_hamming, synthetic_marker_required, synthetic_marker_prefix, "
            "quarantine_halt_threshold, quarantine_halt_window_minutes, source_file, source_sha256) VALUES ("
            + ", ".join([
                sql_text(ctx), sql_text(ver), sql_text(ds["storage_adapter_id"]), sql_text(ds["storage_container_ref"]),
                sql_text(ds["context_root_ref"]), sql_text(ds["inbox_ref"]), sql_text(ds["working_ref"]), sql_text(ds["archive_root_ref"]),
                sql_text(ds["drafts_ref"]), sql_text(ds["reports_ref"]), sql_array(ds["allowed_mime_types"]),
                str(int(ds["max_file_size_mb"])), sql_array(ds["ocr_provider_allowlist"]),
                str(int(ds["ocr_min_characters"])), sql_text(ds["ocr_min_mean_confidence"]) + "::numeric",
                str(int(ds["fingerprint_max_hamming"])), sql_bool(ds["synthetic_marker_required"]),
                sql_text(ds["synthetic_marker_prefix"]), str(int(ds["quarantine_halt_threshold"])),
                str(int(ds["quarantine_halt_window_minutes"])), sql_text(rel), sql_text(sha),
            ])
            + ")\nON CONFLICT (context_id) DO UPDATE SET "
            + ", ".join(f"{col} = EXCLUDED.{col}" for col in [
                "config_version", "storage_adapter_id", "storage_container_ref", "context_root_ref", "inbox_ref",
                "working_ref",
                "archive_root_ref", "drafts_ref", "reports_ref", "allowed_mime_types", "max_file_size_mb",
                "ocr_provider_allowlist", "ocr_min_characters", "ocr_min_mean_confidence", "fingerprint_max_hamming",
                "synthetic_marker_required", "synthetic_marker_prefix", "quarantine_halt_threshold",
                "quarantine_halt_window_minutes", "source_file", "source_sha256"])
            + ", loaded_at = now();"
        )
        for b in sorted(c["source_bindings"], key=lambda x: x["binding_key"]):
            bindings.append(b["binding_key"])
            out.append(
                "INSERT INTO jarvis_ops.source_binding (binding_key, context_id, adapter_id, channel, location_ref, "
                "purpose, enabled, config_version, source_file, source_sha256) VALUES ("
                + ", ".join([
                    sql_text(b["binding_key"]), sql_text(ctx), sql_text(b["adapter_id"]), sql_text(b["channel"]),
                    sql_text(b["location_ref"]), sql_text(b["purpose"]), sql_bool(b["enabled"]), sql_text(ver),
                    sql_text(rel), sql_text(sha),
                ])
                + ")\nON CONFLICT (binding_key) DO UPDATE SET context_id = EXCLUDED.context_id, "
                "adapter_id = EXCLUDED.adapter_id, channel = EXCLUDED.channel, location_ref = EXCLUDED.location_ref, "
                "purpose = EXCLUDED.purpose, enabled = EXCLUDED.enabled, config_version = EXCLUDED.config_version, "
                "source_file = EXCLUDED.source_file, source_sha256 = EXCLUDED.source_sha256, loaded_at = now();"
            )
    out += [
        "",
        "-- Nicht mehr konfigurierte Bindungen deaktivieren.",
        "UPDATE jarvis_ops.source_binding SET enabled = false, config_version = " + sql_text(ver)
        + ", loaded_at = now() WHERE enabled AND binding_key <> ALL (" + sql_array(bindings) + ");",
        "",
        "-- Selbstpruefung: Datenbank entspricht der Datei.",
        "DO $$",
        "DECLARE",
        "    v_bad text;",
        "BEGIN",
        "    SELECT string_agg(x, ', ') INTO v_bad FROM (",
        "        SELECT 'settings:' || e.ctx AS x",
        f"        FROM unnest({sql_array(sorted(doc['contexts']))}) AS e(ctx)",
        "        LEFT JOIN jarvis_ops.context_document_settings s ON s.context_id = e.ctx",
        f"        WHERE s.source_sha256 IS DISTINCT FROM {sql_text(sha)}",
        "        UNION ALL",
        "        SELECT 'binding:' || e.k",
        f"        FROM unnest({sql_array(bindings)}) AS e(k)",
        "        LEFT JOIN jarvis_ops.source_binding b ON b.binding_key = e.k",
        f"        WHERE b.source_sha256 IS DISTINCT FROM {sql_text(sha)}",
        "        UNION ALL",
        "        SELECT 'aktiv_ohne_datei:' || b.binding_key",
        "        FROM jarvis_ops.source_binding b",
        f"        WHERE b.enabled AND b.binding_key <> ALL ({sql_array(bindings)})",
        "    ) q;",
        "    IF v_bad IS NOT NULL THEN",
        "        RAISE EXCEPTION 'intake_config_mismatch: %', v_bad USING ERRCODE = '23514';",
        "    END IF;",
        "END",
        "$$;",
        "",
    ]
    return "\n".join(out)


def self_test() -> None:
    raw = CONFIG_FILE.read_bytes()
    ctx = known_contexts()
    sql = render(raw, ctx)
    assert render(raw, ctx) == sql, "Ausgabe nicht deterministisch"
    base = json.loads(raw.decode("utf-8"))

    def expect_fail(mutate, marker: str) -> None:
        d = copy.deepcopy(base)
        mutate(d)
        try:
            render(json.dumps(d).encode("utf-8"), ctx)
        except RenderError as exc:
            assert marker in str(exc), f"falsche Fehlerart: {exc}"
            return
        raise AssertionError(f"Gegenprobe {marker} nicht erkannt")

    expect_fail(lambda d: d["contexts"]["privat"]["document_settings"].update(inbox_ref="1AbCdEfG"), "K1")
    expect_fail(lambda d: d["contexts"].update(fremd=copy.deepcopy(d["contexts"]["privat"])), "K2")
    expect_fail(lambda d: d["contexts"]["arbeitgeber_visolva"]["source_bindings"][0].update(binding_key="privat_drive_inbox"), "K3")
    expect_fail(lambda d: d["contexts"]["privat"]["source_bindings"][0].update(adapter_id="storage_sharepoint"), "K4")
    expect_fail(lambda d: d["contexts"]["arbeitgeber_visolva"]["document_settings"].update(reports_ref="env:JV_PRIVAT_REPORTS_FOLDER_ID"), "K6")
    expect_fail(lambda d: d["contexts"]["privat"]["document_settings"].update(max_file_size_mb=50.5), "K1")
    expect_fail(lambda d: d["contexts"]["privat"]["document_settings"].pop("context_root_ref"), "K1")
    expect_fail(lambda d: d["contexts"]["privat"]["document_settings"].update(
        context_root_ref="env:JV_PRIVAT_INBOX_FOLDER_ID"), "K9")
    expect_fail(lambda d: d.update(config_version="9.9.9"), "K10")

    # K5: zwei Probe-Bindungen auf demselben Ort sind zulaessig (Nachweis K-07) ...
    probe = copy.deepcopy(base)
    probe["contexts"]["privat"]["source_bindings"].append(
        {"binding_key": "privat_k07_probe", "adapter_id": "storage_gdrive", "channel": "drive_inbox",
         "location_ref": "env:JV_K07_PROBE_FOLDER_ID", "purpose": "probe", "enabled": True})
    probe["contexts"]["arbeitgeber_visolva"]["source_bindings"].append(
        {"binding_key": "visolva_k07_probe", "adapter_id": "storage_gdrive", "channel": "drive_inbox",
         "location_ref": "env:JV_K07_PROBE_FOLDER_ID", "purpose": "probe", "enabled": True})
    probe_sql = render(json.dumps(probe).encode("utf-8"), ctx)
    assert probe_sql.count("INSERT INTO jarvis_ops.source_binding") == 4
    # ... aber nie auf einem produktiven Ordner (K8) ...
    def probe_on_archive(d):
        d["contexts"]["privat"]["source_bindings"].append(
            {"binding_key": "privat_k07_probe", "adapter_id": "storage_gdrive", "channel": "drive_inbox",
             "location_ref": "env:JV_PRIVAT_ARCHIVE_ROOT_ID", "purpose": "probe", "enabled": True})
    expect_fail(probe_on_archive, "K8")
    # ... und eine Eingangsbindung auf einem geteilten Ort nie (K5).
    expect_fail(lambda d: d["contexts"]["privat"]["source_bindings"].append(
        {"binding_key": "privat_zweiter_eingang", "adapter_id": "storage_gdrive", "channel": "drive_inbox",
         "location_ref": "env:JV_PRIVAT_INBOX_FOLDER_ID", "purpose": "probe", "enabled": True}), "K5")
    print("SELBSTTEST BESTANDEN: Datei gueltig, deterministisch, Probe zulaessig, 11 Gegenproben")


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
        sql = render(CONFIG_FILE.read_bytes())
        if a.check:
            if a.check.read_text(encoding="utf-8") != sql:
                print("ABWEICHUNG: Migration entspricht nicht der Konfigurationsdatei. Neu erzeugen.")
                return 1
            print("OK: Migration entspricht der Konfigurationsdatei.")
            return 0
        if a.out:
            a.out.mkdir(parents=True, exist_ok=True)
            target = a.out / OUTPUT_BY_VERSION[json.loads(CONFIG_FILE.read_text(encoding="utf-8"))["config_version"]][1]
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
