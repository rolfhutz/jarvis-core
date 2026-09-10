# HANDOVER_PHASE_1_0_2026-09-10

**Modul:** Phase 1, Schritt 1.0 — Fundament aktivieren
**Stand:** 10. September 2026
**Status:** 1.0-A1 bis 1.0-A8 nachgewiesen. Offen: 1.0.8 (Werkzeugfreigabe), danach Phase-1.0-Gate.
**Vorherige Übergabe:** `HANDOVER_PHASE_0_2026-08-31.md`

---

## 1. Ziel des Moduls

Das Phase-0-Fundament lauffähig machen: Datenbank, Kontexttrennung, neun
Kern-Subworkflows, Werkzeugregister, Wiederherstellbarkeit. Ohne diesen
Schritt beginnt kein Dokumentenfluss (Spezifikation 4.0.2, Abschnitt 7).

## 2. Verbindliche Entscheidungen

Unverändert gültig: B1–B5, D1–D6, D8, D9, E1, E2, ADR-001 (siehe `docs/decisions/`).

Neu am 10.09.2026, von Rolf entschieden:

| ID | Entscheidung |
|---|---|
| P1-O1 | Supabase förmlich bestätigt; Auflagen Keep-Alive, Sicherung, gekapselter Adapter |
| P1-O5 | Eingang `privat` über Google-Drive-Eingangsordner; `arbeitgeber_visolva` über SharePoint (ADR-001), nur synthetische Testdokumente; E-Mail und API später |
| P1-O7 | Repo-Änderungen per Claude Code als Pull Request, Merge durch Rolf. Kein Web-Upload über „Upload files" (legt Dateien flach ab) |
| ADR-002 | Werkzeugregister zur Laufzeit als Tabelle `jarvis_ops.tool_registry` (Variante A) |
| ADR-003 | Kein Freitext über `queryReplacement`; Freitext als base64-JSON-Block |
| — | Smoke-Test-Einträge im append-only Fachprotokoll bleiben dauerhaft, gekennzeichnet `trc_smoke_` |
| — | Credentials heissen `jv_privat_postgres` und `jv_visolva_postgres` |
| OFFEN-1 | Repo vorläufig öffentlich (Rolf); spätestens vor Pilotstart wieder privat |

Fremdes „Jarvis"-Dokument (Mark 53/56) geprüft und verworfen. GPT-6 Astra erst nach Produktivstart von Phase 1 als Modellkandidat testen.

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| Datenbank: 3 Schemas, 42 Tabellen (39 + 3 Register), 4 Rollen, Migrationen 0001–0014 | produktiv |
| Werkzeugregister: 14 Werkzeuge, alle `draft`, selbstprüfend | produktiv |
| 9 Kern-Subworkflows | getestet, unveröffentlicht (Aufruf nur durch Elternworkflows) |
| `JV-CORE-OPS-db_keepalive-v1` | produktiv, täglich 05:00 UTC |
| `JV-CORE-OPS-smoke_test-v1` | getestet, manuell |
| `jarvis_gate_test_context_isolation` (31.08.) | unverändert, erneut bestanden (Ausführung 21854) |

## 4. Dateien und Workflow-Namen

| Pfad | Inhalt |
|---|---|
| `db/migrations/0011`–`0014` | Login-Benutzer, Suchpfad, Registerstruktur, Registerbefüllung |
| `tools/render_tool_registry.py` | erzeugt 0014 aus den Registerdateien |
| `tools/normalize_n8n_export.py` | bereinigt n8n-Exporte, bricht bei Geheimnissen ab |
| `tests/n8n/check_restore.py` | Abgleich einer wiederhergestellten Instanz (1.0-A8) |
| `n8n/core/*.json` | 11 Workflows mit IDs und Credential-IDs |
| `n8n/core/MANIFEST.md`, `README.md` | Übersicht, Wiederherstellungsablauf |
| `docs/decisions/ADR-002`, `ADR-003`, `DECISION_LOG.md` | Entscheidungen |
| `docs/evidence/PHASE_1_0_*_2026-09-10.md` | Nachweise Register, Smoke-Test, A8 |

Workflow-IDs: siehe `n8n/core/MANIFEST.md`.

## 5. Datenmodelle und Schnittstellen

- `jarvis_ops.tool_registry` (PK `tool_id`, `version`): Vertragsfelder unveränderlich; nur `status` änderbar, nur mit Session-Variable `jarvis.release_evidence_ref`; jede Änderung schreibt `tool_release_log` (append-only). Kontextbenutzer: nur `SELECT`.
- `jarvis_ops.context_risk_override`: nur Hochstufung; in 1.0 leer.
- Kern-Subworkflows: genau ein Objekt je Aufruf. Eingaben je Workflow in den Trigger-Knoten; Rückgabe enthält `status` und fachliche Felder. `tool_invoke` liefert `gate_code` und die Nachweisstrategie aus dem Register; `evidence_verify` liefert `verification.contract_ref` und `limitation`.
- Freigabe eines Werkzeugs (nur Administrator):

  ```sql
  BEGIN;
  SELECT set_config('jarvis.release_evidence_ref', '<Nachweisdokument oder Ausfuehrungs-ID>', true);
  UPDATE jarvis_ops.tool_registry SET status = 'approved' WHERE tool_id = '<id>' AND version = '<v>';
  COMMIT;
  ```

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| Gate A-3/A-4 aus n8n, erneut | 7/7 | Ausführung 21854 |
| Register R-1, R-2 (+ 5 Zusatzprüfungen) | bestanden | `PHASE_1_0_TOOL_REGISTRY_2026-09-10.md` |
| Smoke-Test Lauf 1 | 38/48, drei echte Fehler gefunden | Ausführung 21865 |
| Smoke-Test Lauf 2 und 3 (R-3 bis R-5, 1.0-A5 bis A7) | 48/48 | Ausführungen 21907, 21949 |
| 1.0-A8 Wiederherstellung | bestanden nach Befund | `PHASE_1_0_RESTORE_A8_2026-09-10.md` |
| 1.0-A1 bis A4 | bestanden am 30.08. | `PHASE_1_0_SUPABASE_2026-08-30.md` |

**Nicht getestet:** zugelassener Werkzeugaufruf (kein Werkzeug `approved`), Datenbank-Wiederherstellung aus Sicherung, Verhalten bei Keep-Alive-Fehlschlag.

## 7. Bekannte Fehler

Keine offenen. Behoben am 10.09.: Register-Doppelpflege in drei Workflows; Komma-Zerlegung und `"null"` in Protokoll-Workflows; verlorene Eskalationsentscheidung; Credential-Fehlzuordnung beim Import ohne IDs.

## 8. Technische Schulden

| Nr. | Schuld | Wann |
|---|---|---|
| P1-TD1 | SSL-Zertifikatskette der DB-Verbindung wird nicht geprüft (n8n bietet kein CA-Feld) | von Rolf noch nicht übernommen |
| TS-10 | Kontextliste und Quellbindungen fest in Code-Knoten statt aus `context_registry` | 1.1 |
| TS-11 | `context_risk_override` leer | 1.1 mit echter Kontextkonfiguration |
| TS-12 | Keep-Alive meldet Fehlschläge nicht aktiv | Phase 2 (Meldekanal) |
| TS-13 | Wöchentliche Sicherung (`pg_dump`) nicht umgesetzt, Wiederherstellungstest DB offen | vor Pilot |
| TS-14 | `tool_invoke` ruft noch keinen Adapter auf (Platzhalter) | 1.0.8 |
| TS-15 | Zuordnung der Tests K-01–K-08, I-01–I-05, P1-T-21–23 zu den erbrachten Nachweisen nicht dokumentiert | Gate-Nachweis 1.0 |
| TS-16 | Testdaten vom 31.08. (Gate) im Fachbestand, Umgang offen | vor Pilot |

## 9. Offene Entscheidungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| P1-TD1 | Übernahme als technische Schuld | vor Pilot |
| OFFEN-1 | Repo zurück auf privat | vor Pilot |
| P1-O2, P1-O10 | Freigabeadapter; Dokumente ohne Handlungsbedarf | vor 1.3 |
| P1-O3, P1-O4, P1-O6 | OCR, Modelle, Kategorien | innerhalb der Umsetzung |
| P1-O8, P1-O9 | Aufbewahrung, Altbestand | später |

## 10. Exakter nächster Bauschritt

**Schritt 1.0.8: drei interne Werkzeuge freigeben.**

1. Je Werkzeug einen Adapter-Workflow bauen (`JV-CORE-ADP-docstore_internal-v1`, `JV-CORE-ADP-casestore_internal-v1`, `JV-CORE-ADP-tasks_internal-v1`): schreibt idempotent ins Kontextschema (`document`, `case`, `task`), Freitext nach ADR-003, Rückgabe mit Readback.
2. `tool_invoke`: Platzhalter durch Weiterleitung an den Adapter je `adapter_id` ersetzen; danach `evidence_verify` mit `readback`.
3. Smoke-Test um je einen positiven Durchlauf erweitern (Klassifizierung → Sperre → Aufruf → Nachweis → Fachprotokoll); zuerst erwartet `tool_not_released`.
4. Nach bestandenem Lauf je Werkzeug die Freigabe mit Nachweisverweis (Abschnitt 5); Smoke-Test erneut: jetzt `invocation_allowed = true` und `verified`.
5. Gate-Nachweis 1.0 mit Zuordnung aller Kriterien und Testfälle (TS-15), dann Gate-Freigabe durch Rolf.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
