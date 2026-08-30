-- =====================================================================
-- JARVIS Phase 1.0 - Abnahme der Datenbank, Fassung fuer eine einzelne
-- SQL-Sitzung (Supabase MCP, SQL Editor, psql).
--
-- Inhaltsgleich mit tests/db/phase_1_0_acceptance.py. Die Python-Fassung
-- ruft psql je Pruefung einmal auf; diese Fassung laeuft in einer
-- einzigen Sitzung und faengt jeden erwarteten Fehler selbst ab.
--
-- WICHTIG - Unterschied zur Python-Fassung:
-- Alles hier laeuft in EINER Transaktion. Ein abgefangener Fehler rollt
-- den umschliessenden Unterblock vollstaendig zurueck, auch die vor dem
-- Fehler geglueckten Anweisungen. Eine Vorbedingung muss deshalb in einem
-- EIGENEN Unterblock stehen. Steht sie im selben Block wie der erwartete
-- Fehler, verschwindet sie wieder - siehe die Vorbedingung zu 1.0-A6.
--
-- Voraussetzungen:
--   - Migrationen 0001 bis 0010 eingespielt
--   - frisch migrierte, leere Datenbank; der Lauf schreibt synthetische
--     Zeilen und raeumt sie nicht ab, weil action_log append-only ist
--   - der ausfuehrende Benutzer darf die Kontextrollen annehmen
--     (Migration 0010)
--
-- Es werden ausschliesslich synthetische Testdaten verwendet.
-- Ein erwarteter Fehler ist ein Nachweis: Eine Ablehnung muss als FEHLER
-- kommen und darf nicht still verschluckt werden.
--
-- Geprueft werden 1.0-A1 bis 1.0-A7 aus Abschnitt 7.3 sowie sieben
-- ergaenzende Pruefungen der Phase-1-Tabellen. Insgesamt 23 Pruefungen.
-- 1.0-A8 (Export und Wiederherstellung) ist nicht enthalten: es setzt die
-- n8n-Subworkflows voraus.
-- =====================================================================

CREATE TEMP TABLE jv_check(nr int, id text, titel text, passed boolean, detail text);

DO $harness$
DECLARE
    v_ok     boolean;
    v_detail text;
    v_text   text;
    v_num    bigint;
    k_idem   char(64) := repeat('a', 64);
    k_idem2  char(64) := repeat('c', 64);
    k_doc    text := 'doc_01JQ8ZKPT4N7VXWA2E5GHM3BCD';
    k_case   text := 'cse_01JQ8ZKPT4N7VXWA2E5GHM3BCD';
    k_act    text := 'act_01JQ8ZKPT4N7VXWA2E5GHM3BCD';
    k_hash   text := 'sha256:' || repeat('d', 64);
BEGIN
    -- 1.0-A1 -----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'INSERT INTO jarvis_visolva.action_log (entry_kind, actor, summary_de, body)
                 VALUES (''test'', ''jarvis'', ''Fremdzugriff'', ''{}''::jsonb)';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        -- Bewusst auf den Meldungstext geprueft, nicht nur auf 42501:
        -- ein fehlendes SET-Recht auf die Rolle liefert denselben Code und
        -- wuerde sonst faelschlich als bestandene Trennung gelten.
        v_ok := v_detail LIKE '%permission denied for schema jarvis_visolva%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (1, '1.0-A1', 'Schreibversuch in fremdes Kontextschema scheitert', v_ok, v_detail);

    -- 1.0-A1b ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'SELECT 1 FROM jarvis_visolva.action_log LIMIT 1';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%permission denied for schema jarvis_visolva%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (2, '1.0-A1b', 'Lesezugriff auf fremdes Fachprotokoll scheitert', v_ok, v_detail);

    -- 1.0-A2 -----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'INSERT INTO jarvis_privat.action_log (context_id, entry_kind, actor, summary_de, body)
                 VALUES (''arbeitgeber_visolva'', ''test'', ''jarvis'', ''Falscher Kontext'', ''{}''::jsonb)';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%log_context_chk%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (3, '1.0-A2', 'Datensatz mit fremder context_id wird abgewiesen', v_ok, v_detail);

    -- 1.0-A2b ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.action (
                    action_id, schema_version, context_id, action_type, tool_id, tool_version,
                    risk_class, risk_class_source, status, priority, idempotency_key, body)
                 VALUES (%L, ''1.0.0'', ''arbeitgeber_visolva'', ''document.file'', ''storage_gdrive'',
                         ''1.0.0'', ''A'', ''tool_registry'', ''planned'', ''normal'', %L, ''{}''::jsonb)',
                 'act_01JQ8ZKPT4N7VXWA2E5GHM3BCE', k_idem2);
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%action_context_chk%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (4, '1.0-A2b', 'Aktion mit fremder context_id wird abgewiesen', v_ok, v_detail);

    -- 1.0-A3a ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'UPDATE jarvis_privat.action_log SET summary_de = ''manipuliert''';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%permission denied for table action_log%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (5, '1.0-A3a', 'UPDATE auf action_log scheitert als Kontextbenutzer', v_ok, v_detail);

    -- 1.0-A3b ----------------------------------------------------------
    -- Die Trigger fuer UPDATE und DELETE sind zeilenbasiert. Auf einer
    -- leeren Tabelle greifen sie nicht, weil es keine Zeile gibt, die
    -- geaendert wuerde. Der Test legt sich deshalb zuerst eine Zeile an.
    BEGIN
        EXECUTE 'INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
                 VALUES (''abnahme'', ''jarvis'', ''Synthetische Zeile fuer die Triggerprobe'', ''{}''::jsonb)';
        EXECUTE 'UPDATE jarvis_privat.action_log SET summary_de = ''manipuliert''';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%append_only_violation%';
    END;
    INSERT INTO jv_check VALUES (6, '1.0-A3b', 'UPDATE auf action_log scheitert auch als Eigentuemer (Trigger)', v_ok, v_detail);

    -- 1.0-A3c ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'DELETE FROM jarvis_privat.action_log';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%permission denied for table action_log%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (7, '1.0-A3c', 'DELETE auf action_log scheitert als Kontextbenutzer', v_ok, v_detail);

    -- 1.0-A3d ----------------------------------------------------------
    BEGIN
        EXECUTE 'INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
                 VALUES (''abnahme'', ''jarvis'', ''Synthetische Zeile fuer die Loeschprobe'', ''{}''::jsonb)';
        EXECUTE 'DELETE FROM jarvis_privat.action_log';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%append_only_violation%';
    END;
    INSERT INTO jv_check VALUES (8, '1.0-A3d', 'DELETE auf action_log scheitert auch als Eigentuemer (Trigger)', v_ok, v_detail);

    -- 1.0-A3e ----------------------------------------------------------
    BEGIN
        EXECUTE 'TRUNCATE jarvis_privat.action_log';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%append_only_violation%';
    END;
    INSERT INTO jv_check VALUES (9, '1.0-A3e', 'TRUNCATE auf action_log scheitert (Trigger)', v_ok, v_detail);

    -- 1.0-A4 -----------------------------------------------------------
    v_num := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'INSERT INTO jarvis_privat.action_log (entry_kind, actor, summary_de, body)
                 VALUES (''abnahme'', ''jarvis'', ''Synthetischer Abnahmeeintrag Phase 1.0'', ''{}''::jsonb)
                 RETURNING log_id' INTO v_num;
        v_ok := v_num IS NOT NULL; v_detail := 'log_id=' || coalesce(v_num::text, 'NULL');
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (10, '1.0-A4', 'INSERT in action_log gelingt, Sequenzrecht greift', v_ok, v_detail);

    -- 1.0-A5 -----------------------------------------------------------
    v_text := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'INSERT INTO jarvis_ops.workflow_run (run_id, trace_id, workflow_name, workflow_version,
                     context_id, started_at, status)
                 VALUES (''run_phase10_abnahme_0001'', ''trc_abnahme_0001'', ''phase_1_0_abnahme'',
                         ''1.0.0'', ''privat'', now(), ''running'')';
        EXECUTE 'UPDATE jarvis_ops.workflow_run
                    SET finished_at = now(), duration_ms = 42, status = ''succeeded'', items_out = 1
                  WHERE run_id = ''run_phase10_abnahme_0001''';
        EXECUTE 'SELECT status FROM jarvis_ops.workflow_run WHERE run_id = ''run_phase10_abnahme_0001''' INTO v_text;
        v_ok := v_text = 'succeeded'; v_detail := 'status=' || coalesce(v_text, 'NULL');
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (11, '1.0-A5', 'Workflow-Lauf kann gestartet und abgeschlossen werden', v_ok, v_detail);

    -- 1.0-A5b ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'UPDATE jarvis_ops.workflow_run SET status = ''failed''
                  WHERE run_id = ''run_phase10_abnahme_0001''';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%run_already_final%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (12, '1.0-A5b', 'Abgeschlossener Lauf kann nicht erneut veraendert werden', v_ok, v_detail);

    -- Vorbedingung fuer 1.0-A6 und 1.0-A7 -------------------------------
    -- MUSS ein eigener Unterblock sein, sonst rollt der erwartete Fehler
    -- des zweiten Einfuegens diese erste Aktion mit zurueck.
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.action (
                    action_id, schema_version, action_type, tool_id, tool_version,
                    risk_class, risk_class_source, status, priority, idempotency_key, body)
                 VALUES (%L, ''1.0.0'', ''document.file'', ''storage_gdrive'', ''1.0.0'',
                         ''A'', ''tool_registry'', ''planned'', ''normal'', %L, ''{}''::jsonb)', k_act, k_idem);
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Vorbedingung fuer 1.0-A6 fehlgeschlagen: % %', SQLSTATE, SQLERRM;
    END;
    EXECUTE 'RESET ROLE';

    -- 1.0-A6 -----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.action (
                    action_id, schema_version, action_type, tool_id, tool_version,
                    risk_class, risk_class_source, status, priority, idempotency_key, body)
                 VALUES (%L, ''1.0.0'', ''document.file'', ''storage_gdrive'', ''1.0.0'',
                         ''A'', ''tool_registry'', ''planned'', ''normal'', %L, ''{}''::jsonb)',
                 'act_01JQ8ZKPT4N7VXWA2E5GHM3BCF', k_idem);
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%action_idempotency_uq%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (13, '1.0-A6', 'Derselbe Idempotenzschluessel erzeugt keine zweite Aktion', v_ok, v_detail);

    -- 1.0-A6b ----------------------------------------------------------
    EXECUTE format('SELECT count(*) FROM jarvis_privat.action WHERE idempotency_key = %L', k_idem) INTO v_num;
    INSERT INTO jv_check VALUES (14, '1.0-A6b', 'Nach dem Doppelversuch existiert genau eine Aktion',
                                 v_num = 1, 'count=' || v_num::text);

    -- 1.0-A7 -----------------------------------------------------------
    v_text := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.action_lock (idempotency_key, action_id, claimed_by, expires_at)
                 VALUES (%L, %L, ''lauf_1'', now() + interval ''5 min'')
                 ON CONFLICT DO NOTHING RETURNING idempotency_key', k_idem, k_act) INTO v_text;
        v_ok := v_text IS NOT NULL;
        v_detail := 'Sperre erhalten: ' || coalesce(left(v_text, 12) || '...', 'NULL');
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (15, '1.0-A7', 'Sperre kann nur einmal beansprucht werden', v_ok, v_detail);

    -- 1.0-A7b ----------------------------------------------------------
    v_text := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.action_lock (idempotency_key, action_id, claimed_by, expires_at)
                 VALUES (%L, %L, ''lauf_2'', now() + interval ''5 min'')
                 ON CONFLICT DO NOTHING RETURNING idempotency_key', k_idem, k_act) INTO v_text;
        v_ok := v_text IS NULL;
        v_detail := 'zurueckgegebene Zeile: ' || coalesce(v_text, 'keine');
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (16, '1.0-A7b', 'Zweiter Anspruch auf dieselbe Sperre erhaelt keine Zeile', v_ok, v_detail);

    -- 1.0-P1a ----------------------------------------------------------
    v_text := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'SELECT jarvis_privat.next_case_number(2026) || '' '' || jarvis_privat.next_case_number(2026)' INTO v_text;
        v_ok := v_text = 'V-2026-0001 V-2026-0002'; v_detail := v_text;
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (17, '1.0-P1a', 'Vorgangsnummer wird fortlaufend und je Jahr vergeben', v_ok, v_detail);

    -- 1.0-P1b ----------------------------------------------------------
    v_text := NULL;
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat."case" (case_id, schema_version, case_number, title,
                     category_key, status, opened_at, body)
                 VALUES (%L, ''1.0.0'', ''V-2026-0003'', ''Synthetischer Testvorgang'',
                         ''versicherung'', ''open'', now(), ''{}''::jsonb)', k_case);
        EXECUTE format('INSERT INTO jarvis_privat.document (document_id, schema_version, status,
                     intake_channel, intake_adapter_id, source_external_id, received_at, source_event_id,
                     mime_type, size_bytes, content_hash, case_id, case_number, body)
                 VALUES (%L, ''1.0.0'', ''received'', ''drive_inbox'', ''storage_gdrive'',
                         ''synthetic-file-0001'', now(), ''evt_01JQ8ZKPT4N7VXWA2E5GHM3BCD'',
                         ''application/pdf'', 12345, %L, %L, ''V-2026-0003'', ''{}''::jsonb)
                 RETURNING document_id', k_doc, k_hash, k_case) INTO v_text;
        v_ok := v_text = k_doc; v_detail := 'document_id=' || coalesce(v_text, 'NULL');
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM; v_ok := false;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (18, '1.0-P1b', 'Dokument und Vorgang lassen sich anlegen', v_ok, v_detail);

    -- 1.0-P1c ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.document (document_id, schema_version, status,
                     intake_channel, intake_adapter_id, source_external_id, received_at, source_event_id,
                     mime_type, size_bytes, content_hash, body)
                 VALUES (''doc_01JQ8ZKPT4N7VXWA2E5GHM3BCE'', ''1.0.0'', ''received'', ''drive_inbox'',
                         ''storage_gdrive'', ''synthetic-file-0002'', now(),
                         ''evt_01JQ8ZKPT4N7VXWA2E5GHM3BCE'', ''application/pdf'', 999, %L, ''{}''::jsonb)', k_hash);
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%document_content_hash_uq%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (19, '1.0-P1c', 'Gleicher content_hash wird als harte Dublette abgewiesen', v_ok, v_detail);

    -- 1.0-P1d ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'INSERT INTO jarvis_privat.document (document_id, schema_version, status,
                     intake_channel, intake_adapter_id, source_external_id, received_at, source_event_id,
                     mime_type, size_bytes, content_hash, body)
                 VALUES (''doc_01JQ8ZKPT4N7VXWA2E5GHM3BCF'', ''1.0.0'', ''duplicate'', ''drive_inbox'',
                         ''storage_gdrive'', ''synthetic-file-0003'', now(),
                         ''evt_01JQ8ZKPT4N7VXWA2E5GHM3BCF'', ''application/pdf'', 999,
                         ''sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'', ''{}''::jsonb)';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%document_duplicate_requires_original%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (20, '1.0-P1d', 'Dublette ohne Verweis auf das Original wird abgewiesen', v_ok, v_detail);

    -- 1.0-P1e ----------------------------------------------------------
    -- Auch hier gilt: die erste Kennung entsteht in einem eigenen Block.
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.case_identifier (case_id, identifier_type, value_normalized)
                 VALUES (%L, ''policy_number'', ''SYNTH-POL-0001'')', k_case);
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    EXECUTE 'RESET ROLE';
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('INSERT INTO jarvis_privat.case_identifier (case_id, identifier_type, value_normalized)
                 VALUES (%L, ''policy_number'', ''SYNTH-POL-0001'')', k_case);
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%case_identifier_value_uq%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (21, '1.0-P1e', 'Dieselbe Kennung kann nicht zwei Vorgaengen gehoeren', v_ok, v_detail);

    -- 1.0-P1f ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE format('UPDATE jarvis_privat."case" SET status = ''closed'' WHERE case_id = %L', k_case);
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%case_closed_requires_timestamp%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (22, '1.0-P1f', 'Abgeschlossener Vorgang ohne Abschlusszeitpunkt wird abgewiesen', v_ok, v_detail);

    -- 1.0-P1g ----------------------------------------------------------
    BEGIN
        EXECUTE 'SET ROLE jv_privat_user';
        EXECUTE 'DELETE FROM jarvis_privat.document';
        v_ok := false; v_detail := 'kein Fehler aufgetreten';
    EXCEPTION WHEN OTHERS THEN
        v_detail := SQLSTATE || ' ' || SQLERRM;
        v_ok := v_detail LIKE '%permission denied for table document%';
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO jv_check VALUES (23, '1.0-P1g', 'Kein DELETE auf dem Dokumentregister', v_ok, v_detail);
END;
$harness$;

SELECT nr, id, passed, left(detail, 95) AS detail FROM jv_check ORDER BY nr;

SELECT count(*) FILTER (WHERE passed)     AS bestanden,
       count(*) FILTER (WHERE NOT passed) AS fehlgeschlagen,
       count(*)                           AS gesamt
  FROM jv_check;
