# ADR-003: Parameteruebergabe an PostgreSQL aus n8n

- Status: angenommen
- Datum: 10. September 2026
- Grundlage: Befund Smoke-Test, Ausfuehrung 21865

## Befund

Der n8n-Postgres-Knoten (`executeQuery`, Option `queryReplacement`) erhaelt
seine Werte als kommagetrennte Liste. Im Test zeigte sich:

1. Ein Text mit Komma wird am Komma zerlegt. Alle folgenden Werte verrutschen
   in falsche Spalten. Das faellt nur auf, wenn eine Spalte den falschen Typ
   zufaellig ablehnt; sonst entstehen unbemerkt falsche Daten.
2. Ein leerer Wert (`null`) kommt als Text `"null"` an.

## Regel (verbindlich fuer alle JARVIS-Workflows)

1. **Kein Freitext ueber `queryReplacement`.** Erlaubt sind dort nur Werte mit
   festem Muster ohne Komma: Kennungen (`act_...`, `tool_id`, Version,
   `context_id`), Hashwerte, Zahlen.
2. **Freitext, JSON und moeglicherweise leere Werte** werden als genau ein
   base64-kodierter JSON-Block uebergeben und in der Datenbank entpackt:

   ```sql
   INSERT INTO <schema>.<tabelle> (...)
   SELECT r.* FROM jsonb_to_record(
       convert_from(decode($1, 'base64'), 'UTF8')::jsonb
   ) AS r(<spalte> <typ>, ...);
   ```

   Der Block wird im vorgelagerten Code-Knoten mit
   `Buffer.from(JSON.stringify(zeile), 'utf8').toString('base64')` gebildet.
3. Jeder neue Workflow mit Datenbankschreibzugriff wird im Smoke-Test mit einem
   Text geprueft, der Kommas, Umlaute und einen leeren Wert enthaelt.

## Betroffen und behoben

`fach_log_write`, `tech_log_write`, `error_handler`. Die Registerabfragen in
`action_classify`, `tool_invoke`, `evidence_verify` und die Sperre in
`idempotency_guard` uebergeben nur Kennungen und fallen unter Regel 1.

Ergaenzt die n8n-Konventionen aus dem Phase-0-Paket, ohne das freigegebene
Spezifikationspaket zu veraendern.
