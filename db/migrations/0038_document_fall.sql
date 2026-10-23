-- 0038_document_fall
-- CR-09 (01.10.2026, freigegeben von Rolf: 1C, alle Fälle, 3B, Fristwarnung ja)
-- Fall-Katalog für die Weboberfläche Dokumente: legt je Upload fest, was mit dem Dokument geschieht.
-- K9: Ein neuer Fall ist ein Eintrag in dieser Tabelle plus Vorlage (entwurf_regeln), kein Umbau der Workflows.
-- Rein additiv. Workflows lesen nur (SELECT für jv_privat_user).

CREATE TABLE IF NOT EXISTS jarvis_privat.document_fall (
  fall_key                text        NOT NULL PRIMARY KEY,
  context_id              text        NOT NULL DEFAULT 'privat',
  label_de                text        NOT NULL,
  kurzinfo_de             text,
  gruppe                  text        NOT NULL,
  analyse_tiefe           text        NOT NULL,
  hinweis_platzhalter     text,
  hinweis_pflicht         boolean     NOT NULL DEFAULT false,
  titel_vorlage           text,
  auftrag_satz            text,
  entwurf_regeln          text,
  betreff_muster          text,
  adresse_zweck           text,
  termin_label            text,
  termin_standard         text,
  empfaenger_ist_absender boolean     NOT NULL DEFAULT true,
  mit_anhang              boolean     NOT NULL DEFAULT false,
  sort_order              integer     NOT NULL DEFAULT 100,
  active                  boolean     NOT NULL DEFAULT true,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT document_fall_context_chk CHECK (context_id = 'privat'),
  CONSTRAINT document_fall_key_chk CHECK (fall_key ~ '^[a-z][a-z_]{2,29}$'),
  CONSTRAINT document_fall_gruppe_chk CHECK (gruppe IN ('ablage', 'analyse', 'entwurf', 'aufgabe')),
  CONSTRAINT document_fall_tiefe_chk CHECK (analyse_tiefe IN ('kurz', 'voll')),
  CONSTRAINT document_fall_entwurf_chk CHECK (gruppe <> 'entwurf' OR (titel_vorlage IS NOT NULL AND auftrag_satz IS NOT NULL AND entwurf_regeln IS NOT NULL)),
  CONSTRAINT document_fall_aufgabe_chk CHECK (gruppe <> 'aufgabe' OR titel_vorlage IS NOT NULL)
);

COMMENT ON TABLE jarvis_privat.document_fall IS 'CR-09: Fall-Katalog der Weboberfläche Dokumente (was mit einem Dokument geschieht). Ablage läuft immer (K2); Aussenwirkung nur als Entwurf (K6).';

INSERT INTO jarvis_privat.document_fall
  (fall_key, label_de, kurzinfo_de, gruppe, analyse_tiefe, hinweis_platzhalter, hinweis_pflicht, titel_vorlage, auftrag_satz, entwurf_regeln, betreff_muster, adresse_zweck, termin_label, termin_standard, empfaenger_ist_absender, mit_anhang, sort_order)
VALUES
('ablegen', 'Nur ablegen', 'Erkennen, benennen, ablegen – ohne Aufgaben.', 'ablage', 'kurz',
  NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, false, 10),

('altbestand', 'Altbestand', 'Aus der alten Ablage überführen – ohne Fristen und Aufgaben. Ist der Ordner bekannt, legt JARVIS sofort ab.', 'ablage', 'kurz',
  NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, false, 20),

('detailanalyse', 'Detailanalyse', 'Fristen, Beträge, Risiken und Aufgabenvorschläge.', 'analyse', 'voll',
  NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, false, 30),

('kuendigen', 'Kündigen', 'Kündigungsentwurf im Outlook, Versand durch dich.', 'entwurf', 'voll',
  'Grund und Hinweise (optional), z. B. Grund: Umzug in ein anderes Land; Kündigung zum 31.12.', false,
  'Kündigung {name} versenden',
  'den Vertrag aus dem beigefügten Dokument zu kündigen',
$r$K1. empfaenger_email: nur eine im Dokument genannte E-Mail-Adresse des Vertragspartners (Kundendienst, Kündigungen, Agentur, Berater).
K2. termin (Kündigungstermin): Nennt Rolf im Hinweis einen Termin, verwende ihn. Sonst leite ihn nur ab, wenn Vertragsablauf oder Kündigungsfrist im Dokument stehen, und gib den Beleg in termin_beleg an. Sonst kündige auf den nächstmöglichen Termin und setze termin auf null.
K3. spaetester_versand: nur berechnen, wenn Kündigungstermin und Kündigungsfrist feststehen (Datum JJJJ-MM-TT), sonst null.
K4. formvorschrift: Verlangt das Dokument Schriftform, Unterschrift oder eingeschriebenen Brief für Kündigungen, setze schriftlich bzw. eingeschrieben und gib den Beleg an. Sonst keine_angabe.
K5. text: Aufbau: Anrede, klare Kündigungserklärung mit Vertrags- oder Policennummer und Versicherungsnehmer, Termin, Bitte um schriftliche Bestätigung der Kündigung mit Beendigungsdatum, Grussformel. Nennt Rolf im Hinweis einen Grund, nenne ihn in einem kurzen Satz; sonst keine Begründung.
K6. betreff: enthält das Wort Kündigung und die Vertrags- oder Policennummer, falls vorhanden.
K7. machbar = false nur, wenn im Dokument kein kündbarer Vertrag erkennbar ist; dann grund angeben.
K8. hinweise: z. B. Bindung, Mindestlaufzeit, Folgen der Kündigung, falls im Dokument genannt.$r$,
  'k[üu]ndigung', 'die Kündigung eines Vertrags', 'Kündigung zum', 'nächstmöglicher Termin', true, false, 40),

('adressaenderung', 'Adressänderung', 'Neue Anschrift mitteilen, Entwurf im Outlook.', 'entwurf', 'voll',
  'Hinweise (optional), z. B. gültig ab 01.11.2026', false,
  'Adressänderung an {name} senden',
  'dem Absender des beigefügten Dokuments Rolfs neue Anschrift mitzuteilen',
$r$A1. Die neue Anschrift ist die unten angegebene aktuelle Anschrift von Rolf. Ist keine aktuelle Anschrift angegeben, setze machbar = false und grund «Aktuelle Anschrift von Rolf ist nicht hinterlegt».
A2. Nenne zur Zuordnung die Kunden-, Vertrags- oder Policennummer und die bisherige Anschrift, wie sie im Dokument steht.
A3. termin: Datum, ab dem die neue Anschrift gilt (JJJJ-MM-TT), nur wenn Rolf es im Hinweis nennt; sonst null und im Text «ab sofort».
A4. Bitte um eine kurze Bestätigung der Änderung. Weitere Änderungen nur, wenn Rolf sie im Hinweis verlangt.
A5. betreff: enthält «Adressänderung» und die Bezugsnummer, falls vorhanden.
A6. hinweise: z. B. wenn das Dokument Folgen eines Wohnsitzwechsels (etwa ins Ausland) für den Vertrag nennt.$r$,
  'adress', 'eine Adressänderung (Änderung der Kundendaten)', 'Gültig ab', 'sofort', true, false, 50),

('widerspruch', 'Widerspruch / Reklamation', 'Bescheid oder Rechnung anfechten, Entwurf im Outlook.', 'entwurf', 'voll',
  'Was ist falsch und was soll geschehen? z. B. Betrag doppelt verrechnet, bitte Gutschrift', false,
  'Widerspruch an {name} senden',
  'gegen das beigefügte Dokument (Bescheid, Rechnung, Entscheid oder Abrechnung) Widerspruch einzulegen bzw. es zu reklamieren',
$r$W1. Beziehe dich eindeutig auf das Dokument: Art, Datum und Aktenzeichen bzw. Rechnungs-, Kunden- oder Policennummer.
W2. Begründung nur aus dem Hinweis von Rolf und aus Tatsachen, die im Dokument stehen. Ohne Hinweis von Rolf: Widerspruch fristwahrend einlegen und die Begründung als [bitte ergänzen: Begründung] vorsehen.
W3. Formuliere klar, was Rolf verlangt (z. B. Korrektur, Gutschrift, Überprüfung, Aufhebung); fehlt das, als [bitte ergänzen: Forderung].
W4. spaetester_versand: Widerspruchs-, Einspruchs- oder Reklamationsfrist aus dem Dokument (JJJJ-MM-TT), Beleg in hinweise; sonst null.
W5. formvorschrift: Verlangt das Dokument Schriftform, Unterschrift oder eingeschriebenen Brief, setze schriftlich bzw. eingeschrieben mit Beleg. Sonst keine_angabe.
W6. betreff: enthält «Widerspruch» oder «Reklamation» und die Bezugsnummer.
W7. Sachlich, ohne Vorwürfe und ohne rechtliche Würdigung, die nicht im Dokument steht.$r$,
  '(widerspruch|reklamation|einspruch|einsprache|beanstandung)', 'einen Widerspruch oder eine Reklamation', NULL, NULL, true, false, 60),

('antworten', 'Antworten', 'Antwort an den Absender, Entwurf im Outlook.', 'entwurf', 'voll',
  'Was soll die Antwort enthalten? z. B. Termin bestätigen; Unterlagen folgen bis Monatsende', false,
  'Antwort an {name} senden',
  'auf das beigefügte Schreiben zu antworten',
$r$R1. Antworte mit genau dem Inhalt, den Rolf im Hinweis vorgibt. Ohne Hinweis: kurze Empfangsbestätigung und [bitte ergänzen: Antwort].
R2. Nenne Datum und Bezugsnummer des Schreibens.
R3. Beantworte Fragen aus dem Dokument nur, soweit Rolf die Antwort im Hinweis gibt; offene Fragen unter fehlende_angaben nennen.
R4. betreff: Thema des Schreibens und Bezugsnummer, z. B. «Ihr Schreiben vom 26.01.2026 – Polizze 800/1234».
R5. spaetester_versand: Antwortfrist aus dem Dokument (JJJJ-MM-TT), sonst null.$r$,
  NULL, 'eine Antwort an den Kundendienst', NULL, NULL, true, false, 70),

('zahlen', 'Zahlen', 'Aufgabe mit Betrag, Empfänger und Frist – JARVIS zahlt nicht selbst.', 'aufgabe', 'voll',
  'Hinweis (optional)', false,
  'Rechnung {name} bezahlen',
  NULL, NULL, NULL, NULL, NULL, NULL, true, false, 80),

('einreichen', 'Einreichen / Weiterleiten', 'Dokument mit Anhang an eine andere Stelle senden, z. B. an die Krankenkasse.', 'entwurf', 'voll',
  'An wen und wozu? z. B. an SWICA zur Rückerstattung, Versichertennummer 123.456', true,
  '{dokument} einreichen',
  'das beigefügte Dokument an eine andere Stelle einzureichen oder weiterzuleiten; das Dokument wird der E-Mail als Anhang beigefügt',
$r$E1. Das beigefügte Dokument liegt der E-Mail als Anhang bei. Erwähne den Anhang im Text.
E2. Empfänger, Zweck und Rolfs Nummer beim Empfänger (z. B. Versichertennummer) stehen im Hinweis von Rolf. Nennt der Hinweis keinen Empfänger, setze machbar = false und grund «Empfänger fehlt im Hinweis».
E3. empfaenger_name ist der Empfänger aus dem Hinweis, nicht der Absender des Dokuments. empfaenger_email nur, wenn Rolf sie im Hinweis nennt.
E4. Nenne im Text, was eingereicht wird (Dokumentart, Aussteller, Datum, Betrag, betroffene Person) und was Rolf möchte (z. B. Rückerstattung, Kenntnisnahme). Fehlt Rolfs Nummer beim Empfänger, [bitte ergänzen: Versicherten- bzw. Kundennummer].
E5. betreff: Zweck und Dokument, z. B. «Rückforderungsbeleg Laborrechnung vom 26.01.2026».
E6. spaetester_versand: nur eine im Dokument oder Hinweis genannte Einreichungsfrist (JJJJ-MM-TT), sonst null.$r$,
  NULL, 'die Einreichung von Belegen (z. B. zur Rückerstattung)', NULL, NULL, false, true, 90)
ON CONFLICT (fall_key) DO NOTHING;

GRANT SELECT ON jarvis_privat.document_fall TO jv_privat_user;
