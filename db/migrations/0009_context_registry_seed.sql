-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0009
-- Befuellung des Kontextregisters
--
-- Grundlage: SPEC_PHASE_1 Abschnitt 7.1 Punkt 5.
--
-- Das Register ist ein Verzeichnis ohne Fachdaten. Es enthaelt
-- ausschliesslich die Zuordnung von Kontext zu Schema und Datenbankrolle.
-- Ordner-IDs, Konten, Endpunkte und Zugangsdaten stehen bewusst nicht
-- darin; sie werden ueber env-Verweise der Kontextkonfiguration aufgeloest.
--
-- Die Werte stammen aus
-- spec/phase-0/jarvis-phase-0/templates/context_config.example.json
-- und stimmen mit den gerenderten Migrationen 0003 bis 0008 ueberein.
--
-- Wiederholbar: ein erneuter Lauf aktualisiert die Zeilen, statt zu scheitern.
-- =====================================================================

INSERT INTO jarvis_ops.context_registry
    (context_id, display_name, context_kind, db_schema, db_user, status, config_version, updated_at)
VALUES
    ('privat',              'Privat',      'private',  'jarvis_privat',  'jv_privat_user',  'active', '1.0.0', now()),
    ('arbeitgeber_visolva', 'Arbeitgeber', 'employer', 'jarvis_visolva', 'jv_visolva_user', 'active', '1.0.0', now())
ON CONFLICT (context_id) DO UPDATE
    SET display_name   = EXCLUDED.display_name,
        context_kind   = EXCLUDED.context_kind,
        db_schema      = EXCLUDED.db_schema,
        db_user        = EXCLUDED.db_user,
        status         = EXCLUDED.status,
        config_version = EXCLUDED.config_version,
        updated_at     = now();

-- ---------------------------------------------------------------------
-- Registrierte Vertragsversionen
--
-- Haelt fest, welcher Vertragsstand in dieser Instanz aktiv ist. Der
-- git_ref verweist auf das Repository, nicht auf einen Inhalt.
-- ---------------------------------------------------------------------
INSERT INTO jarvis_ops.contract_version
    (contract_id, contract_kind, version, git_ref, activated_at)
VALUES
    ('spec_phase_0', 'schema', '1.1.0', 'rolfhutz/jarvis-core', now()),
    ('spec_phase_1', 'schema', '4.0.2', 'rolfhutz/jarvis-core', now())
ON CONFLICT (contract_id, version) DO NOTHING;
