-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0011 - Login-Benutzer je Kontext
--
-- Eingespielt am 31.08.2026 (Supabase-Fassung 20260831172833).
-- Nachgetragen am 10.09.2026 im Wortlaut aus
-- supabase_migrations.schema_migrations, weil am 31.08. kein
-- Schreibzugang zum Repository bestand.
-- Entscheidung E1 vom 31.08.2026: Rechte haengen an der Gruppenrolle,
-- nicht am Login. Der Login ist rotierbar, ohne Rechte anzufassen.
-- =====================================================================

-- Weg B: je Kontext ein eigener Login-Benutzer, der die bestehende Gruppenrolle erbt.
-- Rechte bleiben ausschliesslich an jv_privat_user / jv_visolva_user.
-- Passwoerter werden bewusst NICHT in dieser Migration gesetzt (kein Geheimnis in der Versionshistorie).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jv_privat_login') THEN
    CREATE ROLE jv_privat_login LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'jv_visolva_login') THEN
    CREATE ROLE jv_visolva_login LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$$;

GRANT jv_privat_user  TO jv_privat_login;
GRANT jv_visolva_user TO jv_visolva_login;

DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO jv_privat_login, jv_visolva_login', current_database());
END
$$;
