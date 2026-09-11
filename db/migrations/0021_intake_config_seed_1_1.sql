-- =====================================================================
-- JARVIS Phase 1.1 - Migration 0021 - Laufzeitkonfiguration Eingang
--
-- ERZEUGT durch tools/render_intake_config.py. Nicht von Hand bearbeiten.
-- Quelle: config/intake_config.json (config_version 1.1.0)
-- sha256: 6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244
--
-- Wiederholbar. Konfigurationsfelder werden auf den Stand der Datei gesetzt.
-- Der Laufzeitzustand (halted_at, halt_reason, halted_by) bleibt unberuehrt.
-- Bindungen, die nicht mehr in der Datei stehen, werden deaktiviert, nicht
-- geloescht.
-- =====================================================================

INSERT INTO jarvis_ops.context_document_settings (context_id, config_version, storage_adapter_id, storage_container_ref, context_root_ref, inbox_ref, working_ref, archive_root_ref, drafts_ref, reports_ref, allowed_mime_types, max_file_size_mb, ocr_provider_allowlist, ocr_min_characters, ocr_min_mean_confidence, fingerprint_max_hamming, synthetic_marker_required, synthetic_marker_prefix, quarantine_halt_threshold, quarantine_halt_window_minutes, source_file, source_sha256) VALUES ('arbeitgeber_visolva', '1.1.0', 'storage_sharepoint', 'env:JV_VISOLVA_SP_DRIVE_ID', 'env:JV_VISOLVA_ROOT_FOLDER_ID', 'env:JV_VISOLVA_INBOX_FOLDER_ID', 'env:JV_VISOLVA_WORKING_FOLDER_ID', 'env:JV_VISOLVA_ARCHIVE_ROOT_ID', 'env:JV_VISOLVA_DRAFTS_FOLDER_ID', 'env:JV_VISOLVA_REPORTS_FOLDER_ID', ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/tiff']::text[], 50, ARRAY[]::text[], 200, '0.600'::numeric, 6, true, 'SYNTH_', 5, 60, 'config/intake_config.json', '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244')
ON CONFLICT (context_id) DO UPDATE SET config_version = EXCLUDED.config_version, storage_adapter_id = EXCLUDED.storage_adapter_id, storage_container_ref = EXCLUDED.storage_container_ref, context_root_ref = EXCLUDED.context_root_ref, inbox_ref = EXCLUDED.inbox_ref, working_ref = EXCLUDED.working_ref, archive_root_ref = EXCLUDED.archive_root_ref, drafts_ref = EXCLUDED.drafts_ref, reports_ref = EXCLUDED.reports_ref, allowed_mime_types = EXCLUDED.allowed_mime_types, max_file_size_mb = EXCLUDED.max_file_size_mb, ocr_provider_allowlist = EXCLUDED.ocr_provider_allowlist, ocr_min_characters = EXCLUDED.ocr_min_characters, ocr_min_mean_confidence = EXCLUDED.ocr_min_mean_confidence, fingerprint_max_hamming = EXCLUDED.fingerprint_max_hamming, synthetic_marker_required = EXCLUDED.synthetic_marker_required, synthetic_marker_prefix = EXCLUDED.synthetic_marker_prefix, quarantine_halt_threshold = EXCLUDED.quarantine_halt_threshold, quarantine_halt_window_minutes = EXCLUDED.quarantine_halt_window_minutes, source_file = EXCLUDED.source_file, source_sha256 = EXCLUDED.source_sha256, loaded_at = now();
INSERT INTO jarvis_ops.source_binding (binding_key, context_id, adapter_id, channel, location_ref, purpose, enabled, config_version, source_file, source_sha256) VALUES ('visolva_sharepoint_inbox', 'arbeitgeber_visolva', 'storage_sharepoint', 'drive_inbox', 'env:JV_VISOLVA_INBOX_FOLDER_ID', 'intake', true, '1.1.0', 'config/intake_config.json', '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244')
ON CONFLICT (binding_key) DO UPDATE SET context_id = EXCLUDED.context_id, adapter_id = EXCLUDED.adapter_id, channel = EXCLUDED.channel, location_ref = EXCLUDED.location_ref, purpose = EXCLUDED.purpose, enabled = EXCLUDED.enabled, config_version = EXCLUDED.config_version, source_file = EXCLUDED.source_file, source_sha256 = EXCLUDED.source_sha256, loaded_at = now();
INSERT INTO jarvis_ops.context_document_settings (context_id, config_version, storage_adapter_id, storage_container_ref, context_root_ref, inbox_ref, working_ref, archive_root_ref, drafts_ref, reports_ref, allowed_mime_types, max_file_size_mb, ocr_provider_allowlist, ocr_min_characters, ocr_min_mean_confidence, fingerprint_max_hamming, synthetic_marker_required, synthetic_marker_prefix, quarantine_halt_threshold, quarantine_halt_window_minutes, source_file, source_sha256) VALUES ('privat', '1.1.0', 'storage_gdrive', NULL, 'env:JV_PRIVAT_ROOT_FOLDER_ID', 'env:JV_PRIVAT_INBOX_FOLDER_ID', 'env:JV_PRIVAT_WORKING_FOLDER_ID', 'env:JV_PRIVAT_ARCHIVE_ROOT_ID', 'env:JV_PRIVAT_DRAFTS_FOLDER_ID', 'env:JV_PRIVAT_REPORTS_FOLDER_ID', ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/tiff']::text[], 50, ARRAY[]::text[], 200, '0.600'::numeric, 6, false, NULL, 5, 60, 'config/intake_config.json', '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244')
ON CONFLICT (context_id) DO UPDATE SET config_version = EXCLUDED.config_version, storage_adapter_id = EXCLUDED.storage_adapter_id, storage_container_ref = EXCLUDED.storage_container_ref, context_root_ref = EXCLUDED.context_root_ref, inbox_ref = EXCLUDED.inbox_ref, working_ref = EXCLUDED.working_ref, archive_root_ref = EXCLUDED.archive_root_ref, drafts_ref = EXCLUDED.drafts_ref, reports_ref = EXCLUDED.reports_ref, allowed_mime_types = EXCLUDED.allowed_mime_types, max_file_size_mb = EXCLUDED.max_file_size_mb, ocr_provider_allowlist = EXCLUDED.ocr_provider_allowlist, ocr_min_characters = EXCLUDED.ocr_min_characters, ocr_min_mean_confidence = EXCLUDED.ocr_min_mean_confidence, fingerprint_max_hamming = EXCLUDED.fingerprint_max_hamming, synthetic_marker_required = EXCLUDED.synthetic_marker_required, synthetic_marker_prefix = EXCLUDED.synthetic_marker_prefix, quarantine_halt_threshold = EXCLUDED.quarantine_halt_threshold, quarantine_halt_window_minutes = EXCLUDED.quarantine_halt_window_minutes, source_file = EXCLUDED.source_file, source_sha256 = EXCLUDED.source_sha256, loaded_at = now();
INSERT INTO jarvis_ops.source_binding (binding_key, context_id, adapter_id, channel, location_ref, purpose, enabled, config_version, source_file, source_sha256) VALUES ('privat_drive_inbox', 'privat', 'storage_gdrive', 'drive_inbox', 'env:JV_PRIVAT_INBOX_FOLDER_ID', 'intake', true, '1.1.0', 'config/intake_config.json', '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244')
ON CONFLICT (binding_key) DO UPDATE SET context_id = EXCLUDED.context_id, adapter_id = EXCLUDED.adapter_id, channel = EXCLUDED.channel, location_ref = EXCLUDED.location_ref, purpose = EXCLUDED.purpose, enabled = EXCLUDED.enabled, config_version = EXCLUDED.config_version, source_file = EXCLUDED.source_file, source_sha256 = EXCLUDED.source_sha256, loaded_at = now();

-- Nicht mehr konfigurierte Bindungen deaktivieren.
UPDATE jarvis_ops.source_binding SET enabled = false, config_version = '1.1.0', loaded_at = now() WHERE enabled AND binding_key <> ALL (ARRAY['visolva_sharepoint_inbox', 'privat_drive_inbox']::text[]);

-- Selbstpruefung: Datenbank entspricht der Datei.
DO $$
DECLARE
    v_bad text;
BEGIN
    SELECT string_agg(x, ', ') INTO v_bad FROM (
        SELECT 'settings:' || e.ctx AS x
        FROM unnest(ARRAY['arbeitgeber_visolva', 'privat']::text[]) AS e(ctx)
        LEFT JOIN jarvis_ops.context_document_settings s ON s.context_id = e.ctx
        WHERE s.source_sha256 IS DISTINCT FROM '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244'
        UNION ALL
        SELECT 'binding:' || e.k
        FROM unnest(ARRAY['visolva_sharepoint_inbox', 'privat_drive_inbox']::text[]) AS e(k)
        LEFT JOIN jarvis_ops.source_binding b ON b.binding_key = e.k
        WHERE b.source_sha256 IS DISTINCT FROM '6bdae5cb2927fdfde15319de603dd02ba7b3df1db64c9b0c4434071b636fa244'
        UNION ALL
        SELECT 'aktiv_ohne_datei:' || b.binding_key
        FROM jarvis_ops.source_binding b
        WHERE b.enabled AND b.binding_key <> ALL (ARRAY['visolva_sharepoint_inbox', 'privat_drive_inbox']::text[])
    ) q;
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'intake_config_mismatch: %', v_bad USING ERRCODE = '23514';
    END IF;
END
$$;
