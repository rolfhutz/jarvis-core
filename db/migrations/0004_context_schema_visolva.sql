-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0004 - Kontextschema jarvis_visolva
--
-- Erzeugt aus: spec/phase-0/jarvis-phase-0/db/001_context_schema_template.sql via tools/render_context_schema.py --context arbeitgeber_visolva
-- Nicht von Hand bearbeiten. Aenderungen erfolgen an der Vorlage und
-- werden neu gerendert.
-- =====================================================================

-- =====================================================================
-- JARVIS Phase 0 - Kontextschema-Vorlage
-- Version 1.1.0
--
-- Diese Datei ist eine VORLAGE mit Platzhaltern und wird nicht direkt
-- ausgefuehrt. Das Einspielen erfolgt ausschliesslich ueber
--     python3 tools/render_context_schema.py --context <context_id>
-- Das Skript validiert Schemanamen und Kontextkennung gegen die
-- Kontextkonfiguration und lehnt jeden nicht registrierten Wert ab.
-- Freie Textersetzung ist unzulaessig.
--
-- Platzhalter:
--   jarvis_visolva      Zielschema, z. B. jarvis_privat
--   arbeitgeber_visolva  Kontextkennung, z. B. privat
--   jv_visolva_user     Datenbankbenutzer des Kontexts, z. B. jv_privat_user
--
-- Grundsatz: Fachliche Inhalte liegen ausschliesslich in Kontextschemata.
-- Jeder Kontext hat einen eigenen Datenbankbenutzer mit Rechten nur auf
-- sein eigenes Schema. Eine Verwechslung des Fachprotokolls ist dadurch
-- technisch ausgeschlossen und nicht nur per Konvention verboten.
--
-- Status: Vorlage. Noch nicht ausgefuehrt.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS jarvis_visolva;

-- ---------------------------------------------------------------------
-- Ereignisse
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.event (
    event_id           text PRIMARY KEY,
    schema_version     text NOT NULL,
    event_type         text NOT NULL,
    event_time         timestamptz NOT NULL,
    received_at        timestamptz NOT NULL,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    severity           text NOT NULL DEFAULT 'info',
    idempotency_key    char(64) NOT NULL,
    subject_type       text NOT NULL,
    subject_id         text,
    subject_external   text,
    body               jsonb NOT NULL,
    trace_id           text NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT event_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);
CREATE UNIQUE INDEX event_idempotency_uq ON jarvis_visolva.event (idempotency_key);
CREATE INDEX event_type_time_idx ON jarvis_visolva.event (event_type, event_time DESC);

-- ---------------------------------------------------------------------
-- Aufgaben
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.task (
    task_id            text PRIMARY KEY,
    schema_version     text NOT NULL,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    title              text NOT NULL,
    success_criterion  text NOT NULL,
    actor              text NOT NULL CHECK (actor IN ('jarvis','rolf','mitarbeiter','externer')),
    status             text NOT NULL,
    priority           text NOT NULL,
    due_at             timestamptz,
    idempotency_key    char(64) NOT NULL,
    body               jsonb NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT task_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);
CREATE UNIQUE INDEX task_idempotency_uq ON jarvis_visolva.task (idempotency_key);
CREATE INDEX task_open_due_idx ON jarvis_visolva.task (status, due_at);

-- ---------------------------------------------------------------------
-- Aktionen - zentrale Idempotenzsicherung
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.action (
    action_id           text PRIMARY KEY,
    schema_version      text NOT NULL,
    context_id          text NOT NULL DEFAULT 'arbeitgeber_visolva',
    action_type         text NOT NULL,
    tool_id             text NOT NULL,
    tool_version        text NOT NULL,
    -- Technische Aktionen werden ausschliesslich vom Executor ausgefuehrt.
    actor               text NOT NULL DEFAULT 'jarvis' CHECK (actor = 'jarvis'),
    risk_class          char(1) NOT NULL CHECK (risk_class IN ('A','B','C')),
    risk_class_source   text NOT NULL,
    status              text NOT NULL,
    approval_id         text,
    approval_status     text NOT NULL DEFAULT 'not_required',
    priority            text NOT NULL,
    due_at              timestamptz,
    idempotency_key     char(64) NOT NULL,
    content_fingerprint text,
    attempt_count       integer NOT NULL DEFAULT 0,
    max_attempts        integer NOT NULL DEFAULT 3,
    next_attempt_at     timestamptz,
    body                jsonb NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    executed_at         timestamptz,
    verified_at         timestamptz,
    CONSTRAINT action_context_chk CHECK (context_id = 'arbeitgeber_visolva'),
    CONSTRAINT action_class_c_requires_approval CHECK (
        risk_class <> 'C'
        OR status NOT IN ('running','succeeded')
        OR (approval_id IS NOT NULL AND approval_status = 'approved')
    ),
    CONSTRAINT action_success_requires_verification CHECK (
        status <> 'succeeded' OR (executed_at IS NOT NULL AND verified_at IS NOT NULL)
    )
);
CREATE UNIQUE INDEX action_idempotency_uq ON jarvis_visolva.action (idempotency_key);
CREATE INDEX action_status_idx ON jarvis_visolva.action (status, next_attempt_at);

-- ---------------------------------------------------------------------
-- Ausfuehrungssperre gegen parallele Doppelausfuehrung
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.action_lock (
    idempotency_key    char(64) PRIMARY KEY,
    action_id          text NOT NULL REFERENCES jarvis_visolva.action(action_id),
    claimed_at         timestamptz NOT NULL DEFAULT now(),
    claimed_by         text NOT NULL,
    expires_at         timestamptz NOT NULL,
    released_at        timestamptz
);
-- Anspruch wird erhoben mit:
--   INSERT INTO action_lock (...) VALUES (...) ON CONFLICT DO NOTHING RETURNING idempotency_key;
-- Kommt keine Zeile zurueck, laeuft die Aktion bereits und wird nicht erneut ausgefuehrt.

-- ---------------------------------------------------------------------
-- Freigaben
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.approval (
    approval_id        text PRIMARY KEY,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    action_id          text NOT NULL REFERENCES jarvis_visolva.action(action_id),
    action_fingerprint text NOT NULL,
    token_hash         text NOT NULL,
    status             text NOT NULL,
    requested_at       timestamptz NOT NULL,
    expires_at         timestamptz NOT NULL,
    decided_at         timestamptz,
    consumed_at        timestamptz,
    body               jsonb NOT NULL,
    CONSTRAINT approval_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);
CREATE UNIQUE INDEX approval_open_uq
    ON jarvis_visolva.approval (action_id, action_fingerprint)
    WHERE status = 'pending';
CREATE UNIQUE INDEX approval_token_uq ON jarvis_visolva.approval (token_hash);

-- ---------------------------------------------------------------------
-- Ergebnisnachweise
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.evidence (
    evidence_id         text PRIMARY KEY,
    context_id          text NOT NULL DEFAULT 'arbeitgeber_visolva',
    action_id           text NOT NULL REFERENCES jarvis_visolva.action(action_id),
    evidence_type       text NOT NULL,
    verification_method text NOT NULL,
    verification_result text NOT NULL,
    contract_tool_id    text NOT NULL,
    contract_version    text NOT NULL,
    readback_supported  boolean NOT NULL,
    observed_at         timestamptz NOT NULL,
    body                jsonb NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT evidence_context_chk CHECK (context_id = 'arbeitgeber_visolva'),
    -- Ist ein unabhaengiger Readback moeglich, ist er verpflichtend (Entscheidung D3).
    CONSTRAINT evidence_readback_required CHECK (
        readback_supported = false OR verification_method = 'readback'
    )
);
CREATE INDEX evidence_action_idx ON jarvis_visolva.evidence (action_id);

-- ---------------------------------------------------------------------
-- Fehler und Eskalationen
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.error_event (
    error_id           text PRIMARY KEY,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    action_id          text,
    event_id           text,
    error_class        text NOT NULL,
    escalation_level   text NOT NULL,
    attempt            integer NOT NULL,
    occurred_at        timestamptz NOT NULL,
    resolution_status  text NOT NULL,
    body               jsonb NOT NULL,
    CONSTRAINT error_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);

-- ---------------------------------------------------------------------
-- Fachliches Aktionsprotokoll - append-only
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.action_log (
    log_id             bigserial PRIMARY KEY,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    logged_at          timestamptz NOT NULL DEFAULT now(),
    entry_kind         text NOT NULL,
    action_id          text,
    task_id            text,
    event_id           text,
    actor              text NOT NULL,
    summary_de         text NOT NULL,
    body               jsonb NOT NULL,
    corrects_log_id    bigint REFERENCES jarvis_visolva.action_log(log_id),
    CONSTRAINT log_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);

-- Append-only wird auf zwei Wegen durchgesetzt.
--
-- Weg 1: Rechteentzug. Der Kontextbenutzer erhaelt kein UPDATE und kein DELETE.
--        Siehe Abschnitt Rechtevergabe am Ende dieser Datei.
--
-- Weg 2: Trigger, der jeden verbliebenen Versuch mit einem FEHLER abweist.
--        Bewusst KEIN "CREATE RULE ... DO INSTEAD NOTHING": eine Regel wuerde
--        den Aenderungsversuch stillschweigend verwerfen und dem Aufrufer
--        Erfolg melden. Ein stiller Verlust ist schlimmer als ein Fehler.
CREATE OR REPLACE FUNCTION jarvis_visolva.deny_log_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'append_only_violation: % auf %.action_log ist unzulaessig. Korrekturen erfolgen als neuer Eintrag mit corrects_log_id.',
        TG_OP, TG_TABLE_SCHEMA
        USING ERRCODE = '42501';
END;
$$;

CREATE TRIGGER action_log_deny_update
    BEFORE UPDATE ON jarvis_visolva.action_log
    FOR EACH ROW EXECUTE FUNCTION jarvis_visolva.deny_log_mutation();

CREATE TRIGGER action_log_deny_delete
    BEFORE DELETE ON jarvis_visolva.action_log
    FOR EACH ROW EXECUTE FUNCTION jarvis_visolva.deny_log_mutation();

CREATE TRIGGER action_log_deny_truncate
    BEFORE TRUNCATE ON jarvis_visolva.action_log
    FOR EACH STATEMENT EXECUTE FUNCTION jarvis_visolva.deny_log_mutation();

-- ---------------------------------------------------------------------
-- Dokumentregister und Dublettenerkennung
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.document_index (
    document_id         text PRIMARY KEY,
    context_id          text NOT NULL DEFAULT 'arbeitgeber_visolva',
    content_hash        text NOT NULL,
    storage_external_id text,
    first_seen_at       timestamptz NOT NULL DEFAULT now(),
    body                jsonb NOT NULL,
    CONSTRAINT document_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);
CREATE UNIQUE INDEX document_content_hash_uq ON jarvis_visolva.document_index (content_hash);

-- ---------------------------------------------------------------------
-- Gedaechtnis - Schema in Phase 0, produktive Nutzung ab Phase 4
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_visolva.memory_entry (
    memory_id          text PRIMARY KEY,
    context_id         text NOT NULL DEFAULT 'arbeitgeber_visolva',
    memory_store       text NOT NULL CHECK (memory_store IN ('session','profile','working','source_knowledge')),
    entry_type         text NOT NULL,
    epistemic_status   text NOT NULL CHECK (epistemic_status IN ('fact','assumption','interpretation','user_statement')),
    status             text NOT NULL,
    valid_from         timestamptz,
    valid_to           timestamptz,
    superseded_by      text REFERENCES jarvis_visolva.memory_entry(memory_id),
    expires_at         timestamptz,
    body               jsonb NOT NULL,
    created_at         timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT memory_context_chk CHECK (context_id = 'arbeitgeber_visolva')
);
CREATE INDEX memory_store_status_idx ON jarvis_visolva.memory_entry (memory_store, status);
-- pgvector wird erst bei Bedarf ergaenzt und ist in Phase 0 nicht Bestandteil.

-- =====================================================================
-- Rechtevergabe fuer den Kontextbenutzer
-- =====================================================================

-- Zugriff auf das eigene Schema
GRANT USAGE ON SCHEMA jarvis_visolva TO jv_visolva_user;

-- Arbeitstabellen: lesen, schreiben, aendern
GRANT SELECT, INSERT, UPDATE ON
    jarvis_visolva.event,
    jarvis_visolva.task,
    jarvis_visolva.action,
    jarvis_visolva.action_lock,
    jarvis_visolva.approval,
    jarvis_visolva.evidence,
    jarvis_visolva.error_event,
    jarvis_visolva.document_index,
    jarvis_visolva.memory_entry
TO jv_visolva_user;

-- Abgelaufene Sperren duerfen nach Statusabgleich entfernt werden
GRANT DELETE ON jarvis_visolva.action_lock TO jv_visolva_user;

-- Fachprotokoll: ausschliesslich lesen und einfuegen
GRANT SELECT, INSERT ON jarvis_visolva.action_log TO jv_visolva_user;
REVOKE UPDATE, DELETE, TRUNCATE ON jarvis_visolva.action_log FROM jv_visolva_user;

-- Sequenzen: fuer bigserial in action_log wird USAGE auf der Sequenz benoetigt,
-- sonst schlaegt jedes INSERT mit "permission denied for sequence" fehl.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA jarvis_visolva TO jv_visolva_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA jarvis_visolva
    GRANT USAGE, SELECT ON SEQUENCES TO jv_visolva_user;

-- Fremde Kontexte bleiben unzugaenglich. Das Entziehen erfolgt zentral in
-- 003_grants_and_isolation.sql, damit es bei jedem neuen Kontext wiederholt wird.
