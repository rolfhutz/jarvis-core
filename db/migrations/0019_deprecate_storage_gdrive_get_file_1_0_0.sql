-- =====================================================================
-- JARVIS Phase 1.1 - Migration 0019 - storage_gdrive.get_file@1.0.0 ausser Betrieb
--
-- Entscheidung 1.1-E1 vom 10.09.2026 (Rolf), Grundlage ADR-001:
-- Google Drive ist nur fuer den Kontext privat zulaessig. Version 1.0.0
-- erlaubt beide Kontexte und wird nie freigegeben. Nachfolger ist
-- storage_gdrive.get_file@1.1.0 mit allowed_contexts = [privat] (Migration 0018).
--
-- deprecated ist nach 0013 endgueltig; die Aenderung wird mit Nachweisverweis
-- in tool_release_log protokolliert. Wiederholbar: Ein zweiter Lauf findet
-- keine Zeile im Status draft und aendert nichts.
-- Haengt ab von: 0013, 0014, 0018.
-- =====================================================================

DO $$
DECLARE
    v_status text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM jarvis_ops.tool_registry
                   WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0') THEN
        RAISE EXCEPTION 'successor_missing: storage_gdrive.get_file@1.1.0 fehlt, zuerst Migration 0018 einspielen'
            USING ERRCODE = '23514';
    END IF;

    SELECT status INTO v_status FROM jarvis_ops.tool_registry
    WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0';

    IF v_status = 'approved' THEN
        RAISE EXCEPTION 'unexpected_state: storage_gdrive.get_file@1.0.0 ist approved; Klaerung vor dem Ausserbetriebnehmen'
            USING ERRCODE = '23514';
    END IF;

    IF v_status = 'draft' THEN
        PERFORM set_config('jarvis.release_evidence_ref',
                           'DECISION_LOG 1.1-E1 (ADR-001): Nachfolger storage_gdrive.get_file@1.1.0, nur privat', true);
        UPDATE jarvis_ops.tool_registry
           SET status = 'deprecated'
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0' AND status = 'draft';
    END IF;

    -- Selbstpruefung
    IF (SELECT status FROM jarvis_ops.tool_registry
        WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0') <> 'deprecated'
       OR NOT EXISTS (SELECT 1 FROM jarvis_ops.tool_release_log
                      WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.0.0'
                        AND to_status = 'deprecated') THEN
        RAISE EXCEPTION 'deprecation_not_verified: storage_gdrive.get_file@1.0.0' USING ERRCODE = '23514';
    END IF;
END
$$;
