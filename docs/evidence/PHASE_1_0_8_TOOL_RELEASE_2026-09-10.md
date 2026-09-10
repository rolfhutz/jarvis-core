# Nachweis Phase 1.0, Schritt 1.0.8 — Freigabe der drei internen Werkzeuge

**Datum:** 10. September 2026
**Grundlage:** SPEC_PHASE_1 4.0.2, Abschnitt 12.1.1; Entscheidungen E-1, E-2, A-6, A-7 (DECISION_LOG)
**Datenbank:** Supabase `slatmyyxwruxvihcaklk`, Zugriff ausschliesslich über `jv_privat_postgres` und `jv_visolva_postgres`
**Gegengeprüft am 10.09.2026 nachmittags** per n8n-MCP und Supabase-MCP (Abschnitt 5)

## 1. Ergebnis

`casestore_internal.upsert_case`, `docstore_internal.upsert_document` und
`tasks_internal.create_task` (je Version 1.0.0) stehen auf `approved`. Alle übrigen
elf Werkzeuge stehen auf `draft`. Die Freigabe erfolgte erst nach bestandenem Lauf mit
gespeichertem Nachweis in beiden Kontexten.

## 2. Die fünf Bedingungen aus 12.1.1

| Schritt | Bedingung | Beleg |
|---|---|---|
| 1 | Vertrag vollständig, Ein- und Ausgabeschema auflösbar | Registereinträge aus 0014 (R-1, R-2 in `PHASE_1_0_TOOL_REGISTRY_2026-09-10.md`); Nutzlast nach `document`/`case`/`task.schema.json` |
| 2 | Adapter ausgewählt und mit Credentials konfiguriert | `JV-CORE-ADP-*-v1`, `adapter_id` im Register, je Kontext eigenes Credential |
| 3 | Testlauf im Zielsystem erfolgreich | Smoke-Test 21999 und 22087, je 104/104, Adapter direkt aufgerufen (A-6) |
| 4 | Ergebnisnachweis nach Vertrag erbracht | Readback-Abgleich über `evidence_verify`, gespeichert als `confirmed` (Tabelle unten) |
| 5 | erst danach `approved` | `tool_release_log` 14:14:20 UTC, nach Lauf 22087 (14:11:09–14:11:29 UTC) |

Freigabenachweise aus Lauf 22087 (ULID-Zeitstempel 14:11:25–14:11:27 UTC):

| Werkzeug | privat | arbeitgeber_visolva |
|---|---|---|
| `casestore_internal.upsert_case` | `evd_01M25THEDDVD3XEYP70FK8DTTW` | `evd_01M25THEMYNC0Q4WMXWB3PNPW0` |
| `docstore_internal.upsert_document` | `evd_01M25THEWADDBMCZGGWD01HA4G` | `evd_01M25THF36P9QB0AFGPYF8T7BF` |
| `tasks_internal.create_task` | `evd_01M25THFAG1PD0VCJQSQ0V8R7R` | `evd_01M25THFRGFF0GMGPTRX4CVKV3` |

## 3. Läufe

| Ausführung | Zeit (UTC) | Zustand | Ergebnis |
|---|---|---|---|
| 21999 | 14:09:44 | vor Freigabe | 104/104 |
| 22087 | 14:11:09 | vor Freigabe, Aufrufer beschränkt | **104/104 = Freigabenachweis** |
| — | 14:14:20 | Freigabe im Register | 3 × `approved` |
| 22175 | 14:14:35 | nach Freigabe, Adapter unveröffentlicht | 98/104, Befund 4.2 |
| 22265 | 14:16:00 | nach Freigabe, Adapter veröffentlicht | **104/104** |

Der Smoke-Test wurde nach 14:09:41 UTC nicht mehr geändert; alle vier Läufe prüfen denselben Stand.
Prüfumfang: 39 Prüfungen aus 1.0 (C, I, K, T, E, G, F, L, H), 48 Werkzeugprüfungen
(WK, WS, WA, WN, WT, WF), G12 und 16 Readback-Prüfungen (RB, RBW).

## 4. Abnahmekriterien 1.0.8

| Nr. | Kriterium | Stand | Fälle |
|---|---|---|---|
| A1 | Aufruf vor Freigabe → `tool_not_released`, kein Schreiben | ✅ | WT-* in 21999/22087 |
| A2 | Positiver Lauf 3 × 2 mit Readback, Nachweiszeile, Fachprotokoll | ✅ | WA-*-neu, WN-*, WF-*, RBW-* |
| A3 | Wiederholung ohne Dublette | ✅ | WA-*-wdh, WA-p-tsk-neue-id, WA-p-doc-dublette, RBW-*-einmalig |
| A4 | Parallelaufruf: genau ein Schreibvorgang | ⚠️ teilweise | WS-*, G12; echter Parallelaufruf nicht auslösbar (TS-20) |
| A5 | Falscher Kontext → kein Schreiben | ✅ | WA-p-doc-fremdkontext |
| A6 | Ungültige Eingabe → Fehlerdatensatz, kein Schreiben | ✅ | WA-p-cse-ungueltig, WA-p-doc-ungueltig, WA-p-tsk-ohne-verantwortung, WA-p-doc-status |
| A7 | Readback-Abweichung → `mismatch`, gespeichert `not_confirmed` | ⚠️ teilweise | WN-p-tsk-abweichung; Eskalation und Aktionsstatus erst im Hauptablauf (TS-20) |
| A8 | Unbekannte `adapter_id` → `adapter_unknown` | ⚠️ nur Aufbau | Knoten „Adapter unbekannt“ in `tool_invoke`; nicht auslösbar, da alle Registereinträge einen Adapter haben (TS-20) |
| A9 | Freigabe mit Nachweisverweis | ✅ | `tool_release_log` Zeilen 2–4 |
| A10 | Export, Wiederherstellung 14 Workflows | ✅ | `PHASE_1_0_8_RESTORE_2026-09-10.md` |

## 5. Befunde

1. **B-1 Vorgangsnummern-Zähler.** Zähler privat 2026 stand auf 2, vergeben war bereits
   V-2026-0003. Behoben mit Migration 0015. Stand nach allen Läufen: privat 7 = V-2026-0007,
   visolva 4 = V-2026-0004. 0015 wurde vor der Ablage im Repo eingespielt; die Repo-Datei ist
   mit dem in Supabase registrierten Text identisch (bis auf den abschliessenden Zeilenumbruch).
2. **Verschachtelter Aufruf unveröffentlichter Adapter** (22175): „Workflow is not active and
   cannot be executed“. Nach Veröffentlichung bestanden (22265). *Nachtrag 10.09.2026:* Ursache ist das Veröffentlichungsmodell
   von n8n 2.x (Entwürfe für Elternworkflows nicht sichtbar); Regel TS-23 entschieden und umgesetzt, siehe DECISION_LOG.
3. **B-2 Export verlor die Aufruferbeschränkung.** `normalize_n8n_export.py` behielt
   `callerPolicy`, entfernte `callerIds`; `check_restore.py` prüfte keine Einstellungen.
   Behoben, Gegenprobe in `PHASE_1_0_8_RESTORE_2026-09-10.md`.
4. **Randnotiz:** `tool_release_log` beginnt bei ID 2. Löschen ist per Trigger gesperrt; die
   Lücke stammt aus einem zurückgerollten Vorgang. Alle drei Statuswechsel sind protokolliert.

## 6. Gegenprüfung am 10.09.2026

| Prüfpunkt | Ergebnis |
|---|---|
| Register | 3 × `approved`, 11 × `draft` |
| Nachweiszeilen | privat 20 `confirmed` / 8 `not_confirmed`, visolva 12 `confirmed` = 4 Läufe × (7 bzw. 3) |
| Adapter in n8n | `active = true`, veröffentlichte Version = aktueller Stand, `callerIds` korrekt |
| Download-Stände | `versionId` der sechs geänderten Workflows identisch mit dem per MCP gelesenen Stand |

## 7. Nicht Gegenstand

Echter Parallelaufruf, Eskalation nach `mismatch`, Wiederholungsregel (TS-19, TS-20),
Aufruf aus einem veröffentlichten Hauptworkflow über ein unveröffentlichtes `tool_invoke` (TS-23).
