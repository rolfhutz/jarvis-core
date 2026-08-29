"""
JARVIS Phase 1 - Validierung der Spezifikationsartefakte gegen die Phase-0-Vertraege.

Version 4.0.2

Geprueft wird in acht Teilen:

  1. Die Phase-1-Schemata sind gueltiges JSON Schema Draft 2020-12 und
     referenzieren ausschliesslich Phase-0- oder Phase-1-Definitionen.
  2. Die Beispieldatensaetze validieren gegen ihre Schemata.
  3. Das Phase-1-Werkzeugregister validiert gegen das Phase-0-Registerschema.
  4. Werkzeugvertraege: Ein- und Ausgabeschema existieren, sind gueltig,
     ihre $id-Werte sind eindeutig und alle $ref-Verweise sind aufloesbar.
  5. Normalisierungsregeln: alle Beispiele der Registry werden gegen die
     Referenzimplementierung geprueft, dazu die Ablehnungsfaelle fuer
     unmoegliche Kalenderdaten und die Rechenprobe mit Decimal.
  6. Vertragsregeln V1 bis V17, darunter Belegpflicht, Dateiendung aus dem
     MIME-Typ, Geldwerte ohne Gleitkommazahl und der Ausgang jeder Klaerung.
  7. Freigabeplan der Werkzeuge.
  8. Gegenproben: unzulaessige Faelle muessen abgewiesen werden.

Aufruf:
    python3 tools/validate_phase1.py --phase0 <pfad_zum_phase0_paket>

Voraussetzung: jsonschema, referencing (siehe README.md)
"""

import argparse
import copy
import json
import pathlib
import re
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from referencing.exceptions import Unresolvable

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from normalization_reference import (  # noqa: E402
    NormalizationError, apply_rule, evidence_contains, extension_for_mime,
    filename_matches_mime, is_canonical_money, rule_data_type, to_decimal,
    values_match,
)

RISK_ORDER = {"A": 0, "B": 1, "C": 2}

# Werkzeuge, die in Phase 1 tatsaechlich verwendet werden. Drei davon stammen
# aus dem Phase-0-Register und werden dort unveraendert weitergefuehrt.
PHASE1_TOOLS = [
    "storage_gdrive.get_file",
    "storage_gdrive.move_file",
    "ocr_default.analyze_document",
    "llm_default.extract_fields",
    "llm_default.analyze_document",
    "docstore_internal.upsert_document",
    "casestore_internal.upsert_case",
    "drafts_internal.create_draft",
    "report_internal.write_daily_report",
    "tasks_internal.create_task",
    "approval_email.request_decision",
    "test.record_approved_action",
]

EXAMPLE_MAPPING = {
    "document_filed.json": "document.schema.json",
    "document_filed_photo.json": "document.schema.json",
    "document_needs_review.json": "document.schema.json",
    "document_misrouted.json": "document.schema.json",
    "case_insurance.json": "case.schema.json",
    "document_analysis_beitragsanpassung.json": "document_analysis.schema.json",
    "extraction_result_beitragsanpassung.json": "extraction_result.schema.json",
}

ACTIONABLE_FIELDS = {
    "deadline", "due_date", "effective_date", "total_amount", "new_amount",
    "previous_amount", "unit_amount", "currency", "policy_number",
    "contract_number", "invoice_number", "case_number_external",
    "reference_number", "customer_number", "recipient_name",
}


# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------
def schema_paths(phase0: pathlib.Path):
    return (list((phase0 / "schemas").glob("*.json"))
            + list((ROOT / "schemas").glob("*.json"))
            + list((ROOT / "schemas" / "tools").glob("*.json")))


def load_registry(phase0: pathlib.Path):
    registry = Registry()
    for path in schema_paths(phase0):
        doc = json.loads(path.read_text(encoding="utf-8"))
        registry = registry.with_resource(doc["$id"], Resource.from_contents(doc))
    return registry


def schema_of(name, phase0):
    for candidate in (ROOT / "schemas" / name, phase0 / "schemas" / name):
        if candidate.exists():
            return json.loads(candidate.read_text(encoding="utf-8"))
    raise FileNotFoundError(name)


def resolve_ref_path(ref: str, phase0: pathlib.Path):
    """Ein Schemaverweis wird zuerst im Phase-1-Paket, dann in Phase 0 gesucht."""
    for base in (ROOT, phase0):
        candidate = base / ref
        if candidate.exists():
            return candidate
    return None


def load_tools(phase0):
    p0 = json.loads((phase0 / "registry" / "tool_registry.json").read_text(encoding="utf-8"))
    p1 = json.loads((ROOT / "registry" / "tool_registry_phase1.json").read_text(encoding="utf-8"))
    merged = {t["tool_id"]: t for t in p0["tools"]}
    for t in p1["tools"]:
        merged[t["tool_id"]] = t
    return p0, p1, merged


def load(name):
    return json.loads((ROOT / "examples" / name).read_text(encoding="utf-8"))


def collect_refs(node, out):
    if isinstance(node, dict):
        if isinstance(node.get("$ref"), str):
            out.append(node["$ref"])
        for v in node.values():
            collect_refs(v, out)
    elif isinstance(node, list):
        for v in node:
            collect_refs(v, out)


# ---------------------------------------------------------------------------
# Teil 1 - Schemata
# ---------------------------------------------------------------------------
def validate_schemas_themselves(failures):
    for path in sorted((ROOT / "schemas").glob("*.json")):
        doc = json.loads(path.read_text(encoding="utf-8"))
        try:
            Draft202012Validator.check_schema(doc)
        except Exception as exc:  # noqa: BLE001
            failures.append(f"[SCHEMA] {path.name} ist kein gueltiges Schema: {exc}")
            continue
        refs = []
        collect_refs(doc, refs)
        foreign = [r for r in refs
                   if r.startswith("http") and not r.startswith("https://jarvis.local/schemas/")]
        if foreign:
            failures.append(f"[SCHEMA] {path.name} verweist auf fremde Schemata: {foreign}")
        else:
            print(f"  ok  {path.name:40s} gueltig, {len(refs)} interne Verweise")


# ---------------------------------------------------------------------------
# Teil 2 - Beispiele
# ---------------------------------------------------------------------------
def validate_examples(registry, phase0, failures):
    for filename, schema_name in EXAMPLE_MAPPING.items():
        schema = schema_of(schema_name, phase0)
        instance = load(filename)
        validator = Draft202012Validator(schema, registry=registry)
        errors = sorted(validator.iter_errors(instance), key=lambda e: e.path)
        if errors:
            for e in errors:
                failures.append(f"[BEISPIEL] {filename}: {list(e.path)} -> {e.message}")
        else:
            print(f"  ok  {filename:44s} gegen {schema_name}")


# ---------------------------------------------------------------------------
# Teil 3 - Werkzeugregister
# ---------------------------------------------------------------------------
def validate_tool_registry(registry, phase0, failures):
    schema = json.loads((phase0 / "schemas" / "tool_registry.schema.json").read_text(encoding="utf-8"))
    p0, p1, merged = load_tools(phase0)
    validator = Draft202012Validator(schema, registry=registry)
    errors = sorted(validator.iter_errors(p1), key=lambda e: e.path)
    if errors:
        for e in errors:
            failures.append(f"[REGISTER] tool_registry_phase1.json: {list(e.path)} -> {e.message}")
    else:
        print(f"  ok  tool_registry_phase1.json ({len(p1['tools'])} Werkzeuge) gegen Phase-0-Registerschema")

    overlap = {t["tool_id"] for t in p0["tools"]} & {t["tool_id"] for t in p1["tools"]}
    if overlap:
        failures.append(f"[REGISTER] Doppelt gepflegte Werkzeuge: {sorted(overlap)}")
    else:
        print(f"  ok  Keine Doppelpflege zwischen den Registern ({len(merged)} Werkzeuge gesamt)")

    missing = [t for t in PHASE1_TOOLS if t not in merged]
    if missing:
        failures.append(f"[REGISTER] In Phase 1 verwendete Werkzeuge ohne Vertrag: {missing}")
    else:
        print(f"  ok  Alle {len(PHASE1_TOOLS)} in Phase 1 verwendeten Werkzeuge sind registriert")


# ---------------------------------------------------------------------------
# Teil 4 - Werkzeugvertraege vollstaendig aufloesbar
# ---------------------------------------------------------------------------
def validate_tool_contracts(registry, phase0, failures):
    _, _, merged = load_tools(phase0)
    seen_ids = {}
    checked = 0

    for path in schema_paths(phase0):
        doc = json.loads(path.read_text(encoding="utf-8"))
        sid = doc.get("$id")
        if sid is None:
            failures.append(f"[VERTRAG] {path.name} hat keine $id")
            continue
        if sid in seen_ids and seen_ids[sid] != path.name:
            failures.append(f"[VERTRAG] Doppelte $id {sid}: {seen_ids[sid]} und {path.name}")
        seen_ids[sid] = path.name

    for tool_id in PHASE1_TOOLS:
        tool = merged[tool_id]
        for slot in ("input_schema_ref", "output_schema_ref"):
            ref = tool.get(slot)
            if not ref:
                failures.append(f"[VERTRAG] {tool_id}: {slot} fehlt")
                continue
            path = resolve_ref_path(ref, phase0)
            if path is None:
                failures.append(f"[VERTRAG] {tool_id}: {slot} zeigt auf die nicht vorhandene Datei {ref}")
                continue
            doc = json.loads(path.read_text(encoding="utf-8"))
            try:
                Draft202012Validator.check_schema(doc)
            except Exception as exc:  # noqa: BLE001
                failures.append(f"[VERTRAG] {tool_id}: {ref} ist kein gueltiges Schema: {exc}")
                continue
            validator = Draft202012Validator(doc, registry=registry)
            try:
                list(validator.iter_errors({"__unresolvable_probe__": True}))
            except Unresolvable as exc:
                failures.append(f"[VERTRAG] {tool_id}: nicht aufloesbarer Verweis in {ref}: {exc}")
                continue
            checked += 1

    if not any(f.startswith("[VERTRAG]") for f in failures):
        print(f"  ok  {checked} Vertragsschemata vorhanden, gueltig und vollstaendig aufloesbar")
        print(f"  ok  {len(seen_ids)} Schema-Kennungen sind eindeutig")


# ---------------------------------------------------------------------------
# Teil 5 - Normalisierungsregeln
# ---------------------------------------------------------------------------
def validate_normalization_rules(failures):
    reg = json.loads((ROOT / "registry" / "normalization_rules.json").read_text(encoding="utf-8"))
    total = 0
    total_rejects = 0
    for rule in reg["rules"]:
        rid = rule["rule_id"]
        try:
            declared = rule_data_type(rid)
        except NormalizationError as exc:
            failures.append(f"[NORM] {rid}: {exc}")
            continue
        if declared != rule["data_type"]:
            failures.append(
                f"[NORM] {rid}: Datentyp {rule['data_type']} weicht von der Implementierung ({declared}) ab")
        bad = []
        for ex in rule["examples"]:
            total += 1
            try:
                got = apply_rule(rid, ex["raw"])
            except NormalizationError as exc:
                bad.append(f"{ex['raw']!r} -> Fehler {exc}")
                continue
            if not values_match(ex["normalized"], got):
                bad.append(f"{ex['raw']!r} -> {got!r} statt {ex['normalized']!r}")
        rejected = 0
        for raw in rule.get("rejects", []):
            try:
                got = apply_rule(rid, raw)
            except NormalizationError:
                rejected += 1
                continue
            bad.append(f"{raw!r} wurde faelschlich akzeptiert und ergab {got!r}")
        if bad:
            failures.append(f"[NORM] {rid}: {bad}")
        else:
            suffix = f", {rejected} unzulaessige Eingaben abgewiesen" if rejected else ""
            print(f"  ok  {rid:32s} {len(rule['examples'])} Beispiele reproduziert{suffix}")
        total_rejects += rejected
    if not any(f.startswith("[NORM]") for f in failures):
        print(f"  ok  {total} Beispiele und {total_rejects} Ablehnungsfaelle aus der Registry geprueft")

    # Geldwerte werden exakt gerechnet, nicht als Gleitkommazahl
    summe = to_decimal(apply_rule("decimal.de", "0,10")) + to_decimal(apply_rule("decimal.de", "0,20"))
    if format(summe, "f") != "0.30":
        failures.append(f"[NORM] Decimal-Rechenprobe: 0.10 + 0.20 ergab {summe}")
    elif 0.1 + 0.2 == 0.3:
        failures.append("[NORM] Rechenprobe ohne Aussagekraft: float verhaelt sich unerwartet exakt")
    else:
        print('  ok  Decimal-Rechenprobe: "0.10" + "0.20" = "0.30" (mit float waere das Ergebnis ungleich)')

    if is_canonical_money(1234.5) or not is_canonical_money("1234.50"):
        failures.append("[NORM] Erkennung kanonischer Geldwerte ist fehlerhaft")
    else:
        print("  ok  Eine Gleitkommazahl gilt nicht als kanonischer Geldwert")


# ---------------------------------------------------------------------------
# Teil 6 - Vertragsregeln
# ---------------------------------------------------------------------------
def check_field_evidence(extraction):
    """Zweistufige Belegpruefung. Gibt eine Liste von Beanstandungen zurueck."""
    findings = []
    for f in extraction["fields"]:
        if f["normalized_value"] is None:
            continue
        ev = f.get("evidence")
        if not ev:
            findings.append(f"{f['field_key']}: Wert ohne Beleg")
            continue
        if not evidence_contains(ev["snippet"], f["raw_value"]):
            findings.append(f"{f['field_key']}: raw_value nicht im Beleg auffindbar")
            continue
        rule = f.get("normalization_rule")
        if not rule:
            findings.append(f"{f['field_key']}: keine Normalisierungsregel")
            continue
        try:
            derived = apply_rule(rule, f["raw_value"])
        except NormalizationError as exc:
            findings.append(f"{f['field_key']}: Regel {rule} nicht anwendbar ({exc})")
            continue
        if not values_match(f["normalized_value"], derived):
            findings.append(
                f"{f['field_key']}: normalized_value {f['normalized_value']!r} "
                f"laesst sich nicht aus raw_value ableiten (ergibt {derived!r})")
    return findings


def check_line_items(extraction):
    findings = []
    field_keys = {f["field_key"] for f in extraction["fields"]
                  if f["normalized_value"] is not None
                  and f["validation_status"] in ("accepted", "accepted_flagged")}
    for item in extraction.get("line_items", []):
        for slot, raw_slot in (("total_amount", "total_amount_raw"), ("unit_amount", "unit_amount_raw")):
            if item.get(slot) is None:
                continue
            raw = item.get(raw_slot)
            rule = item.get("normalization_rule")
            if not raw or not rule:
                findings.append(f"Position {item['position']}: {slot} ohne Rohwert oder Regel")
                continue
            ev = item.get("evidence")
            ref = item.get("field_ref")
            if ev:
                if not evidence_contains(ev["snippet"], raw):
                    findings.append(f"Position {item['position']}: {raw_slot} nicht im Beleg auffindbar")
            elif ref:
                if ref not in field_keys:
                    findings.append(f"Position {item['position']}: field_ref {ref} verweist auf kein belegtes Feld")
            else:
                findings.append(f"Position {item['position']}: {slot} ohne Beleg und ohne Feldverweis")
                continue
            try:
                derived = apply_rule(rule, raw)
            except NormalizationError as exc:
                findings.append(f"Position {item['position']}: Regel nicht anwendbar ({exc})")
                continue
            if not values_match(item[slot], derived):
                findings.append(f"Position {item['position']}: {slot} laesst sich nicht aus {raw_slot} ableiten")
    return findings


def check_resume(doc, resume_map):
    """
    Ausgang einer manuellen Pruefung. Zwei Faelle, die nicht vermischt werden:
    eine fortzusetzende Klaerung mit genau einem Wiederanlaufpunkt, oder eine
    terminale Klaerung ohne jede weitere Verarbeitung.
    """
    findings = []
    review = doc.get("review", {})
    if not review.get("resolved_at"):
        return findings
    rtype = review.get("resolution_type")
    entry = resume_map.get(rtype)
    if entry is None:
        findings.append(f"Unbekannte Klaerungsart {rtype}")
        return findings

    outcome = review.get("outcome")
    if outcome != entry["outcome"]:
        findings.append(f"{rtype}: outcome {outcome} weicht von der Registry ({entry['outcome']}) ab")
        return findings

    if outcome == "resume":
        if review.get("resume_from_stage") != entry["resume_from_stage"]:
            findings.append(
                f"{rtype}: resume_from_stage {review.get('resume_from_stage')} weicht von "
                f"der Registry ({entry['resume_from_stage']}) ab")
        if review.get("terminal_status"):
            findings.append(f"{rtype}: fortzusetzende Klaerung mit Endzustand")
    else:
        if review.get("resume_from_stage") is not None:
            findings.append(f"{rtype}: terminale Klaerung mit Wiederanlaufpunkt "
                            f"{review.get('resume_from_stage')}")
        if review.get("terminal_status") != entry["terminal_status"]:
            findings.append(f"{rtype}: terminal_status {review.get('terminal_status')} weicht von "
                            f"der Registry ({entry['terminal_status']}) ab")
        if doc.get("status") != entry["terminal_status"] and entry["terminal_status"] != "duplicate":
            findings.append(f"{rtype}: Dokumentstatus {doc.get('status')} passt nicht zum "
                            f"Endzustand {entry['terminal_status']}")
        if review.get("successor_intake_hint") and entry["terminal_status"] != "misrouted":
            findings.append(f"{rtype}: Hinweis auf einen neuen Eingang bei nicht fehlgeleitetem Dokument")

    if entry["requires_resolved_values"] and not review.get("resolved_values"):
        findings.append(f"{rtype}: erfordert resolved_values, es fehlen aber Werte")
    if not review.get("blocked_stage"):
        findings.append(f"{rtype}: blocked_stage fehlt")
    return findings


def check_no_cross_context_write(doc):
    """
    Ein fehlgeleitetes Dokument darf keinen Schreibzugriff in ein fremdes
    Kontextschema ausloesen. Zulaessig ist hoechstens ein Hinweis auf den
    erwarteten neuen Eingang, und der traegt keinen fachlichen Inhalt.
    """
    findings = []
    review = doc.get("review", {})
    if review.get("terminal_status") != "misrouted":
        return findings
    ctx = doc["context_id"]
    if doc.get("derived_task_ids") or doc.get("derived_action_ids"):
        findings.append("Fehlgeleitetes Dokument hat Aufgaben oder Aktionen erzeugt")
    if doc.get("storage"):
        findings.append("Fehlgeleitetes Dokument wurde abgelegt")
    if doc.get("case_ref", {}).get("case_id"):
        findings.append("Fehlgeleitetes Dokument wurde einem Vorgang zugeordnet")
    for ref in (doc.get("extraction_result_ref"), doc.get("analysis_ref")):
        if ref and not ref.startswith(ctx + "."):
            findings.append(f"Verweis in ein fremdes Kontextschema: {ref}")
    hint = review.get("successor_intake_hint", "")
    if hint and not re.fullmatch(r"reintake:[a-z][a-z0-9_]*/[a-z_]+", hint):
        findings.append(f"Hinweis auf den neuen Eingang hat kein zulaessiges Format: {hint}")
    return findings


def check_contract_rules(phase0, failures):
    _, p1, _ = load_tools(phase0)
    doc = load("document_filed.json")
    photo = load("document_filed_photo.json")
    rev = load("document_needs_review.json")
    misrouted = load("document_misrouted.json")
    case = load("case_insurance.json")
    analysis = load("document_analysis_beitragsanpassung.json")
    extraction = load("extraction_result_beitragsanpassung.json")
    resume_map = {r["resolution_type"]: r for r in json.loads(
        (ROOT / "registry" / "review_resume_map.json").read_text(encoding="utf-8"))["resolutions"]}

    docschema = json.loads((ROOT / "schemas" / "document.schema.json").read_text(encoding="utf-8"))

    # V1
    props = docschema["properties"]
    forbidden = [k for k in props if k in ("tasks", "actions", "approvals", "evidence", "task", "action")]
    if forbidden:
        failures.append(f"[V1] Dokumentschema enthaelt eingebettete Aufgaben oder Aktionen: {forbidden}")
    elif "derived_task_ids" not in props or "derived_action_ids" not in props:
        failures.append("[V1] Dokumentschema verweist nicht per ID auf Aufgaben und Aktionen")
    else:
        print("  ok  V1 Dokument verweist auf Aufgaben und Aktionen, bettet sie nicht ein")

    # V2
    if len({doc["context_id"], case["context_id"], analysis["context_id"], extraction["context_id"]}) != 1:
        failures.append("[V2] Kontextvermischung zwischen Dokument, Vorgang, Extraktion und Analyse")
    else:
        print("  ok  V2 Dokument, Vorgang, Extraktion und Analyse tragen denselben Kontext")

    # V3
    if doc.get("case_ref", {}).get("case_id") != case["case_id"]:
        failures.append("[V3] Dokument verweist nicht auf den zugehoerigen Vorgang")
    elif doc["document_id"] not in case["document_ids"]:
        failures.append("[V3] Vorgang kennt das Dokument nicht")
    else:
        print("  ok  V3 Dokument und Vorgang verweisen wechselseitig aufeinander")

    # V4
    if case["case_number"] not in doc.get("storage", {}).get("final_filename", ""):
        failures.append("[V4] Vorgangsnummer fehlt im Dateinamen")
    else:
        print("  ok  V4 Dateiname enthaelt die Vorgangsnummer")

    # V5
    bad = [p["title_de"] for p in analysis["proposed_tasks"]
           if not p.get("success_criterion_de") or not p.get("evidence_snippet")]
    if bad:
        failures.append(f"[V5] Aufgabenvorschlaege ohne Erfolgskriterium oder Beleg: {bad}")
    else:
        print(f"  ok  V5 Alle {len(analysis['proposed_tasks'])} Aufgabenvorschlaege belegt und mit Erfolgskriterium")

    # V6
    v6 = []
    for t in p1["tools"]:
        ev = t["evidence"]
        if ev["readback_supported"] and ev["accepted_methods"] != ["readback"]:
            v6.append(f"{t['tool_id']}: Readback moeglich, aber schwaechere Methode zugelassen")
        if not ev["readback_supported"] and not ev.get("limitation"):
            v6.append(f"{t['tool_id']}: Ersatznachweis ohne Grenzangabe")
    failures.extend(f"[V6] {m}" for m in v6)
    if not v6:
        print("  ok  V6 Alle Nachweisstrategien entsprechen der Entscheidung D3")

    # V7
    class_c = [t["tool_id"] for t in p1["tools"] if t["risk_class_default"] == "C"]
    if class_c != ["test.record_approved_action"]:
        failures.append(f"[V7] Unerwartete Klasse-C-Werkzeuge in Phase 1: {class_c}")
    else:
        print("  ok  V7 Klasse C in Phase 1 ausschliesslich ueber das gekennzeichnete Testwerkzeug")

    # V8
    external = [t["tool_id"] for t in p1["tools"]
                if t["external_effect"] in ("external_recipient", "financial", "legal")]
    if external:
        failures.append(f"[V8] Phase-1-Werkzeug mit Aussenwirkung: {external}")
    else:
        print("  ok  V8 Kein Phase-1-Werkzeug loest externe Kommunikation aus")

    # V9
    findings = check_field_evidence(extraction)
    if findings:
        failures.extend(f"[V9] {m}" for m in findings)
    else:
        used = [f for f in extraction["fields"] if f["normalized_value"] is not None]
        print(f"  ok  V9 Alle {len(used)} erkannten Felder sind belegt und ableitbar")

    # V10
    findings = check_line_items(extraction)
    if findings:
        failures.extend(f"[V10] {m}" for m in findings)
    else:
        n = len([i for i in extraction.get("line_items", []) if i.get("total_amount") is not None])
        print(f"  ok  V10 Alle {n} Positionsbetraege sind belegt oder verweisen auf ein belegtes Feld")

    # V11
    v11 = [f["field_key"] for f in extraction["fields"]
           if f["field_key"] in ACTIONABLE_FIELDS
           and f["validation_status"] in ("accepted", "accepted_flagged")
           and not f.get("evidence")]
    if v11:
        failures.append(f"[V11] Handlungsrelevante Felder ohne Beleg: {v11}")
    else:
        print("  ok  V11 Kein handlungsrelevantes Feld ohne Beleg")

    # V12
    v12 = []
    for name, d in (("document_filed", doc), ("document_filed_photo", photo)):
        fn = d.get("storage", {}).get("final_filename")
        mime = d["file"]["mime_type"]
        try:
            if not filename_matches_mime(fn, mime):
                v12.append(f"{name}: Endung passt nicht zu {mime}, erwartet .{extension_for_mime(mime)}")
        except NormalizationError as exc:
            v12.append(f"{name}: {exc}")
    failures.extend(f"[V12] {m}" for m in v12)
    if not v12:
        print("  ok  V12 Dateiendungen entsprechen dem geprueften MIME-Typ (PDF und JPEG)")

    # V13
    findings = check_resume(rev, resume_map) + check_resume(misrouted, resume_map)
    if findings:
        failures.extend(f"[V13] {m}" for m in findings)
    else:
        print(f"  ok  V13 Ausgang jeder Klaerung ist deterministisch "
              f"({rev['review']['resolution_type']} -> {rev['review']['resume_from_stage']}, "
              f"{misrouted['review']['resolution_type']} -> terminal)")

    # V14
    schema_types = set(docschema["properties"]["review"]["properties"]["resolution_type"]["enum"])
    registry_types = set(resume_map)
    if schema_types != registry_types:
        failures.append(f"[V14] Klaerungsarten weichen ab: {schema_types ^ registry_types}")
    else:
        stages = set(docschema["$defs"]["processing_stage_key"]["enum"])
        bad_stage = [r["resolution_type"] for r in resume_map.values()
                     if r["outcome"] == "resume" and r["resume_from_stage"] not in stages]
        terminal_states = set(docschema["properties"]["review"]["properties"]["terminal_status"]["enum"])
        bad_stage += [r["resolution_type"] for r in resume_map.values()
                      if r["outcome"] == "terminal" and r["terminal_status"] not in terminal_states]
        if bad_stage:
            failures.append(f"[V14] Unbekannte Wiederanlaufstufe bei: {bad_stage}")
        else:
            print(f"  ok  V14 {len(registry_types)} Klaerungsarten stimmen mit der Registry ueberein")

    # V15 Terminale Klaerungen haben keinen Wiederanlaufpunkt
    v15 = []
    for r in resume_map.values():
        if r["outcome"] == "terminal":
            if r["resume_from_stage"] is not None:
                v15.append(f"{r['resolution_type']}: terminal mit Wiederanlaufpunkt")
            if not r["terminal_status"]:
                v15.append(f"{r['resolution_type']}: terminal ohne Endzustand")
        else:
            if r["resume_from_stage"] is None:
                v15.append(f"{r['resolution_type']}: fortzusetzend ohne Wiederanlaufpunkt")
            if r["terminal_status"]:
                v15.append(f"{r['resolution_type']}: fortzusetzend mit Endzustand")
    failures.extend(f"[V15] {m}" for m in v15)
    if not v15:
        n_term = sum(1 for r in resume_map.values() if r["outcome"] == "terminal")
        n_res = len(resume_map) - n_term
        print(f"  ok  V15 {n_res} fortzusetzende und {n_term} terminale Klaerungen sind sauber getrennt")

    # V16 Kein kontextuebergreifender Schreibzugriff bei fehlgeleiteten Dokumenten
    findings = check_no_cross_context_write(misrouted)
    if findings:
        failures.extend(f"[V16] {m}" for m in findings)
    else:
        print("  ok  V16 Fehlgeleitetes Dokument erzeugt keinen kontextuebergreifenden Schreibzugriff")

    # V17 Geldwerte niemals als Gleitkommazahl
    v17 = []
    for f in extraction["fields"]:
        if f["data_type"] == "money":
            if isinstance(f["normalized_value"], float):
                v17.append(f"{f['field_key']}: Geldwert als Gleitkommazahl")
            elif f["normalized_value"] is not None and not is_canonical_money(f["normalized_value"]):
                v17.append(f"{f['field_key']}: Geldwert nicht in kanonischer Darstellung")
    for item in extraction.get("line_items", []):
        for slot in ("total_amount", "unit_amount"):
            val = item.get(slot)
            if val is None:
                continue
            if isinstance(val, float) or not is_canonical_money(val):
                v17.append(f"Position {item['position']}: {slot} nicht kanonisch")
    for c in analysis.get("changes_vs_previous", []):
        for slot in ("previous_value", "current_value", "delta_absolute"):
            if isinstance(c.get(slot), float):
                v17.append(f"changes_vs_previous.{slot} als Gleitkommazahl")
    failures.extend(f"[V17] {m}" for m in v17)
    if not v17:
        n_money = sum(1 for f in extraction["fields"] if f["data_type"] == "money")
        print(f"  ok  V17 Alle {n_money} Geldfelder und alle Positionsbetraege sind kanonische Zeichenfolgen")


# ---------------------------------------------------------------------------
# Teil 7 - Freigabeplan
# ---------------------------------------------------------------------------
def validate_release_plan(phase0, failures):
    plan = json.loads((ROOT / "registry" / "tool_release_plan.json").read_text(encoding="utf-8"))
    _, _, merged = load_tools(phase0)
    planned = {t["tool_id"]: t for t in plan["tools"]}

    missing = [t for t in PHASE1_TOOLS if t not in planned]
    if missing:
        failures.append(f"[FREIGABE] Werkzeuge ohne Freigabeplan: {missing}")
    else:
        print(f"  ok  Alle {len(PHASE1_TOOLS)} Phase-1-Werkzeuge haben einen Freigabeplan")

    not_draft = [t for t, e in planned.items()
                 if merged.get(t, {}).get("status") != "draft" or e["current_status"] != "draft"]
    if not_draft:
        failures.append(f"[FREIGABE] Werkzeuge freigegeben, obwohl noch nichts geprueft wurde: {not_draft}")
    else:
        print("  ok  Kein Werkzeug steht vor dem Nachweis auf approved")

    early = [t for t, e in planned.items()
             if e["release_in_step"] == "1.0" and e["adapter_selection_open"]]
    if early:
        failures.append(f"[FREIGABE] Freigabe in 1.0 trotz offener Adapterauswahl: {early}")
    else:
        n10 = [t for t, e in planned.items() if e["release_in_step"] == "1.0"]
        print(f"  ok  Phase 1.0 gibt nur {len(n10)} Kernwerkzeuge mit feststehendem Adapter frei")

    open_adapter = {t for t, e in planned.items() if e["adapter_selection_open"]}
    expected = {"ocr_default.analyze_document", "llm_default.extract_fields",
                "llm_default.analyze_document", "approval_email.request_decision"}
    if open_adapter != expected:
        failures.append(f"[FREIGABE] Unerwartete Menge offener Adapter: {open_adapter ^ expected}")
    else:
        print("  ok  OCR-, Modell- und Freigabewerkzeuge werden erst in ihrer Teilphase freigegeben")


# ---------------------------------------------------------------------------
# Teil 8 - Gegenproben
# ---------------------------------------------------------------------------
def negative_cases(registry, phase0, failures):
    docschema = schema_of("document.schema.json", phase0)
    caseschema = schema_of("case.schema.json", phase0)
    anaschema = schema_of("document_analysis.schema.json", phase0)
    extschema = schema_of("extraction_result.schema.json", phase0)
    _, p1, _ = load_tools(phase0)
    regschema = json.loads((phase0 / "schemas" / "tool_registry.schema.json").read_text(encoding="utf-8"))

    doc = load("document_filed.json")
    photo = load("document_filed_photo.json")
    rev = load("document_needs_review.json")
    misrouted = load("document_misrouted.json")
    case = load("case_insurance.json")
    ana = load("document_analysis_beitragsanpassung.json")
    ext = load("extraction_result_beitragsanpassung.json")

    schema_cases = []

    d = copy.deepcopy(doc); d.pop("storage")
    schema_cases.append(("G01 Abgelegtes Dokument ohne Ablageziel", docschema, d))

    d = copy.deepcopy(doc); d["status"] = "duplicate"
    schema_cases.append(("G02 Dublette ohne Verweis auf das Original", docschema, d))

    d = copy.deepcopy(rev); d["review"] = {"required": True}
    schema_cases.append(("G03 Manuelle Pruefung ohne Grund und Stufe", docschema, d))

    d = copy.deepcopy(doc); d["classification"]["category_key"] = "07 Versicherungen"
    schema_cases.append(("G04 Kategorieschluessel mit Leerzeichen", docschema, d))

    c = copy.deepcopy(case); c["case_number"] = "2026-42"
    schema_cases.append(("G05 Vorgangsnummer im falschen Format", caseschema, c))

    c = copy.deepcopy(case); c["status"] = "closed"
    schema_cases.append(("G06 Abgeschlossener Vorgang ohne Abschlusszeitpunkt", caseschema, c))

    a = copy.deepcopy(ana); a["proposed_tasks"][0].pop("success_criterion_de")
    schema_cases.append(("G07 Aufgabenvorschlag ohne Erfolgskriterium", anaschema, a))

    a = copy.deepcopy(ana); a["proposed_tasks"][0].pop("evidence_snippet")
    schema_cases.append(("G08 Aufgabenvorschlag ohne Textbeleg", anaschema, a))

    a = copy.deepcopy(ana); a["proposed_tasks"][0]["risk_class"] = "A"
    schema_cases.append(("G09 Modell setzt eine Risikoklasse", anaschema, a))

    e = copy.deepcopy(ext); e["fields"][1].pop("evidence")
    schema_cases.append(("G10 Erkanntes Feld ohne Textbeleg", extschema, e))

    e = copy.deepcopy(ext); e["fields"][1].pop("normalization_rule")
    schema_cases.append(("G11 Erkanntes Feld ohne Normalisierungsregel", extschema, e))

    e = copy.deepcopy(ext); e["fields"][1]["raw_value"] = None
    schema_cases.append(("G12 Kanonischer Wert ohne Rohwert", extschema, e))

    e = copy.deepcopy(ext); e["fields"][1]["normalization_rule"] = "date.fantasie"
    schema_cases.append(("G13 Unbekannte Normalisierungsregel", extschema, e))

    e = copy.deepcopy(ext); e["line_items"][1].pop("evidence")
    schema_cases.append(("G14 Positionsbetrag ohne Beleg und ohne Feldverweis", extschema, e))

    e = copy.deepcopy(ext); e["line_items"][1].pop("total_amount_raw")
    schema_cases.append(("G15 Positionsbetrag ohne Rohwert", extschema, e))

    d = copy.deepcopy(rev); d["review"].pop("resume_from_stage")
    schema_cases.append(("G16 Geklaerte Pruefung ohne Wiederanlaufpunkt", docschema, d))

    d = copy.deepcopy(rev); d["review"].pop("resolution_type")
    schema_cases.append(("G17 Geklaerte Pruefung ohne Art der Klaerung", docschema, d))

    d = copy.deepcopy(rev); d["review"]["resolution_type"] = "duplicate_confirmed"
    schema_cases.append(("G18 Korrigierte Werte bei einer Klaerung ohne Wertkorrektur", docschema, d))

    d = copy.deepcopy(rev); d["review"]["resume_from_stage"] = "verstehen"
    schema_cases.append(("G19 Unbekannte Wiederanlaufstufe", docschema, d))

    d = copy.deepcopy(photo)
    d["storage"]["final_filename"] = "2026-08-29__Elektrofachmarkt__Quittung__Waschmaschine__V-2026-0043.gif"
    schema_cases.append(("G20 Dateiendung ausserhalb der erlaubten Formate", docschema, d))

    d = copy.deepcopy(doc); d["storage"]["final_filename"] = "Beitragsanpassung.pdf"
    schema_cases.append(("G21 Dateiname ohne Datum und Vorgangsnummer", docschema, d))

    bad_reg = copy.deepcopy(p1)
    bad_reg["tools"][8]["risk_class_default"] = "A"
    bad_reg["tools"][8]["external_effect"] = "legal"
    schema_cases.append(("G22 Werkzeug mit rechtlicher Wirkung als Klasse A", regschema, bad_reg))

    bad_reg = copy.deepcopy(p1)
    bad_reg["tools"][4]["evidence"]["accepted_methods"] = ["provider_status"]
    schema_cases.append(("G23 Vertrag umgeht den moeglichen Readback", regschema, bad_reg))

    e = copy.deepcopy(ext)
    e["fields"][4]["normalized_value"] = 448.0
    schema_cases.append(("G34 Geldwert als Gleitkommazahl im Feld", extschema, e))

    e = copy.deepcopy(ext)
    e["fields"][4]["normalized_value"] = "448.0"
    schema_cases.append(("G35 Geldwert mit nur einer Nachkommastelle", extschema, e))

    e = copy.deepcopy(ext)
    e["fields"][4]["normalized_value"] = "4.4800e2"
    schema_cases.append(("G36 Geldwert in Exponentialschreibweise", extschema, e))

    e = copy.deepcopy(ext)
    e["line_items"][1]["total_amount"] = 1234.5
    schema_cases.append(("G37 Positionsbetrag als Gleitkommazahl", extschema, e))

    d = copy.deepcopy(rev)
    d["review"]["outcome"] = "terminal"
    d["review"]["terminal_status"] = "discarded"
    schema_cases.append(("G38 Terminale Klaerung mit Wiederanlaufstufe", docschema, d))

    d = copy.deepcopy(misrouted)
    d["review"]["outcome"] = "resume"
    schema_cases.append(("G39 Fortzusetzende Klaerung ohne Wiederanlaufstufe", docschema, d))

    d = copy.deepcopy(misrouted)
    d["review"]["resume_from_stage"] = "analysis"
    schema_cases.append(("G40 Terminale Klaerung mit gesetztem Wiederanlaufpunkt", docschema, d))

    d = copy.deepcopy(rev)
    d["review"]["successor_intake_hint"] = "reintake:arbeitgeber_visolva/inbox"
    schema_cases.append(("G41 Hinweis auf neuen Eingang bei nicht fehlgeleitetem Dokument", docschema, d))

    d = copy.deepcopy(misrouted)
    d["status"] = "filed"
    schema_cases.append(("G42 Fehlgeleitetes Dokument mit Ablagestatus", docschema, d))

    for label, schema, instance in schema_cases:
        validator = Draft202012Validator(schema, registry=registry)
        if list(validator.iter_errors(instance)):
            print(f"  ok  {label:62s} wird abgewiesen")
        else:
            print(f"  FEHLER {label:59s} wird faelschlich akzeptiert")
            failures.append(f"[GEGENPROBE] {label}")

    resume_map = {r["resolution_type"]: r for r in json.loads(
        (ROOT / "registry" / "review_resume_map.json").read_text(encoding="utf-8"))["resolutions"]}

    contract_cases = []

    e = copy.deepcopy(ext)
    e["fields"][4]["raw_value"] = "CHF 999.00"
    e["fields"][4]["normalized_value"] = 999.0
    contract_cases.append(("G24 Erfundener Betrag, Rohwert steht nicht im Beleg",
                           lambda inst=e: check_field_evidence(inst)))

    e = copy.deepcopy(ext); e["fields"][4]["normalized_value"] = 4480.0
    contract_cases.append(("G25 Kanonischer Betrag nicht aus dem Rohwert ableitbar",
                           lambda inst=e: check_field_evidence(inst)))

    e = copy.deepcopy(ext); e["fields"][2]["normalized_value"] = "2026-10-30"
    contract_cases.append(("G26 Manipuliertes Datum ohne Deckung im Rohwert",
                           lambda inst=e: check_field_evidence(inst)))

    e = copy.deepcopy(ext); e["fields"][3]["normalized_value"] = "kv9999999"
    contract_cases.append(("G27 Manipulierte Kennung",
                           lambda inst=e: check_field_evidence(inst)))

    e = copy.deepcopy(ext); e["line_items"][1]["total_amount"] = 9999.0
    contract_cases.append(("G28 Positionsbetrag weicht vom Rohwert ab",
                           lambda inst=e: check_line_items(inst)))

    e = copy.deepcopy(ext); e["line_items"][0]["field_ref"] = "gibt_es_nicht"
    contract_cases.append(("G29 Feldverweis einer Position zeigt ins Leere",
                           lambda inst=e: check_line_items(inst)))

    r = copy.deepcopy(rev); r["review"]["resume_from_stage"] = "filing"
    contract_cases.append(("G30 Wiederanlaufpunkt widerspricht der Registry",
                           lambda inst=r: check_resume(inst, resume_map)))

    r = copy.deepcopy(rev)
    r["review"]["resolution_type"] = "value_corrected"
    r["review"].pop("resolved_values")
    contract_cases.append(("G31 Wertkorrektur ohne korrigierte Werte",
                           lambda inst=r: check_resume(inst, resume_map)))

    r = copy.deepcopy(misrouted)
    r["review"]["resolution_type"] = "duplicate_confirmed"
    r["review"]["terminal_status"] = "duplicate"
    r["review"]["outcome"] = "resume"
    r["review"]["resume_from_stage"] = "intake"
    contract_cases.append(("G43 Bestaetigte Dublette wird erneut verarbeitet",
                           lambda inst=r: check_resume(inst, resume_map)))

    r = copy.deepcopy(misrouted)
    r["review"]["resolution_type"] = "document_discarded"
    r["review"]["terminal_status"] = "discarded"
    r["status"] = "discarded"
    r["review"]["outcome"] = "resume"
    r["review"]["resume_from_stage"] = "intake"
    contract_cases.append(("G44 Verworfenes Dokument wird erneut verarbeitet",
                           lambda inst=r: check_resume(inst, resume_map)))

    r = copy.deepcopy(misrouted)
    r["derived_task_ids"] = ["tsk_01JBQ8Z4K7M3N9P2R5T6V8W1B9"]
    contract_cases.append(("G45 Fehlgeleitetes Dokument erzeugt Aufgaben",
                           lambda inst=r: check_no_cross_context_write(inst)))

    r = copy.deepcopy(misrouted)
    r["extraction_result_ref"] = "arbeitgeber_visolva.document_extraction:doc_01JBQ8Z4K7M3N9P2R5T6V8W0Z6"
    contract_cases.append(("G46 Fehlgeleitetes Dokument schreibt in ein fremdes Kontextschema",
                           lambda inst=r: check_no_cross_context_write(inst)))

    r = copy.deepcopy(misrouted)
    r["review"]["successor_intake_hint"] = "Kunde Mustermann, Rechnung 4711"
    contract_cases.append(("G47 Hinweis auf neuen Eingang enthaelt fachlichen Inhalt",
                           lambda inst=r: check_no_cross_context_write(inst)))

    for label, check in contract_cases:
        findings = check()
        if findings:
            print(f"  ok  {label:62s} wird abgewiesen")
        else:
            print(f"  FEHLER {label:59s} wird faelschlich akzeptiert")
            failures.append(f"[GEGENPROBE] {label}")

    label = "G32 Dateiendung passt nicht zum MIME-Typ"
    if not filename_matches_mime(
            "2026-08-29__Elektrofachmarkt__Quittung__Waschmaschine__V-2026-0043.pdf", "image/jpeg"):
        print(f"  ok  {label:62s} wird abgewiesen")
    else:
        print(f"  FEHLER {label:59s} wird faelschlich akzeptiert")
        failures.append(f"[GEGENPROBE] {label}")

    label = "G33 Nicht zugelassener MIME-Typ fuer die Ablage"
    try:
        extension_for_mime("image/gif")
        print(f"  FEHLER {label:59s} wird faelschlich akzeptiert")
        failures.append(f"[GEGENPROBE] {label}")
    except NormalizationError:
        print(f"  ok  {label:62s} wird abgewiesen")

    calendar_cases = [
        ("G48 31. Februar", "date.de_numeric", "31.02.2026"),
        ("G49 29. Februar in einem Nicht-Schaltjahr", "date.de_numeric", "29.02.2023"),
        ("G50 31. April", "date.de_numeric", "31.04.2026"),
        ("G51 Tag null", "date.de_numeric", "00.01.2026"),
        ("G52 Monat dreizehn", "date.de_numeric", "01.13.2026"),
        ("G53 Unmoegliches Datum im Zeitstempel", "datetime.de_numeric", "31.02.2026 10:00"),
        ("G54 Unmoegliche Uhrzeit im Zeitstempel", "datetime.de_numeric", "01.01.2026 25:00"),
        ("G55 Unmoegliches Datum in ISO-Schreibweise", "date.iso", "2026-02-31"),
        ("G56 Ausgeschriebenes unmoegliches Datum", "date.de_long", "30. Februar 2026"),
    ]
    for label, rule, raw in calendar_cases:
        try:
            got = apply_rule(rule, raw)
            print(f"  FEHLER {label:59s} wurde zu {got!r} akzeptiert")
            failures.append(f"[GEGENPROBE] {label}")
        except NormalizationError:
            print(f"  ok  {label:62s} wird abgewiesen")


# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase0", default="../jarvis-phase-0",
                        help="Pfad zum entpackten Phase-0-Paket Version 1.1.0")
    args = parser.parse_args()
    phase0 = pathlib.Path(args.phase0)
    if not (phase0 / "schemas" / "common.schema.json").exists():
        print(f"ABBRUCH: Phase-0-Paket nicht gefunden unter {phase0.resolve()}")
        print("Aufruf: python3 tools/validate_phase1.py --phase0 <pfad>")
        return 2

    print("JARVIS Phase 1 - Validierung gegen die Phase-0-Vertraege (Version 4.0.2)\n")
    failures = []
    registry = load_registry(phase0)

    print("Teil 1 - Schemata")
    validate_schemas_themselves(failures)

    print("\nTeil 2 - Beispieldatensaetze")
    validate_examples(registry, phase0, failures)

    print("\nTeil 3 - Werkzeugregister")
    validate_tool_registry(registry, phase0, failures)

    print("\nTeil 4 - Werkzeugvertraege")
    validate_tool_contracts(registry, phase0, failures)

    print("\nTeil 5 - Normalisierungsregeln")
    validate_normalization_rules(failures)

    print("\nTeil 6 - Vertragsregeln")
    check_contract_rules(phase0, failures)

    print("\nTeil 7 - Freigabeplan der Werkzeuge")
    validate_release_plan(phase0, failures)

    print("\nTeil 8 - Gegenproben")
    negative_cases(registry, phase0, failures)

    print()
    if failures:
        print(f"FEHLGESCHLAGEN: {len(failures)} Befund(e)")
        for f in failures:
            print("  -", f)
        return 1
    print("ERGEBNIS: alle Pruefungen bestanden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
