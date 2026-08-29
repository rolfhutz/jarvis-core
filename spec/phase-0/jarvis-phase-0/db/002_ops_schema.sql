-- =====================================================================
-- JARVIS Phase 0 - Gemeinsames technisches Schema
-- Version 1.1.0
--
-- Dieses Schema ist kontextuebergreifend und enthaelt ausschliesslich
-- technische Metadaten. Verboten sind Dokumentinhalte, Gespraechsinhalte,
-- Zusammenfassungen, Betreffzeilen, Empfaengernamen, Betraege, fachliche
-- Entscheidungen und jeder Freitext aus Quellsystemen.
--
-- Durchsetzung ueber eine Positivliste von Spalten. Es gibt bewusst keine
-- jsonb-Spalte und nur ein einziges Freitextfeld: message_safe mit 500
-- Zeichen, das vor dem Schreiben durch tools/sanitize_message.py bereinigt
-- werden muss.
--
-- Status: Vorlage. Wird ueber tools/render_context_schema.py --ops
-- ausgegeben und enthaelt bewusst keine Platzhalter. Die Rechtevergabe je
-- Kontextbenutzer steht in 003_grants_and_isolation.sql.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS jarvis_ops;

-- ---------------------------------------------------------------------
-- Workflow-Laeufe
--
-- Ein Lauf wird beim Start eingefuegt und beim Ende abgeschlossen. Damit
-- der Kontextbenutzer den Lauf abschliessen kann, ohne allgemeine
-- Aenderungsrechte zu erhalten, wird das UPDATE spaltenweise vergeben:
-- nur die Abschlussfelder duerfen gesetzt werden, und ein Trigger
-- verhindert, dass ein bereits abgeschlossener Lauf nachtraeglich
-- veraendert wird.
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.workflow_run (
    run_id             text PRIMARY KEY,
    trace_id           text NOT NULL,
    correlation_id     text,
    workflow_name      text NOT NULL,
    workflow_version   text NOT NULL,
    context_id         text,
    started_at         timestamptz NOT NULL,
    finished_at        timestamptz,
    duration_ms        integer,
    status             text NOT NULL CHECK (status IN ('running','succeeded','failed','cancelled')),
    error_class        text,
    error_code         text,
    items_in           integer,
    items_out          integer
);
CREATE INDEX workflow_run_trace_idx ON jarvis_ops.workflow_run (trace_id);
CREATE INDEX workflow_run_time_idx ON jarvis_ops.workflow_run (started_at DESC);

CREATE OR REPLACE FUNCTION jarvis_ops.guard_workflow_run_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status <> 'running' THEN
        RAISE EXCEPTION
            'run_already_final: Lauf % ist bereits abgeschlossen und darf nicht veraendert werden.',
            OLD.run_id
            USING ERRCODE = '42501';
    END IF;
    IF NEW.run_id <> OLD.run_id
       OR NEW.trace_id <> OLD.trace_id
       OR NEW.workflow_name <> OLD.workflow_name
       OR NEW.workflow_version <> OLD.workflow_version
       OR NEW.started_at <> OLD.started_at
       OR NEW.context_id IS DISTINCT FROM OLD.context_id THEN
        RAISE EXCEPTION
            'run_immutable_field: Nur Abschlussfelder eines Laufs duerfen aktualisiert werden.'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER workflow_run_guard
    BEFORE UPDATE ON jarvis_ops.workflow_run
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.guard_workflow_run_update();

CREATE OR REPLACE FUNCTION jarvis_ops.deny_ops_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION
        'append_only_violation: % auf %.% ist unzulaessig.',
        TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME
        USING ERRCODE = '42501';
END;
$$;

CREATE TRIGGER workflow_run_deny_delete
    BEFORE DELETE ON jarvis_ops.workflow_run
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

-- ---------------------------------------------------------------------
-- Technische Einzelereignisse - append-only
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.tech_event (
    tech_event_id      bigserial PRIMARY KEY,
    trace_id           text NOT NULL,
    run_id             text,
    occurred_at        timestamptz NOT NULL DEFAULT now(),
    workflow_name      text NOT NULL,
    node_name          text,
    context_id         text,
    object_kind        text,
    object_id          text,
    tool_id            text,
    adapter_id         text,
    status_code        integer,
    error_class        text,
    message_safe       varchar(500),
    duration_ms        integer
);
CREATE INDEX tech_event_trace_idx ON jarvis_ops.tech_event (trace_id, occurred_at);
CREATE INDEX tech_event_object_idx ON jarvis_ops.tech_event (object_id);

CREATE TRIGGER tech_event_deny_update
    BEFORE UPDATE ON jarvis_ops.tech_event
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

CREATE TRIGGER tech_event_deny_delete
    BEFORE DELETE ON jarvis_ops.tech_event
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

-- ---------------------------------------------------------------------
-- Zustand der Schutzschalter je Werkzeug
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.tool_circuit_state (
    tool_id            text NOT NULL,
    context_id         text NOT NULL,
    state              text NOT NULL CHECK (state IN ('closed','open','half_open')),
    failure_count      integer NOT NULL DEFAULT 0,
    window_started_at  timestamptz NOT NULL,
    opened_at          timestamptz,
    reopen_after       timestamptz,
    PRIMARY KEY (tool_id, context_id)
);

-- ---------------------------------------------------------------------
-- Registrierte Vertragsversionen
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.contract_version (
    contract_id        text NOT NULL,
    contract_kind      text NOT NULL CHECK (contract_kind IN ('schema','tool','agent','prompt','ruleset','workflow')),
    version            text NOT NULL,
    git_ref            text NOT NULL,
    activated_at       timestamptz NOT NULL,
    deactivated_at     timestamptz,
    PRIMARY KEY (contract_id, version)
);

-- ---------------------------------------------------------------------
-- Kontextregister - Verzeichnis ohne Fachdaten
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.context_registry (
    context_id         text PRIMARY KEY,
    display_name       text NOT NULL,
    context_kind       text NOT NULL,
    db_schema          text NOT NULL UNIQUE,
    db_user            text NOT NULL,
    status             text NOT NULL CHECK (status IN ('active','readonly','archived')),
    config_version     text NOT NULL,
    updated_at         timestamptz NOT NULL DEFAULT now()
);
