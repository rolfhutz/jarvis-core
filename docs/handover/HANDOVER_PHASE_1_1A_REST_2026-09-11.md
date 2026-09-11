# HANDOVER_PHASE_1_1A_REST_2026-09-11

**Modul:** Phase 1, Schritt 1.1, Bauabschnitt 1.1a, Rest: Kontext und Bindungen aus der Datenbank (TS-10)
**Stand:** 11. September 2026
**Status:** 1.1a vollständig. 12 Kern-Workflows geändert, veröffentlicht und getestet (Smoke-Test 116/116, Ausführung 22715); statische Prüfung und Wiederherstellung bestanden. Repo-Übernahme per PR offen.
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_1A_2026-09-10.md`
**Nachweis:** `docs/evidence/PHASE_1_1A_TS10_2026-09-11.md`

---

## 1. Ziel des Moduls

Kontextliste und Quellbindungen kommen aus der Datenbank, keine Kontextwerte stehen mehr im Code der Kern-Workflows (TS-10, Kern von 1.1-A18). Ein unbekannter Kontext bricht in jeder Kontextweiche ab, statt still zu verschwinden.

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus den Vorübergaben, insbesondere E-1, E-2, A-6, A-7, REL-1, G-1, GATE-1.0, TS-23, PLAN-1.1, 1.1-E1 bis 1.1-E6, TS-10b, TS-11.

Neu am 11.09.2026, von Rolf freigegeben:

| ID | Entscheidung |
|---|---|
| TS10-E1 | Umfang: alle 12 Kern-Workflows (9 SUB, 3 ADP). `context_resolve` löst aus `jarvis_ops.source_binding` und `context_registry` auf. Übrige Workflows prüfen den Kontext nur im Format. Die Kontextweiche ist die einzige Kontextstelle und hat einen verbundenen Ausweichausgang. Bewusste Abschwächungen: `id_generate` nur Formatprüfung; Adapter-Probelauf ohne eigene Kontextprüfung |
| TS10-E2 | `jv_privat_postgres` ist der Betriebs-Lesezugang für Lesezugriffe vor bekanntem Kontext, begrenzt auf die Konfigurationstabellen in `jarvis_ops`. Gilt auch für Bindungsliste und K-07-Eintrag des Hauptablaufs (1.1d) |
| TS10-E3 | TS-23 paketweise: jeder Workflow einzeln veröffentlicht und geprüft, ein Smoke-Lauf je Paket |

Umsetzungsdetails (innerhalb der Freigabe):

- AT-1: fail closed bei deaktivierter oder angehaltener Bindung.
- AT-2: `credential_ref` entfällt.
- Fallnummern X01–X11 statt K01–K11, weil K01–K07 schon vergeben sind.

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| `JV-CORE-SUB-context_resolve-v1` mit Datenbankauflösung | produktiv, getestet |
| 7 SUB mit Ausweichausgang „Kontext ohne Weiche“, `id_generate` mit Formatprüfung | produktiv, getestet |
| 3 ADP mit Ausweichausgang auf „Ergebnis ungueltige Eingabe“ | produktiv, getestet |
| Smoke-Test: C05, X01–X11, E03/E04 auf `get_file@1.1.0` (116 Prüfungen) | Entwurf (wie vorgesehen), getestet |
| `tests/n8n/check_ts10.py` | im PR-Archiv, Selbsttest bestanden |

**Nicht umgesetzt:** Speicher- und OCR-Adapter, Hauptablauf, Dispatcher, ortsbasierte Auflösung (nach V-4).

## 4. Dateien und Workflow-Namen

Im PR-Archiv `jarvis-phase-1-1a-rest.zip`:

- `n8n/core/` mit 13 Exporten (ohne `db_keepalive`, unverändert)
- `n8n/core/MANIFEST.md`, `n8n/core/README.md`
- `tests/n8n/check_ts10.py`, `tests/README.md`
- `docs/decisions/DECISION_LOG.md`
- `docs/evidence/PHASE_1_1A_TS10_2026-09-11.md`
- diese Übergabe
- `README.md`
- aus dem Abschlussarchiv 1.1a, bytegleich: `docs/handover/HANDOVER_PHASE_1_1A_2026-09-10.md`, `docs/evidence/PHASE_1_1A_SUPABASE_2026-09-10.md`

Workflow-IDs sind unverändert (`n8n/core/MANIFEST.md`). Es gibt keine neuen Credentials.

## 5. Datenmodelle und Schnittstellen

**`context_resolve`**

- Eingabe: `source_binding`, `context_id_hint`, `trace_id`.
- Ausgabe bei Erfolg: `resolved`, `context_id`, `db_schema`, `resolution_method` = `source_binding`, `source_binding`, `reason_code`, `reason`, `trace_id`, `status` = `resolved`.
- Abbruch: `context_unresolved: <reason_code>: <reason>`.
- Grundcodes: `input_invalid`, `binding_unknown`, `binding_disabled`, `context_not_active`, `binding_halted`, `hint_conflict`.

**Übrige Kern-Workflows:** Die Schnittstellen sind unverändert. Neue Fehlermeldungen:

- `<workflow>_invalid_input: context_id fehlt oder hat kein gueltiges Format`
- `<workflow>_invalid_input: context_id ohne Kontextweiche: <id>`
- in den Adaptern `context_id ohne Kontextweiche` in `error.message`

Datenbank: unverändert seit 0019.

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| Smoke-Test Paket 1 | 105/105 | 22616 |
| Smoke-Test Paket 2 | 116/116 | 22715 |
| `versionId` = `activeVersionId`, 12 Workflows | bestanden | MCP |
| Abgleich 13 Exporte gegen d12f218 und Soll | nur geplante Änderungen | Nachweis Abschnitt 5 |
| `check_ts10.py` neu / Gegenprobe d12f218 / Selbsttest | 0 Befunde / 23 Befunde in 12 Workflows / 6 Fälle | Nachweis |
| Wiederherstellung n8n 2.35.7 | bestanden: 14 Workflows, 164 Knoten, 39 Credential-Zuordnungen | Nachweis |

**Nicht getestet:** `context_not_active` (folgt in 1.1e mit der K-07-Probe) und die ortsbasierte Auflösung (nicht gebaut).

## 7. Bekannte Fehler

Keine offenen. Nebenbefunde aus dem Nachweis:

- Der Normalisierer schreibt fest `jarvis_phase` 1.0.
- `check_restore.py` prüft die Kontext-Credential-Regel nicht für Knoten ohne Kontext im Namen.
- Der Upload von vier gleichnamigen Dateien kam zweimal nicht als Datei an.

## 8. Technische Schulden

**Erledigt:** TS-10 (Kern; abschliessend mit den P1-Workflows in 1.1e).

**Neu:**

| Nr. | Schuld | Wann |
|---|---|---|
| TS-26 | Betriebs-Lesezugang über `jv_privat_postgres` (TS10-E2); eigenen Zugang prüfen | vor Arbeitgeber-Pilot |

**Weiter offen:** P1-TD1, TS-10b, TS-11 (→ 1.3), TS-12, TS-13, TS-16, TS-17 (Aufnahme unbestätigt), TS-18 (Vorgangsnummern jetzt privat bis **V-2026-0011**, visolva bis **V-2026-0008**), TS-19, TS-20, TS-21, TS-22, TS-25 (Aufnahme unbestätigt), OFFEN-1.

## 9. Offene Entscheidungen und Voraussetzungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| V-4 | n8n-Variablen verfügbar? Sonst Ausweichlösung (Abweichung ADR-001) | vor 1.1b |
| V-1 | privates Google-Konto, Credential `jv_privat_gdrive` (nicht `Google Drive rolf@visolva.com`) | vor 1.1b |
| V-2, V-3, V-5, V-6 | Ordner, SharePoint-Testbibliothek, OCR-Zugänge, 20 Testdokumente | vor 1.1b / 1.1c |
| TS-25, TS-17 | Aufnahme bestätigen | vor 1.4 / 1.3 |
| P1-O3 | OCR-Dienst | Ende 1.1 |
| übrige | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

1. **Repo-Übernahme:**
   - Archiv `jarvis-phase-1-1a-rest.zip` auf einen Transfer-Branch legen.
   - Claude Code legt den PR gegen `main` d12f218 an.
   - Byteweise Prüfung des PR gegen das Archiv.
   - Merge durch Rolf.
   - Das Archiv ersetzt `jarvis-phase-1-1a-abschluss.zip`; dessen drei Dateien sind enthalten, die README in fortgeschriebener Fassung.
2. **Parallel bei Rolf:** V-4 und V-1 beantworten.
3. **Danach, in einem neuen Chat, Bauabschnitt 1.1b:**
   - Anleitung für Credential `jv_privat_gdrive`, Ordner und n8n-Variablen.
   - Speicheradapter `storage_gdrive` und `storage_sharepoint` mit Wurzelprüfung.
   - Auslösen von 1.1-A14 (Freigabe vor Verdrahtung), danach Freigabe `get_file`.
   - Jeder neue Workflow muss `tests/n8n/check_ts10.py` bestehen.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
