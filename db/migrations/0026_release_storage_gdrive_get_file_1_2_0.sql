-- =====================================================================
-- JARVIS Phase 1.1b Teil 2 - Migration 0026 - Freigabe storage_gdrive.get_file@1.2.0
--
-- Aenderungspaket 1.1b-E3 (13.09.2026, Rolf): arbeitgeber_visolva laeuft
-- vorlaeufig ueber Google Drive. Version 1.2.0 (Migration 0024) ist inhaltlich
-- gleich 1.1.0, zusaetzlich fuer arbeitgeber_visolva zugelassen.
--
-- Spezifikation 12.1.1, Schritte 1 bis 5, Abnahme S-A6 / 1.1-A16:
--   1 Vertrag vollstaendig        Register 0024, Schemata Nachtrag 1.1
--   2 Adapter mit Credential      JV-CORE-ADP-storage_gdrive-v1 (qZpVoKoKuPRyOGg7, privat)
--                                 JV-CORE-ADP-storage_gdrive_visolva-v1 (IHdbJYSAs2HtMzK6,
--                                 arbeitgeber_visolva), beide veroeffentlicht
--   3 Testlauf im Zielsystem      Smoke-Test 23802, 168/168 (SG-*, SVG-*)
--   4 Nachweis nach Vertrag       evd_01M2E6A38ZX84HYP8C6WA5HPGE (arbeitgeber_visolva),
--                                 provider_status, confirmed, Pruefsumme match
--   5 erst danach approved        diese Migration, nach Freigabe durch Rolf
--
-- Zweiter Teil: 1.1.0 wird durch 1.2.0 abgeloest und auf deprecated gesetzt,
-- damit je Werkzeug genau eine freigegebene Version besteht (Auswahl in
-- tool_invoke, 1.1d). Beide Schritte wiederholbar; ein zweiter Lauf aendert nichts.
-- Haengt ab von: 0013, 0023, 0024.
-- =====================================================================

DO $$
DECLARE
    v_status text;
BEGIN
    SELECT status INTO v_status FROM jarvis_ops.tool_registry
     WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.2.0';

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'tool_missing: storage_gdrive.get_file@1.2.0 fehlt (0024)' USING ERRCODE = '23514';
    END IF;
    IF v_status = 'deprecated' THEN
        RAISE EXCEPTION 'unexpected_state: storage_gdrive.get_file@1.2.0 ist deprecated' USING ERRCODE = '23514';
    END IF;

    -- Schritt 4 muss in der Datenbank belegt sein, nicht nur im Kommentar.
    IF NOT EXISTS (SELECT 1 FROM jarvis_visolva.evidence
                    WHERE evidence_id = 'evd_01M2E6A38ZX84HYP8C6WA5HPGE'
                      AND contract_tool_id = 'storage_gdrive.get_file'
                      AND contract_version = '1.2.0'
                      AND verification_method = 'provider_status'
                      AND verification_result = 'confirmed') THEN
        RAISE EXCEPTION 'release_evidence_not_found: Nachweis evd_01M2E6A38ZX84HYP8C6WA5HPGE fehlt oder ist nicht confirmed'
            USING ERRCODE = '23514';
    END IF;

    IF v_status = 'draft' THEN
        PERFORM set_config('jarvis.release_evidence_ref',
            'Smoke 23802 (168/168), Nachweis arbeitgeber_visolva evd_01M2E6A38ZX84HYP8C6WA5HPGE (provider_status, Pruefsumme match); Freigabe Rolf 13.09.2026 (1.1b-E3)', true);
        UPDATE jarvis_ops.tool_registry
           SET status = 'approved'
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.2.0' AND status = 'draft';
    END IF;

    -- Vorgaenger 1.1.0 abloesen.
    IF (SELECT status FROM jarvis_ops.tool_registry
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0') = 'approved' THEN
        PERFORM set_config('jarvis.release_evidence_ref',
            'Abgeloest durch storage_gdrive.get_file@1.2.0 (1.1b-E3, Migration 0026)', true);
        UPDATE jarvis_ops.tool_registry
           SET status = 'deprecated'
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0' AND status = 'approved';
    END IF;

    -- Selbstpruefung
    IF (SELECT status FROM jarvis_ops.tool_registry
         WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.2.0') <> 'approved'
       OR NOT EXISTS (SELECT 1 FROM jarvis_ops.tool_release_log
                       WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.2.0'
                         AND to_status = 'approved'
                         AND evidence_ref LIKE '%evd_01M2E6A38ZX84HYP8C6WA5HPGE%')
       OR (SELECT status FROM jarvis_ops.tool_registry
            WHERE tool_id = 'storage_gdrive.get_file' AND version = '1.1.0') <> 'deprecated'
       OR (SELECT count(*) FROM jarvis_ops.tool_registry
            WHERE tool_id = 'storage_gdrive.get_file' AND status = 'approved') <> 1 THEN
        RAISE EXCEPTION 'release_not_verified: storage_gdrive.get_file@1.2.0' USING ERRCODE = '23514';
    END IF;
END
$$;
