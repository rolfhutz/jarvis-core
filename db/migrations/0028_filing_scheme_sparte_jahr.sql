-- S1c: drittes Ablageschema 'sparte_jahr' = Kategorie / Sparte / Jahr.
-- Anlass: Rolf am 27.09.2026 - Steuern braucht eine Unterkategorie, das Jahr bleibt trotzdem fuehrend.
ALTER TABLE jarvis_privat.filing_rule DROP CONSTRAINT filing_rule_scheme_check;
ALTER TABLE jarvis_privat.filing_rule
  ADD CONSTRAINT filing_rule_scheme_check CHECK (scheme IN ('jahr', 'vertrag', 'sparte_jahr'));

COMMENT ON TABLE jarvis_privat.filing_rule IS
  'Ablageregel je Kategorie: Ordner unter dem Archiv und Schema (jahr = Kategorie/Jahr, sparte_jahr = Kategorie/Sparte/Jahr, vertrag = Kategorie/[Sparte]/Vertrag).';

UPDATE jarvis_privat.filing_rule
   SET scheme = 'sparte_jahr', updated_at = now()
 WHERE category_key = 'steuern';

-- Arbeitsannahme: Rolf ist Grenzgaenger (Wohnsitz Oesterreich, Arbeit Schweiz).
-- Erweiterbar ueber die Weboberflaeche, Deaktivieren statt Loeschen.
INSERT INTO jarvis_privat.filing_subcategory (category_key, sub_key, label_de, folder_name, sort_order, created_by) VALUES
 ('steuern', 'oesterreich', 'Österreich', 'Oesterreich', 10, 'migration'),
 ('steuern', 'schweiz',     'Schweiz',    'Schweiz',     20, 'migration'),
 ('steuern', 'sonstige',    'Sonstige',   'Sonstige',    90, 'migration');
