"""
JARVIS Phase 1.0 - Readback der Datenbankstruktur.

Liest zurueck, was tatsaechlich in der Datenbank steht, und vergleicht es
mit dem, was die Spezifikation erwartet. Grundsatz aus Entscheidung D3:
Ein unabhaengiger Readback ist der Nachweis, nicht die Rueckmeldung des
ausfuehrenden Werkzeugs.

Geprueft werden:
  1. Schemata
  2. Tabellen je Schema, einschliesslich der Phase-1-Erweiterung
  3. Rollen und ihr Anmelderecht
  4. Pruefbedingungen der Kontexttrennung
  5. Trigger des Fachprotokolls und des Laufschutzes
  6. Eindeutigkeitsindizes
  7. Eintraege im Kontextregister

Aufruf:
    python3 tests/db/readback_phase_1_0.py --psql-args="-h /sock -p 5432 -U postgres -d jarvis_test"
"""

from __future__ import annotations

import argparse
import datetime
import pathlib
import shlex
import subprocess

CONTEXT_SCHEMAS = {"jarvis_privat": "privat", "jarvis_visolva": "arbeitgeber_visolva"}

PHASE_0_TABLES = [
    "event", "task", "action", "action_lock", "approval", "evidence",
    "error_event", "action_log", "memory_entry",
]
PHASE_1_TABLES = [
    "document", "case", "case_identifier", "document_text",
    "document_extraction", "document_analysis", "case_number_seq",
    "test_approval_record",
]
OPS_TABLES = [
    "workflow_run", "tech_event", "tool_circuit_state",
    "contract_version", "context_registry",
]
ROLES = ["jv_privat_user", "jv_visolva_user"]


def query(psql_args, sql):
    proc = subprocess.run(
        ["psql", *psql_args, "-X", "-t", "-A", "-F", "|", "-v", "ON_ERROR_STOP=1", "-c", sql],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip())
    return [ln for ln in proc.stdout.strip().splitlines() if ln]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--psql-args", default="")
    parser.add_argument("--dsn")
    parser.add_argument("--write-log")
    args = parser.parse_args()

    psql_args = [args.dsn] if args.dsn else shlex.split(args.psql_args)
    if not psql_args:
        parser.error("--psql-args oder --dsn angeben")

    lines = []
    failed = 0

    def out(text=""):
        print(text)
        lines.append(text)

    def check(label, ok, detail=""):
        nonlocal failed
        out(f"  [{'ok ' if ok else 'FEHLER'}] {label}{('  -> ' + detail) if detail else ''}")
        if not ok:
            failed += 1

    out("JARVIS Phase 1.0 - Readback der Datenbankstruktur")
    out(f"Zeitpunkt (UTC): {datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')}")
    out(f"Server:          {query(psql_args, 'SELECT version()')[0].split(' on ')[0]}")
    out()

    # 1. Schemata
    out("1. Schemata")
    schemas = set(query(psql_args, "SELECT nspname FROM pg_namespace"))
    for expected in ["jarvis_ops", *CONTEXT_SCHEMAS]:
        check(f"Schema {expected}", expected in schemas)
    out()

    # 2. Tabellen
    out("2. Tabellen")
    for schema in ["jarvis_ops", *CONTEXT_SCHEMAS]:
        found = set(query(
            psql_args,
            f"SELECT tablename FROM pg_tables WHERE schemaname = '{schema}'",
        ))
        expected = OPS_TABLES if schema == "jarvis_ops" else PHASE_0_TABLES + PHASE_1_TABLES
        missing = [t for t in expected if t not in found]
        check(f"{schema}: {len(expected)} erwartete Tabellen vorhanden",
              not missing, f"fehlt: {missing}" if missing else f"{len(found)} Tabellen insgesamt")
        if schema != "jarvis_ops":
            # document_index geht laut Abschnitt 7.2 in document auf.
            check(f"{schema}: document_index ist abgeloest", "document_index" not in found)
    out()

    # 3. Rollen
    out("3. Rollen")
    rows = dict(
        ln.split("|") for ln in query(
            psql_args,
            "SELECT rolname, rolcanlogin::text FROM pg_roles WHERE rolname LIKE 'jv\\_%'",
        )
    )
    # boolean::text liefert in PostgreSQL 'false', nicht 'f'.
    for role in ROLES:
        no_login = rows.get(role) == "false"
        check(f"Rolle {role} existiert", role in rows)
        check(f"Rolle {role} ohne Anmelderecht", no_login,
              "NOLOGIN" if no_login else f"rolcanlogin={rows.get(role)}")
    out()

    # 4. Pruefbedingungen der Kontexttrennung
    out("4. Pruefbedingungen der Kontexttrennung")
    for schema, context_id in CONTEXT_SCHEMAS.items():
        rows = query(psql_args, f"""
            SELECT c.conname
              FROM pg_constraint c
              JOIN pg_class t ON t.oid = c.conrelid
              JOIN pg_namespace n ON n.oid = t.relnamespace
             WHERE n.nspname = '{schema}' AND c.contype = 'c'
               AND pg_get_constraintdef(c.oid) LIKE '%context_id%''{context_id}''%'
        """)
        check(f"{schema}: Kontextbedingung auf {len(rows)} Tabellen", len(rows) >= 15,
              f"{len(rows)} Bedingungen")
    out()

    # 5. Trigger
    out("5. Trigger")
    for schema in CONTEXT_SCHEMAS:
        found = set(query(psql_args, f"""
            SELECT tg.tgname FROM pg_trigger tg
              JOIN pg_class t ON t.oid = tg.tgrelid
              JOIN pg_namespace n ON n.oid = t.relnamespace
             WHERE n.nspname = '{schema}' AND NOT tg.tgisinternal
        """))
        for name in ("action_log_deny_update", "action_log_deny_delete", "action_log_deny_truncate"):
            check(f"{schema}.{name}", name in found)
    ops_trigger = set(query(psql_args, """
        SELECT tg.tgname FROM pg_trigger tg
          JOIN pg_class t ON t.oid = tg.tgrelid
          JOIN pg_namespace n ON n.oid = t.relnamespace
         WHERE n.nspname = 'jarvis_ops' AND NOT tg.tgisinternal
    """))
    for name in ("workflow_run_guard", "workflow_run_deny_delete",
                 "tech_event_deny_update", "tech_event_deny_delete"):
        check(f"jarvis_ops.{name}", name in ops_trigger)
    out()

    # 6. Eindeutigkeitsindizes
    out("6. Eindeutigkeitsindizes")
    for schema in CONTEXT_SCHEMAS:
        found = set(query(psql_args, f"""
            SELECT indexname FROM pg_indexes WHERE schemaname = '{schema}'
        """))
        for name in ("action_idempotency_uq", "event_idempotency_uq", "task_idempotency_uq",
                     "document_content_hash_uq", "case_number_uq", "case_identifier_value_uq"):
            check(f"{schema}.{name}", name in found)
    out()

    # 7. Kontextregister
    out("7. Kontextregister")
    rows = query(psql_args, """
        SELECT context_id, db_schema, db_user, status
          FROM jarvis_ops.context_registry ORDER BY context_id
    """)
    check("Zwei Kontexte registriert", len(rows) == 2, f"{len(rows)} Eintraege")
    for row in rows:
        out(f"           {row}")
    expected_rows = {
        "privat|jarvis_privat|jv_privat_user|active",
        "arbeitgeber_visolva|jarvis_visolva|jv_visolva_user|active",
    }
    check("Eintraege stimmen mit der Kontextkonfiguration ueberein",
          set(rows) == expected_rows)
    contracts = query(psql_args, "SELECT contract_id || ' ' || version FROM jarvis_ops.contract_version ORDER BY contract_id")
    check("Vertragsversionen registriert", len(contracts) == 2, ", ".join(contracts))
    out()

    out(f"Ergebnis: fehlgeschlagene Pruefungen: {failed}")
    out("Gesamtergebnis: " + ("READBACK VOLLSTAENDIG" if failed == 0 else "READBACK UNVOLLSTAENDIG"))

    if args.write_log:
        target = pathlib.Path(args.write_log)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"\nProtokoll geschrieben: {target}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
