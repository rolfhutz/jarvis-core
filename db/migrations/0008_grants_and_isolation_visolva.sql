-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0008 - Rechte und Kontexttrennung fuer jv_visolva_user
--
-- Erzeugt aus: spec/phase-0/jarvis-phase-0/db/003_grants_and_isolation.sql via tools/render_context_schema.py --context arbeitgeber_visolva
-- Nicht von Hand bearbeiten. Aenderungen erfolgen an der Vorlage und
-- werden neu gerendert.
-- =====================================================================

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
--   jv_visolva_user        Datenbankbenutzer des einzuspielenden Kontexts
--   jarvis_visolva         Schema des einzuspielenden Kontexts
--   jarvis_privat kommagetrennte Liste aller uebrigen Kontextschemata
--
-- Einspielen ausschliesslich ueber tools/render_context_schema.py.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Fremde Kontextschemata sind unzugaenglich
-- ---------------------------------------------------------------------
-- Fuer jedes fremde Schema wird der Zugriff ausdruecklich entzogen.
-- Das Rendering-Skript erzeugt je fremdem Schema einen Block dieser Form:
--
--   REVOKE ALL ON SCHEMA <fremdes_schema> FROM jv_visolva_user;
--   REVOKE ALL ON ALL TABLES IN SCHEMA <fremdes_schema> FROM jv_visolva_user;
--   REVOKE ALL ON ALL SEQUENCES IN SCHEMA <fremdes_schema> FROM jv_visolva_user;
--
REVOKE ALL ON SCHEMA jarvis_privat FROM jv_visolva_user;
REVOKE ALL ON ALL TABLES IN SCHEMA jarvis_privat FROM jv_visolva_user;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA jarvis_privat FROM jv_visolva_user;

-- ---------------------------------------------------------------------
-- 2. Keine Rechte aus der oeffentlichen Rolle
-- ---------------------------------------------------------------------
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA jarvis_visolva FROM PUBLIC;
ALTER ROLE jv_visolva_user SET search_path = jarvis_visolva, jarvis_ops;

-- ---------------------------------------------------------------------
-- 3. Gemeinsames technisches Schema
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA jarvis_ops TO jv_visolva_user;

-- Laeufe: einfuegen und ausschliesslich die Abschlussfelder aktualisieren.
-- Ohne diese spaltenweise Vergabe koennte ein Lauf nie abgeschlossen werden.
GRANT INSERT ON jarvis_ops.workflow_run TO jv_visolva_user;
GRANT UPDATE (finished_at, duration_ms, status, error_class, error_code, items_out)
    ON jarvis_ops.workflow_run TO jv_visolva_user;
GRANT SELECT ON jarvis_ops.workflow_run TO jv_visolva_user;

-- Technische Ereignisse: nur einfuegen und lesen
GRANT INSERT, SELECT ON jarvis_ops.tech_event TO jv_visolva_user;

-- bigserial in tech_event benoetigt USAGE auf der zugehoerigen Sequenz
GRANT USAGE, SELECT ON SEQUENCE jarvis_ops.tech_event_tech_event_id_seq TO jv_visolva_user;

-- Schutzschalter und Register
GRANT SELECT, INSERT, UPDATE ON jarvis_ops.tool_circuit_state TO jv_visolva_user;
GRANT SELECT ON jarvis_ops.contract_version TO jv_visolva_user;
GRANT SELECT ON jarvis_ops.context_registry TO jv_visolva_user;

-- Ausdrueckliche Entzuege
REVOKE DELETE, TRUNCATE ON jarvis_ops.workflow_run FROM jv_visolva_user;
REVOKE UPDATE, DELETE, TRUNCATE ON jarvis_ops.tech_event FROM jv_visolva_user;
REVOKE INSERT, UPDATE, DELETE ON jarvis_ops.contract_version FROM jv_visolva_user;
REVOKE INSERT, UPDATE, DELETE ON jarvis_ops.context_registry FROM jv_visolva_user;

-- ---------------------------------------------------------------------
-- 4. Pruefabfragen fuer den Nachweis der Trennung (Testfaelle K-01 bis K-04)
-- ---------------------------------------------------------------------
-- Erwartet wird jeweils ein FEHLER, kein leeres Ergebnis:
--
--   SET ROLE jv_visolva_user;
--   SELECT 1 FROM <fremdes_schema>.action_log LIMIT 1;   -- permission denied
--   UPDATE jarvis_visolva.action_log SET summary_de = 'x';   -- append_only_violation
--   DELETE FROM jarvis_visolva.action_log;                   -- append_only_violation
--   INSERT INTO jarvis_visolva.action (context_id, ...) VALUES ('fremder_kontext', ...);
--                                                        -- action_context_chk
--   RESET ROLE;
