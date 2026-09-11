# HANDOVER_PHASE_1_1B_TEIL1_2026-09-11

**Modul:** Phase 1, Schritt 1.1, Bauabschnitt 1.1b Teil 1: Kontextwurzel und Speicheradapter Google Drive
**Stand:** 11. September 2026
**Status:** Teil 1 vollständig. Migrationen 0020–0023 produktiv, Adapter veröffentlicht, `storage_gdrive.get_file@1.1.0` freigegeben (nur `privat`), Smoke 23123 143/143, Export und Wiederherstellung bestanden. Repo-Übernahme per PR offen. Teil 2 (SharePoint) wartet auf V-3.
**Vorherige Übergabe:** `docs/handover/HANDOVER_PHASE_1_1A_REST_2026-09-11.md`
**Nachweis:** `docs/evidence/PHASE_1_1B_GDRIVE_2026-09-11.md`

---

## 1. Ziel des Moduls

Je Kontext ein Speicheradapter, der eine Datei nur innerhalb der Kontextwurzel liest, den Inhalt selbst hasht und den Nachweis nach Vertrag liefert; Freigabe `get_file` nach 12.1.1. Teil 1 deckt Google Drive (`privat`) ab.

## 2. Verbindliche Entscheidungen

Unverändert gültig: alles aus den Vorübergaben, insbesondere E-1, E-2, A-6, A-7, REL-1, G-1, GATE-1.0, TS-23, PLAN-1.1, 1.1-E1 bis 1.1-E6, TS10-E1 bis TS10-E3.

Neu am 11.09.2026, von Rolf entschieden:

| ID | Entscheidung |
|---|---|
| V-4 | n8n-Variablen verfügbar (Scope „Personal“) |
| V-1 | Private Ablage im bestehenden privaten Google-Konto (Variante B), Credential `jv_privat_gdrive`; neu bewerten, falls ein weiterer Admin der n8n-Instanz dazukommt |
| 1.1b-E1 | Kontextwurzel als eigenes Feld `context_root_ref` (Variante A), Migrationen 0020–0022, Variablen `JV_PRIVAT_ROOT_FOLDER_ID`, `JV_VISOLVA_ROOT_FOLDER_ID` |
| 1.1b-E2 | 1.1-A14 erst in 1.1d: `get_file` in 1.1b nur freigegeben, Verdrahtung in `tool_invoke` erst nach dem A14-Lauf im Hauptablauf. Ändert Tabelle 7 der Freigabevorlage |
| REL-1.1b | `storage_gdrive.get_file@1.1.0` → `approved` (Migration 0023) |
| TS-27 A | Einrichtungsprüfung liest nur die neun JARVIS-Ordner, keine Ordnerliste des Kontos |

Arbeitsannahmen AA-B1 bis AA-B7 (Vorlage 1.1b) gelten; AA-B6 präzisiert: Testobjekte über Ordner-Variablen, der Smoke-Test findet sie selbst.

## 3. Umgesetzte Komponenten

| Komponente | Status |
|---|---|
| Migrationen 0020, 0021 (erzeugt, Konfiguration 1.1.0), 0022, 0023 | produktiv, getestet |
| `config/intake_config.json` 1.1.0, Schema, `tools/render_intake_config.py` (K9, K10, Ausgabe je Version) | im Repo-Entwurf, Selbsttest bestanden |
| `JV-CORE-ADP-storage_gdrive-v1` (`qZpVoKoKuPRyOGg7`) | produktiv, freigegeben, getestet; nicht in `tool_invoke` verdrahtet |
| Smoke-Test: Einrichtungsprüfung (SE-01–09), 13 Adapterfälle (SG-01–13), Freigabenachweis (SN-01) | Entwurf (wie vorgesehen), getestet |
| `tests/db/p1_1b_context_root.sql` | 9/9 in Supabase |
| Private Drive-Struktur | `JARVIS_privat` mit 00_Eingang, 10_Arbeit, 20_Entwuerfe, 30_Berichte, 90_Archiv, 99_Test; daneben `JARVIS_Test_ausserhalb`, `JARVIS_K07_Probe` |

**Nicht umgesetzt:** SharePoint-Adapter (V-3), OCR (1.1c), Hauptablauf und Dispatcher (1.1d), Verdrahtung `get_file` in `tool_invoke` (1.1d).

## 4. Dateien und Workflow-Namen

PR-Archiv `jarvis-phase-1-1b-teil1.zip` (Pfade relativ zum Repo):

- `db/migrations/0020_context_root_ref.sql`, `0021_intake_config_seed_1_1.sql`, `0022_context_root_ref_not_null.sql`, `0023_release_storage_gdrive_get_file_1_1_0.sql`, `db/migrations/README.md`
- `config/intake_config.json`, `config/schemas/intake_config.schema.json`, `tools/render_intake_config.py`, `tools/README.md`
- `tests/db/p1_1b_context_root.sql`, `tests/README.md`
- `n8n/core/JV-CORE-ADP-storage_gdrive-v1.json` (neu), `n8n/core/JV-CORE-OPS-smoke_test-v1.json`, `n8n/core/MANIFEST.md`
- `docs/decisions/DECISION_LOG.md`, `docs/evidence/PHASE_1_1B_GDRIVE_2026-09-11.md`, diese Übergabe, `README.md`

Credential neu: `jv_privat_gdrive` (`T9eXpovYsz2Ipp6B`). n8n-Variablen neu: `JV_PRIVAT_ROOT_FOLDER_ID`, `JV_PRIVAT_TEST_INSIDE_FOLDER_ID`, `JV_PRIVAT_TEST_OUTSIDE_FOLDER_ID` (Werte nur in n8n, reine IDs).

## 5. Datenmodelle und Schnittstellen

**`jarvis_ops.context_document_settings`:** neue Pflichtspalte `context_root_ref` (env-Verweis), Rollen-Eindeutigkeit einschliesslich Wurzel (`cds_refs_distinct`). `config_version` 1.1.0.

**`JV-CORE-ADP-storage_gdrive-v1`:**

- Eingabe wie alle Adapter: `context_id`, `action_id` (`act_…`), `tool_id` = `storage_gdrive.get_file`, `payload` {`context_id`, `adapter_id`, `file_external_id`, `include_content`?, `max_size_mb`?}, `dry_run`, `trace_id`.
- Erfolg: `status` `ok`, `verification_method` `provider_status`, `result` {`file_external_id`, `filename`, `mime_type`, `size_bytes`, `modified_at`, `content_hash` `sha256:…`, `provider_status` 200, `content_ref` `data` nur bei Inhalt}, `observed` {`provider_status`, `content_hash`, `provider_checksum`}, Binärdatum `data`.
- Fehler: `status` `error`, `checked_stage` (`input`, `config`, `metadata`, `root`, `type`, `content`), `error` {`error_class`, `error_code`, `retryable`, `message`}.
- Codes: `invalid_input`, `config_missing`, `config_unresolved`, `adapter_context_mismatch`, `metadata_mismatch`, `outside_context_root`, `root_check_incomplete`, `shortcut_not_allowed`, `not_a_file`, `no_binary_content`, `file_trashed`, `size_unknown`, `file_too_large`, `filename_invalid`, `content_missing`, `size_mismatch`, `checksum_mismatch`, `not_found`, `auth_failed`, `permission_denied`, `rate_limited`, `provider_timeout`, `provider_unavailable`, `provider_unreachable`. Wiederholbar nur `transient_network`, `rate_limited`, `timeout`.
- Wurzelprüfung vor jedem Download; Typ und Grösse erst danach (eine Datei ausserhalb liefert immer `outside_context_root`).

## 6. Ausgeführte Tests und Ergebnisse

| Test | Ergebnis | Beleg |
|---|---|---|
| DB-Test 1.1b / Rückwärts 1.1a | 9/9 / 21/21 | Supabase, erzwungener Rollback |
| Lokal PG 16: 0001–0023 inkl. Gegenproben | bestanden | Nachweis Abschnitt 2 |
| Smoke 22880 / 23001 / 23123 | 142/142 / 143/143 / 143/143 | n8n |
| Freigabenachweise | `evd_01M2826973HJ0PPK7SJH6PTVA8` (Freigabe), `evd_01M282Z7GJDD5B4GQARZZ7ZGJ1` | `jarvis_privat.evidence` |
| `check_ts10.py` gegen echten Export | 0 Befunde | Nachweis Abschnitt 6 |
| Wiederherstellung n8n 2.35.7 | 15 Workflows, 194 Knoten, 48 Credential-Zuordnungen, BESTANDEN | Nachweis Abschnitt 6 |

**Nicht getestet:** SharePoint (nicht gebaut); `get_file` über `tool_invoke` (1.1d); Wiederholung über den Dispatcher (1.1d).

## 7. Bekannte Fehler

Keine offenen. Nebenbefunde: Der Normalisierer schreibt weiterhin fest `jarvis_phase` 1.0; `check_restore.py` prüft die Kontext-Credential-Regel nur für Postgres-Knoten mit Kontext im Namen (Drive-Knoten nicht erfasst, Zuordnung über die Credential-IDs geprüft).

## 8. Technische Schulden

**Neu:**

| Nr. | Schuld | Wann |
|---|---|---|
| TS-27 | Läufe 22880 und 23001 enthalten die Ordnerliste des privaten Kontos (IDs, keine Namen); Massnahme A umgesetzt, Löschen der beiden Läufe offen | nach Merge |
| TS-28 | Adapter liest je Aufruf die Ordnerliste des Kontos für die Wurzelprüfung. **Aufnahme durch Rolf noch nicht bestätigt** | vor 1.1d bewerten |

**Weiter offen:** P1-TD1, TS-10b, TS-11 (→ 1.3), TS-12, TS-13, TS-16, TS-17 (Aufnahme unbestätigt), TS-18 (Vorgangsnummern jetzt privat bis **V-2026-0014**, visolva bis **V-2026-0011**), TS-19, TS-20, TS-21, TS-22, TS-25 (Aufnahme unbestätigt), TS-26, OFFEN-1.

## 9. Offene Entscheidungen und Voraussetzungen

| Nr. | Gegenstand | spätestens |
|---|---|---|
| V-3 | SharePoint-Testbibliothek, Credential `jv_visolva_sharepoint`, Variablen `JV_VISOLVA_*` inkl. `JV_VISOLVA_ROOT_FOLDER_ID` | vor 1.1b Teil 2 |
| V-5, V-6 | OCR-Zugänge, 20 Testdokumente | vor 1.1c |
| TS-28, TS-25, TS-17 | Aufnahme bestätigen | vor 1.1d / 1.4 / 1.3 |
| P1-O3 | OCR-Dienst | Ende 1.1 |
| übrige | wie Vorübergabe | wie Vorübergabe |

## 10. Exakter nächster Bauschritt

1. **Repo-Übernahme:** Archiv `jarvis-phase-1-1b-teil1.zip` auf einen Transfer-Branch legen, Claude Code legt den PR gegen `main` `eb190cf` an, byteweise Prüfung gegen das Archiv, Merge durch Rolf, Transfer-Branch löschen.
2. **Nach dem Merge:** Läufe 22880 und 23001 in n8n löschen (TS-27).
3. **Danach, je nachdem, was zuerst bereitsteht:**
   - V-3 erfüllt → 1.1b Teil 2 in neuem Chat: `JV-CORE-ADP-storage_sharepoint-v1` nach demselben Muster (Wurzel `JV_VISOLVA_ROOT_FOLDER_ID`, Bibliothek `JV_VISOLVA_SP_DRIVE_ID`, AA-B7), Smoke-Erweiterung, Freigabe `storage_sharepoint.get_file@1.0.0`.
   - V-5, V-6 erfüllt → 1.1c (OCR-Bewertung, P1-O3) in neuem Chat.
   - Jeder neue Workflow muss `tests/n8n/check_ts10.py` bestehen.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
