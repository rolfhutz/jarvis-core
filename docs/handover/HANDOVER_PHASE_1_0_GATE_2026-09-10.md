# HANDOVER_PHASE_1_0_GATE_2026-09-10

**Modul:** Phase 1, Abschluss Schritt 1.0.8 (A10) und Vorbereitung Phase-1.0-Gate
**Stand:** 10. September 2026, abends
**Status:** 1.0.8 abgeschlossen (PR #7, `main` 515f051). **Phase-1.0-Gate am 10.09.2026 von Rolf freigegeben, G-1 entschieden.** Schritt 1.0 ist abgeschlossen.
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_0_8_2026-09-10.md`

---

## 1. Ziel des Moduls

Stand aus n8n Cloud und Supabase ins Repo übernehmen, Wiederherstellbarkeit der 14 Workflows
nachweisen (1.0.8-A10 / 1.0-A8) und alle Gate-Kriterien samt Testfällen den Nachweisen zuordnen (TS-15).

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus `HANDOVER_PHASE_1_0_2026-09-10.md` und `HANDOVER_PHASE_1_0_8_2026-09-10.md`
Abschnitt 2 (u. a. E-1, E-2, A-6, A-7, 0015, Freigabe der drei Werkzeuge). Neu im DECISION_LOG
eingetragen: E-1, E-2, A-6, A-7, 0015, REL-1.

Neu am 10.09.2026, von Rolf entschieden:

| ID | Entscheidung |
|---|---|
| G-1 | K-07, I-01 (Laufstatus `already_processed`), I-04, P1-T-22 sind Abnahmebedingungen von Schritt 1.1; K-08 von Schritt 1.2; 1.0.8-A4, A7, A8 (TS-20) im Hauptablauf 1.1 |
| GATE-1.0 | Phase-1.0-Gate freigegeben; damit Phase-0-Gate nach Spezifikation 7.3 geschlossen |
| TS-23 | Kern-Subworkflows und Adapter werden veröffentlicht, Smoke-Test bleibt Entwurf. Änderung → veröffentlichen → `versionId` = `activeVersionId` prüfen → Smoke-Test → Export |

## 3. Umgesetzte Komponenten

Alle folgenden Komponenten sind mit PR #7 in `main` (515f051); G-1, Gate-Freigabe und TS-23 mit dem Folge-PR.

| Komponente | Status |
|---|---|
| 14 normalisierte Exporte in `n8n/core/` | im PR |
| `tools/normalize_n8n_export.py`: `callerIds` bleibt erhalten (Befund B-2) | im PR, Selbsttest bestanden |
| `tests/n8n/check_restore.py`: prüft `callerPolicy`/`callerIds` | im PR, getestet inkl. Gegenprobe |
| `tests/db/i05_new_action_same_source.sql` | im PR, gegen Supabase ausgeführt |
| Migration 0015 im Repo | im PR (in Supabase seit 10.09. produktiv) |
| Dokumentation MANIFEST, README (n8n, Repo, Tests, Migrationen), DECISION_LOG | im PR |
| Nachweise 1.0.8, Wiederherstellung, Gate | im PR |

Änderungen in n8n Cloud: nach der Entscheidung TS-23 die neun `JV-CORE-SUB-*` veröffentlicht, jeweils mit
explizit angegebener Version = Repo-Stand (unveränderte Entwürfe). Sonst in n8n und Supabase nur gelesen;
I-05-Test zurückgerollt; Smoke-Lauf 22371 schrieb wie jeder Lauf synthetische Daten (TS-18).

## 4. Dateien und Workflow-Namen

| Pfad | Änderung |
|---|---|
| `n8n/core/JV-CORE-ADP-{tasks,docstore,casestore}_internal-v1.json` | neu |
| `n8n/core/JV-CORE-SUB-tool_invoke-v1.json`, `JV-CORE-SUB-evidence_verify-v1.json`, `JV-CORE-OPS-smoke_test-v1.json` | aktualisiert |
| übrige acht `n8n/core/*.json` | unverändert (inhaltlich identisch mit n8n Cloud geprüft) |
| `n8n/core/MANIFEST.md`, `n8n/core/README.md` | aktualisiert |
| `db/migrations/0015_case_number_seq_sync.sql`, `db/migrations/README.md` | neu / aktualisiert |
| `tools/normalize_n8n_export.py`, `tests/n8n/check_restore.py` | B-2 |
| `tests/db/i05_new_action_same_source.sql`, `tests/README.md` | neu / aktualisiert |
| `docs/decisions/DECISION_LOG.md` | sechs Einträge |
| `docs/evidence/PHASE_1_0_8_TOOL_RELEASE_2026-09-10.md` | neu |
| `docs/evidence/PHASE_1_0_8_RESTORE_2026-09-10.md` | neu |
| `docs/evidence/PHASE_1_0_GATE_2026-09-10.md` | neu |
| `docs/handover/HANDOVER_PHASE_1_0_8_2026-09-10.md`, dieses Dokument | neu |
| `README.md` | Stand und nächster Schritt |

Workflow-IDs und Credentials: `n8n/core/MANIFEST.md`.

## 5. Datenmodelle und Schnittstellen

Unverändert gegenüber `HANDOVER_PHASE_1_0_8_2026-09-10.md` Abschnitt 5.
Neu nur im Exportformat: `settings.callerPolicy` und `settings.callerIds` sind Teil von `n8n/core/*.json`.

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| Gegenprüfung Übergabe 1.0.8 gegen n8n und Supabase | keine Abweichung | `PHASE_1_0_8_TOOL_RELEASE_2026-09-10.md` Abschnitt 6 |
| Ausführungen 22087 und 22265 nachgelesen | je 104/104 | n8n |
| Acht unveränderte Workflows gegen Repo 54f5f33 | identisch | `PHASE_1_0_8_RESTORE_2026-09-10.md` |
| Wiederherstellung Probe, Repo-Stand 11 Workflows | bestanden (90/19/9) | ebenda |
| **Wiederherstellung 14 Workflows, n8n 2.35.7** | **bestanden** (155 Knoten, 38 Zuordnungen, 20 Verweise, 6 Aufruferregeln) | ebenda |
| Gegenprobe B-2 mit altem Normalisierer | nicht bestanden wie erwartet (3 × `callerIds` fehlt) | ebenda |
| Normalisierer-Selbsttest | 4 Prüfungen, 2 Gegenproben | lokal |
| I-05 gegen Supabase | bestanden, zurückgerollt, 0 Restzeilen | `PHASE_1_0_GATE_2026-09-10.md` |
| Smoke-Test nach Veröffentlichung aller SUB (TS-23) | **104/104** | Ausführung 22371 (per MCP ausgelöst) |

**Nicht getestet:** echte Wiederherstellung inklusive DB-Verbindung und Smoke-Lauf in einer
zweiten Instanz; Veröffentlichen in der wiederhergestellten Instanz.

## 7. Bekannte Fehler

Keine offenen. B-2 (Export verlor `callerIds`) behoben. Prozesshinweis: Migration 0015 wurde
vor der Ablage im Repo eingespielt, entgegen `db/migrations/README.md`; nachträglich abgelegt,
inhaltsgleich geprüft.

## 8. Technische Schulden

Weiter offen: P1-TD1, TS-10, TS-11, TS-12, TS-13, TS-16, TS-17 (Aufnahme unbestätigt), TS-18
(Vorgangsnummern jetzt privat bis V-2026-0008, visolva bis V-2026-0005), TS-19, TS-20, TS-21, TS-22.
**Erledigt:** TS-14 (1.0.8), TS-15 (Gate-Nachweis), TS-23 (Regel entschieden und umgesetzt).

| Nr. | Schuld | Wann |
|---|---|---|
| TS-24 | `settings.binaryMode` wird beim Export nicht übernommen. Heute ohne Wirkung (keine Binärdaten), ab Dateieingang relevant | vor erstem Workflow mit Binärdaten, 1.1 |

## 9. Offene Entscheidungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| TS-17 | Aufnahme als technische Schuld bestätigen | vor 1.3 |
| P1-TD1, OFFEN-1 | wie Vorübergabe | vor Pilot |
| P1-O2, P1-O10 | wie Vorübergabe | vor 1.3 |
| P1-O3, P1-O4, P1-O6, P1-O8, P1-O9 | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

**Schritt 1.1 vorbereiten (Eingang und Normalisierung), neuer Chat.**

1. Folge-PR mit G-1, Gate-Freigabe und TS-23 mergen (DECISION_LOG, Gate-Nachweis, MANIFEST,
   n8n-README, diese Übergabe, README).
2. Neuer Chat für 1.1 mit Masterfahrplan, Spezifikation 4.0.2 und dieser Übergabe. Vor dem Bau
   Ziel, Umfang, Voraussetzungen und Abnahmekriterien vorlegen, **einschliesslich der aus G-1
   übertragenen Fälle** K-07, I-01, I-04, P1-T-22 und TS-20 sowie TS-10, TS-19, TS-24.
3. Voraussetzungen 1.1 laut Testplan: Eingangs-, Arbeits-, Archiv-, Entwurfs- und Berichtsordner
   je Kontext eingerichtet; Adapterwahl OCR (P1-O3) für `ocr_default.analyze_document`.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
