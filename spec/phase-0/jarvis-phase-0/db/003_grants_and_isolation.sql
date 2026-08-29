-- =====================================================================
-- JARVIS Phase 0 - Rechtevergabe und Kontexttrennung
-- Version 1.1.0
--
-- Diese Datei wird nach jedem neuen Kontext erneut ausgefuehrt. Sie stellt
-- sicher, dass jeder Kontextbenutzer ausschliesslich sein eigenes Schema
-- erreicht und im gemeinsamen technischen Schema nur das darf, was fuer
-- die Diagnose noetig ist.
--
-- Platzhalter:
--   {{DB_USER}}        Datenbankbenutzer des einzuspielenden Kontexts
--   {{SCHEMA}}         Schema des einzuspielenden Kontexts
--   {{FOREIGN_SCHEMAS}} kommagetrennte Liste aller uebrigen Kontextschemata
--
-- Einspielen ausschliesslich ueber tools/render_context_schema.py.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Fremde Kontextschemata sind unzugaenglich
-- ---------------------------------------------------------------------
-- Fuer jedes fremde Schema wird der Zugriff ausdruecklich entzogen.
-- Das Rendering-Skript erzeugt je fremdem Schema einen Block dieser Form:
--
--   REVOKE ALL ON SCHEMA <fremdes_schema> FROM {{DB_USER}};
--   REVOKE ALL ON ALL TABLES IN SCHEMA <fremdes_schema> FROM {{DB_USER}};
--   REVOKE ALL ON ALL SEQUENCES IN SCHEMA <fremdes_schema> FROM {{DB_USER}};
--
{{REVOKE_FOREIGN_BLOCK}}

-- ---------------------------------------------------------------------
-- 2. Keine Rechte aus der oeffentlichen Rolle
-- ---------------------------------------------------------------------
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA {{SCHEMA}} FROM PUBLIC;
ALTER ROLE {{DB_USER}} SET search_path = {{SCHEMA}}, jarvis_ops;

-- ---------------------------------------------------------------------
-- 3. Gemeinsames technisches Schema
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA jarvis_ops TO {{DB_USER}};

-- Laeufe: einfuegen und ausschliesslich die Abschlussfelder aktualisieren.
-- Ohne diese spaltenweise Vergabe koennte ein Lauf nie abgeschlossen werden.
GRANT INSERT ON jarvis_ops.workflow_run TO {{DB_USER}};
GRANT UPDATE (finished_at, duration_ms, status, error_class, error_code, items_out)
    ON jarvis_ops.workflow_run TO {{DB_USER}};
GRANT SELECT ON jarvis_ops.workflow_run TO {{DB_USER}};

-- Technische Ereignisse: nur einfuegen und lesen
GRANT INSERT, SELECT ON jarvis_ops.tech_event TO {{DB_USER}};

-- bigserial in tech_event benoetigt USAGE auf der zugehoerigen Sequenz
GRANT USAGE, SELECT ON SEQUENCE jarvis_ops.tech_event_tech_event_id_seq TO {{DB_USER}};

-- Schutzschalter und Register
GRANT SELECT, INSERT, UPDATE ON jarvis_ops.tool_circuit_state TO {{DB_USER}};
GRANT SELECT ON jarvis_ops.contract_version TO {{DB_USER}};
GRANT SELECT ON jarvis_ops.context_registry TO {{DB_USER}};

-- Ausdrueckliche Entzuege
REVOKE DELETE, TRUNCATE ON jarvis_ops.workflow_run FROM {{DB_USER}};
REVOKE UPDATE, DELETE, TRUNCATE ON jarvis_ops.tech_event FROM {{DB_USER}};
REVOKE INSERT, UPDATE, DELETE ON jarvis_ops.contract_version FROM {{DB_USER}};
REVOKE INSERT, UPDATE, DELETE ON jarvis_ops.context_registry FROM {{DB_USER}};

-- ---------------------------------------------------------------------
-- 4. Pruefabfragen fuer den Nachweis der Trennung (Testfaelle K-01 bis K-04)
-- ---------------------------------------------------------------------
-- Erwartet wird jeweils ein FEHLER, kein leeres Ergebnis:
--
--   SET ROLE {{DB_USER}};
--   SELECT 1 FROM <fremdes_schema>.action_log LIMIT 1;   -- permission denied
--   UPDATE {{SCHEMA}}.action_log SET summary_de = 'x';   -- append_only_violation
--   DELETE FROM {{SCHEMA}}.action_log;                   -- append_only_violation
--   INSERT INTO {{SCHEMA}}.action (context_id, ...) VALUES ('fremder_kontext', ...);
--                                                        -- action_context_chk
--   RESET ROLE;
