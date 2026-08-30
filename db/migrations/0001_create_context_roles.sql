-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0001
-- Datenbankrollen der Kontexte
--
-- Grundlage: SPEC_PHASE_1 Abschnitt 7.1 Punkt 4.
--
-- Die Rollen werden ohne Kennwort und ohne Anmelderecht angelegt. Sie
-- tragen zu diesem Zeitpunkt ausschliesslich Rechte, keine Identitaet.
-- Das Anmelderecht und die Zugangsdaten werden erst bei der n8n-Anbindung
-- vergeben und ausschliesslich im Anmeldeinformationsspeicher von n8n
-- gehalten. In diesem Repository steht kein Kennwort.
--
-- Setzen des Anmelderechts spaeter, ausserhalb dieses Repositoriums:
--   ALTER ROLE jv_privat_user  WITH LOGIN PASSWORD '<im Tresor erzeugt>';
--   ALTER ROLE jv_visolva_user WITH LOGIN PASSWORD '<im Tresor erzeugt>';
--
-- Die Rollen sind bewusst NOINHERIT und ohne jedes Sonderrecht. Alles,
-- was sie duerfen, wird in Migration 0007 und 0008 einzeln vergeben.
-- =====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jv_privat_user') THEN
        CREATE ROLE jv_privat_user
            NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jv_visolva_user') THEN
        CREATE ROLE jv_visolva_user
            NOLOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
END;
$$;

COMMENT ON ROLE jv_privat_user  IS
    'JARVIS Kontextbenutzer privat. Rechte nur auf jarvis_privat und den erlaubten Teil von jarvis_ops.';
COMMENT ON ROLE jv_visolva_user IS
    'JARVIS Kontextbenutzer arbeitgeber_visolva. Rechte nur auf jarvis_visolva und den erlaubten Teil von jarvis_ops.';
