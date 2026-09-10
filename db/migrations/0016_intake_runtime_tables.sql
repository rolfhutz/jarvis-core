-- =====================================================================
-- JARVIS Phase 1.1 - Migration 0016 - Eingang: Laufzeitkonfiguration und
-- Ausnahmeliste ohne Kontext
--
-- Entscheidungen vom 10.09.2026 (Rolf):
--   1.1-E3  Eingaenge ohne aufloesbaren Kontext (K-07) landen in einer
--           eigenen, inhaltsfreien, append-only Tabelle in jarvis_ops.
--   1.1-E4  Kontextliste, Quellbindungen und Dokumenteinstellungen kommen
--           zur Laufzeit aus jarvis_ops, erzeugt aus config/intake_config.json
--           (Migration 0017, tools/render_intake_config.py). Ordner-IDs
--           stehen nur als env-Verweis hier; die Werte liegen in n8n-Variablen.
--   15.3    Fuenf Zurueckstellungen je Eingangsordner und Stunde halten die
--           Bindung an (halted_at). Aufheben nur durch den Administrator.
--
-- AR-2: Keine Spalte nimmt Dateinamen oder Dokumentinhalt auf. Externe
-- Datei-IDs sind Kennungen, keine Inhalte; ihr Muster schliesst Leerzeichen
-- aus.
--
-- Nicht wiederholbar ausfuehrbar (legt Objekte an), wie 0002 bis 0008.
-- Haengt ab von: 0002 (context_registry, deny_ops_mutation), 0001 (Rollen).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Hilfsfunktion: Ist der aktuelle Benutzer ein Kontextbenutzer?
--    Liefert die context_id, deren Rolle der aktuelle Benutzer nutzt
--    (Login-Benutzer erben sie, 0011). Administrator: NULL. Der
--    Administrator ist auf Supabase Mitglied mit INHERIT FALSE (0010) und
--    wird deshalb nicht als Kontextbenutzer erkannt; ein Superuser auch nicht.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION jarvis_ops.current_context_id()
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT r.context_id
    FROM jarvis_ops.context_registry r
    WHERE pg_has_role(current_user, r.db_user, 'USAGE')
      AND NOT coalesce((SELECT rolsuper FROM pg_roles WHERE rolname = current_user), false)
    ORDER BY r.context_id
    LIMIT 1
$$;

COMMENT ON FUNCTION jarvis_ops.current_context_id() IS
    'Kontext des aktuellen Datenbankbenutzers oder NULL fuer den Administrator. Grundlage der Zeilenregeln in jarvis_ops.';

-- ---------------------------------------------------------------------
-- 1. Dokumenteinstellungen je Kontext (Spezifikation 6.3, 10.4, 1.1-E6)
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.context_document_settings (
    context_id                      text PRIMARY KEY
                                    REFERENCES jarvis_ops.context_registry (context_id),
    config_version                  text NOT NULL CHECK (config_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
    storage_adapter_id              text NOT NULL CHECK (storage_adapter_id ~ '^[a-z][a-z0-9_]{2,63}$'),
    storage_container_ref           text CHECK (storage_container_ref IS NULL
                                                OR storage_container_ref ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    inbox_ref                       text NOT NULL CHECK (inbox_ref        ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    working_ref                     text NOT NULL CHECK (working_ref      ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    archive_root_ref                text NOT NULL CHECK (archive_root_ref ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    drafts_ref                      text NOT NULL CHECK (drafts_ref       ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    reports_ref                     text NOT NULL CHECK (reports_ref      ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    allowed_mime_types              text[] NOT NULL CHECK (
                                        cardinality(allowed_mime_types) >= 1
                                        AND allowed_mime_types <@ ARRAY['application/pdf','image/jpeg','image/png','image/tiff']::text[]),
    max_file_size_mb                integer NOT NULL CHECK (max_file_size_mb BETWEEN 1 AND 200),
    -- Leer heisst: keine Uebermittlung an einen OCR-Dienst (fail closed).
    ocr_provider_allowlist          text[] NOT NULL,
    ocr_min_characters              integer NOT NULL CHECK (ocr_min_characters >= 1),
    ocr_min_mean_confidence         numeric(4,3) NOT NULL CHECK (ocr_min_mean_confidence BETWEEN 0 AND 1),
    fingerprint_max_hamming         integer NOT NULL CHECK (fingerprint_max_hamming BETWEEN 0 AND 64),
    synthetic_marker_required       boolean NOT NULL,
    synthetic_marker_prefix         text CHECK (synthetic_marker_prefix IS NULL
                                                OR synthetic_marker_prefix ~ '^[A-Z][A-Z0-9_]{1,15}$'),
    quarantine_halt_threshold       integer NOT NULL CHECK (quarantine_halt_threshold >= 1),
    quarantine_halt_window_minutes  integer NOT NULL CHECK (quarantine_halt_window_minutes >= 1),
    source_file                     text NOT NULL,
    source_sha256                   text NOT NULL CHECK (source_sha256 ~ '^[a-f0-9]{64}$'),
    loaded_at                       timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT cds_marker_requires_prefix CHECK (
        NOT synthetic_marker_required OR synthetic_marker_prefix IS NOT NULL),
    -- Ein Ordner darf nicht zwei Rollen haben (Eingang = Archiv waere ein Konfigurationsfehler).
    CONSTRAINT cds_refs_distinct CHECK (
        inbox_ref <> working_ref AND inbox_ref <> archive_root_ref AND inbox_ref <> drafts_ref
        AND inbox_ref <> reports_ref AND working_ref <> archive_root_ref AND working_ref <> drafts_ref
        AND working_ref <> reports_ref AND archive_root_ref <> drafts_ref
        AND archive_root_ref <> reports_ref AND drafts_ref <> reports_ref)
);

COMMENT ON TABLE jarvis_ops.context_document_settings IS
    'Dokumenteinstellungen je Kontext. Nur env-Verweise, keine Ordner-IDs. Befuellung ausschliesslich ueber Migration 0017 (tools/render_intake_config.py).';

-- ---------------------------------------------------------------------
-- 2. Quellbindungen (Kontextaufloesung source_binding, TS-10)
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.source_binding (
    binding_key      text PRIMARY KEY CHECK (binding_key ~ '^[a-z][a-z0-9_]{2,63}$'),
    context_id       text NOT NULL REFERENCES jarvis_ops.context_registry (context_id),
    adapter_id       text NOT NULL CHECK (adapter_id ~ '^[a-z][a-z0-9_]{2,63}$'),
    channel          text NOT NULL CHECK (channel IN ('drive_inbox','scan','mobile_photo','manual_upload','api')),
    location_ref     text NOT NULL CHECK (location_ref ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    -- probe nur fuer den Nachweis K-07 (mehrdeutige Bindung).
    purpose          text NOT NULL CHECK (purpose IN ('intake','probe')),
    enabled          boolean NOT NULL,
    config_version   text NOT NULL CHECK (config_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
    -- Laufzeitzustand, nie aus der Konfiguration ueberschrieben.
    halted_at        timestamptz,
    halt_reason      text CHECK (halt_reason IS NULL OR halt_reason IN ('quarantine_burst')),
    halted_by        text,
    source_file      text NOT NULL,
    source_sha256    text NOT NULL CHECK (source_sha256 ~ '^[a-f0-9]{64}$'),
    loaded_at        timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT sb_halt_complete CHECK (
        (halted_at IS NULL AND halt_reason IS NULL AND halted_by IS NULL)
        OR (halted_at IS NOT NULL AND halt_reason IS NOT NULL AND halted_by IS NOT NULL))
);

-- Zwei Eingangsbindungen duerfen nie denselben Ort teilen. Laufzeitpruefung
-- auf den aufgeloesten Wert bleibt zusaetzlich Pflicht (context_resolve).
CREATE UNIQUE INDEX source_binding_intake_location_uq
    ON jarvis_ops.source_binding (adapter_id, location_ref)
    WHERE purpose = 'intake';

COMMENT ON TABLE jarvis_ops.source_binding IS
    'Quellbindungen je Kontext. Konfigurationsfelder nur ueber Migration 0017; halted_at setzt JARVIS im eigenen Kontext, aufheben nur der Administrator.';

CREATE OR REPLACE FUNCTION jarvis_ops.guard_source_binding_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ctx text := jarvis_ops.current_context_id();
BEGIN
    IF v_ctx IS NULL THEN
        -- Administrator (Konfigurationslauf oder manuelles Aufheben).
        RETURN NEW;
    END IF;
    IF OLD.context_id IS DISTINCT FROM v_ctx THEN
        RAISE EXCEPTION
            'binding_foreign_context: Bindung % gehoert nicht zum Kontext %.',
            OLD.binding_key, v_ctx
            USING ERRCODE = '42501';
    END IF;
    IF OLD.halted_at IS NOT NULL THEN
        RAISE EXCEPTION
            'binding_halt_final: Bindung % ist angehalten; Aufheben nur durch den Administrator.',
            OLD.binding_key
            USING ERRCODE = '42501';
    END IF;
    IF NEW.halted_at IS NULL THEN
        RAISE EXCEPTION
            'binding_update_denied: Kontextbenutzer duerfen eine Bindung nur anhalten.'
            USING ERRCODE = '42501';
    END IF;
    NEW.halted_by := current_user;
    RETURN NEW;
END;
$$;

CREATE TRIGGER source_binding_guard_update
    BEFORE UPDATE ON jarvis_ops.source_binding
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.guard_source_binding_update();

-- Lesen duerfen beide Kontextbenutzer alle Bindungen: Mehrdeutigkeit ist nur
-- ueber alle Kontexte erkennbar, die Tabelle enthaelt keine Fachdaten.
-- Anhalten nur im eigenen Kontext; der Trigger weist fremde Bindungen laut
-- ab (keine Zeilenregel, die still null Zeilen liefern wuerde).

-- ---------------------------------------------------------------------
-- 3. Ausnahmeliste fuer Eingaenge ohne aufloesbaren Kontext (K-07, AR-1)
--    append-only, ohne Inhaltsspalten, eindeutig je Datei und Grund.
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.intake_exception (
    intake_exception_id  bigserial PRIMARY KEY,
    detected_at          timestamptz NOT NULL DEFAULT now(),
    trace_id             text NOT NULL,
    adapter_id           text NOT NULL CHECK (adapter_id ~ '^[a-z][a-z0-9_]{2,63}$'),
    location_ref         text NOT NULL CHECK (location_ref ~ '^env:JV_[A-Z0-9_]{3,60}$'),
    source_external_id   text NOT NULL CHECK (source_external_id ~ '^[A-Za-z0-9!_.-]{1,200}$'),
    reason_code          text NOT NULL CHECK (reason_code IN (
                             'binding_ambiguous','context_not_active','binding_unknown')),
    candidate_contexts   text[],
    CONSTRAINT ie_ambiguous_needs_candidates CHECK (
        reason_code <> 'binding_ambiguous' OR cardinality(candidate_contexts) >= 2)
);

CREATE UNIQUE INDEX intake_exception_once_uq
    ON jarvis_ops.intake_exception (adapter_id, location_ref, source_external_id, reason_code);

COMMENT ON TABLE jarvis_ops.intake_exception IS
    'Ausnahmeliste fuer Eingaenge ohne aufloesbaren Kontext (K-07). Keine Aufgabe, keine Aktion, kein Inhalt. Eintrag genau einmal je Datei, Ort und Grund.';

CREATE TRIGGER intake_exception_deny_update
    BEFORE UPDATE ON jarvis_ops.intake_exception
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

CREATE TRIGGER intake_exception_deny_delete
    BEFORE DELETE ON jarvis_ops.intake_exception
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

-- ---------------------------------------------------------------------
-- 4. Rechte
-- ---------------------------------------------------------------------
REVOKE ALL ON jarvis_ops.context_document_settings FROM PUBLIC;
REVOKE ALL ON jarvis_ops.source_binding            FROM PUBLIC;
REVOKE ALL ON jarvis_ops.intake_exception          FROM PUBLIC;
REVOKE ALL ON FUNCTION jarvis_ops.current_context_id() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION jarvis_ops.current_context_id() TO jv_privat_user, jv_visolva_user;

GRANT SELECT ON jarvis_ops.context_document_settings TO jv_privat_user, jv_visolva_user;

GRANT SELECT ON jarvis_ops.source_binding TO jv_privat_user, jv_visolva_user;
GRANT UPDATE (halted_at, halt_reason, halted_by) ON jarvis_ops.source_binding TO jv_privat_user, jv_visolva_user;

GRANT SELECT, INSERT ON jarvis_ops.intake_exception TO jv_privat_user, jv_visolva_user;
GRANT USAGE, SELECT ON SEQUENCE jarvis_ops.intake_exception_intake_exception_id_seq TO jv_privat_user, jv_visolva_user;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON jarvis_ops.context_document_settings FROM jv_privat_user, jv_visolva_user;
REVOKE INSERT, DELETE, TRUNCATE          ON jarvis_ops.source_binding            FROM jv_privat_user, jv_visolva_user;
REVOKE UPDATE, DELETE, TRUNCATE          ON jarvis_ops.intake_exception          FROM jv_privat_user, jv_visolva_user;
