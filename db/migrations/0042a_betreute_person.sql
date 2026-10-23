-- Datentrennung DT-1 (Rolf, 23.10.2026): Die Daten weiterer betreuter Personen (Name, Anschrift) liegen nicht im öffentlichen Repository.
-- Private Ergänzung: Claude-Projekt «JARVIS – Persönlicher KI-Assistent», Datei claude/privat_daten/0042a_betreute_person.privat.sql
-- Wiederherstellung: zuerst diese Datei, danach die private Ergänzung. In der Datenbank eingespielt ist die
-- Gesamtfassung (Migrationshistorie, Name 0042a_betreute_person).
CREATE TABLE jarvis_privat.betreute_person (
  person_key       text PRIMARY KEY CHECK (person_key ~ '^[a-z][a-z_]{1,29}$'),
  context_id       text NOT NULL DEFAULT 'privat' CHECK (context_id = 'privat'),
  anzeigename      text NOT NULL,
  ordner_name      text CHECK (ordner_name IS NULL OR ordner_name ~ '^[A-Za-z0-9_-]{2,40}$'),
  erkennung        text[] NOT NULL DEFAULT '{}',
  anschrift        jsonb,
  vollmacht        boolean NOT NULL DEFAULT false,
  todo_list_name   text,
  ist_selbst       boolean NOT NULL DEFAULT false,
  aktiv            boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX betreute_person_selbst_uq ON jarvis_privat.betreute_person (ist_selbst) WHERE ist_selbst;
INSERT INTO jarvis_privat.betreute_person (person_key, anzeigename, ordner_name, erkennung, anschrift, vollmacht, todo_list_name, ist_selbst) VALUES
 ('rolf', 'Rolf Hutz', NULL, ARRAY['Rolf Hutz'], NULL, false, NULL, true);
ALTER TABLE jarvis_privat.document      ADD COLUMN person_key text NOT NULL DEFAULT 'rolf' REFERENCES jarvis_privat.betreute_person(person_key);
ALTER TABLE jarvis_privat.task          ADD COLUMN person_key text NOT NULL DEFAULT 'rolf' REFERENCES jarvis_privat.betreute_person(person_key);
ALTER TABLE jarvis_privat.filing_target ADD COLUMN person_key text NOT NULL DEFAULT 'rolf' REFERENCES jarvis_privat.betreute_person(person_key);
CREATE INDEX document_person_idx ON jarvis_privat.document (person_key);
GRANT SELECT ON jarvis_privat.betreute_person TO jv_privat_user;
