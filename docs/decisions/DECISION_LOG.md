# Decision Log

| ID | Datum | Status | Entscheidung |
|---|---|---|---|
| ADR-001 | 2026-08-29 | angenommen | Supabase Free; privat Google Drive; Arbeitgeber SharePoint; persoenliches GitHub-Repository |
| P1-O1 | 2026-08-30 | entschieden | PostgreSQL-Anbieter: Supabase Free fuer Phase 1.0 und den ersten Pilot. Wiederherstellungstest vor Pilotbeginn bleibt offen |
| P1-O7 | 2026-08-30 | entschieden | Git-Repository: privates GitHub-Repository `rolfhutz/jarvis-core` |
| E1 | 2026-08-31 | angenommen | Je Kontext ein Login-Benutzer, der die Rechte ausschliesslich ueber die Gruppenrolle erbt (Migration 0011) |
| E2 | 2026-08-31 | angenommen | Phase-0-Gate geschlossen (A-3, A-4 aus n8n nachgewiesen) |
| P1-O1 | 2026-09-10 | bestaetigt | Supabase foermlich als PostgreSQL-Anbieter bestaetigt; Betriebsauflagen Keep-Alive, Sicherung, gekapselter Adapter |
| P1-O5 | 2026-09-10 | entschieden | Eingangskanal Phase 1: `privat` Google-Drive-Eingangsordner; `arbeitgeber_visolva` SharePoint gemaess ADR-001 (nur synthetische Testdokumente); E-Mail-Anhaenge und API spaeter |
| P1-O7 | 2026-09-10 | praezisiert | Repo-Aenderungen werden per Claude Code als Pull Request eingebracht und von Rolf gemergt |
| ADR-002 | 2026-09-10 | angenommen | Werkzeugregister zur Laufzeit als Tabelle `jarvis_ops.tool_registry` (Variante A) |
| ADR-003 | 2026-09-10 | angenommen | Kein Freitext ueber `queryReplacement`; Freitext als base64-JSON-Block |
| BETR-1 | 2026-09-10 | umgesetzt | Keep-Alive `JV-CORE-OPS-db_keepalive-v1` produktiv (taeglich 05:00 UTC) nach Pausierung des Supabase-Projekts |
| OFFEN-1 | 2026-09-10 | offen | Repository vorlaeufig oeffentlich (Rolf); spaetestens vor Pilotstart wieder privat |
| E-1 | 2026-09-10 | angenommen | `tool_invoke` leitet per Verteiler (Switch auf `adapter_id` aus dem Register) an je einen festen Aufrufknoten weiter; unbekannte `adapter_id` → `adapter_unknown`; neuer Adapter = versionierte Aenderung an `tool_invoke` |
| E-2 | 2026-09-10 | angenommen | `evidence_verify` speichert jeden echten Abgleich (`verified`, `mismatch`) in `<kontext>.evidence` und gibt `evidence_id` zurueck; scheitert die Ablage, gilt der Nachweis als nicht erbracht (`evidence_store_failed`); Freigabeverweis = `evidence_id` |
| A-6 | 2026-09-10 | angenommen | Freigabelauf ruft die Adapter direkt aus dem Smoke-Test auf (Bedingung 3 vor 5); `tool_invoke` bleibt streng; Adapter nur von `tool_invoke` und Smoke-Test aufrufbar (`callerPolicy`) |
| A-7 | 2026-09-10 | angenommen | Vertragsverstoesse des Aufrufers (`readback_required`, `method_not_accepted`, `contract_unknown`, `expected_empty`) erzeugen keine Nachweiszeile |
| 0015 | 2026-09-10 | umgesetzt | Vorgangsnummern-Zaehler je Kontext und Jahr auf hoechste vergebene Nummer angehoben (Befund B-1). Hinweis: vor Ablage im Repo in Supabase eingespielt; Repo-Datei nachtraeglich abgelegt und inhaltsgleich geprueft |
| REL-1 | 2026-09-10 | umgesetzt | Freigabe `casestore_internal.upsert_case`, `docstore_internal.upsert_document`, `tasks_internal.create_task` (je 1.0.0) nach Spezifikation 12.1.1; Nachweis Lauf 22087, je zwei `evidence_id` in `tool_release_log` |
