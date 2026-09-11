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
| G-1 | 2026-09-10 | entschieden | Restumfang der Testfaelle uebertragen: K-07, I-01 (Laufstatus `already_processed`), I-04, P1-T-22 werden Abnahmebedingungen von Schritt 1.1; K-08 von Schritt 1.2; 1.0.8-A4, A7, A8 (TS-20) im Hauptablauf 1.1 |
| GATE-1.0 | 2026-09-10 | freigegeben | Phase-1.0-Gate freigegeben (Nachweis `docs/evidence/PHASE_1_0_GATE_2026-09-10.md`, Repo-Stand 515f051); damit Phase-0-Gate nach Spezifikation 7.3 geschlossen |
| TS-23 | 2026-09-10 | entschieden, umgesetzt | Kern-Subworkflows (`JV-CORE-SUB-*`) und Adapter (`JV-CORE-ADP-*`) werden veroeffentlicht; `JV-CORE-OPS-smoke_test-v1` bleibt unveroeffentlicht. Aenderungen wirken erst nach erneutem Veroeffentlichen; nach jeder Aenderung veroeffentlichen, danach Smoke-Test. Grund: In n8n 2.x sind unveroeffentlichte Entwuerfe fuer Elternworkflows nicht sichtbar (Befund 1.0.8, Lauf 22175). Umgesetzt 10.09.2026: neun SUB mit exakt den Repo-Versionen veroeffentlicht, Smoke-Test 22371 104/104 |
| PLAN-1.1 | 2026-09-10 | freigegeben | Freigabevorlage Schritt 1.1 (Ziel, Umfang, Voraussetzungen V-1 bis V-6, Arbeitsannahmen AA-1 bis AA-11, Abnahmekriterien 1.1-A1 bis 1.1-A21): `docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md` |
| 1.1-E1 | 2026-09-10 | entschieden | Speicher `arbeitgeber_visolva` gemaess ADR-001 SharePoint: Vertraege `storage_sharepoint.get_file`/`.move_file` als Nachtrag (`spec/phase-1/nachtrag-1.1/`), Spezifikationspaket 4.0.2 unveraendert; `storage_gdrive.get_file@1.1.0` nur `privat`, 1.0.0 wird nie freigegeben (umgesetzt als `deprecated`, Migration 0019) |
| 1.1-E2 | 2026-09-10 | entschieden | In 1.1 wird kein Original bewegt; `original_secured` = Hash gebildet und Dokumentdatensatz geschrieben; Verschieben in den Arbeitsbereich mit `move_file` in 1.4 |
| 1.1-E3 | 2026-09-10 | entschieden | Eingaenge ohne aufloesbaren Kontext (K-07) in eigener, inhaltsfreier, append-only Tabelle `jarvis_ops.intake_exception`; keine Aufgabe (K-07 und AR-1 gehen 10.4 vor) |
| 1.1-E4 | 2026-09-10 | entschieden | Laufzeitkonfiguration Eingang als Tabellen in `jarvis_ops` (`source_binding`, `context_document_settings`), erzeugt aus `config/intake_config.json` analog ADR-002; Ordner-IDs nur in n8n-Variablen (ADR-001). Verfuegbarkeit der Variablen (V-4) offen |
| 1.1-E5 | 2026-09-10 | entschieden | `JV-P1-MAIN-retry_dispatcher-v1` (Testplan 1.4.8) wird in 1.1 vorgezogen, allgemein ueber `action.next_attempt_at` und `retry_policy` |
| 1.1-E6 | 2026-09-10 | entschieden | Im Arbeitgebereingang nur Dokumente mit Synthetik-Kennzeichnung (Praefix `SYNTH_`, konfigurierbar); ohne Kennzeichnung Halt vor OCR, `needs_review` `context_unresolved`, Aufgabe, kein Kontextwechsel |
| TS-10b | 2026-09-10 | aufgenommen | Restschuld aus TS-10: Credential-Weiche je Kontext bleibt in den Workflows (n8n bindet das Credential je Knoten); neuer Kontext braucht dort weiterhin einen Zweig |
| TS-11 | 2026-09-10 | verschoben | `context_risk_override` bleibt leer bis Schritt 1.3 (Risikoklassifizierung produktiv) |
| TS10-E1 | 2026-09-11 | entschieden, umgesetzt | Umfang TS-10: Kontextlisten aus allen 12 Kern-Workflows entfernt (9 SUB, 3 ADP; Befund: Uebergabe nannte 9). `context_resolve` loest ueber `jarvis_ops.source_binding` und `context_registry` auf; alle anderen pruefen den Kontext nur im Format, die Kontextweiche (Switch) ist die einzige Kontextstelle und hat einen verbundenen Ausweichausgang (fail closed). Bewusste Abschwaechungen: `id_generate` nur Formatpruefung; Adapter-Probelauf ohne eigene Kontextpruefung (Absicherung durch `tool_invoke`) |
| TS10-E2 | 2026-09-11 | entschieden, umgesetzt | Lesezugriffe vor bekanntem Kontext laufen ueber `jv_privat_postgres` als Betriebs-Lesezugang, begrenzt auf die Konfigurationstabellen in `jarvis_ops` (Rechte seit 0016); gilt auch fuer Bindungsliste und K-07-Eintrag des Hauptablaufs |
| TS10-E3 | 2026-09-11 | entschieden, umgesetzt | TS-23 paketweise: je Paket jeder Workflow einzeln veroeffentlicht und `versionId` = `activeVersionId` geprueft, danach ein Smoke-Lauf (Paket 1: 22616, 105/105; Paket 2: 22715, 116/116) |
| TS-10 | 2026-09-11 | erledigt (Kern) | Kern-Workflows ohne Kontextwerte im Code (`tests/n8n/check_ts10.py`, Gegenprobe gegen d12f218: 23 Befunde in 12 Workflows). 1.1-A18 wird mit den P1-Workflows aus 1.1d in 1.1e abschliessend geprueft. Restschuld TS-10b |
| TS-26 | 2026-09-11 | aufgenommen | `jv_privat_postgres` als Betriebs-Lesezugang (TS10-E2): Aufloesung eines Visolva-Eingangs haengt am privat-Login. Vor dem Arbeitgeber-Pilot eigenen Betriebszugang pruefen |
