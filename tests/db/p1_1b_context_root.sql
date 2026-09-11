-- =====================================================================
-- JARVIS Phase 1.1b - Pruefung der Migrationen 0020 bis 0022 (1.1b-E1)
--
-- Laeuft in einer Transaktion und wird zurueckgerollt. Voraussetzung:
-- 0001 bis 0022 eingespielt, Administrator darf die Kontextrollen annehmen.
-- Gegenproben (G) bestehen nur mit der erwarteten Fehlerart.
-- Aufruf: psql -v ON_ERROR_STOP=1 -f tests/db/p1_1b_context_root.sql
-- Erwartete Ausgabe am Ende: ERGEBNIS: BESTANDEN (9 Pruefungen)
-- =====================================================================

BEGIN;

CREATE TEMP TABLE p11b_result (nr text, ok boolean, detail text);
GRANT INSERT, SELECT ON p11b_result TO jv_privat_user, jv_visolva_user;

CREATE FUNCTION pg_temp.expect_error(p_nr text, p_sql text, p_pattern text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO p11b_result VALUES (p_nr, SQLERRM ILIKE '%' || p_pattern || '%', SQLERRM);
        RETURN;
    END;
    INSERT INTO p11b_result VALUES (p_nr, false, 'kein Fehler, erwartet: ' || p_pattern);
END;
$$;

CREATE FUNCTION pg_temp.expect(p_nr text, p_cond boolean, p_detail text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO p11b_result VALUES (p_nr, coalesce(p_cond, false), p_detail);
END;
$$;

-- Als Administrator
SELECT pg_temp.expect('R01 Wurzel je Kontext gesetzt, Version 1.1.0',
    (SELECT count(*) FROM jarvis_ops.context_document_settings
      WHERE config_version = '1.1.0'
        AND context_root_ref = CASE context_id WHEN 'privat' THEN 'env:JV_PRIVAT_ROOT_FOLDER_ID'
                                               WHEN 'arbeitgeber_visolva' THEN 'env:JV_VISOLVA_ROOT_FOLDER_ID' END) = 2,
    (SELECT string_agg(context_id || '=' || coalesce(context_root_ref, 'NULL'), ', ') FROM jarvis_ops.context_document_settings));
SELECT pg_temp.expect('R02 Spalte ist Pflicht',
    (SELECT attnotnull FROM pg_attribute
      WHERE attrelid = 'jarvis_ops.context_document_settings'::regclass AND attname = 'context_root_ref'),
    'attnotnull');
SELECT pg_temp.expect('R03 Bindungen unveraendert, Laufzeitzustand erhalten',
    (SELECT count(*) FROM jarvis_ops.source_binding WHERE enabled AND config_version = '1.1.0') = 2
    AND (SELECT count(*) FROM jarvis_ops.source_binding WHERE halted_at IS NOT NULL) = 0,
    'zwei aktive Bindungen');
SELECT pg_temp.expect_error('R04 G Wurzel entfernen',
    $q$ UPDATE jarvis_ops.context_document_settings SET context_root_ref = NULL WHERE context_id = 'privat' $q$,
    'null value');
SELECT pg_temp.expect_error('R05 G Wurzel = Eingang',
    $q$ UPDATE jarvis_ops.context_document_settings SET context_root_ref = inbox_ref WHERE context_id = 'privat' $q$,
    'cds_refs_distinct');
SELECT pg_temp.expect_error('R06 G Wurzel = Archiv',
    $q$ UPDATE jarvis_ops.context_document_settings SET context_root_ref = archive_root_ref WHERE context_id = 'privat' $q$,
    'cds_refs_distinct');
SELECT pg_temp.expect_error('R07 G Ordner-ID statt env-Verweis',
    $q$ UPDATE jarvis_ops.context_document_settings SET context_root_ref = '1AbCdEfGhIjKlMn' WHERE context_id = 'privat' $q$,
    'cds_context_root_ref_format');

-- Als Kontextbenutzer privat: lesen ja, aendern nein
SET LOCAL ROLE jv_privat_user;
SELECT pg_temp.expect('R08 Kontextbenutzer liest Wurzel',
    (SELECT context_root_ref FROM jarvis_ops.context_document_settings WHERE context_id = 'privat') = 'env:JV_PRIVAT_ROOT_FOLDER_ID',
    'SELECT');
SELECT pg_temp.expect_error('R09 G Kontextbenutzer aendert Wurzel',
    $q$ UPDATE jarvis_ops.context_document_settings SET context_root_ref = 'env:JV_PRIVAT_ANDERS' WHERE context_id = 'privat' $q$,
    'permission denied');
RESET ROLE;

SELECT nr, CASE WHEN ok THEN 'OK' ELSE 'FEHLER' END AS ergebnis, left(detail, 120) AS detail FROM p11b_result ORDER BY nr;
SELECT 'ERGEBNIS: ' || CASE WHEN bool_and(ok) THEN 'BESTANDEN' ELSE 'NICHT BESTANDEN' END
       || ' (' || count(*) || ' Pruefungen)' AS gesamt FROM p11b_result;

ROLLBACK;
