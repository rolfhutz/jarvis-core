"""
Erzeugt die Beispieldatensaetze fuer die Abnahmekriterien 0.5.1 und 0.5.2:
Ein Dokumentereignis und ein E-Mail-Ereignis werden in dasselbe Ereignisformat
ueberfuehrt und erzeugen strukturgleiche Aktionsobjekte.

Die Beispiele sind Testdaten, keine produktiven Workflows.
"""

import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from idempotency_reference import build_idempotency_key, content_fingerprint  # noqa: E402

OUT = pathlib.Path(__file__).resolve().parent.parent / "examples"
OUT.mkdir(exist_ok=True)

SV = "1.0.0"
NOW = "2026-08-29T07:12:00Z"

IDS = {
    "evt_doc": "evt_01JBQ8Z4K7M3N9P2R5T6V8W0XY",
    "evt_mail": "evt_01JBQ8Z4K7M3N9P2R5T6V8W0Y2",
    "doc": "doc_01JBQ8Z4K7M3N9P2R5T6V8W0Z3",
    "eml": "eml_01JBQ8Z4K7M3N9P2R5T6V8W0Z4",
    "tsk_doc": "tsk_01JBQ8Z4K7M3N9P2R5T6V8W0Z5",
    "tsk_mail": "tsk_01JBQ8Z4K7M3N9P2R5T6V8W0Z6",
    "act_doc": "act_01JBQ8Z4K7M3N9P2R5T6V8W0Z7",
    "act_mail": "act_01JBQ8Z4K7M3N9P2R5T6V8W0Z8",
    "act_send": "act_01JBQ8Z4K7M3N9P2R5T6V8W0Z9",
    "apr": "apr_01JBQ8Z4K7M3N9P2R5T6V8W0ZA",
    "evd": "evd_01JBQ8Z4K7M3N9P2R5T6V8W0ZB",
    "err": "err_01JBQ8Z4K7M3N9P2R5T6V8W0ZC",
    "act_msg": "act_01JBQ8Z4K7M3N9P2R5T6V8W0ZE",
    "evd_msg": "evd_01JBQ8Z4K7M3N9P2R5T6V8W0ZF",
}

TRACE_DOC = {"trace_id": "tr-20260829-0001", "correlation_id": "co-20260829-0001",
             "workflow_name": "JV-P0-CORE-event_ingest-v1", "workflow_version": "1.0.0"}
TRACE_MAIL = {"trace_id": "tr-20260829-0002", "correlation_id": "co-20260829-0002",
              "workflow_name": "JV-P0-CORE-event_ingest-v1", "workflow_version": "1.0.0"}

PRODUCER_NORM = {"producer_type": "agent", "producer_id": "event_normalizer", "producer_version": "1.0.0"}
PRODUCER_PLAN = {"producer_type": "agent", "producer_id": "action_planner", "producer_version": "1.0.0"}
PRODUCER_EXEC = {"producer_type": "agent", "producer_id": "executor", "producer_version": "1.0.0"}
PRODUCER_VERIFY = {"producer_type": "agent", "producer_id": "verifier", "producer_version": "1.0.0"}
PRODUCER_APPR = {"producer_type": "agent", "producer_id": "approval_broker", "producer_version": "1.0.0"}


def write(name, obj):
    (OUT / name).write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


# --------------------------------------------------------------------------
# 1. Ereignis: Dokument im privaten Eingangsordner
# --------------------------------------------------------------------------
event_doc_idem = build_idempotency_key({
    "context_id": "privat",
    "source_ref": "storage_gdrive:file:EXTERNAL_FILE_ID_PLACEHOLDER",
    "action_type": "document.received",
    "target_system": "jarvis_core",
    "target_object_ref": "event",
})

event_doc = {
    "schema_version": SV,
    "event_id": IDS["evt_doc"],
    "event_type": "document.received",
    "event_time": "2026-08-29T06:58:12Z",
    "received_at": NOW,
    "context_id": "privat",
    "context_resolution": {"method": "source_binding", "rule_id": "ctx_rule_privat_inbox", "confidence": 1.0,
                           "confirmed_by_human": False},
    "source": {"adapter_id": "storage_gdrive", "channel": "inbox_folder",
               "external_id": "EXTERNAL_FILE_ID_PLACEHOLDER", "received_via": "polling"},
    "subject": {
        "object_type": "document",
        "object_id": IDS["doc"],
        "context_id": "privat",
        "system": "storage_gdrive",
        "external_id": "EXTERNAL_FILE_ID_PLACEHOLDER",
        "label": "Beitragsanpassung Krankenversicherung 2027",
        "content_hash": "sha256:" + "a" * 64
    },
    "related": [],
    "severity": "notice",
    "idempotency_key": event_doc_idem,
    "payload": {
        "document_type": "Beitragsanpassung",
        "sender_label": "Krankenversicherung",
        "document_date": "2026-08-25",
        "deadline": "2026-09-30",
        "summary_de": "Ankuendigung einer Beitragserhoehung ab 2027 mit Sonderkuendigungsrecht bis 30.09.2026."
    },
    "field_evidence": [
        {"field": "deadline", "value": "2026-09-30", "confidence": 0.94,
         "snippet": "Sonderkuendigungsrecht bis zum 30.09.2026", "locator": "page=1"}
    ],
    "producer": PRODUCER_NORM,
    "trace": TRACE_DOC
}
write("event_document_received.json", event_doc)

# --------------------------------------------------------------------------
# 2. Ereignis: E-Mail im Arbeitgeberkontext
# --------------------------------------------------------------------------
event_mail_idem = build_idempotency_key({
    "context_id": "arbeitgeber_visolva",
    "source_ref": "mail_m365:message:EXTERNAL_MESSAGE_ID_PLACEHOLDER",
    "action_type": "email.received",
    "target_system": "jarvis_core",
    "target_object_ref": "event",
})

event_mail = {
    "schema_version": SV,
    "event_id": IDS["evt_mail"],
    "event_type": "email.received",
    "event_time": "2026-08-29T06:41:03Z",
    "received_at": NOW,
    "context_id": "arbeitgeber_visolva",
    "context_resolution": {"method": "source_binding", "rule_id": "ctx_rule_visolva_mailbox", "confidence": 1.0,
                           "confirmed_by_human": False},
    "source": {"adapter_id": "mail_m365", "channel": "mail_label",
               "external_id": "EXTERNAL_MESSAGE_ID_PLACEHOLDER", "received_via": "webhook"},
    "subject": {
        "object_type": "email",
        "object_id": IDS["eml"],
        "context_id": "arbeitgeber_visolva",
        "system": "mail_m365",
        "external_id": "EXTERNAL_MESSAGE_ID_PLACEHOLDER",
        "label": "Rueckfrage zum Angebot 2026-0815"
    },
    "related": [],
    "severity": "notice",
    "idempotency_key": event_mail_idem,
    "payload": {
        "sender_label": "Kunde",
        "subject_de": "Rueckfrage zum Angebot 2026-0815",
        "deadline": "2026-09-02",
        "summary_de": "Der Kunde bittet bis zum 02.09.2026 um eine Rueckmeldung zur Lieferzeit."
    },
    "field_evidence": [
        {"field": "deadline", "value": "2026-09-02", "confidence": 0.88,
         "snippet": "Rueckmeldung bis 02.09.", "locator": "body"}
    ],
    "producer": PRODUCER_NORM,
    "trace": TRACE_MAIL
}
write("event_email_received.json", event_mail)


# --------------------------------------------------------------------------
# 3. Zwei strukturgleiche Aktionsobjekte aus beiden Quellen
# --------------------------------------------------------------------------
def make_task_action(action_id, context_id, source_event_id, target_object_ref, goal, trace, due_at, source_ref_obj):
    basis = {
        "context_id": context_id,
        "source_ref": source_event_id,
        "action_type": "task.create",
        "target_system": "tasks_internal",
        "target_object_ref": target_object_ref,
    }
    return {
        "schema_version": SV,
        "action_id": action_id,
        "context_id": context_id,
        "goal": goal,
        "action_type": "task.create",
        "origin": {"event_id": source_event_id, "trigger": "event", "source_refs": [source_ref_obj]},
        "actor": "jarvis",
        "target": {
            "system_adapter_id": "tasks_internal",
            "tool_id": "tasks_internal.create_task",
            "tool_version": "1.0.0",
            "target_object": {"object_type": "task", "context_id": context_id,
                              "system": "tasks_internal", "external_id": target_object_ref},
            "recipients": []
        },
        "inputs": {"title": goal, "due_at": due_at, "priority": "high"},
        "missing_inputs": [],
        "risk_class": "A",
        "risk_rationale": "Interne Aufgabe ohne Aussenwirkung, jederzeit loeschbar.",
        "risk_class_source": "tool_default",
        "reversibility": "reversible",
        "approval_status": "not_required",
        "status": "planned",
        "dry_run": False,
        "priority": "high",
        "due_at": due_at,
        "idempotency_key": build_idempotency_key(basis),
        "idempotency_basis": basis,
        "attempt_count": 0,
        "max_attempts": 3,
        "evidence_ids": [],
        "error_ids": [],
        "created_at": NOW,
        "producer": PRODUCER_PLAN,
        "trace": trace
    }


action_doc = make_task_action(
    IDS["act_doc"], "privat", IDS["evt_doc"], "case:privat/versicherung/beitragsanpassung-2027",
    "Sonderkuendigungsrecht pruefen und bis 30.09.2026 entscheiden",
    TRACE_DOC, "2026-09-23T12:00:00Z",
    {"object_type": "document", "object_id": IDS["doc"], "context_id": "privat"}
)
write("action_from_document.json", action_doc)

action_mail = make_task_action(
    IDS["act_mail"], "arbeitgeber_visolva", IDS["evt_mail"], "case:visolva/angebot/2026-0815",
    "Rueckmeldung zur Lieferzeit bis 02.09.2026 geben",
    TRACE_MAIL, "2026-09-01T12:00:00Z",
    {"object_type": "email", "object_id": IDS["eml"], "context_id": "arbeitgeber_visolva"}
)
write("action_from_email.json", action_mail)

# --------------------------------------------------------------------------
# 4. Klasse-C-Aktion mit Freigabe
# --------------------------------------------------------------------------
fingerprint = content_fingerprint({
    "action_type": "mail.send",
    "recipient_ref": "person:kunde-4711",
    "subject": "Rueckmeldung zur Lieferzeit Angebot 2026-0815",
    "body_hash": "sha256:" + "b" * 64
})

basis_send = {
    "context_id": "arbeitgeber_visolva",
    "source_ref": IDS["evt_mail"],
    "action_type": "mail.send",
    "target_system": "mail_m365",
    "target_object_ref": "thread:EXTERNAL_THREAD_ID_PLACEHOLDER",
}

action_send = {
    "schema_version": SV,
    "action_id": IDS["act_send"],
    "context_id": "arbeitgeber_visolva",
    "goal": "Antwort an den Kunden zur Lieferzeit versenden",
    "description": "Individuelle Antwort auf die Rueckfrage zum Angebot 2026-0815.",
    "action_type": "mail.send",
    "origin": {"event_id": IDS["evt_mail"], "task_id": IDS["tsk_mail"], "trigger": "event",
               "source_refs": [{"object_type": "email", "object_id": IDS["eml"], "context_id": "arbeitgeber_visolva"}]},
    "actor": "jarvis",
    "target": {
        "system_adapter_id": "mail_m365",
        "tool_id": "mail_default.send_message",
        "tool_version": "1.0.0",
        "target_object": {"object_type": "email", "context_id": "arbeitgeber_visolva",
                          "system": "mail_m365", "external_id": "EXTERNAL_THREAD_ID_PLACEHOLDER"},
        "recipients": [{"object_type": "person", "context_id": "arbeitgeber_visolva",
                        "system": "crm_odoo", "external_id": "EXTERNAL_PARTNER_ID_PLACEHOLDER",
                        "label": "Kundenkontakt"}]
    },
    "inputs": {"subject": "Rueckmeldung zur Lieferzeit Angebot 2026-0815",
               "body_ref": "draft:internal/EXTERNAL_DRAFT_REF"},
    "missing_inputs": [],
    "risk_class": "C",
    "risk_rationale": "Individuelle E-Mail an einen externen Empfaenger, nicht rueckholbar.",
    "risk_class_source": "context_override",
    "reversibility": "irreversible",
    "approval_id": IDS["apr"],
    "approval_status": "approved",
    "status": "succeeded",
    "dry_run": False,
    "priority": "high",
    "due_at": "2026-09-01T12:00:00Z",
    "idempotency_key": build_idempotency_key(basis_send),
    "idempotency_basis": basis_send,
    "content_fingerprint": fingerprint,
    "attempt_count": 1,
    "max_attempts": 3,
    "last_attempt_at": "2026-08-29T08:02:11Z",
    "evidence_ids": [IDS["evd"]],
    "error_ids": [],
    "created_at": NOW,
    "updated_at": "2026-08-29T08:02:40Z",
    "executed_at": "2026-08-29T08:02:11Z",
    "verified_at": "2026-08-29T08:02:34Z",
    "producer": PRODUCER_EXEC,
    "trace": TRACE_MAIL
}
write("action_class_c_mail_send.json", action_send)

approval = {
    "schema_version": SV,
    "approval_id": IDS["apr"],
    "context_id": "arbeitgeber_visolva",
    "action_id": IDS["act_send"],
    "requested_risk_class": "C",
    "action_fingerprint": fingerprint,
    "channel": {"adapter_id": "approval_email", "recipient_ref": "env:JV_VISOLVA_APPROVAL_RECIPIENT"},
    "decision_summary": {
        "situation": "Der Kunde hat am 29.08.2026 nach der Lieferzeit zum Angebot 2026-0815 gefragt und erwartet eine Rueckmeldung bis 02.09.2026.",
        "planned_action": "Versand einer individuellen Antwort mit der bestaetigten Lieferzeit.",
        "recipients_label": "Kundenkontakt zum Angebot 2026-0815",
        "consequences": "Externe verbindliche Aussage. Nach dem Versand nicht rueckholbar.",
        "sources": [{"object_type": "email", "object_id": IDS["eml"], "context_id": "arbeitgeber_visolva"}]
    },
    "token_hash": "sha256:" + "c" * 64,
    "requested_at": "2026-08-29T07:20:00Z",
    "expires_at": "2026-08-31T07:20:00Z",
    "status": "consumed",
    "decided_at": "2026-08-29T07:58:02Z",
    "decided_by": "rolf",
    "decision_note": "Freigegeben.",
    "decision_evidence": {"method": "signed_link_confirm", "confirmed_second_step": True,
                          "client_fingerprint": "sha256-truncated-hash"},
    "consumed_at": "2026-08-29T08:02:11Z",
    "producer": PRODUCER_APPR,
    "trace": TRACE_MAIL
}
write("approval_class_c.json", approval)

evidence = {
    "schema_version": SV,
    "evidence_id": IDS["evd"],
    "context_id": "arbeitgeber_visolva",
    "action_id": IDS["act_send"],
    "evidence_type": "message_ref",
    "system_adapter_id": "mail_m365",
    "object_ref": {"object_type": "email", "context_id": "arbeitgeber_visolva", "system": "mail_m365",
                   "external_id": "EXTERNAL_SENT_MESSAGE_ID_PLACEHOLDER",
                   "uri": "adapter://mail_m365/sent/EXTERNAL_SENT_MESSAGE_ID_PLACEHOLDER"},
    "observed_at": "2026-08-29T08:02:34Z",
    "observed_values": {"folder": "sent_items", "recipient_count": 1,
                        "sent_at": "2026-08-29T08:02:12Z"},
    "verification": {"method": "readback", "result": "confirmed", "verified_at": "2026-08-29T08:02:34Z",
                     "verified_by": "verifier",
                     "detail": "Nachricht wurde nach dem Versand im Ordner der gesendeten Nachrichten erneut gelesen.",
                     "contract_ref": {"tool_id": "mail_default.send_message", "tool_version": "1.0.0",
                                      "readback_supported": True}},
    "created_at": "2026-08-29T08:02:34Z",
    "producer": PRODUCER_VERIFY,
    "trace": TRACE_MAIL
}
write("evidence_message_sent.json", evidence)

error = {
    "schema_version": SV,
    "error_id": IDS["err"],
    "context_id": "arbeitgeber_visolva",
    "action_id": IDS["act_send"],
    "occurred_at": "2026-08-29T08:01:05Z",
    "error_class": "transient_network",
    "error_code": "ETIMEDOUT",
    "message_safe": "Zielsystem antwortete nicht innerhalb des Zeitlimits.",
    "adapter_id": "mail_m365",
    "tool_id": "mail_default.send_message",
    "retryable": True,
    "attempt": 1,
    "max_attempts": 3,
    "next_attempt_at": "2026-08-29T08:02:05Z",
    "reconciliation": {"performed": True, "method": "readback", "result": "not_executed",
                       "checked_at": "2026-08-29T08:01:50Z"},
    "escalation_level": "L0_retry",
    "resolution": {"status": "resolved_auto", "resolved_at": "2026-08-29T08:02:34Z",
                   "note": "Zweiter Versuch innerhalb gueltiger Freigabe erfolgreich, identischer Idempotenzschluessel."},
    "producer": PRODUCER_EXEC,
    "trace": TRACE_MAIL
}
write("error_retry_transient.json", error)

task_doc = {
    "schema_version": SV,
    "task_id": IDS["tsk_doc"],
    "context_id": "privat",
    "title": "Sonderkuendigungsrecht Krankenversicherung pruefen",
    "description": "Beitragsanpassung 2027 pruefen und ueber Kuendigung oder Verbleib entscheiden.",
    "success_criterion": "Entscheidung dokumentiert; bei Kuendigung liegt eine Eingangsbestaetigung des Versicherers vor.",
    "consequence_of_inaction": "Das Sonderkuendigungsrecht verfaellt am 30.09.2026.",
    "actor": "rolf",
    "assignee": {"object_type": "person", "context_id": "privat", "system": "internal", "external_id": "rolf"},
    "origin": {"event_id": IDS["evt_doc"], "derivation": "extracted",
               "source_refs": [{"object_type": "document", "object_id": IDS["doc"], "context_id": "privat"}]},
    "status": "open",
    "priority": "high",
    "due_at": "2026-09-23T12:00:00Z",
    "action_ids": [IDS["act_doc"]],
    "idempotency_key": build_idempotency_key({
        "context_id": "privat", "source_ref": IDS["evt_doc"], "action_type": "task.derive",
        "target_system": "tasks_internal", "target_object_ref": "case:privat/versicherung/beitragsanpassung-2027"}),
    "created_at": NOW,
    "producer": PRODUCER_PLAN,
    "trace": TRACE_DOC
}
write("task_from_document.json", task_doc)


# --------------------------------------------------------------------------
# 5. Klasse-B-Aktion ohne unabhaengigen Readback (geaenderte Regel D3)
# --------------------------------------------------------------------------
basis_msg = {
    "context_id": "arbeitgeber_visolva",
    "source_ref": IDS["evt_mail"],
    "action_type": "messaging.send_template",
    "target_system": "messaging_superchat",
    "target_object_ref": "conversation:EXTERNAL_CONVERSATION_ID_PLACEHOLDER",
}

action_msg = {
    "schema_version": SV,
    "action_id": IDS["act_msg"],
    "context_id": "arbeitgeber_visolva",
    "goal": "Standardnachricht zum Eingang der Rueckfrage senden",
    "description": "Freigegebene Standardnachricht ueber den Messenger-Kanal.",
    "action_type": "messaging.send_template",
    "origin": {"event_id": IDS["evt_mail"], "trigger": "event",
               "source_refs": [{"object_type": "email", "object_id": IDS["eml"],
                                "context_id": "arbeitgeber_visolva"}]},
    "actor": "jarvis",
    "target": {
        "system_adapter_id": "messaging_superchat",
        "tool_id": "messaging_superchat.send_template_message",
        "tool_version": "1.0.0",
        "target_object": {"object_type": "conversation", "context_id": "arbeitgeber_visolva",
                          "system": "messaging_superchat",
                          "external_id": "EXTERNAL_CONVERSATION_ID_PLACEHOLDER"},
        "recipients": [{"object_type": "person", "context_id": "arbeitgeber_visolva",
                        "system": "crm_odoo", "external_id": "EXTERNAL_PARTNER_ID_PLACEHOLDER",
                        "label": "Kundenkontakt"}]
    },
    "inputs": {"template_id": "eingangsbestaetigung_v1"},
    "missing_inputs": [],
    "risk_class": "B",
    "risk_rationale": "Standardisierte Nachricht an einen externen Empfaenger, nicht rueckholbar, aber inhaltlich vorab freigegeben.",
    "risk_class_source": "tool_default",
    "reversibility": "irreversible",
    "approval_status": "not_required",
    "status": "succeeded",
    "dry_run": False,
    "priority": "normal",
    "idempotency_key": build_idempotency_key(basis_msg),
    "idempotency_basis": basis_msg,
    "attempt_count": 1,
    "max_attempts": 3,
    "evidence_ids": [IDS["evd_msg"]],
    "error_ids": [],
    "created_at": NOW,
    "executed_at": "2026-08-29T07:31:02Z",
    "verified_at": "2026-08-29T07:31:44Z",
    "producer": PRODUCER_EXEC,
    "trace": TRACE_MAIL
}
write("action_class_b_message_send.json", action_msg)

evidence_msg = {
    "schema_version": SV,
    "evidence_id": IDS["evd_msg"],
    "context_id": "arbeitgeber_visolva",
    "action_id": IDS["act_msg"],
    "evidence_type": "provider_id",
    "system_adapter_id": "messaging_superchat",
    "observed_at": "2026-08-29T07:31:44Z",
    "observed_values": {"provider_message_id": "EXTERNAL_PROVIDER_MESSAGE_ID_PLACEHOLDER",
                        "provider_status": "delivered"},
    "verification": {
        "method": "provider_message_id",
        "result": "confirmed",
        "verified_at": "2026-08-29T07:31:44Z",
        "verified_by": "verifier",
        "detail": "Der Anbieter hat eine unveraenderliche Nachrichten-ID und den Status delivered zurueckgemeldet.",
        "contract_ref": {"tool_id": "messaging_superchat.send_template_message",
                         "tool_version": "1.0.0", "readback_supported": False},
        "limitation": "Belegt die Annahme und Auslieferung durch den Anbieter, nicht das Lesen oder Verstehen durch den Empfaenger.",
        "deferred_check_due_at": "2026-08-30T07:31:44Z"
    },
    "created_at": "2026-08-29T07:31:44Z",
    "producer": PRODUCER_VERIFY,
    "trace": TRACE_MAIL
}
write("evidence_provider_no_readback.json", evidence_msg)

print("Beispiele erzeugt:", sorted(p.name for p in OUT.glob("*.json")))
