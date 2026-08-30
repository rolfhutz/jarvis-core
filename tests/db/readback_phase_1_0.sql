-- =====================================================================
-- JARVIS Phase 1.0 - Readback der Datenbankstruktur, Fassung fuer eine
-- einzelne SQL-Sitzung (Supabase MCP, SQL Editor, psql).
--
-- Inhaltsgleich mit tests/db/readback_phase_1_0.py: 39 Pruefungen in
-- sieben Abschnitten.
--
-- Grundsatz aus Entscheidung D3: Der Nachweis ist der unabhaengige
-- Readback aus dem Systemkatalog, nicht die Rueckmeldung der Migration.
--
-- Erwartet wird passed = true in jeder Zeile.
-- =====================================================================

WITH
-- 1. Schemata (3 Pruefungen) ------------------------------------------
s1 AS (
  SELECT 1 AS abschnitt, 'Schema ' || s AS pruefung,
         EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = s) AS passed,
         '' AS detail
    FROM unnest(ARRAY['jarvis_ops','jarvis_privat','jarvis_visolva']) s
),
-- 2. Tabellen (5 Pruefungen) ------------------------------------------
erwartet(schema, tabellen) AS (VALUES
  ('jarvis_ops',     ARRAY['workflow_run','tech_event','tool_circuit_state','contract_version','context_registry']),
  ('jarvis_privat',  ARRAY['event','task','action','action_lock','approval','evidence','error_event','action_log','memory_entry',
                           'document','case','case_identifier','document_text','document_extraction','document_analysis',
                           'case_number_seq','test_approval_record']),
  ('jarvis_visolva', ARRAY['event','task','action','action_lock','approval','evidence','error_event','action_log','memory_entry',
                           'document','case','case_identifier','document_text','document_extraction','document_analysis',
                           'case_number_seq','test_approval_record'])
),
vorhanden AS (
  SELECT schemaname::text AS schemaname, array_agg(tablename::text) AS tabellen FROM pg_tables
   WHERE schemaname IN ('jarvis_ops','jarvis_privat','jarvis_visolva') GROUP BY schemaname
),
s2 AS (
  SELECT 2, e.schema || ': ' || array_length(e.tabellen,1) || ' erwartete Tabellen vorhanden',
         e.tabellen <@ v.tabellen,
         'vorhanden: ' || array_length(v.tabellen,1) ||
         coalesce(', fehlt: ' || nullif(array_to_string(ARRAY(SELECT unnest(e.tabellen) EXCEPT SELECT unnest(v.tabellen)), ', '), ''), '')
    FROM erwartet e JOIN vorhanden v ON v.schemaname = e.schema
  UNION ALL
  -- Abschnitt 7.2: document_index geht in document auf.
  SELECT 2, s || ': document_index ist abgeloest',
         NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = s AND tablename = 'document_index'), ''
    FROM unnest(ARRAY['jarvis_privat','jarvis_visolva']) s
),
-- 3. Rollen (4 Pruefungen) --------------------------------------------
s3 AS (
  SELECT 3, 'Rolle ' || r || ' existiert',
         EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r), ''
    FROM unnest(ARRAY['jv_privat_user','jv_visolva_user']) r
  UNION ALL
  SELECT 3, 'Rolle ' || r || ' ohne Anmelderecht',
         EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r AND rolcanlogin = false), 'NOLOGIN'
    FROM unnest(ARRAY['jv_privat_user','jv_visolva_user']) r
),
-- 4. Pruefbedingungen der Kontexttrennung (2 Pruefungen) ---------------
bed AS (
  SELECT n.nspname::text AS schema, count(*) AS anzahl
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname IN ('jarvis_privat','jarvis_visolva') AND c.contype = 'c'
     AND pg_get_constraintdef(c.oid) LIKE '%context_id%'
     AND pg_get_constraintdef(c.oid) LIKE '%=%'
   GROUP BY n.nspname
),
s4 AS (
  SELECT 4, schema || ': Kontextbedingung auf ' || anzahl || ' Tabellen', anzahl >= 15, anzahl || ' Bedingungen'
    FROM bed
),
-- 5. Trigger (10 Pruefungen) ------------------------------------------
s5 AS (
  SELECT 5, x.schema || '.' || x.tg,
         EXISTS (SELECT 1 FROM pg_trigger tg JOIN pg_class c ON c.oid = tg.tgrelid
                   JOIN pg_namespace n ON n.oid = c.relnamespace
                  WHERE n.nspname = x.schema AND NOT tg.tgisinternal AND tg.tgname = x.tg), ''
    FROM (
      SELECT s AS schema, t AS tg FROM unnest(ARRAY['jarvis_privat','jarvis_visolva']) s
        CROSS JOIN unnest(ARRAY['action_log_deny_update','action_log_deny_delete','action_log_deny_truncate']) t
      UNION ALL
      SELECT 'jarvis_ops', t FROM unnest(ARRAY['workflow_run_guard','workflow_run_deny_delete',
                                               'tech_event_deny_update','tech_event_deny_delete']) t
    ) x
),
-- 6. Eindeutigkeitsindizes (12 Pruefungen) -----------------------------
s6 AS (
  SELECT 6, s || '.' || i,
         EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname = s AND indexname = i), ''
    FROM unnest(ARRAY['jarvis_privat','jarvis_visolva']) s
    CROSS JOIN unnest(ARRAY['action_idempotency_uq','event_idempotency_uq','task_idempotency_uq',
                            'document_content_hash_uq','case_number_uq','case_identifier_value_uq']) i
),
-- 7. Kontextregister (3 Pruefungen) ------------------------------------
s7 AS (
  SELECT 7, 'Zwei Kontexte registriert',
         (SELECT count(*) FROM jarvis_ops.context_registry) = 2,
         (SELECT count(*)::text || ' Eintraege' FROM jarvis_ops.context_registry)
  UNION ALL
  SELECT 7, 'Eintraege stimmen mit der Kontextkonfiguration ueberein',
         (SELECT count(*) FROM jarvis_ops.context_registry
           WHERE (context_id, db_schema, db_user, status) IN (
                 ('privat','jarvis_privat','jv_privat_user','active'),
                 ('arbeitgeber_visolva','jarvis_visolva','jv_visolva_user','active'))) = 2,
         (SELECT string_agg(context_id || '|' || db_schema || '|' || db_user || '|' || status, '  ' ORDER BY context_id)
            FROM jarvis_ops.context_registry)
  UNION ALL
  SELECT 7, 'Vertragsversionen registriert',
         (SELECT count(*) FROM jarvis_ops.contract_version) = 2,
         (SELECT string_agg(contract_id || ' ' || version, ', ' ORDER BY contract_id) FROM jarvis_ops.contract_version)
),
alle AS (
  SELECT * FROM s1 UNION ALL SELECT * FROM s2 UNION ALL SELECT * FROM s3
  UNION ALL SELECT * FROM s4 UNION ALL SELECT * FROM s5 UNION ALL SELECT * FROM s6 UNION ALL SELECT * FROM s7
)
SELECT abschnitt, pruefung, passed, left(detail, 90) AS detail
  FROM alle ORDER BY abschnitt, pruefung;
