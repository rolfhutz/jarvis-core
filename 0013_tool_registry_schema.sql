-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0013 - Werkzeugregister zur Laufzeit
--
-- Entscheidung: Variante A vom 10.09.2026 (Rolf). Das Werkzeugregister wird
-- zur Laufzeit ausschliesslich aus jarvis_ops.tool_registry gelesen.
-- Definitionsquelle bleiben die Registerdateien im Repository:
--   spec/phase-0/jarvis-phase-0/registry/tool_registry.json
--   spec/phase-1/jarvis-phase-1/registry/tool_registry_phase1.json
-- Die Befuellung erfolgt ausschliesslich ueber die erzeugte Migration 0014
-- (tools/render_tool_registry.py). Freie Pflege in der Datenbank ist
-- unzulaessig.
--
-- Grundsaetze:
--   1. Vertragsfelder sind unveraenderlich. Eine Aenderung erfordert eine
--      neue Version des Werkzeugs.
--   2. Veraenderlich ist nur der Freigabestatus. Jede Statusaenderung
--      braucht einen Nachweisverweis und wird append-only protokolliert.
--   3. Kontextbenutzer duerfen nur lesen. JARVIS kann kein Werkzeug selbst
--      freigeben.
--   4. Die Regeln aus tool_registry.schema.json sind zusaetzlich als
--      Pruefbedingungen hinterlegt.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Werkzeugregister
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.tool_registry (
    tool_id              text NOT NULL CHECK (tool_id ~ '^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$'),
    version              text NOT NULL CHECK (version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
    adapter_id           text NOT NULL,
    operation            text NOT NULL CHECK (operation IN ('read','write')),
    external_effect      text NOT NULL CHECK (external_effect IN ('none','internal','external_recipient','financial','legal')),
    risk_class_default   char(1) NOT NULL CHECK (risk_class_default IN ('A','B','C')),
    reversibility        text NOT NULL,
    undo_tool_id         text,
    allowed_contexts     text[] NOT NULL,
    readback_supported   boolean NOT NULL,
    accepted_methods     text[] NOT NULL CHECK (cardinality(accepted_methods) >= 1),
    evidence_limitation  text,
    timeout_seconds      integer NOT NULL CHECK (timeout_seconds >= 1),
    dry_run_supported    boolean NOT NULL,
    status               text NOT NULL CHECK (status IN ('draft','approved','deprecated')),
    status_changed_at    timestamptz,
    definition           jsonb NOT NULL,
    definition_sha256    text NOT NULL CHECK (definition_sha256 ~ '^[a-f0-9]{64}$'),
    source_file          text NOT NULL,
    source_sha256        text NOT NULL CHECK (source_sha256 ~ '^[a-f0-9]{64}$'),
    loaded_at            timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (tool_id, version),

    CONSTRAINT tool_external_min_b CHECK (
        external_effect NOT IN ('external_recipient','financial','legal')
        OR risk_class_default IN ('B','C')),
    CONSTRAINT tool_financial_legal_c CHECK (
        external_effect NOT IN ('financial','legal')
        OR risk_class_default = 'C'),
    CONSTRAINT tool_irreversible_write_min_b CHECK (
        NOT (operation = 'write' AND reversibility = 'irreversible')
        OR risk_class_default IN ('B','C')),
    CONSTRAINT tool_readback_exclusive CHECK (
        NOT readback_supported OR accepted_methods = ARRAY['readback']::text[]),
    CONSTRAINT tool_substitute_needs_limitation CHECK (
        readback_supported OR length(coalesce(evidence_limitation, '')) >= 10)
);

COMMENT ON TABLE jarvis_ops.tool_registry IS
    'Laufzeitkopie des Werkzeugregisters. Einzige Laufzeitquelle fuer Risikoklasse, Freigabestatus und Nachweisstrategie. Befuellung nur ueber Migration 0014.';

-- ---------------------------------------------------------------------
-- 2. Freigabeprotokoll - append-only
-- ---------------------------------------------------------------------
CREATE TABLE jarvis_ops.tool_release_log (
    release_log_id  bigserial PRIMARY KEY,
    tool_id         text NOT NULL,
    version         text NOT NULL,
    from_status     text NOT NULL,
    to_status       text NOT NULL,
    evidence_ref    text NOT NULL CHECK (length(evidence_ref) >= 5),
    changed_by      text NOT NULL,
    changed_at      timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (tool_id, version) REFERENCES jarvis_ops.tool_registry (tool_id, version)
);

CREATE TRIGGER tool_release_log_deny_update
    BEFORE UPDATE ON jarvis_ops.tool_release_log
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

CREATE TRIGGER tool_release_log_deny_delete
    BEFORE DELETE ON jarvis_ops.tool_release_log
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

-- ---------------------------------------------------------------------
-- 3. Unveraenderlichkeit und protokollierte Statusaenderung
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION jarvis_ops.guard_tool_registry_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_evidence text;
BEGIN
    IF (to_jsonb(NEW) - 'status' - 'status_changed_at')
       IS DISTINCT FROM
       (to_jsonb(OLD) - 'status' - 'status_changed_at') THEN
        RAISE EXCEPTION
            'registry_immutable: Vertragsfelder von %@% sind unveraenderlich. Aenderung nur ueber eine neue Version.',
            OLD.tool_id, OLD.version
            USING ERRCODE = '42501';
    END IF;

    IF NEW.status IS DISTINCT FROM OLD.status THEN
        IF OLD.status = 'deprecated' THEN
            RAISE EXCEPTION
                'registry_status_final: %@% ist deprecated und kann nicht reaktiviert werden.',
                OLD.tool_id, OLD.version
                USING ERRCODE = '42501';
        END IF;

        v_evidence := nullif(current_setting('jarvis.release_evidence_ref', true), '');
        IF v_evidence IS NULL THEN
            RAISE EXCEPTION
                'release_evidence_missing: Statusaenderung von %@% ohne Nachweisverweis (jarvis.release_evidence_ref).',
                OLD.tool_id, OLD.version
                USING ERRCODE = '42501';
        END IF;

        INSERT INTO jarvis_ops.tool_release_log
            (tool_id, version, from_status, to_status, evidence_ref, changed_by)
        VALUES
            (OLD.tool_id, OLD.version, OLD.status, NEW.status, v_evidence, current_user);

        NEW.status_changed_at := now();
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tool_registry_guard_update
    BEFORE UPDATE ON jarvis_ops.tool_registry
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.guard_tool_registry_update();

CREATE TRIGGER tool_registry_deny_delete
    BEFORE DELETE ON jarvis_ops.tool_registry
    FOR EACH ROW EXECUTE FUNCTION jarvis_ops.deny_ops_mutation();

-- ---------------------------------------------------------------------
-- 4. Kontextregeln fuer die Risikoklasse (nur Hochstufung)
-- ---------------------------------------------------------------------
-- Entspricht policy.risk_class_overrides der Kontextkonfiguration.
-- Eine Regel kann eine Klasse ausschliesslich anheben: Die Risikoklasse
-- einer Aktion ist das Maximum aus Registerwert und allen Regeln.
-- In Phase 1.0 bewusst leer; die Befuellung erfolgt mit der echten
-- Kontextkonfiguration in Schritt 1.1.
CREATE TABLE jarvis_ops.context_risk_override (
    override_id     bigserial PRIMARY KEY,
    context_id      text NOT NULL REFERENCES jarvis_ops.context_registry (context_id),
    action_type     text,
    tool_id         text,
    min_risk_class  char(1) NOT NULL CHECK (min_risk_class IN ('A','B','C')),
    reason          text NOT NULL CHECK (length(reason) >= 10),
    config_version  text NOT NULL,
    CHECK (action_type IS NOT NULL OR tool_id IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- 5. Rechte: Kontextbenutzer duerfen ausschliesslich lesen
-- ---------------------------------------------------------------------
REVOKE ALL ON jarvis_ops.tool_registry         FROM PUBLIC;
REVOKE ALL ON jarvis_ops.tool_release_log      FROM PUBLIC;
REVOKE ALL ON jarvis_ops.context_risk_override FROM PUBLIC;

GRANT SELECT ON jarvis_ops.tool_registry, jarvis_ops.tool_release_log, jarvis_ops.context_risk_override
    TO jv_privat_user, jv_visolva_user;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE
    ON jarvis_ops.tool_registry, jarvis_ops.tool_release_log, jarvis_ops.context_risk_override
    FROM jv_privat_user, jv_visolva_user;
