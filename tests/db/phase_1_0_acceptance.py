"""
JARVIS Phase 1.0 - Praktischer Nachweis der Datenbankabnahme.

Prueft die Abnahmekriterien 1.0-A1 bis 1.0-A7 aus
SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.2.md, Abschnitt 7.3, gegen eine
laufende PostgreSQL-Instanz, in die die Migrationen aus db/migrations/
bereits eingespielt wurden.

Kriterium 1.0-A8 (Export und Wiederherstellung der Workflows) wird hier
bewusst nicht geprueft. Es setzt die n8n-Subworkflows voraus, die in
diesem Schritt noch nicht existieren.

Grundsatz: Ein erwarteter Fehler ist ein Nachweis. Ein Test gilt nur dann
als bestanden, wenn die Datenbank genau so reagiert wie vorgesehen - eine
Ablehnung muss als FEHLER kommen und darf nicht still verschluckt werden.

Es werden ausschliesslich synthetische Testdaten verwendet.

WICHTIG: Der Lauf setzt eine frisch migrierte, leere Datenbank voraus. Er
schreibt synthetische Zeilen und laesst sie stehen. Ein zweiter Lauf gegen
dieselbe Instanz schlaegt fehl, weil die Kennungen dann bereits vergeben
sind. Aufraeumen ist bewusst nicht vorgesehen: action_log ist append-only,
ein Testlauf darf diese Eigenschaft nicht unterlaufen. Fuer einen erneuten
Lauf wird die Datenbank neu aufgebaut.

Aufrufe:
    python3 tests/db/phase_1_0_acceptance.py --psql-args "-h /pfad -p 5432 -U postgres -d jarvis_test"
    python3 tests/db/phase_1_0_acceptance.py --dsn "postgresql://..." --write-log docs/evidence/...
"""

from __future__ import annotations

import argparse
import datetime
import pathlib
import shlex
import subprocess
import sys

# --- Synthetische Testkennungen -------------------------------------------
# Muster der Vertraege eingehalten, Inhalte frei erfunden.
DOC_A = "doc_01JQ8ZKPT4N7VXWA2E5GHM3BCD"
CASE_A = "cse_01JQ8ZKPT4N7VXWA2E5GHM3BCD"
ACTION_A = "act_01JQ8ZKPT4N7VXWA2E5GHM3BCD"
IDEM_A = "a" * 64
IDEM_LOCK = "b" * 64
RUN_A = "run_phase10_abnahme_0001"

ACTION_INSERT = """
INSERT INTO jarvis_privat.action (
    action_id, schema_version, action_type, tool_id, tool_version,
    risk_class, risk_class_source, status, priority, idempotency_key, body)
VALUES (
    '{action_id}', '1.0.0', 'document.file', 'storage_gdrive', '1.0.0',
    'A', 'tool_registry', 'planned', 'normal', '{idem}', '{{}}'::jsonb)
"""


def sql_test(test_id, title, sql, expect, match=None):
    return {"id": test_id, "title": title, "sql": sql, "expect": expect, "match": match}


TESTS = [
    # ---------------------------------------------------------------- A1
    sql_test(
        "1.0-A1", "Schreibversuch in fremdes Kontextschema scheitert",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_visolva.action_log (entry_kind, actor, summary_de, body)
        VALUES ('test', 'jarvis', 'Fremdzugriff', '{}'::jsonb);
        """,
        expect="error", match="permission denied",
    ),
    sql_test(
        "1.0-A1b", "Lesezugriff auf fremdes Fachprotokoll scheitert",
        """
        SET ROLE jv_privat_user;
        SELECT 1 FROM jarvis_visolva.action_log LIMIT 1;
        """,
        expect="error", match="permission denied",
    ),
    # ---------------------------------------------------------------- A2
    sql_test(
        "1.0-A2", "Datensatz mit fremder context_id wird abgewiesen",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.action_log (context_id, entry_kind, actor, summary_de, body)
        VALUES ('arbeitgeber_visolva', 'test', 'jarvis', 'Falscher Kontext', '{}'::jsonb);
        """,
        expect="error", match="log_context_chk",
    ),
    sql_test(
        "1.0-A2b", "Aktion mit fremder context_id wird abgewiesen",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.action (
            action_id, schema_version, context_id, action_type, tool_id, tool_version,
            risk_class, risk_class_source, status, priority, idempotency_key, body)
        VALUES ('act_01JQ8ZKPT4N7VXWA2E5GHM3BCE', '1.0.0', 'arbeitgeber_visolva',
                'document.file', 'storage_gdrive', '1.0.0', 'A', 'tool_registry',
                'planned', 'normal', '""" + "c" * 64 + """', '{}'::jsonb);
        """,
        expect="error", match="action_context_chk",
    ),
    # ---------------------------------------------------------------- A3
    sql_test(
        "1.0-A3a", "UPDATE auf action_log scheitert als Kontextbenutzer",
        """
        SET ROLE jv_privat_user;
        UPDATE jarvis_privat.action_log SET summary_de = 'manipuliert';
        """,
        expect="error", match="permission denied",
    ),
    sql_test(
        "1.0-A3b", "UPDATE auf action_log scheitert auch als Eigentuemer (Trigger)",
        # Die Trigger fuer UPDATE und DELETE sind zeilenbasiert. Auf einer leeren
        # Tabelle greifen sie nicht, weil es keine Zeile gibt, die geaendert
        # wuerde. Der Test legt sich deshalb zuerst eine eigene Zeile an und ist
        # damit unabhaengig von der Reihenfolge der uebrigen Pruefungen.
        """
        INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
        VALUES ('abnahme', 'jarvis', 'Synthetische Zeile fuer die Triggerprobe', '{}'::jsonb);
        UPDATE jarvis_privat.action_log SET summary_de = 'manipuliert';
        """,
        expect="error", match="append_only_violation",
    ),
    sql_test(
        "1.0-A3c", "DELETE auf action_log scheitert als Kontextbenutzer",
        """
        SET ROLE jv_privat_user;
        DELETE FROM jarvis_privat.action_log;
        """,
        expect="error", match="permission denied",
    ),
    sql_test(
        "1.0-A3d", "DELETE auf action_log scheitert auch als Eigentuemer (Trigger)",
        # Gleicher Grund wie bei 1.0-A3b: erst eine Zeile anlegen, dann loeschen.
        """
        INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
        VALUES ('abnahme', 'jarvis', 'Synthetische Zeile fuer die Loeschprobe', '{}'::jsonb);
        DELETE FROM jarvis_privat.action_log;
        """,
        expect="error", match="append_only_violation",
    ),
    sql_test(
        "1.0-A3e", "TRUNCATE auf action_log scheitert (Trigger)",
        "TRUNCATE jarvis_privat.action_log;",
        expect="error", match="append_only_violation",
    ),
    # ---------------------------------------------------------------- A4
    sql_test(
        "1.0-A4", "INSERT in action_log gelingt, Sequenzrecht greift",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
        VALUES ('abnahme', 'jarvis', 'Synthetischer Abnahmeeintrag Phase 1.0', '{}'::jsonb)
        RETURNING log_id;
        """,
        expect="ok", match="1",
    ),
    # ---------------------------------------------------------------- A5
    sql_test(
        "1.0-A5", "Workflow-Lauf kann gestartet und abgeschlossen werden",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_ops.workflow_run (
            run_id, trace_id, workflow_name, workflow_version, context_id, started_at, status)
        VALUES ('""" + RUN_A + """', 'trc_abnahme_0001', 'phase_1_0_abnahme', '1.0.0',
                'privat', now(), 'running');
        UPDATE jarvis_ops.workflow_run
           SET finished_at = now(), duration_ms = 42, status = 'succeeded', items_out = 1
         WHERE run_id = '""" + RUN_A + """';
        SELECT status FROM jarvis_ops.workflow_run WHERE run_id = '""" + RUN_A + """';
        """,
        expect="ok", match="succeeded",
    ),
    sql_test(
        "1.0-A5b", "Abgeschlossener Lauf kann nicht erneut veraendert werden",
        """
        SET ROLE jv_privat_user;
        UPDATE jarvis_ops.workflow_run SET status = 'failed'
         WHERE run_id = '""" + RUN_A + """';
        """,
        expect="error", match="run_already_final",
    ),
    # ---------------------------------------------------------------- A6
    sql_test(
        "1.0-A6", "Derselbe Idempotenzschluessel erzeugt keine zweite Aktion",
        """
        SET ROLE jv_privat_user;
        """ + ACTION_INSERT.format(action_id=ACTION_A, idem=IDEM_A) + """;
        """ + ACTION_INSERT.format(action_id="act_01JQ8ZKPT4N7VXWA2E5GHM3BCF", idem=IDEM_A) + """;
        """,
        expect="error", match="action_idempotency_uq",
    ),
    sql_test(
        "1.0-A6b", "Nach dem Doppelversuch existiert genau eine Aktion",
        "SELECT count(*) FROM jarvis_privat.action WHERE idempotency_key = '" + IDEM_A + "';",
        expect="ok", match="1",
    ),
    # ---------------------------------------------------------------- A7
    sql_test(
        "1.0-A7", "Sperre kann nur einmal beansprucht werden",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.action_lock (idempotency_key, action_id, claimed_by, expires_at)
        VALUES ('""" + IDEM_A + """', '""" + ACTION_A + """', 'lauf_1', now() + interval '5 min')
        ON CONFLICT DO NOTHING
        RETURNING idempotency_key;
        """,
        expect="ok", match=IDEM_A,
    ),
    sql_test(
        "1.0-A7b", "Zweiter Anspruch auf dieselbe Sperre erhaelt keine Zeile",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.action_lock (idempotency_key, action_id, claimed_by, expires_at)
        VALUES ('""" + IDEM_A + """', '""" + ACTION_A + """', 'lauf_2', now() + interval '5 min')
        ON CONFLICT DO NOTHING
        RETURNING idempotency_key;
        """,
        # Der zweite Anspruch laeuft ohne Fehler durch, gibt aber keine Zeile
        # zurueck. Genau daran erkennt der Aufrufer, dass die Aktion bereits
        # laeuft und nicht erneut ausgefuehrt werden darf.
        expect="ok", match="(0 rows)",
    ),
    # --------------------------------------------------- Phase-1-Tabellen
    sql_test(
        "1.0-P1a", "Vorgangsnummer wird fortlaufend und je Jahr vergeben",
        """
        SET ROLE jv_privat_user;
        SELECT jarvis_privat.next_case_number(2026) || ' ' || jarvis_privat.next_case_number(2026);
        """,
        expect="ok", match="V-2026-0001 V-2026-0002",
    ),
    sql_test(
        "1.0-P1b", "Dokument und Vorgang lassen sich anlegen",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat."case" (
            case_id, schema_version, case_number, title, category_key, status, opened_at, body)
        VALUES ('""" + CASE_A + """', '1.0.0', 'V-2026-0003', 'Synthetischer Testvorgang',
                'versicherung', 'open', now(), '{}'::jsonb);
        INSERT INTO jarvis_privat.document (
            document_id, schema_version, status, intake_channel, intake_adapter_id,
            source_external_id, received_at, source_event_id, mime_type, size_bytes,
            content_hash, case_id, case_number, body)
        VALUES ('""" + DOC_A + """', '1.0.0', 'received', 'drive_inbox', 'storage_gdrive',
                'synthetic-file-0001', now(), 'evt_01JQ8ZKPT4N7VXWA2E5GHM3BCD',
                'application/pdf', 12345, 'sha256:""" + "d" * 64 + """',
                '""" + CASE_A + """', 'V-2026-0003', '{}'::jsonb)
        RETURNING document_id;
        """,
        expect="ok", match=DOC_A,
    ),
    sql_test(
        "1.0-P1c", "Gleicher content_hash wird als harte Dublette abgewiesen",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.document (
            document_id, schema_version, status, intake_channel, intake_adapter_id,
            source_external_id, received_at, source_event_id, mime_type, size_bytes,
            content_hash, body)
        VALUES ('doc_01JQ8ZKPT4N7VXWA2E5GHM3BCE', '1.0.0', 'received', 'drive_inbox',
                'storage_gdrive', 'synthetic-file-0002', now(),
                'evt_01JQ8ZKPT4N7VXWA2E5GHM3BCE', 'application/pdf', 999,
                'sha256:""" + "d" * 64 + """', '{}'::jsonb);
        """,
        expect="error", match="document_content_hash_uq",
    ),
    sql_test(
        "1.0-P1d", "Dublette ohne Verweis auf das Original wird abgewiesen",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.document (
            document_id, schema_version, status, intake_channel, intake_adapter_id,
            source_external_id, received_at, source_event_id, mime_type, size_bytes,
            content_hash, body)
        VALUES ('doc_01JQ8ZKPT4N7VXWA2E5GHM3BCF', '1.0.0', 'duplicate', 'drive_inbox',
                'storage_gdrive', 'synthetic-file-0003', now(),
                'evt_01JQ8ZKPT4N7VXWA2E5GHM3BCF', 'application/pdf', 999,
                'sha256:""" + "e" * 64 + """', '{}'::jsonb);
        """,
        expect="error", match="document_duplicate_requires_original",
    ),
    sql_test(
        "1.0-P1e", "Dieselbe Kennung kann nicht zwei Vorgaengen gehoeren",
        """
        SET ROLE jv_privat_user;
        INSERT INTO jarvis_privat.case_identifier (case_id, identifier_type, value_normalized)
        VALUES ('""" + CASE_A + """', 'policy_number', 'SYNTH-POL-0001');
        INSERT INTO jarvis_privat.case_identifier (case_id, identifier_type, value_normalized)
        VALUES ('""" + CASE_A + """', 'policy_number', 'SYNTH-POL-0001');
        """,
        expect="error", match="case_identifier_value_uq",
    ),
    sql_test(
        "1.0-P1f", "Abgeschlossener Vorgang ohne Abschlusszeitpunkt wird abgewiesen",
        """
        SET ROLE jv_privat_user;
        UPDATE jarvis_privat."case" SET status = 'closed' WHERE case_id = '""" + CASE_A + """';
        """,
        expect="error", match="case_closed_requires_timestamp",
    ),
    sql_test(
        "1.0-P1g", "Kein DELETE auf dem Dokumentregister",
        """
        SET ROLE jv_privat_user;
        DELETE FROM jarvis_privat.document;
        """,
        expect="error", match="permission denied",
    ),
]


def run_sql(psql_args, sql):
    """Fuehrt SQL in einer eigenen Sitzung aus. Rueckgabe: (erfolg, ausgabe)."""
    script = "\\set ON_ERROR_STOP on\n\\set VERBOSITY verbose\n" + sql
    proc = subprocess.run(
        ["psql", *psql_args, "-v", "ON_ERROR_STOP=1", "-X", "-q"],
        input=script, capture_output=True, text=True,
    )
    return proc.returncode == 0, (proc.stdout + proc.stderr).strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--psql-args", default="", help="Argumente fuer psql, z. B. \"-h /sock -p 5432 -U postgres -d jarvis_test\"")
    parser.add_argument("--dsn", help="alternativ eine Verbindungszeichenfolge")
    parser.add_argument("--write-log", help="Nachweis zusaetzlich in diese Datei schreiben")
    args = parser.parse_args()

    psql_args = [args.dsn] if args.dsn else shlex.split(args.psql_args)
    if not psql_args:
        parser.error("--psql-args oder --dsn angeben")

    lines = []

    def out(text=""):
        print(text)
        lines.append(text)

    started = datetime.datetime.now(datetime.timezone.utc)
    out("JARVIS Phase 1.0 - Abnahme der Datenbank")
    out(f"Zeitpunkt (UTC): {started.isoformat(timespec='seconds')}")
    ok, version = run_sql(psql_args, "SELECT version();")
    out(f"Server:          {version.splitlines()[0].strip() if ok else 'unbekannt'}")
    out()

    failed = 0
    for test in TESTS:
        success, output = run_sql(psql_args, test["sql"])
        first_error = next(
            (ln.strip() for ln in output.splitlines() if ln.startswith(("ERROR", "FEHLER"))),
            output.splitlines()[0].strip() if output.splitlines() else "",
        )

        if test["expect"] == "ok":
            passed = success and (test["match"] is None or test["match"] in output)
            detail = output.replace("\n", " ")[:110] if passed else first_error[:110]
        else:
            passed = (not success) and (test["match"] is None or test["match"] in output)
            detail = first_error[:110]

        mark = "ok " if passed else "FEHLER"
        out(f"  [{mark}] {test['id']:9} {test['title']}")
        out(f"           -> {detail}")
        if not passed:
            failed += 1

    out()
    out(f"Pruefungen: {len(TESTS)}, davon fehlgeschlagen: {failed}")
    out("1.0-A8 (Export und Wiederherstellung) steht aus: setzt die n8n-Subworkflows voraus.")
    out("Gesamtergebnis: " + ("ALLE PRUEFUNGEN BESTANDEN" if failed == 0 else "FEHLGESCHLAGEN"))

    if args.write_log:
        target = pathlib.Path(args.write_log)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"\nProtokoll geschrieben: {target}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
