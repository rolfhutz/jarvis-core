"""
Validiert alle JARVIS-Phase-0-Beispiele gegen die JSON-Schemata und prueft
zusaetzlich die Vertragsregeln, die sich nicht rein deklarativ ausdruecken lassen.

Einzige Quelle fuer Risikoklassen und Nachweisstrategien ist
registry/tool_registry.json. Es gibt bewusst keine zweite Pflege im Skriptcode.

Aufruf:  python3 tools/validate_schemas.py
Rueckgabe: Exit-Code 0 bei Erfolg, 1 bei mindestens einem Fehler.
"""

import json
import pathlib
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA_DIR = ROOT / "schemas"
EXAMPLE_DIR = ROOT / "examples"
TEMPLATE_DIR = ROOT / "templates"
REGISTRY_DIR = ROOT / "registry"

MAPPING = {
    "event_document_received.json": "event.schema.json",
    "event_email_received.json": "event.schema.json",
    "action_from_document.json": "action.schema.json",
    "action_from_email.json": "action.schema.json",
    "action_class_c_mail_send.json": "action.schema.json",
    "action_class_b_message_send.json": "action.schema.json",
    "approval_class_c.json": "approval.schema.json",
    "evidence_message_sent.json": "evidence.schema.json",
    "evidence_provider_no_readback.json": "evidence.schema.json",
    "error_retry_transient.json": "error_escalation.schema.json",
    "task_from_document.json": "task.schema.json",
}

RISK_ORDER = {"A": 0, "B": 1, "C": 2}


def load_registry_resources():
    registry = Registry()
    for path in SCHEMA_DIR.glob("*.json"):
        doc = json.loads(path.read_text(encoding="utf-8"))
        registry = registry.with_resource(doc["$id"], Resource.from_contents(doc))
    return registry


def load_tools():
    data = json.loads((REGISTRY_DIR / "tool_registry.json").read_text(encoding="utf-8"))
    return data, {t["tool_id"]: t for t in data["tools"]}


def validate_documents(registry, failures):
    for filename, schema_name in MAPPING.items():
        schema = json.loads((SCHEMA_DIR / schema_name).read_text(encoding="utf-8"))
        instance = json.loads((EXAMPLE_DIR / filename).read_text(encoding="utf-8"))
        validator = Draft202012Validator(schema, registry=registry)
        errors = sorted(validator.iter_errors(instance), key=lambda e: e.path)
        if errors:
            for e in errors:
                failures.append(f"[SCHEMA] {filename}: {list(e.path)} -> {e.message}")
        else:
            print(f"  ok  {filename:36s} gegen {schema_name}")


def validate_context_config(registry, failures):
    schema = json.loads((SCHEMA_DIR / "context.schema.json").read_text(encoding="utf-8"))
    cfg = json.loads((TEMPLATE_DIR / "context_config.example.json").read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema, registry=registry)
    for ctx in cfg["contexts"]:
        errors = sorted(validator.iter_errors(ctx), key=lambda e: e.path)
        if errors:
            for e in errors:
                failures.append(f"[SCHEMA] context {ctx.get('context_id')}: {list(e.path)} -> {e.message}")
        else:
            print(f"  ok  Kontext {ctx['context_id']:26s} gegen context.schema.json")


def validate_tool_registry(registry, failures):
    schema = json.loads((SCHEMA_DIR / "tool_registry.schema.json").read_text(encoding="utf-8"))
    data, _ = load_tools()
    validator = Draft202012Validator(schema, registry=registry)
    errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
    if errors:
        for e in errors:
            failures.append(f"[SCHEMA] tool_registry.json: {list(e.path)} -> {e.message}")
    else:
        print(f"  ok  tool_registry.json ({len(data['tools'])} Werkzeuge) gegen tool_registry.schema.json")


def check_contract_rules(failures):
    """Regeln, die ueber reine Schemavalidierung hinausgehen."""
    _, tools = load_tools()

    def load(name):
        return json.loads((EXAMPLE_DIR / name).read_text(encoding="utf-8"))

    ev_doc = load("event_document_received.json")
    ev_mail = load("event_email_received.json")
    ac_doc = load("action_from_document.json")
    ac_mail = load("action_from_email.json")
    ac_c = load("action_class_c_mail_send.json")
    ac_b = load("action_class_b_message_send.json")
    apr = load("approval_class_c.json")
    evd_mail = load("evidence_message_sent.json")
    evd_msg = load("evidence_provider_no_readback.json")

    all_actions = [("action_from_document", ac_doc), ("action_from_email", ac_mail),
                   ("action_class_c_mail_send", ac_c), ("action_class_b_message_send", ac_b)]

    # R1
    if set(ac_doc) != set(ac_mail):
        failures.append("[R1] Aktionsobjekte aus Dokument und E-Mail sind nicht strukturgleich")
    else:
        print("  ok  R1 Aktionsobjekte aus Dokument und E-Mail sind strukturgleich")

    # R2
    if set(ev_doc) != set(ev_mail):
        failures.append("[R2] Ereignisse aus Dokument und E-Mail sind nicht strukturgleich")
    else:
        print("  ok  R2 Ereignisse aus Dokument und E-Mail sind strukturgleich")

    # R3 Kontexttreue aller Verweise
    r3 = []
    for name, act in all_actions:
        ctx = act["context_id"]
        refs = [act["target"]["target_object"]] + act["target"].get("recipients", []) \
            + act["origin"].get("source_refs", [])
        if [r for r in refs if r.get("context_id") != ctx]:
            r3.append(f"[R3] {name}: Verweis auf fremden Kontext")
    failures.extend(r3)
    if not r3:
        print("  ok  R3 Keine Aktion verweist auf einen fremden Kontext")

    # R4 Eindeutigkeit der Idempotenzschluessel
    keys = {a["idempotency_key"] for _, a in all_actions}
    if len(keys) != len(all_actions):
        failures.append("[R4] Idempotenzschluessel kollidieren zwischen unterschiedlichen Aktionen")
    else:
        print("  ok  R4 Idempotenzschluessel sind eindeutig")

    # R5 Klasse C nur mit gueltiger, verbrauchter Freigabe
    if ac_c["risk_class"] == "C":
        if ac_c.get("approval_status") != "approved" or ac_c.get("approval_id") != apr["approval_id"]:
            failures.append("[R5] Klasse-C-Aktion ohne gueltige Freigabe ausgefuehrt")
        elif ac_c.get("content_fingerprint") != apr.get("action_fingerprint"):
            failures.append("[R5] Fingerprint der Aktion weicht von der Freigabe ab")
        elif apr["status"] != "consumed":
            failures.append("[R5] Freigabe wurde nicht als verbraucht markiert")
        else:
            print("  ok  R5 Klasse-C-Aktion mit gueltiger, einmalig verbrauchter Freigabe")

    # R6 Herabstufungsverbot gegenueber dem Werkzeugregister
    r6 = []
    for name, act in all_actions:
        tool = tools.get(act["target"]["tool_id"])
        if tool is None:
            r6.append(f"[R6] {name}: Werkzeug nicht im Register")
        elif RISK_ORDER[act["risk_class"]] < RISK_ORDER[tool["risk_class_default"]]:
            r6.append(f"[R6] {name}: Risikoklasse unter dem Werkzeugminimum")
    failures.extend(r6)
    if not r6:
        print("  ok  R6 Keine Herabstufung unter das Werkzeugminimum")

    # R7 Nachweis entspricht der im Werkzeugvertrag festgelegten Strategie
    r7 = []
    evidence_by_action = {e["action_id"]: e for e in (evd_mail, evd_msg)}
    for name, act in all_actions:
        if act["status"] != "succeeded":
            continue
        ev = evidence_by_action.get(act["action_id"])
        tool = tools[act["target"]["tool_id"]]
        contract = tool["evidence"]
        if ev is None:
            r7.append(f"[R7] {name}: kein Ergebnisnachweis vorhanden")
            continue
        v = ev["verification"]
        if v["result"] != "confirmed":
            r7.append(f"[R7] {name}: Nachweis nicht bestaetigt")
        elif v["method"] not in contract["accepted_methods"]:
            r7.append(f"[R7] {name}: Methode {v['method']} ist im Werkzeugvertrag nicht zugelassen")
        elif contract["readback_supported"] and v["method"] != "readback":
            r7.append(f"[R7] {name}: unabhaengiger Readback moeglich, aber nicht verwendet")
        elif not contract["readback_supported"] and not v.get("limitation"):
            r7.append(f"[R7] {name}: Ersatznachweis ohne Angabe seiner Grenzen")
        elif v["contract_ref"]["tool_id"] != tool["tool_id"]:
            r7.append(f"[R7] {name}: Nachweis verweist auf einen anderen Werkzeugvertrag")
    failures.extend(r7)
    if not r7:
        print("  ok  R7 Jeder Erfolg beruht auf einer vertraglich zugelassenen Nachweismethode")

    # R8 Aktionen werden ausschliesslich vom Executor ausgefuehrt
    r8 = [f"[R8] {n}: actor ist nicht jarvis" for n, a in all_actions if a["actor"] != "jarvis"]
    failures.extend(r8)
    if not r8:
        print("  ok  R8 Technische Aktionen tragen ausschliesslich den Akteur jarvis")

    # R9 Werkzeuge werden nur in erlaubten Kontexten verwendet
    r9 = []
    for name, act in all_actions:
        tool = tools[act["target"]["tool_id"]]
        if act["context_id"] not in tool["allowed_contexts"]:
            r9.append(f"[R9] {name}: Werkzeug im Kontext {act['context_id']} nicht erlaubt")
    failures.extend(r9)
    if not r9:
        print("  ok  R9 Alle Werkzeuge werden nur in erlaubten Kontexten verwendet")


def main():
    print("JARVIS Phase 0 - Schema- und Vertragsvalidierung\n")
    failures = []
    registry = load_registry_resources()
    validate_documents(registry, failures)
    validate_context_config(registry, failures)
    validate_tool_registry(registry, failures)
    print()
    check_contract_rules(failures)
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
