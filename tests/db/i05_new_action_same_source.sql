-- =====================================================================
-- JARVIS Phase 1.0 - Testfall I-05 (Phase-0-Matrix)
-- "Fachlich neue Aktion aus derselben Quelle: neuer Schluessel, neue Aktion,
--  keine Blockade."  Gegenprobe: gleicher Schluessel wird abgewiesen (I-01).
--
-- Laeuft als Administrator, schreibt aber als jv_privat_user (SET LOCAL ROLE).
-- Endet IMMER mit RAISE EXCEPTION: Die Meldung ist das Ergebnis, alle
-- Schreibvorgaenge werden dadurch zurueckgerollt. Es bleibt nichts im Bestand.
-- Vorlage fuer Pflichtfelder ist eine vorhandene Smoke-Aktion (trc_smoke_).
--
-- Erwartete Meldung:
--   I05_ERGEBNIS rolle=jv_privat_user schluessel_verschieden=t
--   aktionen_aus_quelle=2 gleicher_schluessel=abgewiesen: ... action_idempotency_uq
-- Ausgefuehrt am 10.09.2026 gegen Supabase (MCP): Ergebnis wie erwartet,
-- Nachkontrolle: 0 Zeilen act_I05PROBE% im Bestand.
-- =====================================================================
DO $$
DECLARE
  t jarvis_privat.action%ROWTYPE;
  k1 text := encode(sha256(convert_to('privat|action|trc_i05_probe|quelle_evt_1|aufgabe_a','UTF8')),'hex');
  k2 text := encode(sha256(convert_to('privat|action|trc_i05_probe|quelle_evt_1|aufgabe_b','UTF8')),'hex');
  n_neu int; dup text := 'nein';
BEGIN
  SELECT * INTO STRICT t FROM jarvis_privat.action
   WHERE action_id LIKE 'act_smoke_%' ORDER BY created_at DESC LIMIT 1;
  SET LOCAL ROLE jv_privat_user;
  t.action_id := 'act_I05PROBE0000000000000000A'; t.idempotency_key := k1;
  t.body := jsonb_build_object('trace', jsonb_build_object('trace_id','trc_i05_probe'), 'source_event','quelle_evt_1');
  INSERT INTO jarvis_privat.action SELECT t.*;
  t.action_id := 'act_I05PROBE0000000000000000B'; t.idempotency_key := k2;
  INSERT INTO jarvis_privat.action SELECT t.*;
  BEGIN
    t.action_id := 'act_I05PROBE0000000000000000C'; t.idempotency_key := k1;
    INSERT INTO jarvis_privat.action SELECT t.*;
  EXCEPTION WHEN unique_violation THEN dup := 'abgewiesen: ' || SQLERRM;
  END;
  SELECT count(*) INTO n_neu FROM jarvis_privat.action WHERE body->>'source_event' = 'quelle_evt_1';
  RAISE EXCEPTION 'I05_ERGEBNIS rolle=% schluessel_verschieden=% aktionen_aus_quelle=% gleicher_schluessel=%',
    current_user, (k1 <> k2), n_neu, dup;
END $$;

-- Nachkontrolle (separat ausfuehren, erwartet 0):
-- SELECT count(*) FROM jarvis_privat.action WHERE action_id LIKE 'act_I05PROBE%';
