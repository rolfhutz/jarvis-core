-- 0047_schemaabgleich_live.sql
-- CR-19 (Wiederherstellungstest 31.10.2026): Zwei Schemaänderungen waren live vorgenommen worden, ohne als
-- Migration festgehalten zu sein. Der Schemavergleich Live-Datenbank gegen frisch migrierte Datenbank hat sie gezeigt;
-- ohne sie scheitert das Zurückspielen einer Sicherung.
--   1. finance_import.source_format kennt zusätzlich 'web' (Browser-Abruf E-Banking, Finanzmodul, Oktober 2026).
--   2. Der alte Eindeutigkeitsindex filing_target_uq (ohne Person, aus 0035) ist live entfernt;
--      massgeblich ist filing_target_person_uq aus 0042b (CR-15: gleicher Anbieter für Rolf und Rosa möglich).
-- Auf der Live-Datenbank ändert diese Migration nichts (wiederholbar). Keine Daten.

begin;

alter table jarvis_privat.finance_import drop constraint if exists finance_import_source_format_check;
alter table jarvis_privat.finance_import add constraint finance_import_source_format_check
  check (source_format = any (array['pdf'::text, 'csv'::text, 'screenshot'::text, 'web'::text]));

drop index if exists jarvis_privat.filing_target_uq;

commit;
