# HANDOVER_PHASE_1_0_8_2026-09-10

**Modul:** Phase 1, Schritt 1.0.8 — Werkzeugfreigabe (drei interne Werkzeuge)
**Stand:** 10. September 2026, 16:20 MESZ
**Status:** Werkzeuge freigegeben und nachgewiesen. **Offen:** Export, Wiederherstellung (A10), Repo-Übernahme per PR, Gate-Nachweis 1.0.
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_0_2026-09-10.md`

> **Wichtig:** In diesem Abschnitt wurde **nichts ins Repo committet.** Alle Änderungen liegen
> in n8n Cloud und Supabase. Die einzige neue Datei ist `db/migrations/0015_case_number_seq_sync.sql`
> (liegt dieser Übergabe bei, in Supabase bereits eingespielt). Der Repo-Stand `main` (54f5f33)
> bildet den Stand **vor** 1.0.8 ab.

---

## 1. Ziel des Moduls

`casestore_internal.upsert_case`, `docstore_internal.upsert_document` und
`tasks_internal.create_task` nach den fünf Bedingungen aus Spezifikation 12.1.1 auf
`approved` bringen. Dabei erstmals die vollständige Kette durchlaufen:
Einstufung → Sperre → Aufruf → Adapter → Readback → Nachweis → Fachprotokoll.

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus `HANDOVER_PHASE_1_0_2026-09-10.md` Abschnitt 2.

Neu am 10.09.2026, von Rolf freigegeben:

| ID | Entscheidung |
|---|---|
| E-1 | `tool_invoke` leitet per Verteiler (Switch auf `adapter_id` aus dem Register) an je einen festen Aufrufknoten weiter. Unbekannte `adapter_id` → `adapter_unknown`. Neuer Adapter = versionierte Änderung an `tool_invoke`. |
| E-2 | `evidence_verify` speichert jeden echten Abgleich (`verified`, `mismatch`) als Zeile in `<kontext>.evidence` und gibt `evidence_id` zurück. Scheitert die Ablage, gilt der Nachweis als nicht erbracht (`evidence_store_failed`). Freigabeverweis = `evidence_id`. |
| A-6 | Der Freigabelauf ruft die Adapter direkt aus dem Smoke-Test auf (Bedingung 3 vor Bedingung 5). `tool_invoke` bleibt streng. Adapter dürfen nur von `tool_invoke` und dem Smoke-Test aufgerufen werden. |
| A-7 | Vertragsverstösse des Aufrufers (`readback_required`, `method_not_accepted`, `contract_unknown`, `expected_empty`) erzeugen **keine** Nachweiszeile. |
| B-1 / 0015 | Vorgangsnummern-Zähler je Kontext/Jahr wird auf die höchste vergebene Nummer angehoben (Migration 0015). |
| — | Freigabe der drei Werkzeuge, erteilt nach Nachweis (Lauf 22087). |

Arbeitsannahmen (nicht blockierend, gelten bis zur Korrektur):

| Nr. | Annahme |
|---|---|
| A-1 | Readback ist eine eigene Abfrage nach dem Schreiben, nicht `RETURNING`. |
| A-2 | IDs (`doc_`, `cse_`, `tsk_`) kommen vom Aufrufer. Wiederholung trifft denselben Schlüssel; Vorgangsnummer nur bei Neuanlage. |
| A-3 | „Fortschreiben“ nur für im Schema vorgesehene Felder. Unveränderliche Felder (Eingang, Datei, `content_hash`) werden nie überschrieben; Abweichung fällt im Readback auf. Die Kennungsliste eines Vorgangs gilt als vollständiger Sollstand. |
| A-4 | Adapter klassifizieren Fehler (`retryable` nach Register), die Wiederholung selbst übernimmt ab 1.1 der aufrufende Ablauf. |
| A-5 | Testdaten tragen `trc_smoke_` (in `body.trace.trace_id`) und bleiben im Bestand. |

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| Migration `0015_case_number_seq_sync` | produktiv (Supabase), Selbstprüfung bestanden; **nicht im Repo** |
| `JV-CORE-ADP-tasks_internal-v1` | produktiv, **veröffentlicht**, Aufrufer beschränkt |
| `JV-CORE-ADP-docstore_internal-v1` | produktiv, **veröffentlicht**, Aufrufer beschränkt |
| `JV-CORE-ADP-casestore_internal-v1` | produktiv, **veröffentlicht**, Aufrufer beschränkt |
| `JV-CORE-SUB-tool_invoke-v1` | geändert (E-1, `action_id`, `dry_run`, `adapter_error`), getestet, unveröffentlicht |
| `JV-CORE-SUB-evidence_verify-v1` | geändert (E-2), getestet, unveröffentlicht |
| `JV-CORE-OPS-smoke_test-v1` | erweitert auf 47 Knoten / 104 Prüfungen, getestet, manuell |
| Werkzeugregister | 3 × `approved`, je 1 Eintrag in `tool_release_log`, 11 × `draft` |
| TS-14 (`tool_invoke` ohne Adapter) | **erledigt** |

Unverändert seit Repo-Stand 54f5f33: `context_resolve`, `id_generate`, `idempotency_guard`,
`action_classify`, `fach_log_write`, `tech_log_write`, `error_handler`, `db_keepalive`.

## 4. Dateien und Workflow-Namen

| Workflow | n8n-ID | Änderung in 1.0.8 |
|---|---|---|
| `JV-CORE-ADP-tasks_internal-v1` | `GFTIzQsak9UJVhAj` | neu |
| `JV-CORE-ADP-docstore_internal-v1` | `2QdRVAniHgkWjqh2` | neu |
| `JV-CORE-ADP-casestore_internal-v1` | `V1fuepKIR20OwgZp` | neu |
| `JV-CORE-SUB-tool_invoke-v1` | `ELs6LnRIWKCv04yc` | geändert |
| `JV-CORE-SUB-evidence_verify-v1` | `UKcnRE0eJzyl8T1V` | geändert |
| `JV-CORE-OPS-smoke_test-v1` | `P5IlT5RlGBK1aqiO` | geändert |

Aufrufer-Liste der drei Adapter (`callerPolicy: workflowsFromAList`):
`ELs6LnRIWKCv04yc,P5IlT5RlGBK1aqiO`. Credentials unverändert (`jv_privat_postgres`
`oCkj27EiMe96vXvU`, `jv_visolva_postgres` `7BblU6FbDds3EZBb`).

Beiliegend: `0015_case_number_seq_sync.sql` → gehört nach `db/migrations/`.

**Noch zu erstellen (nächster Chat):** 6 normalisierte Exporte in `n8n/core/`,
`n8n/core/MANIFEST.md` und `README.md` aktualisieren, `docs/decisions/DECISION_LOG.md`
(E-1, E-2, A-6, A-7, 0015, Freigabe), `db/migrations/README.md` (Zeile 0015),
`docs/evidence/PHASE_1_0_8_TOOL_RELEASE_2026-09-10.md`, `docs/evidence/PHASE_1_0_GATE_*.md`,
Nachweis A8 für 14 Workflows.

## 5. Datenmodelle und Schnittstellen

**Adapter (alle drei gleich aufgebaut)**
- Eingabe: `context_id`, `action_id` (`^act_[A-Za-z0-9_]{6,64}$`), `tool_id`, `payload` (Objekt nach `document`/`case`/`task.schema.json`), `dry_run` (boolean), `trace_id`.
- Ablauf: Eingabe prüfen (Pflichtfelder, Muster, `payload.context_id` = Aufrufkontext) → Weg wählen (`privat` / `arbeitgeber_visolva` / `dry_run` / `invalid`) → Schreiben (ein SQL-Statement, base64-Block nach ADR-003) → Readback (eigene Abfrage) → Ergebnis.
- Rückgabe `ok`: `status`, `write_outcome`, `target_object_ref {object_type, object_id, requested_id}`, `verification_method: readback`, `observed`, `expected` (Casestore zusätzlich `case_number`).
- Rückgabe Fehler: `status: error`, `error {error_class, error_code, retryable, message}`. Codes u. a. `invalid_input`, `duplicate_content`, `readback_missing`, `permission_denied`, `unique_violation`, `constraint_violation`, `reference_missing`, `db_timeout`, `db_unreachable`.
- `write_outcome`: tasks `created | existing | conflict`; docstore `created | unchanged | updated | duplicate_content | conflict`; casestore `created | unchanged | updated`.
- Docstore: `content_hash` unter anderer `document_id` → kein Schreiben, `duplicate_content` mit `existing_document_id`. Status `discarded`/`misrouted` → abgewiesen (siehe TS-17).
- Casestore: Vorgangsnummer über `next_case_number()` nur bei Neuanlage; Kennungen `ON CONFLICT DO NOTHING`, fremd belegte Kennung fällt im Readback als Abweichung auf.

**`tool_invoke`** — neue Eingaben `action_id`, `dry_run`. Register liefert zusätzlich `adapter_id`.
Neue Gate-Codes: `action_id_missing` (freigegebenes Werkzeug ohne `action_id`), `adapter_unknown`.
Erfolg: `invocation_allowed: true`, `gate_code: allowed`, Adapterfelder, Adapterfehler in `adapter_error`
(nicht `error`). Den Nachweis ruft der Aufrufer getrennt über `evidence_verify` (D8).

**`evidence_verify`** — Register liefert `evidence_type` (`definition.evidence.required_types[0]`).
Neue Rückgabefelder: `evidence_id`, `evidence_stored`, `evidence_id_planned`, `store_route`.
`verification_result` in der Tabelle: `confirmed` / `not_confirmed` (Schema-Enum).
`evidence.action_id` hat einen Fremdschlüssel auf `action` → Nachweis nur für existierende Aktionen.

**Freigabe** wie in der Vorübergabe, Nachweisverweis = zwei `evidence_id` (privat, visolva).

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| SQL-Kern aller drei Adapter gegen Supabase (Transaktion, zurückgerollt) | bestanden | Chat 10.09. |
| Smoke-Test vor Freigabe | 104/104 | Ausführung 21999 |
| Smoke-Test mit Aufrufer-Beschränkung, vor Freigabe | 104/104 | Ausführung 22087 (= Freigabenachweis) |
| Smoke-Test nach Freigabe, Adapter unveröffentlicht | 98/104 — Befund siehe 7 | Ausführung 22175 |
| Smoke-Test nach Freigabe, Adapter veröffentlicht | **104/104** | **Ausführung 22265** |
| Freigabe | 3 × `approved`, je 1 Eintrag `tool_release_log`, 11 × `draft` | SQL-Prüfung |

Nachweise des Freigabelaufs 22087:

| Werkzeug | privat | arbeitgeber_visolva |
|---|---|---|
| `casestore_internal.upsert_case` | `evd_01M25THEDDVD3XEYP70FK8DTTW` | `evd_01M25THEMYNC0Q4WMXWB3PNPW0` |
| `docstore_internal.upsert_document` | `evd_01M25THEWADDBMCZGGWD01HA4G` | `evd_01M25THF36P9QB0AFGPYF8T7BF` |
| `tasks_internal.create_task` | `evd_01M25THFAG1PD0VCJQSQ0V8R7R` | `evd_01M25THFRGFF0GMGPTRX4CVKV3` |

Abnahmekriterien 1.0.8:

| Nr. | Kriterium | Stand |
|---|---|---|
| A1 | Aufruf vor Freigabe → `tool_not_released`, kein Schreiben | ✅ |
| A2 | Positiver Lauf 3 × 2 mit Readback, Nachweiszeile, Fachprotokoll | ✅ |
| A3 | Wiederholung ohne Dublette (inkl. neue ID/gleicher Schlüssel, gleicher Hash) | ✅ |
| A4 | Parallelaufruf: genau ein Schreibvorgang | ⚠️ teilweise (Sperre G12; echter Parallelaufruf nicht auslösbar) |
| A5 | Falscher Kontext → kein Schreiben | ✅ |
| A6 | Ungültige Eingabe → Fehlerdatensatz, kein Schreiben | ✅ |
| A7 | Readback-Abweichung → `mismatch`, gespeichert als `not_confirmed` | ⚠️ teilweise (Eskalation/Aktionsstatus erst im Hauptablauf) |
| A8 | Unbekannte `adapter_id` → `adapter_unknown` | ⚠️ nur Aufbau (nicht auslösbar) |
| A9 | Freigabe mit Nachweisverweis | ✅ |
| A10 | Export, Wiederherstellung 14 Workflows, PR | **offen** |

**Nicht getestet:** Wiederherstellung der 14 Workflows (A10), echter Parallelaufruf eines Adapters,
Aufruf eines Adapters aus einem veröffentlichten Hauptworkflow über ein unveröffentlichtes `tool_invoke`.

## 7. Bekannte Fehler

Keine offenen. Befunde dieses Abschnitts:

1. **B-1 Zähler Vorgangsnummer** (V-2026-0003 vergeben bei Zählerstand 2) → behoben mit 0015.
2. **Verschachtelter Adapteraufruf scheiterte** (Lauf 22175): `tool_invoke` → Adapter lieferte
   „Workflow is not active and cannot be executed“, solange die Adapter unveröffentlicht waren.
   Nach Veröffentlichung bestanden (22265). **Ursache nicht abschliessend geklärt**: entweder
   greift `callerPolicy: workflowsFromAList` nur bei veröffentlichten Workflows, oder n8n verlangt
   für verschachtelte Aufrufe eine aktive Version. Direkte Aufrufe aus dem Smoke-Test liefen auch
   unveröffentlicht. Folge: **Änderungen an den Adaptern wirken erst nach erneutem Veröffentlichen.**
3. Korrektur einer Aussage aus dem Chat: „zwei der acht unveränderten Workflows liegen geprüft im
   Repo“ war ungenau. Richtig: Alle acht unveränderten Workflows liegen im Repo (Stand 54f5f33);
   die sechs neuen bzw. geänderten fehlen dort vollständig.

## 8. Technische Schulden

Aus der Vorübergabe weiter offen: P1-TD1, TS-10, TS-11, TS-12, TS-13, TS-15, TS-16.
TS-14 erledigt.

| Nr. | Schuld | Wann |
|---|---|---|
| TS-17 | `document.schema.json` erlaubt Status `discarded`, `misrouted` (K9), DB-CHECK nicht. Adapter weist ab. Migration nötig. **Aufnahme als TS durch Rolf noch nicht bestätigt.** | vor 1.3 |
| TS-18 | Jeder Smoke-Lauf schreibt Vorgänge, Dokumente, Aufgaben, Aktionen, Nachweise in den Fachbestand und **verbraucht echte Vorgangsnummern** (privat bis V-2026-0007, visolva bis V-2026-0004). | mit TS-16, vor Pilot |
| TS-19 | Wiederholungsregel (`retry_policy`) nicht umgesetzt, Adapter klassifizieren nur. | 1.1 |
| TS-20 | A4 (echter Parallelaufruf), A7 (Eskalation, Aktionsstatus nach Nachweis bleibt `planned`), A8 (`adapter_unknown` nur strukturell). | 1.1 Hauptablauf |
| TS-21 | Adapter prüfen Pflichtfelder und Muster im Code, keine vollständige JSON-Schema-Validierung (kein Validator in n8n Cloud). | später, bei Bedarf |
| TS-22 | ULID-Erzeugung in `evidence_verify` dupliziert statt `id_generate`. | bei nächster Änderung |
| TS-23 | Veröffentlichungsstatus der Kern-Subworkflows für verschachtelte Aufrufe ungeklärt (Befund 7.2). | vor 1.1 |

## 9. Offene Entscheidungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| TS-17 | Aufnahme als technische Schuld bestätigen | vor 1.3 |
| TS-23 | Regel: Kern-Subworkflows veröffentlichen ja/nein | vor 1.1 |
| P1-TD1, OFFEN-1 | wie Vorübergabe | vor Pilot |
| P1-O2, P1-O10 | wie Vorübergabe | vor 1.3 |
| P1-O3, P1-O4, P1-O6, P1-O8, P1-O9 | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

**Schritt 1.0.8 abschliessen (A10), dann Phase-1.0-Gate.**

1. Die sechs geänderten/neuen Workflows aus n8n Cloud holen (per MCP `get_workflow_details`
   oder Download durch Rolf) und mit `tools/normalize_n8n_export.py` normalisieren. Prüfen, dass
   die acht unveränderten Workflows in n8n noch den Repo-Stand haben.
2. Wiederherstellung A8 für alle 14 Workflows: frische lokale n8n 2.35.7, Ablauf nach
   `n8n/core/README.md`, `tests/n8n/check_restore.py`. Erwartung: 14 Workflows, alle IDs,
   Credential-Zuordnungen und Subworkflow-Verweise identisch, `callerPolicy`/`callerIds` erhalten.
3. Dokumentation: MANIFEST, README, DECISION_LOG, `db/migrations/README.md`, Nachweis
   `PHASE_1_0_8_TOOL_RELEASE_2026-09-10.md`.
4. Gate-Nachweis 1.0 mit Zuordnung aller Kriterien 1.0-A1…A8 und der Testfälle K-01–K-08,
   I-01–I-05, P1-T-21–23 (TS-15). Teilweise erfüllte Kriterien A4, A7, A8 ausweisen.
5. Alles als ein Archiv, Übernahme über Transfer-Branch und Claude Code als PR
   (Vorgehen wie Teil 2 am 10.09.). Nach Merge: Gate-Freigabe durch Rolf.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
