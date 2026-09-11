# HANDOVER_PHASE_1_1A_2026-09-10

**Modul:** Phase 1, Schritt 1.1 (Eingang und Normalisierung): Vorbereitung und Bauabschnitt 1.1a
**Stand:** 10. September 2026, spätabends
**Status:** Freigabevorlage 1.1 von Rolf freigegeben. 1.1a (Datenbank, Konfiguration, Registernachtrag, TS-24) im Repo (`main` d12f218, PR #9) und **produktiv in Supabase**. n8n unverändert. **Rest von 1.1a offen:** Kontextliste und Bindungen in den Workflows aus der Datenbank lesen (TS-10).
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_0_GATE_2026-09-10.md`
**Verbindliche Vorlage für 1.1:** `docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md` (Ziel, Umfang, V-1 bis V-6, AA-1 bis AA-11, Abnahmekriterien 1.1-A1 bis 1.1-A21)

> **Nicht im Repo:** diese Übergabe und `docs/evidence/PHASE_1_1A_SUPABASE_2026-09-10.md`. Beide gehen mit dem
> nächsten PR ins Repo (Archiv `jarvis-phase-1-1a-abschluss.zip`, drei Dateien, einschliesslich README-Korrektur).

---

## 1. Ziel des Moduls

Schritt 1.1 so vorbereiten, dass ohne offene Grundsatzfragen gebaut werden kann, und die Datenbasis dafür
schaffen: Laufzeitkonfiguration je Kontext, Ausnahmeliste ohne Kontext (K-07), SharePoint-Verträge nach
ADR-001, Erhalt von `binaryMode` im Export (TS-24).

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus den Vorübergaben (u. a. E-1, E-2, A-6, A-7, 0015, REL-1, G-1, GATE-1.0, TS-23).

Neu am 10.09.2026, von Rolf freigegeben (im DECISION_LOG auf `main`):

| ID | Entscheidung |
|---|---|
| PLAN-1.1 | Freigabevorlage Schritt 1.1 vollständig freigegeben |
| 1.1-E1 | Arbeitgeberspeicher SharePoint (ADR-001); Nachtrag `spec/phase-1/nachtrag-1.1/`; `storage_gdrive.get_file@1.1.0` nur `privat`; 1.0.0 nie freigegeben |
| 1.1-E2 | In 1.1 wird kein Original bewegt; `original_secured` = Hash + Datensatz; Verschieben erst 1.4 |
| 1.1-E3 | K-07 in eigener append-only Tabelle `jarvis_ops.intake_exception`, keine Aufgabe |
| 1.1-E4 | Laufzeitkonfiguration in `jarvis_ops` aus `config/intake_config.json`; Ordner-IDs nur in n8n-Variablen |
| 1.1-E5 | `JV-P1-MAIN-retry_dispatcher-v1` in 1.1 vorgezogen |
| 1.1-E6 | Arbeitgebereingang nur mit Präfix `SYNTH_`; sonst Halt vor OCR, `needs_review` `context_unresolved`, Aufgabe |
| TS-10b | Credential-Weiche je Kontext bleibt (n8n bindet Credential je Knoten) |
| TS-11 | `context_risk_override` bleibt leer bis 1.3 |

Umsetzungsentscheidungen in 1.1a (innerhalb der Freigabe, zur Kenntnis):

| Nr. | Umsetzung | Grund |
|---|---|---|
| U-1 | `storage_gdrive.get_file@1.0.0` auf `deprecated` (Migration 0019, Verweis 1.1-E1) | setzt „nie freigegeben“ technisch durch; `deprecated` ist endgültig |
| U-2 | Anhalten einer Bindung per Trigger mit Fehlermeldung, keine Zeilenregel | Zeilenregeln hätten fremde Bindungen still ausgeblendet |
| U-3 | OCR-Positivliste je Kontext leer | fail closed bis P1-O3 |
| U-4 | K-07-Probe (`purpose: probe`) nicht in der Grundkonfiguration; für den Nachweis als eigene Konfigurationsversion ergänzen, danach entfernen | kein Prüfeingang im Dauerbetrieb |
| U-5 | Registerrenderer mit Sätzen `0014` (bytegleich) und `0018`; Schemaverweisprüfung nur im Satz `0018` | Bestand im Phase-0-Register verweist auf nicht vorhandene Schemata von Nicht-Phase-1-Werkzeugen |

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| Migration 0016: `context_document_settings`, `source_binding`, `intake_exception`, Funktion `current_context_id()`, Trigger `guard_source_binding_update` | produktiv, getestet |
| Migration 0017: Eingangskonfiguration 1.0.0 (erzeugt) | produktiv, Selbstprüfung bestanden |
| Migration 0018: Registernachtrag, 3 Werkzeuge `draft` (erzeugt) | produktiv, Prüfwerte von der DB nachgerechnet |
| Migration 0019: `storage_gdrive.get_file@1.0.0` → `deprecated` | produktiv, im `tool_release_log` |
| `tools/render_intake_config.py` (Regeln K1–K8) | im Repo, Selbsttest bestanden |
| `tools/render_tool_registry.py` (`--set`) | im Repo, Selbsttest bestanden, 0014 bytegleich |
| TS-24: `normalize_n8n_export.py`, `check_restore.py` | im Repo, Selbsttest bestanden; Wirkung erst mit erstem Binär-Workflow belegbar |
| `tests/db/p1_1a_runtime_config.sql` | im Repo, lokal und gegen Supabase 21/21 |

**Nicht umgesetzt:** jede n8n-Änderung, Speicher- und OCR-Adapter, Hauptablauf, Dispatcher.

## 4. Dateien und Workflow-Namen

Mit PR #9 auf `main` (24 Dateien): `config/intake_config.json`, `config/schemas/intake_config.schema.json`,
`db/migrations/0016`–`0019`, `spec/phase-1/nachtrag-1.1/` (README, Register, vier SharePoint-Schemata),
`tools/render_intake_config.py`, `tools/render_tool_registry.py`, `tools/normalize_n8n_export.py`,
`tests/n8n/check_restore.py`, `tests/db/p1_1a_runtime_config.sql`, `docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md`,
`docs/evidence/PHASE_1_1A_ENTWURF_LOKALTEST_2026-09-10.md`, DECISION_LOG, READMEs.

Mit dem nächsten PR: diese Übergabe, `docs/evidence/PHASE_1_1A_SUPABASE_2026-09-10.md`, README (Stand „eingespielt“).

Workflows unverändert, IDs in `n8n/core/MANIFEST.md`. Keine neuen Credentials.

## 5. Datenmodelle und Schnittstellen

**`jarvis_ops.context_document_settings`** (PK `context_id`): Speicheradapter, `storage_container_ref`, fünf
Ordner-Verweise `env:JV_*` (paarweise verschieden), erlaubte MIME-Typen, `max_file_size_mb`,
`ocr_provider_allowlist`, `ocr_min_characters` 200, `ocr_min_mean_confidence` 0.600, `fingerprint_max_hamming` 6
(Startwert), Synthetik-Pflicht und Präfix, Haltregel 5 / 60 min. Kontextbenutzer: nur `SELECT`.

**`jarvis_ops.source_binding`** (PK `binding_key`): Kontext, Adapter, Kanal, `location_ref`, `purpose`
(`intake`/`probe`), `enabled`, Laufzeitzustand `halted_at`/`halt_reason`/`halted_by`. Eindeutig: (Adapter, Ort)
für `intake`. Kontextbenutzer: `SELECT` auf alle Zeilen, `UPDATE` nur der drei Haltspalten, nur eigener Kontext,
nur anhalten (`binding_foreign_context`, `binding_halt_final`, `binding_update_denied`). Aufheben nur Administrator.
Bestand: `privat_drive_inbox` (storage_gdrive, `env:JV_PRIVAT_INBOX_FOLDER_ID`), `visolva_sharepoint_inbox`
(storage_sharepoint, `env:JV_VISOLVA_INBOX_FOLDER_ID`).

**`jarvis_ops.intake_exception`**: append-only; `adapter_id`, `location_ref`, `source_external_id`
(Muster ohne Leerzeichen), `reason_code` (`binding_ambiguous` mit ≥ 2 `candidate_contexts`, `context_not_active`,
`binding_unknown`), `trace_id`. Eindeutig je (Adapter, Ort, Datei-ID, Grund); Einfügen mit `ON CONFLICT DO NOTHING`.

**`jarvis_ops.current_context_id()`**: Kontext des aktuellen Benutzers über `pg_has_role(…, 'USAGE')`,
Administrator und Superuser → `NULL`.

**n8n-Variablen (noch anzulegen, V-4):** `JV_PRIVAT_{INBOX,WORKING,DRAFTS,REPORTS}_FOLDER_ID`,
`JV_PRIVAT_ARCHIVE_ROOT_ID`, entsprechend `JV_VISOLVA_*`, `JV_VISOLVA_SP_DRIVE_ID`; für den K-07-Nachweis
`JV_K07_PROBE_FOLDER_ID`.

**Register:** `storage_gdrive.get_file@1.1.0` (privat), `storage_sharepoint.get_file@1.0.0` und
`.move_file@1.0.0` (arbeitgeber_visolva), alle `draft`. Gesamt 3 `approved`, 13 `draft`, 1 `deprecated`.

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| Renderer Register: Selbsttest, `--check 0014`, `--set 0018 --check` | bestanden, 0014 bytegleich | lokal und auf PR-Stand |
| Renderer Konfiguration: Selbsttest (8 Gegenproben), `--check 0017` | bestanden | lokal und auf PR-Stand |
| Normalisierer-Selbsttest | 5 Prüfungen, 2 Gegenproben | lokal und auf PR-Stand |
| PR #9 gegen Archiv | 24/24 byteidentisch, keine ZIP, Basis a0d7229 | Chat |
| 0001–0019 in leere lokale DB (PG 16), 0017–0019 doppelt | fehlerfrei | `PHASE_1_1A_ENTWURF_LOKALTEST_2026-09-10.md` |
| Regression 1.0-Abnahme lokal | 23/23 | ebenda |
| Prüfskript 1.1a lokal / **gegen Supabase** | **21/21 / 21/21**, zurückgerollt | `PHASE_1_1A_SUPABASE_2026-09-10.md` |
| Smoke-Test nach Einspielen | **104/104**, Ausführung **22498** | ebenda |

**Nicht getestet:** Zugriff über `jv_*_login` und Session Pooler auf die neuen Tabellen.

## 7. Bekannte Fehler

Keine offenen. Befunde:

1. `evidence_verify` prüft den Registerstatus nicht; ein Nachweis gegen eine `deprecated`-Version ist möglich. Smoke-Fälle E03/E04 nutzen noch `storage_gdrive.get_file@1.0.0`; bei der nächsten Smoke-Änderung auf 1.1.0 umstellen.
2. **Umfang TS-10 grösser als angenommen:** Neun Kern-Subworkflows führen Kontextlisten im Code: `action_classify`, `context_resolve`, `error_handler`, `evidence_verify`, `fach_log_write`, `id_generate`, `idempotency_guard`, `tech_log_write`, `tool_invoke`. Abnahme 1.1-A18 verlangt 0 (ausser Credential-Weiche, TS-10b). Jede Änderung braucht den TS-23-Zyklus.
3. README auf `main` meldet 1.1a noch als „nicht eingespielt“; Korrektur im nächsten PR.

## 8. Technische Schulden

Weiter offen: P1-TD1, TS-10 (in Arbeit), TS-10b, TS-11 (→ 1.3), TS-12, TS-13, TS-16, TS-17 (Aufnahme unbestätigt),
TS-18 (Vorgangsnummern jetzt privat bis **V-2026-0009**, visolva bis **V-2026-0006**), TS-19, TS-20, TS-21, TS-22, OFFEN-1.
**Erledigt im Repo:** TS-24 (Nachweis der Wirkung mit erstem Binär-Workflow in 1.1b/1.1d).

| Nr. | Schuld | Wann |
|---|---|---|
| TS-25 | Erledigung von Einträgen in `intake_exception` nicht abgebildet. **Aufnahme durch Rolf noch nicht bestätigt** | 1.4 (Tagesbericht) |

## 9. Offene Entscheidungen und Voraussetzungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| V-4 | n8n-Variablen verfügbar (Settings → Variables)? Sonst Ausweichlösung vorlegen (Abweichung ADR-001) | vor 1.1b |
| V-1 | privates Google-Konto für `privat` benennen; Credential `jv_privat_gdrive`. **Nicht** `Google Drive rolf@visolva.com` | vor 1.1b |
| V-2, V-3, V-5, V-6 | Ordner, SharePoint-Testbibliothek, OCR-Zugänge, Testdokumente (Vorlage Abschnitt 3) | vor 1.1b / 1.1c |
| TS-10-Umfang | Befund 7.2: alle neun Workflows umbauen oder Umfang begrenzen | vor dem Bau des 1.1a-Rests |
| TS-25, TS-17 | Aufnahme bestätigen | vor 1.4 / 1.3 |
| P1-O3 | OCR-Dienst | Ende 1.1 |
| P1-O2, P1-O10 | wie Vorübergabe | vor 1.3 |
| P1-O4, P1-O6, P1-O8, P1-O9, P1-TD1, OFFEN-1 | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

**Rest von 1.1a: Kontextliste und Bindungen aus der Datenbank (TS-10), neuer Chat.**

1. Vor dem Bau Rolf vorlegen: Umfang TS-10 nach Befund 7.2 (Empfehlung mit Begründung: welche der neun Workflows, welcher Mechanismus, Aufwand in TS-23-Zyklen), Abnahme nach 1.1-A18.
2. `JV-CORE-SUB-context_resolve-v1` zuerst: Auflösung über `binding_key` aus `jarvis_ops.source_binding` und `context_registry` (`binding_unknown`, `context_not_active`, Widerspruch zum Hinweis). Smoke-Fälle C01–C04 müssen unverändert bestehen. Die ortsbasierte Auflösung mit Mehrdeutigkeitsprüfung auf **aufgelösten** Ordner-IDs folgt nach V-4.
3. Ablauf je Workflow nach TS-23: ändern → veröffentlichen → `versionId` = `activeVersionId` → Smoke-Test (E03/E04 dabei auf `storage_gdrive.get_file@1.1.0`) → Export mit `normalize_n8n_export.py`.
4. Übernahme per Archiv, Transfer-Branch und Claude Code als PR, **einschliesslich** `jarvis-phase-1-1a-abschluss.zip` (diese Übergabe, Supabase-Nachweis, README).
5. Parallel bei Rolf: V-4 und V-1 beantworten; danach Anleitung für Credential, Ordner und Variablen (1.1b).

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
