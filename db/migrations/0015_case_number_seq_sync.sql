-- =====================================================================
-- JARVIS Phase 1.0 - Migration 0015 - Vorgangsnummern-Zaehler angleichen
--
-- Anlass: Befund B-1 vom 10.09.2026 (Schritt 1.0.8). Im Kontext privat
-- stand der Zaehler fuer 2026 auf 2, der synthetische Testvorgang vom
-- 30.08.2026 traegt aber bereits V-2026-0003. Jede Neuanlage zog damit
-- eine vergebene Nummer und scheiterte an case_number_uq.
--
-- Wirkung: Je Kontext und Jahr wird last_number auf die hoechste bereits
-- vergebene Nummer angehoben, niemals abgesenkt. Wiederholbar ohne
-- Nebenwirkung. Bestehende Vorgaenge bleiben unveraendert (TS-16 offen).
-- Freigegeben von Rolf am 10.09.2026.
-- =====================================================================

INSERT INTO jarvis_privat.case_number_seq (context_id, year, last_number, updated_at)
SELECT 'privat',
       substring(c.case_number FROM 3 FOR 4)::int,
       max(substring(c.case_number FROM 8 FOR 4)::int),
       now()
FROM jarvis_privat."case" c
GROUP BY substring(c.case_number FROM 3 FOR 4)
ON CONFLICT (context_id, year) DO UPDATE
    SET last_number = EXCLUDED.last_number,
        updated_at  = now()
    WHERE jarvis_privat.case_number_seq.last_number < EXCLUDED.last_number;

INSERT INTO jarvis_visolva.case_number_seq (context_id, year, last_number, updated_at)
SELECT 'arbeitgeber_visolva',
       substring(c.case_number FROM 3 FOR 4)::int,
       max(substring(c.case_number FROM 8 FOR 4)::int),
       now()
FROM jarvis_visolva."case" c
GROUP BY substring(c.case_number FROM 3 FOR 4)
ON CONFLICT (context_id, year) DO UPDATE
    SET last_number = EXCLUDED.last_number,
        updated_at  = now()
    WHERE jarvis_visolva.case_number_seq.last_number < EXCLUDED.last_number;

-- Selbstpruefung: kein Zaehler darf unter der hoechsten vergebenen Nummer liegen.
DO $$
DECLARE
    v_abweichung integer;
BEGIN
    SELECT count(*) INTO v_abweichung FROM (
        SELECT substring(c.case_number FROM 3 FOR 4)::int AS jahr, max(substring(c.case_number FROM 8 FOR 4)::int) AS hoechste
        FROM jarvis_privat."case" c GROUP BY 1
    ) h LEFT JOIN jarvis_privat.case_number_seq s ON s.context_id = 'privat' AND s.year = h.jahr
    WHERE coalesce(s.last_number, 0) < h.hoechste;
    IF v_abweichung > 0 THEN
        RAISE EXCEPTION 'case_number_seq_sync: Zaehler privat liegt weiterhin unter vergebener Nummer';
    END IF;
    SELECT count(*) INTO v_abweichung FROM (
        SELECT substring(c.case_number FROM 3 FOR 4)::int AS jahr, max(substring(c.case_number FROM 8 FOR 4)::int) AS hoechste
        FROM jarvis_visolva."case" c GROUP BY 1
    ) h LEFT JOIN jarvis_visolva.case_number_seq s ON s.context_id = 'arbeitgeber_visolva' AND s.year = h.jahr
    WHERE coalesce(s.last_number, 0) < h.hoechste;
    IF v_abweichung > 0 THEN
        RAISE EXCEPTION 'case_number_seq_sync: Zaehler arbeitgeber_visolva liegt weiterhin unter vergebener Nummer';
    END IF;
END $$;
