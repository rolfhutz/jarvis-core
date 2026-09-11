-- =====================================================================
-- JARVIS Phase 1.1b - Migration 0020 - Kontextwurzel je Kontext
--
-- Entscheidung 1.1b-E1 vom 11.09.2026 (Rolf): Die Wurzelpruefung der
-- Speicheradapter (P1-T-22, 1.1-A11) braucht die Kontextwurzel. Bisher war
-- nur archive_root_ref konfiguriert; der Eingang liegt nicht darunter.
-- Neues Feld context_root_ref (env-Verweis), alle Ordnerrollen liegen
-- darunter. Die Lage unter der Wurzel prueft die Einrichtungspruefung der
-- Adapter zur Laufzeit (Werte nur in n8n-Variablen, ADR-001).
--
-- Ablauf in drei Schritten, damit die Werte ausschliesslich ueber den
-- Generator in die Datenbank gelangen (1.1-E4):
--   0020  Spalte anlegen (noch ohne Pflicht), Eindeutigkeit der Rollen
--         um die Wurzel erweitern
--   0021  ERZEUGT aus config/intake_config.json 1.1.0 - setzt die Werte
--   0022  Spalte zur Pflicht machen, Selbstpruefung
--
-- Nicht wiederholbar ausfuehrbar (legt eine Spalte an), wie 0016.
-- Haengt ab von: 0016, 0017.
-- =====================================================================

ALTER TABLE jarvis_ops.context_document_settings
    ADD COLUMN context_root_ref text
        CONSTRAINT cds_context_root_ref_format
        CHECK (context_root_ref IS NULL OR context_root_ref ~ '^env:JV_[A-Z0-9_]{3,60}$');

COMMENT ON COLUMN jarvis_ops.context_document_settings.context_root_ref IS
    'Kontextwurzel als env-Verweis (1.1b-E1). Speicheradapter lesen nur innerhalb dieser Wurzel. Befuellung nur ueber den Generator (0021 ff.).';

-- Die Wurzel darf keine andere Rolle haben (Wurzel = Eingang waere ein
-- Konfigurationsfehler, der die Wurzelpruefung aushebelt). NULL ist bis
-- 0022 zulaessig; ein Vergleich mit NULL verletzt den CHECK nicht.
ALTER TABLE jarvis_ops.context_document_settings
    DROP CONSTRAINT cds_refs_distinct;

ALTER TABLE jarvis_ops.context_document_settings
    ADD CONSTRAINT cds_refs_distinct CHECK (
        inbox_ref <> working_ref AND inbox_ref <> archive_root_ref AND inbox_ref <> drafts_ref
        AND inbox_ref <> reports_ref AND working_ref <> archive_root_ref AND working_ref <> drafts_ref
        AND working_ref <> reports_ref AND archive_root_ref <> drafts_ref
        AND archive_root_ref <> reports_ref AND drafts_ref <> reports_ref
        AND context_root_ref <> inbox_ref AND context_root_ref <> working_ref
        AND context_root_ref <> archive_root_ref AND context_root_ref <> drafts_ref
        AND context_root_ref <> reports_ref
        AND context_root_ref <> storage_container_ref);

-- Rechte: Kontextbenutzer lesen die Tabelle bereits (0016, GRANT SELECT auf
-- die Tabelle umfasst neue Spalten). Kein Schreibrecht, unveraendert.
