-- =====================================================================
-- JARVIS Phase 1.1 - Migration 0018 - Werkzeugregister Nachtrag 1.1 (ADR-001, 1.1-E1)
--
-- ERZEUGT durch tools/render_tool_registry.py. Nicht von Hand bearbeiten.
-- Quelle:
--   spec/phase-1/nachtrag-1.1/registry/tool_registry_phase1_1.json
--
-- Wiederholbar: Vorhandene Eintraege werden nie ueberschrieben. Der
-- Freigabestatus in der Datenbank bleibt erhalten. Weicht die Definition
-- einer bereits geladenen Version ab, bricht der Lauf ab: Eine geaenderte
-- Definition erfordert eine neue Version.
-- Werkzeuge: 3
-- =====================================================================

INSERT INTO jarvis_ops.tool_registry (tool_id, version, adapter_id, operation, external_effect, risk_class_default, reversibility, undo_tool_id, allowed_contexts, readback_supported, accepted_methods, evidence_limitation, timeout_seconds, dry_run_supported, status, definition, definition_sha256, source_file, source_sha256) VALUES ('storage_gdrive.get_file', '1.1.0', 'storage_gdrive', 'read', 'none', 'A', 'reversible', NULL, ARRAY['privat']::text[], false, ARRAY['provider_status']::text[], 'Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.', 120, true, 'draft', '{"owner": "rolf", "purpose": "Originaldatei und ihre Metadaten aus dem kontextbezogenen Speicher lesen.", "tool_id": "storage_gdrive.get_file", "version": "1.1.0", "evidence": {"limitation": "Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.", "required_types": ["provider_status"], "accepted_methods": ["provider_status"], "readback_supported": false, "verify_delay_seconds": 0, "deferred_check_after_hours": null}, "operation": "read", "adapter_id": "storage_gdrive", "rate_limit": null, "idempotency": {"strategy": "db_unique_constraint", "key_fields": ["context_id", "source_ref", "action_type", "target_system", "target_object_ref"], "extra_dedup": null, "native_support": false}, "display_name": "Datei lesen", "retry_policy": {"backoff": "exponential_1m_factor5_jitter", "max_attempts": 3, "retryable_error_classes": ["transient_network", "rate_limited", "timeout"]}, "side_effects": "Keine. Reine Leseoperation.", "undo_tool_id": null, "reversibility": "reversible", "external_effect": "none", "timeout_seconds": 120, "allowed_contexts": ["privat"], "input_schema_ref": "schemas/tools/storage_gdrive.get_file.input.json", "dry_run_supported": true, "output_schema_ref": "schemas/tools/storage_gdrive.get_file.output.json", "risk_class_default": "A", "required_permissions": ["Datei lesen", "Metadaten lesen"]}'::jsonb, 'ad4d0dee1b148dab81fef8a879c56d9b765402905b199389dd37fae2146c1885', 'spec/phase-1/nachtrag-1.1/registry/tool_registry_phase1_1.json', 'e770a8936af941bd55f138559abc1be41ef7c206b4d27e44ad940b9199b60c89') ON CONFLICT (tool_id, version) DO NOTHING;
INSERT INTO jarvis_ops.tool_registry (tool_id, version, adapter_id, operation, external_effect, risk_class_default, reversibility, undo_tool_id, allowed_contexts, readback_supported, accepted_methods, evidence_limitation, timeout_seconds, dry_run_supported, status, definition, definition_sha256, source_file, source_sha256) VALUES ('storage_sharepoint.get_file', '1.0.0', 'storage_sharepoint', 'read', 'none', 'A', 'reversible', NULL, ARRAY['arbeitgeber_visolva']::text[], false, ARRAY['provider_status']::text[], 'Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.', 120, true, 'draft', '{"owner": "rolf", "purpose": "Originaldatei und ihre Metadaten aus der kontextbezogenen SharePoint-Bibliothek lesen.", "tool_id": "storage_sharepoint.get_file", "version": "1.0.0", "evidence": {"limitation": "Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.", "required_types": ["provider_status"], "accepted_methods": ["provider_status"], "readback_supported": false, "verify_delay_seconds": 0, "deferred_check_after_hours": null}, "operation": "read", "adapter_id": "storage_sharepoint", "rate_limit": null, "idempotency": {"strategy": "db_unique_constraint", "key_fields": ["context_id", "source_ref", "action_type", "target_system", "target_object_ref"], "extra_dedup": null, "native_support": false}, "display_name": "Datei lesen", "retry_policy": {"backoff": "exponential_1m_factor5_jitter", "max_attempts": 3, "retryable_error_classes": ["transient_network", "rate_limited", "timeout"]}, "side_effects": "Keine. Reine Leseoperation.", "undo_tool_id": null, "reversibility": "reversible", "external_effect": "none", "timeout_seconds": 120, "allowed_contexts": ["arbeitgeber_visolva"], "input_schema_ref": "schemas/tools/storage_sharepoint.get_file.input.json", "dry_run_supported": true, "output_schema_ref": "schemas/tools/storage_sharepoint.get_file.output.json", "risk_class_default": "A", "required_permissions": ["Datei lesen", "Metadaten lesen"]}'::jsonb, 'a863602ff30a63b3ad7ecac9e406ffe05154ebeca4815c7df8704ae859c1914c', 'spec/phase-1/nachtrag-1.1/registry/tool_registry_phase1_1.json', 'e770a8936af941bd55f138559abc1be41ef7c206b4d27e44ad940b9199b60c89') ON CONFLICT (tool_id, version) DO NOTHING;
INSERT INTO jarvis_ops.tool_registry (tool_id, version, adapter_id, operation, external_effect, risk_class_default, reversibility, undo_tool_id, allowed_contexts, readback_supported, accepted_methods, evidence_limitation, timeout_seconds, dry_run_supported, status, definition, definition_sha256, source_file, source_sha256) VALUES ('storage_sharepoint.move_file', '1.0.0', 'storage_sharepoint', 'write', 'internal', 'A', 'reversible', 'storage_sharepoint.move_file', ARRAY['arbeitgeber_visolva']::text[], true, ARRAY['readback']::text[], NULL, 60, true, 'draft', '{"owner": "rolf", "purpose": "Datei in der kontextbezogenen SharePoint-Bibliothek in den Zielordner verschieben und umbenennen.", "tool_id": "storage_sharepoint.move_file", "version": "1.0.0", "evidence": {"limitation": null, "required_types": ["file_ref", "state_readback"], "accepted_methods": ["readback"], "readback_supported": true, "verify_delay_seconds": 5, "deferred_check_after_hours": null}, "operation": "write", "adapter_id": "storage_sharepoint", "rate_limit": null, "idempotency": {"strategy": "db_unique_constraint", "key_fields": ["context_id", "source_ref", "action_type", "target_system", "target_object_ref"], "extra_dedup": "content_hash", "native_support": false}, "display_name": "Datei ablegen", "retry_policy": {"backoff": "exponential_1m_factor5_jitter", "max_attempts": 3, "retryable_error_classes": ["transient_network", "rate_limited", "timeout"]}, "side_effects": "Die Datei liegt danach an einem anderen Ort und traegt einen anderen Namen.", "undo_tool_id": "storage_sharepoint.move_file", "reversibility": "reversible", "external_effect": "internal", "timeout_seconds": 60, "allowed_contexts": ["arbeitgeber_visolva"], "input_schema_ref": "schemas/tools/storage_sharepoint.move_file.input.json", "dry_run_supported": true, "output_schema_ref": "schemas/tools/storage_sharepoint.move_file.output.json", "risk_class_default": "A", "required_permissions": ["Datei lesen", "Datei verschieben", "Datei umbenennen"]}'::jsonb, 'f9aaef49556c3a4027f09c1f050e810e72b4c5bff7305e54d2df608a459ce166', 'spec/phase-1/nachtrag-1.1/registry/tool_registry_phase1_1.json', 'e770a8936af941bd55f138559abc1be41ef7c206b4d27e44ad940b9199b60c89') ON CONFLICT (tool_id, version) DO NOTHING;

-- Pruefung: Die Datenbank rechnet den Pruefwert aus der gespeicherten Definition nach.
DO $$
DECLARE
    v_bad text;
BEGIN
    SELECT string_agg(e.tool_id || '@' || e.version, ', ') INTO v_bad
    FROM (VALUES
        ('storage_gdrive.get_file', '1.1.0', 'ad4d0dee1b148dab81fef8a879c56d9b765402905b199389dd37fae2146c1885'),
        ('storage_sharepoint.get_file', '1.0.0', 'a863602ff30a63b3ad7ecac9e406ffe05154ebeca4815c7df8704ae859c1914c'),
        ('storage_sharepoint.move_file', '1.0.0', 'f9aaef49556c3a4027f09c1f050e810e72b4c5bff7305e54d2df608a459ce166')
    ) AS e (tool_id, version, sha)
    LEFT JOIN jarvis_ops.tool_registry t ON t.tool_id = e.tool_id AND t.version = e.version
    WHERE t.definition_sha256 IS DISTINCT FROM e.sha
       OR encode(sha256(convert_to(t.definition::text, 'UTF8')), 'hex') IS DISTINCT FROM e.sha
       OR t.tool_id            IS DISTINCT FROM t.definition->>'tool_id'
       OR t.version            IS DISTINCT FROM t.definition->>'version'
       OR t.adapter_id         IS DISTINCT FROM t.definition->>'adapter_id'
       OR t.operation          IS DISTINCT FROM t.definition->>'operation'
       OR t.external_effect    IS DISTINCT FROM t.definition->>'external_effect'
       OR t.risk_class_default::text IS DISTINCT FROM t.definition->>'risk_class_default'
       OR t.reversibility      IS DISTINCT FROM t.definition->>'reversibility'
       OR t.undo_tool_id       IS DISTINCT FROM t.definition->>'undo_tool_id'
       OR t.timeout_seconds    IS DISTINCT FROM (t.definition->>'timeout_seconds')::int
       OR t.dry_run_supported  IS DISTINCT FROM (t.definition->>'dry_run_supported')::boolean
       OR t.readback_supported IS DISTINCT FROM (t.definition->'evidence'->>'readback_supported')::boolean
       OR t.evidence_limitation IS DISTINCT FROM t.definition->'evidence'->>'limitation'
       OR t.allowed_contexts   IS DISTINCT FROM ARRAY(SELECT jsonb_array_elements_text(t.definition->'allowed_contexts'))
       OR t.accepted_methods   IS DISTINCT FROM ARRAY(SELECT jsonb_array_elements_text(t.definition->'evidence'->'accepted_methods'));
    IF v_bad IS NOT NULL THEN
        RAISE EXCEPTION 'registry_definition_mismatch: %', v_bad USING ERRCODE = '23514';
    END IF;
END
$$;
