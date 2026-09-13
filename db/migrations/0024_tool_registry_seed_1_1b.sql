-- =====================================================================
-- JARVIS Phase 1.1b - Migration 0024 - Werkzeugregister Nachtrag 1.1b (1.1b-E3)
--
-- ERZEUGT durch tools/render_tool_registry.py. Nicht von Hand bearbeiten.
-- Quelle:
--   spec/phase-1/nachtrag-1.1b/registry/tool_registry_phase1_1b.json
--
-- Wiederholbar: Vorhandene Eintraege werden nie ueberschrieben. Der
-- Freigabestatus in der Datenbank bleibt erhalten. Weicht die Definition
-- einer bereits geladenen Version ab, bricht der Lauf ab: Eine geaenderte
-- Definition erfordert eine neue Version.
-- Werkzeuge: 1
-- =====================================================================

INSERT INTO jarvis_ops.tool_registry (tool_id, version, adapter_id, operation, external_effect, risk_class_default, reversibility, undo_tool_id, allowed_contexts, readback_supported, accepted_methods, evidence_limitation, timeout_seconds, dry_run_supported, status, definition, definition_sha256, source_file, source_sha256) VALUES ('storage_gdrive.get_file', '1.2.0', 'storage_gdrive', 'read', 'none', 'A', 'reversible', NULL, ARRAY['privat', 'arbeitgeber_visolva']::text[], false, ARRAY['provider_status']::text[], 'Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.', 120, true, 'draft', '{"owner": "rolf", "purpose": "Originaldatei und ihre Metadaten aus dem kontextbezogenen Speicher lesen. Gegenueber 1.1.0 zusaetzlich fuer arbeitgeber_visolva zugelassen (1.1b-E3).", "tool_id": "storage_gdrive.get_file", "version": "1.2.0", "evidence": {"limitation": "Leseoperation ohne Zustandsaenderung. Der Nachweis belegt die erfolgreiche Antwort des Speicherdienstes einschliesslich Pruefsumme, nicht eine Veraenderung in der Welt.", "required_types": ["provider_status"], "accepted_methods": ["provider_status"], "readback_supported": false, "verify_delay_seconds": 0, "deferred_check_after_hours": null}, "operation": "read", "adapter_id": "storage_gdrive", "rate_limit": null, "idempotency": {"strategy": "db_unique_constraint", "key_fields": ["context_id", "source_ref", "action_type", "target_system", "target_object_ref"], "extra_dedup": null, "native_support": false}, "display_name": "Datei lesen", "retry_policy": {"backoff": "exponential_1m_factor5_jitter", "max_attempts": 3, "retryable_error_classes": ["transient_network", "rate_limited", "timeout"]}, "side_effects": "Keine. Reine Leseoperation.", "undo_tool_id": null, "reversibility": "reversible", "external_effect": "none", "timeout_seconds": 120, "allowed_contexts": ["privat", "arbeitgeber_visolva"], "input_schema_ref": "schemas/tools/storage_gdrive.get_file.input.json", "dry_run_supported": true, "output_schema_ref": "schemas/tools/storage_gdrive.get_file.output.json", "risk_class_default": "A", "required_permissions": ["Datei lesen", "Metadaten lesen"]}'::jsonb, '5b49813a1751aeb98d756d8ac33dc2823aa2e8c0530d17e19433173607d01051', 'spec/phase-1/nachtrag-1.1b/registry/tool_registry_phase1_1b.json', '95e8a196c4473038a2e5b34010a0c601cdcd88c62fae955350f812237d29634a') ON CONFLICT (tool_id, version) DO NOTHING;

-- Pruefung: Die Datenbank rechnet den Pruefwert aus der gespeicherten Definition nach.
DO $$
DECLARE
    v_bad text;
BEGIN
    SELECT string_agg(e.tool_id || '@' || e.version, ', ') INTO v_bad
    FROM (VALUES
        ('storage_gdrive.get_file', '1.2.0', '5b49813a1751aeb98d756d8ac33dc2823aa2e8c0530d17e19433173607d01051')
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
