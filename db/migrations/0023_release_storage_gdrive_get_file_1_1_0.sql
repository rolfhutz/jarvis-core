-- =====================================================================
-- JARVIS Phase 1.1b - Migration 0023 - Freigabe storage_gdrive.get_file@1.1.0
--
-- Spezifikation 12.1.1, Schritte 1 bis 5, Abnahme 1.1-A16 (Speicherteil):
--   1 Vertrag vollstaendig        Register 0018, Schemata Nachtrag 1.1
--   2 Adapter mit Credential      JV-CORE-ADP-storage_gdrive-v1 (qZpVoKoKuPRyOGg7),
--                                 jv_privat_gdrive, veroeffentlicht
--   3 Testlauf im Zielsystem      Smoke-Test 23001, 143/143 (A-6, Adapter direkt)
--   4 Nachweis nach Vertrag       evd_01M2826973HJ0PPK7SJH6PTVA8 (privat),
--                                 provider_status, confirmed, Pruefsumme match
--   5 erst danach approved        diese Migration, nach Freigabe durch Rolf
--
-- Nur Kontext privat (allowed_contexts aus 0018). Verdrahtung in tool_invoke
-- folgt nach 1.1b-E2 erst in 1.1d (A14). Wiederholbar: ein zweiter Lauf
-- findet keine Zeile im Status draft und aendert nichts.
-- Haengt ab von: 0013, 0018.
-- =====================================================================

DO $$
DECLARE
    v_status text;
BEGIN
    SELECT status INTO v_status FROM jarvis_ops.tool_registry
     WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0';

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'tool_missing: storage_gdrive.get_file@1.1.0 fehlt (0018)' USING ERRCODE = '23514';
    END IF;
    IF v_status = 'deprecated' THEN
        RAISE EXCEPTION 'unexpected_state: storage_gdrive.get_file@1.1.0 ist deprecated' USING ERRCODE = '23514';
    END IF;

    -- Schritt 4 muss in der Datenbank belegt sein, nicht nur im Kommentar.
    IF NOT EXISTS (SELECT 1 FROM jarvis_privat.evidence
                    WHERE evidence_id = 'evd_01M2826973HJ0PPK7SJH6PTVA8'
                      AND contract_tool_id = 'storage_gdrive.get_file'
                      AND contract_version = '1.1.0'
                      AND verification_method = 'provider_status'
                      AND verification_result = 'confirmed') THEN
        RAISE EXCEPTION 'release_evidence_not_found: Nachweis evd_01M2826973HJ0PPK7SJH6PTVA8 fehlt oder ist nicht confirmed'
            USING ERRCODE = '23514';
    END IF;

    IF v_status = 'draft' THEN
        PERFORM set_config('jarvis.release_evidence_ref',
            'Smoke 23001 (143/143), Nachweis privat evd_01M2826973HJ0PPK7SJH6PTVA8 (provider_status, Pruefsumme match); Freigabe Rolf 11.09.2026', true);
        UPDATE jarvis_ops.tool_registry
           SET status = 'approved'
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0' AND status = 'draft';
    END IF;

    -- Selbstpruefung
    IF (SELECT status FROM jarvis_ops.tool_registry
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0') <> 'approved'
       OR NOT EXISTS (SELECT 1 FROM jarvis_ops.tool_release_log
                       WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0'
                         AND to_status = 'approved'
                         AND evidence_ref LIKE '%evd_01M2826973HJ0PPK7SJH6PTVA8%') THEN
        RAISE EXCEPTION 'release_not_verified: storage_gdrive.get_file@1.1.0' USING ERRCODE = '23514';
    END IF;
END
$$;
