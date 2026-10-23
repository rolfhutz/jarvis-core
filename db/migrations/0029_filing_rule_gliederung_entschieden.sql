-- S1c (Rolf 27.09.2026, Variante A): einmalige Klick-Entscheidung je Kategorie, wie gegliedert wird.
ALTER TABLE jarvis_privat.filing_rule
  ADD COLUMN gliederung_entschieden boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN jarvis_privat.filing_rule.gliederung_entschieden IS
  'true = Gliederung von Rolf festgelegt; false = Oberflaeche fragt beim naechsten Dokument einmal nach (nur Jahr oder Unterkategorie und Jahr).';
UPDATE jarvis_privat.filing_rule SET gliederung_entschieden = true WHERE scheme IN ('vertrag', 'sparte_jahr');
