"""
Gegenprobe zu validate_schemas.py.

Ein Datenvertrag ist nur belastbar, wenn er unzulaessige Faelle auch wirklich
abweist. Dieses Skript veraendert gueltige Beispiele gezielt und erwartet,
dass die Pruefung fehlschlaegt.

Teil 1: Schemaverstoesse.
Teil 2: Vertragsverstoesse, die erst im Abgleich mit dem Werkzeugregister
        sichtbar werden.

Aufruf:  python3 tools/validate_negative.py
Rueckgabe: Exit-Code 0, wenn alle Negativfaelle korrekt abgewiesen wurden.
"""

import copy
import json
import pathlib
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA_DIR = ROOT / "schemas"
EXAMPLE_DIR = ROOT / "examples"
REGISTRY_DIR = ROOT / "registry"

RISK_ORDER = {"A": 0, "B": 1, "C": 2}


def load_registry():
    registry = Registry()
    for path in SCHEMA_DIR.glob("*.json"):
        doc = json.loads(path.read_text(encoding="utf-8"))
        registry = registry.with_resource(doc["$id"], Resource.from_contents(doc))
    return registry


def load(name):
    return json.loads((EXAMPLE_DIR / name).read_text(encoding="utf-8"))


def tools():
    data = json.loads((REGISTRY_DIR / "tool_registry.json").read_text(encoding="utf-8"))
    return {t["tool_id"]: t for t in data["tools"]}


# ---------------------------------------------------------------------------
# Teil 1 - Schemaverstoesse
# ---------------------------------------------------------------------------
def schema_cases():
    cases = []

    a = load("action_class_c_mail_send.json")
    a.pop("approval_id")
    a["approval_status"] = "not_required"
    cases.append(("N01 Klasse C ohne Freigabe ausgefuehrt", "action.schema.json", a))

    a = load("action_class_c_mail_send.json")
    a["evidence_ids"] = []
    cases.append(("N02 Erfolg ohne Ergebnisnachweis", "action.schema.json", a))

    e = load("event_document_received.json")
    e.pop("context_id")
    cases.append(("N03 Ereignis ohne Kontext", "event.schema.json", e))

    e = load("event_document_received.json")
    e["event_type"] = "dokument.eingegangen_prüfung"
    cases.append(("N04 Umlaut im technischen Bezeichner", "event.schema.json", e))

    e = load("event_document_received.json")
    e["received_at"] = "2026-08-29T09:12:00+02:00"
    cases.append(("N05 Zeitstempel nicht in UTC", "event.schema.json", e))

    t = load("task_from_document.json")
    t.pop("success_criterion")
    cases.append(("N06 Aufgabe ohne Erfolgskriterium", "task.schema.json", t))

    t = load("task_from_document.json")
    t.pop("assignee")
    cases.append(("N07 Menschliche Aufgabe ohne Zuordnung", "task.schema.json", t))

    a = load("action_from_document.json")
    a["idempotency_key"] = "nicht-normalisiert-42"
    cases.append(("N08 Ungueltiger Idempotenzschluessel", "action.schema.json", a))

    a = load("action_from_document.json")
    a["freitext_zusatz"] = "irgendetwas"
    cases.append(("N09 Unbekanntes Zusatzfeld", "action.schema.json", a))

    err = load("error_retry_transient.json")
    err["error_class"] = "unknown_state"
    err["retryable"] = True
    cases.append(("N10 Blinde Wiederholung bei unklarem Status", "error_escalation.schema.json", err))

    err = load("error_retry_transient.json")
    err.pop("reconciliation")
    cases.append(("N11 Retry ohne Statusabgleich", "error_escalation.schema.json", err))

    ap = load("approval_class_c.json")
    ap["status"] = "approved"
    ap.pop("decision_evidence")
    cases.append(("N12 Freigabe ohne Entscheidungsnachweis", "approval.schema.json", ap))

    ev = load("evidence_message_sent.json")
    ev["object_ref"] = {"object_type": "email", "context_id": "arbeitgeber_visolva"}
    cases.append(("N13 Objektverweis ohne ID", "evidence.schema.json", ev))

    mem = {
        "schema_version": "1.0.0",
        "memory_id": "mem_01JBQ8Z4K7M3N9P2R5T6V8W0ZD",
        "context_id": "privat",
        "memory_store": "profile",
        "entry_type": "fact",
        "epistemic_status": "fact",
        "statement": "Beispielaussage ohne Quelle.",
        "status": "active",
        "created_at": "2026-08-29T07:12:00Z",
        "producer": {"producer_type": "agent", "producer_id": "memory_writer"},
        "source_refs": []
    }
    cases.append(("N14 Langzeitgedaechtnis ohne Quelle", "memory_entry.schema.json", mem))

    # --- neu in Version 1.1.0 ---

    a = load("action_from_document.json")
    a["actor"] = "rolf"
    cases.append(("N15 Technische Aktion mit menschlichem Akteur", "action.schema.json", a))

    ev = load("evidence_provider_no_readback.json")
    ev["verification"].pop("limitation")
    cases.append(("N16 Ersatznachweis ohne Angabe seiner Grenzen", "evidence.schema.json", ev))

    ev = load("evidence_message_sent.json")
    ev["verification"]["method"] = "provider_message_id"
    ev["verification"]["limitation"] = "Belegt nur die Annahme."
    cases.append(("N17 Ersatznachweis trotz moeglichem Readback", "evidence.schema.json", ev))

    ev = load("evidence_message_sent.json")
    ev["verification"].pop("contract_ref")
    cases.append(("N18 Nachweis ohne Bezug auf einen Werkzeugvertrag", "evidence.schema.json", ev))

    reg = json.loads((REGISTRY_DIR / "tool_registry.json").read_text(encoding="utf-8"))
    bad = copy.deepcopy(reg)
    bad["tools"][2]["risk_class_default"] = "A"
    cases.append(("N19 Werkzeug mit Aussenwirkung als Klasse A", "tool_registry.schema.json", bad))

    bad = copy.deepcopy(reg)
    bad["tools"][3]["evidence"]["limitation"] = None
    cases.append(("N20 Vertrag ohne Readback und ohne Grenzangabe", "tool_registry.schema.json", bad))

    bad = copy.deepcopy(reg)
    bad["tools"][0]["evidence"]["accepted_methods"] = ["provider_status"]
    cases.append(("N21 Vertrag laesst trotz Readback eine schwaechere Methode zu", "tool_registry.schema.json", bad))

    return cases


# ---------------------------------------------------------------------------
# Teil 2 - Vertragsverstoesse gegenueber dem Werkzeugregister
# ---------------------------------------------------------------------------
def contract_cases():
    """Jeder Eintrag: (Bezeichnung, Pruefaufruf). Erwartet wird eine Beanstandung."""
    reg = tools()

    def check_method_allowed(action, evidence):
        tool = reg[action["target"]["tool_id"]]
        c = tool["evidence"]
        if evidence["verification"]["method"] not in c["accepted_methods"]:
            return "Methode im Werkzeugvertrag nicht zugelassen"
        if c["readback_supported"] and evidence["verification"]["method"] != "readback":
            return "Readback moeglich, aber nicht verwendet"
        return None

    def check_risk(action):
        tool = reg[action["target"]["tool_id"]]
        if RISK_ORDER[action["risk_class"]] < RISK_ORDER[tool["risk_class_default"]]:
            return "Risikoklasse unter dem Werkzeugminimum"
        return None

    def check_context(action):
        tool = reg[action["target"]["tool_id"]]
        if action["context_id"] not in tool["allowed_contexts"]:
            return "Werkzeug im gewaehlten Kontext nicht erlaubt"
        return None

    cases = []

    ac = load("action_class_b_message_send.json")
    ev = load("evidence_provider_no_readback.json")
    ev["verification"]["method"] = "human_confirm"
    cases.append(("N22 Nachweismethode ausserhalb des Vertrags",
                  lambda: check_method_allowed(ac, ev)))

    ac2 = load("action_class_c_mail_send.json")
    ac2["risk_class"] = "A"
    cases.append(("N23 Herabstufung einer Klasse-C-Aktion", lambda: check_risk(ac2)))

    ac3 = load("action_from_document.json")
    ac3["context_id"] = "arbeitgeber_visolva"
    ac3["target"]["tool_id"] = "storage_gdrive.move_file"
    cases.append(("N24 Werkzeug im nicht erlaubten Kontext", lambda: check_context(ac3)))

    return cases


def main():
    print("JARVIS Phase 0 - Gegenprobe (Negativfaelle)\n")
    registry = load_registry()
    unexpected = []

    print("Teil 1 - Schemaverstoesse")
    for label, schema_name, instance in schema_cases():
        schema = json.loads((SCHEMA_DIR / schema_name).read_text(encoding="utf-8"))
        validator = Draft202012Validator(schema, registry=registry)
        errors = list(validator.iter_errors(copy.deepcopy(instance)))
        if errors:
            print(f"  ok  {label:56s} wird abgewiesen")
        else:
            print(f"  FEHLER {label:53s} wird faelschlich akzeptiert")
            unexpected.append(label)

    print("\nTeil 2 - Vertragsverstoesse gegenueber dem Werkzeugregister")
    for label, check in contract_cases():
        finding = check()
        if finding:
            print(f"  ok  {label:56s} wird abgewiesen ({finding})")
        else:
            print(f"  FEHLER {label:53s} wird faelschlich akzeptiert")
            unexpected.append(label)

    print()
    if unexpected:
        print(f"FEHLGESCHLAGEN: {len(unexpected)} Negativfall/-faelle wurden akzeptiert")
        return 1
    print("ERGEBNIS: alle Negativfaelle korrekt abgewiesen")
    return 0


if __name__ == "__main__":
    sys.exit(main())
