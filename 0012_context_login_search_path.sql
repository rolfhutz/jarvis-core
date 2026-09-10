-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0012 - Suchpfad der Login-Benutzer
--
-- Eingespielt am 31.08.2026 (Supabase-Fassung 20260831174026).
-- Nachgetragen am 10.09.2026 im Wortlaut aus
-- supabase_migrations.schema_migrations.
-- =====================================================================

-- Standard-search_path je Login-Benutzer, damit Workflows ohne Schema-Praefix
-- niemals versehentlich im falschen Kontext landen.
ALTER ROLE jv_privat_login  SET search_path = jarvis_privat, jarvis_ops, public;
ALTER ROLE jv_visolva_login SET search_path = jarvis_visolva, jarvis_ops, public;
