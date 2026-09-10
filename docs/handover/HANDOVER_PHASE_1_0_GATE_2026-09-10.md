# HANDOVER_PHASE_1_0_GATE_2026-09-10

**Modul:** Phase 1, Abschluss Schritt 1.0.8 (A10) und Vorbereitung Phase-1.0-Gate
**Stand:** 10. September 2026, abends
**Status:** 1.0.8 abgeschlossen. Gate-Nachweis vorbereitet. **Offen:** Merge des PR, Entscheidung G-1, Gate-Freigabe durch Rolf.
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_0_8_2026-09-10.md`

---

## 1. Ziel des Moduls

Stand aus n8n Cloud und Supabase ins Repo übernehmen, Wiederherstellbarkeit der 14 Workflows
nachweisen (1.0.8-A10 / 1.0-A8) und alle Gate-Kriterien samt Testfällen den Nachweisen zuordnen (TS-15).

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus `HANDOVER_PHASE_1_0_2026-09-10.md` und `HANDOVER_PHASE_1_0_8_2026-09-10.md`
Abschnitt 2 (u. a. E-1, E-2, A-6, A-7, 0015, Freigabe der drei Werkzeuge). Neu im DECISION_LOG
eingetragen: E-1, E-2, A-6, A-7, 0015, REL-1.

In diesem Abschnitt keine neue Entscheidung. Offen zur Entscheidung: G-1 (Abschnitt 9).

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| 14 normalisierte Exporte in `n8n/core/` | im PR |
| `tools/normalize_n8n_export.py`: `callerIds` bleibt erhalten (Befund B-2) | im PR, Selbsttest bestanden |
| `tests/n8n/check_restore.py`: prüft `callerPolicy`/`callerIds` | im PR, getestet inkl. Gegenprobe |
| `tests/db/i05_new_action_same_source.sql` | im PR, gegen Supabase ausgeführt |
| Migration 0015 im Repo | im PR (in Supabase seit 10.09. produktiv) |
| Dokumentation MANIFEST, README (n8n, Repo, Tests, Migrationen), DECISION_LOG | im PR |
| Nachweise 1.0.8, Wiederherstellung, Gate | im PR |

In n8n Cloud und Supabase wurde in diesem Abschnitt **nichts geändert** (nur gelesen; I-05-Test zurückgerollt).

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

**Nicht getestet:** echte Wiederherstellung inklusive DB-Verbindung und Smoke-Lauf in einer
zweiten Instanz; Veröffentlichen in der wiederhergestellten Instanz.

## 7. Bekannte Fehler

Keine offenen. B-2 (Export verlor `callerIds`) behoben. Prozesshinweis: Migration 0015 wurde
vor der Ablage im Repo eingespielt, entgegen `db/migrations/README.md`; nachträglich abgelegt,
inhaltsgleich geprüft.

## 8. Technische Schulden

Weiter offen: P1-TD1, TS-10, TS-11, TS-12, TS-13, TS-16, TS-17 (Aufnahme unbestätigt), TS-18,
TS-19, TS-20, TS-21, TS-22, TS-23. **Erledigt:** TS-14 (1.0.8), TS-15 (Gate-Nachweis).

| Nr. | Schuld | Wann |
|---|---|---|
| TS-24 | `settings.binaryMode` wird beim Export nicht übernommen. Heute ohne Wirkung (keine Binärdaten), ab Dateieingang relevant | vor erstem Workflow mit Binärdaten, 1.1 |

## 9. Offene Entscheidungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| **G-1** | Gate 1.0 mit Restumfang freigeben: K-07, I-01 (Laufstatus), I-04, P1-T-22 → Abnahme 1.1; K-08 → Abnahme 1.2. Empfehlung: ja | Gate-Freigabe |
| TS-23 | Regel: Kern-Subworkflows veröffentlichen ja/nein | vor 1.1 |
| TS-17 | Aufnahme als technische Schuld bestätigen | vor 1.3 |
| P1-TD1, OFFEN-1 | wie Vorübergabe | vor Pilot |
| P1-O2, P1-O10 | wie Vorübergabe | vor 1.3 |
| P1-O3, P1-O4, P1-O6, P1-O8, P1-O9 | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

1. Archiv `jarvis-core_phase-1-0-8.zip` auf einen Transfer-Branch legen; Claude Code entpackt es
   relativ zur Repo-Wurzel und legt einen PR gegen `main` an (Vorgehen wie 10.09.). Merge durch Rolf.
2. Nach dem Merge: Rolf entscheidet G-1 und erteilt die Gate-Freigabe 1.0. Eintrag im
   DECISION_LOG (G-1, GATE-1.0) und Status in `PHASE_1_0_GATE_2026-09-10.md` nachziehen.
3. Vor Beginn von 1.1: TS-23 entscheiden.
4. Danach neuer Chat für Schritt 1.1 mit Masterfahrplan, Spezifikation 4.0.2 und dieser Übergabe.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
