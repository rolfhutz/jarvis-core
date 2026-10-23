-- CR-02 / S1b: Ablageregeln je Kategorie und erweiterbare Sparten (Kontext privat).
-- Freigabe Rolf 27.09.2026: Variante B (Kategorie / Sparte / Vertrag), Spartenliste jederzeit erweiterbar.
CREATE TABLE jarvis_privat.filing_rule (
    category_key  text PRIMARY KEY CHECK (category_key ~ '^[a-z][a-z0-9_]{2,63}$'),
    context_id    text NOT NULL DEFAULT 'privat',
    label_de      text NOT NULL CHECK (char_length(label_de) BETWEEN 2 AND 80),
    folder_name   text NOT NULL CHECK (folder_name ~ '^[A-Za-z0-9][A-Za-z0-9_.-]{1,79}$'),
    scheme        text NOT NULL CHECK (scheme IN ('jahr', 'vertrag')),
    sort_order    integer NOT NULL DEFAULT 100,
    active        boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT filing_rule_context_chk CHECK (context_id = 'privat')
);
CREATE UNIQUE INDEX filing_rule_folder_uq ON jarvis_privat.filing_rule (folder_name);
COMMENT ON TABLE jarvis_privat.filing_rule IS 'Ablageregel je Kategorie: Ordner unter dem Archiv und Schema (jahr = Kategorie/Jahr, vertrag = Kategorie/[Sparte]/Vertrag).';

CREATE TABLE jarvis_privat.filing_subcategory (
    category_key  text NOT NULL REFERENCES jarvis_privat.filing_rule (category_key),
    sub_key       text NOT NULL CHECK (sub_key ~ '^[a-z][a-z0-9_]{1,63}$'),
    context_id    text NOT NULL DEFAULT 'privat',
    label_de      text NOT NULL CHECK (char_length(label_de) BETWEEN 2 AND 80),
    folder_name   text NOT NULL CHECK (folder_name ~ '^[A-Za-z0-9][A-Za-z0-9_.-]{1,79}$'),
    sort_order    integer NOT NULL DEFAULT 100,
    active        boolean NOT NULL DEFAULT true,
    created_by    text NOT NULL DEFAULT 'migration',
    created_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (category_key, sub_key),
    CONSTRAINT filing_subcategory_context_chk CHECK (context_id = 'privat')
);
CREATE UNIQUE INDEX filing_subcategory_folder_uq ON jarvis_privat.filing_subcategory (category_key, folder_name);
COMMENT ON TABLE jarvis_privat.filing_subcategory IS 'Sparten je Kategorie (z. B. Versicherungsarten). Erweiterbar ueber die Weboberflaeche; Deaktivieren statt Loeschen.';

GRANT SELECT, INSERT, UPDATE ON jarvis_privat.filing_rule TO jv_privat_user;
GRANT SELECT, INSERT, UPDATE ON jarvis_privat.filing_subcategory TO jv_privat_user;

INSERT INTO jarvis_privat.filing_rule (category_key, label_de, folder_name, scheme, sort_order) VALUES
 ('person_identitaet_behoerden', 'Person, Identität, Behörden', '01_Person_Identitaet_Behoerden', 'jahr', 1),
 ('familie_kinder', 'Familie, Kinder', '02_Familie_Kinder', 'jahr', 2),
 ('scheidung_recht', 'Scheidung, Recht', '03_Scheidung_Recht', 'jahr', 3),
 ('wohnen', 'Wohnen (Miete, Nebenkosten, Umzug)', '04_Wohnen', 'vertrag', 4),
 ('finanzen_banken', 'Finanzen, Banken', '05_Finanzen_Banken', 'jahr', 5),
 ('steuern', 'Steuern', '06_Steuern', 'jahr', 6),
 ('versicherungen', 'Versicherungen', '07_Versicherungen', 'vertrag', 7),
 ('gesundheit_krankenkasse', 'Gesundheit, Krankenkasse', '08_Gesundheit_Krankenkasse', 'jahr', 8),
 ('vorsorge_pension', 'Vorsorge, Pension', '09_Vorsorge_Pension', 'jahr', 9),
 ('arbeit_einkommen', 'Arbeit, Einkommen', '10_Arbeit_Einkommen', 'jahr', 10),
 ('fahrzeuge_mobilitaet', 'Fahrzeuge, Mobilität', '11_Fahrzeuge_Mobilitaet', 'vertrag', 11),
 ('vertraege_abonnements', 'Verträge, Abonnements', '12_Vertraege_Abonnements', 'vertrag', 12),
 ('anschaffungen_garantien', 'Anschaffungen, Garantien', '13_Anschaffungen_Garantien', 'jahr', 13),
 ('reisen', 'Reisen', '14_Reisen', 'jahr', 14),
 ('ausbildung_qualifikationen', 'Ausbildung, Qualifikationen', '15_Ausbildung_Qualifikationen', 'jahr', 15),
 ('archiv_abgeschlossen', 'Archiv, abgeschlossen', '98_Archiv_Abgeschlossen', 'jahr', 98),
 ('system_regeln_vorlagen', 'System, Regeln, Vorlagen', '99_System_Regeln_Vorlagen', 'jahr', 99);

INSERT INTO jarvis_privat.filing_subcategory (category_key, sub_key, label_de, folder_name, sort_order) VALUES
 ('versicherungen', 'hausrat_privathaftpflicht', 'Hausrat & Privathaftpflicht', 'Hausrat_Privathaftpflicht', 10),
 ('versicherungen', 'rechtsschutz', 'Rechtsschutz', 'Rechtsschutz', 20),
 ('versicherungen', 'motorfahrzeug', 'Motorfahrzeug', 'Motorfahrzeug', 30),
 ('versicherungen', 'gebaeude', 'Gebäude', 'Gebaeude', 40),
 ('versicherungen', 'leben_vorsorge', 'Leben & Vorsorge', 'Leben_Vorsorge', 50),
 ('versicherungen', 'reise', 'Reise', 'Reise', 60),
 ('versicherungen', 'sonstige', 'Sonstige', 'Sonstige', 90);
