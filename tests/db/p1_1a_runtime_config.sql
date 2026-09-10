-- =====================================================================
-- JARVIS Phase 1.1a - Pruefung der Migrationen 0016 bis 0019
--
-- Laeuft vollstaendig in einer Transaktion und wird zurueckgerollt: keine
-- Restzeilen (intake_exception ist append-only und liesse sich sonst nicht
-- bereinigen). Voraussetzung: 0001 bis 0019 eingespielt, Administrator darf
-- die Kontextrollen annehmen (0010).
--
-- Gegenproben (G) bestehen nur mit der erwarteten Fehlerart.
-- Aufruf: psql -v ON_ERROR_STOP=1 -f tests/db/p1_1a_runtime_config.sql
-- Erwartete Ausgabe am Ende: ERGEBNIS: BESTANDEN (21 Pruefungen)
-- =====================================================================

BEGIN;

CREATE TEMP TABLE p11a_result (nr text, ok boolean, detail text);
GRANT INSERT, SELECT ON p11a_result TO jv_privat_user, jv_visolva_user;

-- Fuehrt sql aus und erwartet einen Fehler, dessen Meldung pattern enthaelt.
CREATE FUNCTION pg_temp.expect_error(p_nr text, p_sql text, p_pattern text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO p11a_result VALUES (p_nr, SQLERRM ILIKE '%' || p_pattern || '%', SQLERRM);
        RETURN;
    END;
    INSERT INTO p11a_result VALUES (p_nr, false, 'kein Fehler, erwartet: ' || p_pattern);
END;
$$;

CREATE FUNCTION pg_temp.expect(p_nr text, p_cond boolean, p_detail text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO p11a_result VALUES (p_nr, coalesce(p_cond, false), p_detail);
END;
$$;

-- ---------------------------------------------------------------------
-- Als Administrator
-- ---------------------------------------------------------------------
SELECT pg_temp.expect('A01 Admin ist kein Kontextbenutzer', jarvis_ops.current_context_id() IS NULL,
                      coalesce(jarvis_ops.current_context_id(), 'NULL'));
SELECT pg_temp.expect('A02 Register: gdrive.get_file 1.0.0 deprecated, 1.1.0 nur privat',
    (SELECT status FROM jarvis_ops.tool_registry WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0') = 'deprecated'
    AND (SELECT allowed_contexts FROM jarvis_ops.tool_registry WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0') = ARRAY['privat']::text[]
    AND (SELECT allowed_contexts FROM jarvis_ops.tool_registry WHERE tool_id = 'storage_sharepoint.get_file' AND version = '1.0.0') = ARRAY['arbeitgeber_visolva']::text[],
    'Registerstand');
SELECT pg_temp.expect_error('A03 G deprecated nicht reaktivierbar',
    $q$ SELECT set_config('jarvis.release_evidence_ref', 'TEST_REAKTIVIERUNG', true);
        UPDATE jarvis_ops.tool_registry SET status = 'draft'
        WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0' $q$,
    'registry_status_final');
SELECT pg_temp.expect_error('A04 G zweite Eingangsbindung auf demselben Ort',
    $q$ INSERT INTO jarvis_ops.source_binding (binding_key, context_id, adapter_id, channel, location_ref, purpose,
        enabled, config_version, source_file, source_sha256)
        VALUES ('privat_zweiter_eingang', 'privat', 'storage_gdrive', 'drive_inbox', 'env:JV_PRIVAT_INBOX_FOLDER_ID',
        'intake', true, '1.0.0', 'test', repeat('a', 64)) $q$,
    'source_binding_intake_location_uq');
SELECT pg_temp.expect_error('A05 G Ordner-ID statt env-Verweis',
    $q$ UPDATE jarvis_ops.context_document_settings SET inbox_ref = '1AbCdEfGhIjKlMn' WHERE context_id = 'privat' $q$,
    'check constraint');
SELECT pg_temp.expect_error('A06 G Eingang = Archiv',
    $q$ UPDATE jarvis_ops.context_document_settings SET archive_root_ref = inbox_ref WHERE context_id = 'privat' $q$,
    'cds_refs_distinct');

-- ---------------------------------------------------------------------
-- Als Kontextbenutzer privat
-- ---------------------------------------------------------------------
SET LOCAL ROLE jv_privat_user;
SELECT pg_temp.expect('P01 Kontext erkannt', jarvis_ops.current_context_id() = 'privat', coalesce(jarvis_ops.current_context_id(), 'NULL'));
SELECT pg_temp.expect('P02 liest alle Bindungen und Einstellungen',
    (SELECT count(*) FROM jarvis_ops.source_binding) = 2 AND (SELECT count(*) FROM jarvis_ops.context_document_settings) = 2,
    'Anzahl Zeilen');
SELECT pg_temp.expect_error('P03 G Bindung anlegen',
    $q$ INSERT INTO jarvis_ops.source_binding (binding_key, context_id, adapter_id, channel, location_ref, purpose,
        enabled, config_version, source_file, source_sha256)
        VALUES ('privat_neu', 'privat', 'storage_gdrive', 'drive_inbox', 'env:JV_PRIVAT_NEU', 'intake', true, '1.0.0',
        'test', repeat('a', 64)) $q$,
    'permission denied');
SELECT pg_temp.expect_error('P04 G Konfigurationsfeld aendern',
    $q$ UPDATE jarvis_ops.source_binding SET enabled = false WHERE binding_key = 'privat_drive_inbox' $q$,
    'permission denied');
SELECT pg_temp.expect_error('P05 G fremde Bindung anhalten',
    $q$ UPDATE jarvis_ops.source_binding SET halted_at = now(), halt_reason = 'quarantine_burst', halted_by = 'x'
        WHERE binding_key = 'visolva_sharepoint_inbox' $q$,
    'binding_foreign_context');
UPDATE jarvis_ops.source_binding SET halted_at = now(), halt_reason = 'quarantine_burst', halted_by = 'wird_ueberschrieben'
 WHERE binding_key = 'privat_drive_inbox' AND halted_at IS NULL;
SELECT pg_temp.expect('P06 eigene Bindung anhalten, halted_by = Datenbankbenutzer',
    (SELECT halted_by FROM jarvis_ops.source_binding WHERE binding_key = 'privat_drive_inbox') = current_user::text,
    (SELECT halted_by FROM jarvis_ops.source_binding WHERE binding_key = 'privat_drive_inbox'));
SELECT pg_temp.expect_error('P07 G Anhalten selbst aufheben',
    $q$ UPDATE jarvis_ops.source_binding SET halted_at = NULL, halt_reason = NULL, halted_by = NULL
        WHERE binding_key = 'privat_drive_inbox' $q$,
    'binding_halt_final');
SELECT pg_temp.expect_error('P08 G Dokumenteinstellung aendern',
    $q$ UPDATE jarvis_ops.context_document_settings SET max_file_size_mb = 200 WHERE context_id = 'privat' $q$,
    'permission denied');
INSERT INTO jarvis_ops.intake_exception (trace_id, adapter_id, location_ref, source_external_id, reason_code, candidate_contexts)
VALUES ('trc_p11a_test', 'storage_gdrive', 'env:JV_K07_PROBE_FOLDER_ID', '1Test_Datei-ID.abc', 'binding_ambiguous',
        ARRAY['privat','arbeitgeber_visolva'])
ON CONFLICT DO NOTHING;
INSERT INTO jarvis_ops.intake_exception (trace_id, adapter_id, location_ref, source_external_id, reason_code, candidate_contexts)
VALUES ('trc_p11a_test_2', 'storage_gdrive', 'env:JV_K07_PROBE_FOLDER_ID', '1Test_Datei-ID.abc', 'binding_ambiguous',
        ARRAY['privat','arbeitgeber_visolva'])
ON CONFLICT DO NOTHING;
SELECT pg_temp.expect('P09 Ausnahme genau einmal je Datei, Ort und Grund',
    (SELECT count(*) FROM jarvis_ops.intake_exception WHERE source_external_id = '1Test_Datei-ID.abc') = 1,
    'zweiter Eintrag ohne Wirkung');
SELECT pg_temp.expect_error('P10 G Dateiname statt Datei-ID',
    $q$ INSERT INTO jarvis_ops.intake_exception (trace_id, adapter_id, location_ref, source_external_id, reason_code)
        VALUES ('trc_p11a_test', 'storage_gdrive', 'env:JV_K07_PROBE_FOLDER_ID', 'Rechnung Mai 2026.pdf', 'context_not_active') $q$,
    'check constraint');
SELECT pg_temp.expect_error('P11 G Mehrdeutigkeit ohne zwei Kandidaten',
    $q$ INSERT INTO jarvis_ops.intake_exception (trace_id, adapter_id, location_ref, source_external_id, reason_code, candidate_contexts)
        VALUES ('trc_p11a_test', 'storage_gdrive', 'env:JV_K07_PROBE_FOLDER_ID', '1Andere', 'binding_ambiguous', ARRAY['privat']) $q$,
    'ie_ambiguous_needs_candidates');
SELECT pg_temp.expect_error('P12 G Ausnahme loeschen',
    $q$ DELETE FROM jarvis_ops.intake_exception WHERE source_external_id = '1Test_Datei-ID.abc' $q$,
    'permission denied');
RESET ROLE;

-- ---------------------------------------------------------------------
-- Als Kontextbenutzer arbeitgeber_visolva und wieder als Administrator
-- ---------------------------------------------------------------------
SET LOCAL ROLE jv_visolva_user;
SELECT pg_temp.expect('V01 Kontext erkannt', jarvis_ops.current_context_id() = 'arbeitgeber_visolva', coalesce(jarvis_ops.current_context_id(), 'NULL'));
RESET ROLE;

SELECT pg_temp.expect_error('A07 G Ausnahme aendern (auch Administrator)',
    $q$ UPDATE jarvis_ops.intake_exception SET reason_code = 'binding_unknown' WHERE source_external_id = '1Test_Datei-ID.abc' $q$,
    'append_only_violation');
UPDATE jarvis_ops.source_binding SET halted_at = NULL, halt_reason = NULL, halted_by = NULL WHERE binding_key = 'privat_drive_inbox';
SELECT pg_temp.expect('A08 Administrator hebt Anhalten auf',
    (SELECT halted_at FROM jarvis_ops.source_binding WHERE binding_key = 'privat_drive_inbox') IS NULL, 'halted_at NULL');

-- ---------------------------------------------------------------------
-- Auswertung
-- ---------------------------------------------------------------------
SELECT nr, CASE WHEN ok THEN 'OK' ELSE 'FEHLER' END AS ergebnis, left(detail, 120) AS detail FROM p11a_result ORDER BY nr;
SELECT 'ERGEBNIS: ' || CASE WHEN bool_and(ok) THEN 'BESTANDEN' ELSE 'NICHT BESTANDEN' END
       || ' (' || count(*) || ' Pruefungen)' AS gesamt FROM p11a_result;

ROLLBACK;
