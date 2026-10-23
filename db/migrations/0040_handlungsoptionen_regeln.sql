-- 0040_handlungsoptionen_regeln
-- CR-13b+ (15.10.2026, von Rolf freigegeben: Variante B = Optionsliste + Rückfrage + eigene Regeln)
-- Zweck:
--   1. vorgang_typ    – feste Vorgangsarten, in die die KI jedes Dokument einordnet (statt freier «dokumentart»).
--   2. vorgang_option – welche Handlungsoptionen (Fälle aus document_fall) JARVIS je Vorgangsart IMMER zur Wahl stellt.
--   3. handling_rule  – Rolfs eigene Regeln, gepflegt über die Weboberfläche, von der KI bei jeder Analyse mitgelesen.
-- Grundsätze:
--   - Rein additiv. Bestehende Tabellen und Fälle bleiben unverändert.
--   - Optionen und Regeln steuern nur VORSCHLÄGE. Klasse C bleibt: kein Versand, keine Zahlung durch JARVIS.
--   - handling_rule ist versioniert und ohne Löschrecht: Ändern = neue Zeile + alte auf inaktiv (ersetzt_rule_id).
--   - Keine Geheimnisse, keine Konten, keine IDs von Drittsystemen.
-- TS-34 (23.10.2026): Diese Migration wurde ohne Eintrag in der Migrationshistorie eingespielt. Die Fassung hier
-- stammt aus der freigegebenen Projektdatei; abgeglichen mit der Datenbank (9 Vorgangsarten, 33 Optionen,
-- 11 Constraints und Trigger an handling_rule vorhanden).

-- ---------------------------------------------------------------------------
-- 1. Vorgangsarten
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jarvis_privat.vorgang_typ (
  vorgang_key   text        NOT NULL PRIMARY KEY,
  context_id    text        NOT NULL DEFAULT 'privat',
  label_de      text        NOT NULL,
  erkennung_de  text        NOT NULL,
  sort_order    integer     NOT NULL DEFAULT 100,
  active        boolean     NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT vorgang_typ_context_chk CHECK (context_id = 'privat'),
  CONSTRAINT vorgang_typ_key_chk CHECK (vorgang_key ~ '^[a-z][a-z_]{2,39}$')
);
COMMENT ON TABLE jarvis_privat.vorgang_typ IS 'CR-13b+: Vorgangsarten. Die KI ordnet jedes Dokument genau einer Art zu; daraus folgen die angebotenen Handlungsoptionen.';
COMMENT ON COLUMN jarvis_privat.vorgang_typ.erkennung_de IS 'Beschreibung für die KI, woran die Vorgangsart erkennbar ist.';

INSERT INTO jarvis_privat.vorgang_typ (vorgang_key, label_de, erkennung_de, sort_order) VALUES
('vertragsaenderung', 'Vertragsänderung durch den Anbieter',
 'Der Anbieter ändert einen laufenden Vertrag: Beitrags- oder Preisanpassung, Dynamikerhöhung, Änderung von Bedingungen, AGB oder Leistungen.', 10),
('vertrag_bestand', 'Vertrag / Police',
 'Unterlagen zu einem bestehenden Vertrag ohne Änderung: Police, Vertragsbestätigung, Nachtrag, Versicherungskarte, Jahresmitteilung.', 20),
('rechnung', 'Rechnung',
 'Zahlungsforderung: Rechnung, Prämien- oder Beitragsrechnung, Nebenkostenabrechnung, Honorarnote ohne Erstattung.', 30),
('mahnung', 'Mahnung / Zahlungserinnerung',
 'Erinnerung an eine offene Zahlung, Mahnung, Inkasso.', 40),
('erstattung_abrechnung', 'Leistungsabrechnung / Erstattung',
 'Abrechnung einer Versicherung oder Krankenkasse über erstattete Leistungen, Honorarnote mit Erstattungsschreiben.', 50),
('behoerde_bescheid', 'Bescheid / Behörde',
 'Schreiben einer Behörde oder eines Amtes: Steuerbescheid, Vorauszahlung, Meldebestätigung, Verfügung.', 60),
('vertragsende', 'Kündigung / Vertragsende',
 'Bestätigung einer Kündigung, Storno, Vertragsablauf, Beendigung durch den Anbieter.', 70),
('information', 'Information',
 'Reine Information ohne Handlungsbedarf: Kontoauszug, Mitteilung, Newsletter, Informationsschreiben.', 80),
('sonstiges', 'Sonstiges',
 'Passt in keine andere Vorgangsart.', 900)
ON CONFLICT (vorgang_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Handlungsoptionen je Vorgangsart
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jarvis_privat.vorgang_option (
  vorgang_key  text        NOT NULL REFERENCES jarvis_privat.vorgang_typ (vorgang_key),
  fall_key     text        NOT NULL REFERENCES jarvis_privat.document_fall (fall_key),
  label_de     text,
  bedingung_de text,
  hinweis_de   text,
  sort_order   integer     NOT NULL DEFAULT 100,
  active       boolean     NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (vorgang_key, fall_key)
);
COMMENT ON TABLE jarvis_privat.vorgang_option IS 'CR-13b+: Optionen, die JARVIS je Vorgangsart immer zur Wahl stellt. bedingung_de leer = immer anbieten; sonst nur, wenn die Bedingung laut Dokument erfüllt ist.';
COMMENT ON COLUMN jarvis_privat.vorgang_option.label_de IS 'Optionaler Anzeigename für diese Vorgangsart (überschreibt document_fall.label_de).';
COMMENT ON COLUMN jarvis_privat.vorgang_option.hinweis_de IS 'Was die KI zu dieser Option zwingend nennen muss, z. B. Folgen.';

INSERT INTO jarvis_privat.vorgang_option (vorgang_key, fall_key, label_de, bedingung_de, hinweis_de, sort_order) VALUES
-- Vertragsänderung durch den Anbieter (Beispiel: Dynamikerhöhung BU)
('vertragsaenderung', 'ablegen',         'Änderung akzeptieren – nur ablegen', NULL, 'Was ab wann gilt (neuer Betrag, Datum).', 10),
('vertragsaenderung', 'widerspruch',     'Der Änderung widersprechen', 'Das Dokument nennt ein Widerspruchs- oder Ablehnungsrecht.', 'Frist und Folge des Widerspruchs, z. B. Verlust künftiger Dynamik.', 20),
('vertragsaenderung', 'kuendigen',       'Ganzen Vertrag kündigen', NULL, 'Kündigungsfrist, frühester Termin und Folgen, z. B. Wegfall des Versicherungsschutzes und erschwerter Neuabschluss.', 30),
('vertragsaenderung', 'antworten',       'Rückfrage an den Anbieter', NULL, NULL, 40),
('vertragsaenderung', 'adressaenderung', 'Neue Adresse mitteilen', 'Die Anschrift im Dokument weicht von Rolfs aktueller Anschrift ab.', NULL, 50),
-- Vertrag / Police
('vertrag_bestand', 'ablegen',         'Nur ablegen', NULL, NULL, 10),
('vertrag_bestand', 'kuendigen',       'Vertrag kündigen', NULL, 'Kündigungsfrist, frühester Termin und Folgen.', 20),
('vertrag_bestand', 'antworten',       'Rückfrage an den Anbieter', NULL, NULL, 30),
('vertrag_bestand', 'adressaenderung', 'Neue Adresse mitteilen', 'Die Anschrift im Dokument weicht von Rolfs aktueller Anschrift ab.', NULL, 40),
-- Rechnung
('rechnung', 'zahlen',          'Bezahlen', 'Die Rechnung wird nicht per Lastschrift oder Dauerauftrag eingezogen.', 'Betrag, Fälligkeit, Empfänger.', 10),
('rechnung', 'ablegen',         'Wird eingezogen / bereits bezahlt – nur ablegen', NULL, NULL, 20),
('rechnung', 'widerspruch',     'Reklamieren', NULL, NULL, 30),
('rechnung', 'einreichen',      'Zur Erstattung einreichen', 'Eine Erstattung durch Dritte ist möglich, z. B. Krankenkasse oder Versicherung.', 'Bei wem und mit welcher Nummer.', 40),
('rechnung', 'adressaenderung', 'Neue Adresse mitteilen', 'Die Anschrift im Dokument weicht von Rolfs aktueller Anschrift ab.', NULL, 50),
-- Mahnung
('mahnung', 'zahlen',      'Bezahlen', NULL, 'Betrag inkl. Gebühren, Frist, Folgen bei Nichtzahlung.', 10),
('mahnung', 'widerspruch', 'Forderung bestreiten', NULL, NULL, 20),
('mahnung', 'antworten',   'Bereits bezahlt – Anbieter informieren', NULL, NULL, 30),
('mahnung', 'ablegen',     'Nur ablegen', NULL, NULL, 40),
-- Leistungsabrechnung / Erstattung
('erstattung_abrechnung', 'ablegen',     'Erstattung prüfen – nur ablegen', NULL, 'Erstatteter Betrag und Selbstbehalt.', 10),
('erstattung_abrechnung', 'widerspruch', 'Abrechnung beanstanden', NULL, NULL, 20),
('erstattung_abrechnung', 'einreichen',  'Bei weiterer Stelle einreichen', 'Ein Restbetrag kann bei einer weiteren Stelle eingereicht werden, z. B. Zusatzversicherung.', NULL, 30),
-- Bescheid / Behörde
('behoerde_bescheid', 'ablegen',     'Nur ablegen', NULL, NULL, 10),
('behoerde_bescheid', 'zahlen',      'Bezahlen', 'Der Bescheid enthält eine Zahlungsaufforderung.', 'Betrag, Fälligkeit, Empfänger.', 20),
('behoerde_bescheid', 'widerspruch', 'Einspruch / Einsprache', 'Der Bescheid ist anfechtbar oder nennt eine Rechtsmittelfrist.', 'Rechtsmittelfrist.', 30),
('behoerde_bescheid', 'antworten',   'Antworten / Unterlagen nachreichen', NULL, NULL, 40),
-- Kündigung / Vertragsende
('vertragsende', 'ablegen',     'Bestätigung prüfen – nur ablegen', NULL, 'Beendigungsdatum und ob Rückzahlungen folgen.', 10),
('vertragsende', 'antworten',   'Rückfrage an den Anbieter', NULL, NULL, 20),
('vertragsende', 'widerspruch', 'Der Beendigung widersprechen', 'Die Beendigung ging nicht von Rolf aus.', NULL, 30),
-- Information
('information', 'ablegen',   'Nur ablegen', NULL, NULL, 10),
('information', 'antworten', 'Antworten', NULL, NULL, 20),
-- Sonstiges
('sonstiges', 'ablegen',     'Nur ablegen', NULL, NULL, 10),
('sonstiges', 'antworten',   'Antworten', NULL, NULL, 20),
('sonstiges', 'kuendigen',   'Vertrag kündigen', 'Ein laufender Vertrag ist erkennbar.', 'Kündigungsfrist und Folgen.', 30)
ON CONFLICT (vorgang_key, fall_key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3. Rolfs eigene Regeln (gepflegt über die Weboberfläche)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jarvis_privat.handling_rule (
  rule_id            text        NOT NULL PRIMARY KEY,
  context_id         text        NOT NULL DEFAULT 'privat',
  regel_de           text        NOT NULL,
  geltung_kategorie  text        REFERENCES jarvis_privat.filing_rule (category_key),
  geltung_vorgang    text        REFERENCES jarvis_privat.vorgang_typ (vorgang_key),
  status             text        NOT NULL DEFAULT 'aktiv',
  version            integer     NOT NULL DEFAULT 1,
  ersetzt_rule_id    text        REFERENCES jarvis_privat.handling_rule (rule_id),
  quelle             text        NOT NULL DEFAULT 'web_desk',
  anlass_document_id text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  deactivated_at     timestamptz,
  CONSTRAINT handling_rule_context_chk CHECK (context_id = 'privat'),
  CONSTRAINT handling_rule_id_chk CHECK (rule_id ~ '^rul_[0-9A-HJKMNP-TV-Z]{26}$'),
  CONSTRAINT handling_rule_text_chk CHECK (char_length(btrim(regel_de)) BETWEEN 5 AND 300),
  CONSTRAINT handling_rule_status_chk CHECK (status IN ('aktiv', 'inaktiv')),
  CONSTRAINT handling_rule_inaktiv_chk CHECK ((status = 'inaktiv') = (deactivated_at IS NOT NULL)),
  CONSTRAINT handling_rule_quelle_chk CHECK (quelle IN ('web_desk', 'claude_chat')),
  CONSTRAINT handling_rule_doc_chk CHECK (anlass_document_id IS NULL OR anlass_document_id ~ '^doc_[0-9A-HJKMNP-TV-Z]{26}$')
);
COMMENT ON TABLE jarvis_privat.handling_rule IS 'CR-13b+: Regeln von Rolf für künftige Vorschläge. Nur Vorschlagslogik; ändern = neue Version, alte inaktiv; kein Löschen.';

CREATE INDEX IF NOT EXISTS handling_rule_aktiv_idx ON jarvis_privat.handling_rule (status) WHERE status = 'aktiv';

-- Unveränderlichkeit: nach dem Anlegen darf nur noch der Status (aktiv -> inaktiv) wechseln.
CREATE OR REPLACE FUNCTION jarvis_privat.handling_rule_nur_deaktivieren()
RETURNS trigger LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.rule_id <> OLD.rule_id OR NEW.regel_de <> OLD.regel_de
     OR NEW.geltung_kategorie IS DISTINCT FROM OLD.geltung_kategorie
     OR NEW.geltung_vorgang IS DISTINCT FROM OLD.geltung_vorgang
     OR NEW.version <> OLD.version OR NEW.ersetzt_rule_id IS DISTINCT FROM OLD.ersetzt_rule_id
     OR NEW.quelle <> OLD.quelle OR NEW.anlass_document_id IS DISTINCT FROM OLD.anlass_document_id
     OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION 'handling_rule ist unveränderlich; für Änderungen eine neue Version anlegen';
  END IF;
  IF OLD.status = 'inaktiv' AND NEW.status = 'aktiv' THEN
    RAISE EXCEPTION 'inaktive Regel kann nicht reaktiviert werden; neue Version anlegen';
  END IF;
  RETURN NEW;
END;
$f$;

DROP TRIGGER IF EXISTS handling_rule_nur_deaktivieren_trg ON jarvis_privat.handling_rule;
CREATE TRIGGER handling_rule_nur_deaktivieren_trg
  BEFORE UPDATE ON jarvis_privat.handling_rule
  FOR EACH ROW EXECUTE FUNCTION jarvis_privat.handling_rule_nur_deaktivieren();

-- ---------------------------------------------------------------------------
-- Rechte: Workflows lesen Katalog; Regeln dürfen angelegt und deaktiviert, nie gelöscht werden.
-- ---------------------------------------------------------------------------
GRANT SELECT ON jarvis_privat.vorgang_typ    TO jv_privat_user;
GRANT SELECT ON jarvis_privat.vorgang_option TO jv_privat_user;
GRANT SELECT, INSERT ON jarvis_privat.handling_rule TO jv_privat_user;
GRANT UPDATE (status, deactivated_at) ON jarvis_privat.handling_rule TO jv_privat_user;
