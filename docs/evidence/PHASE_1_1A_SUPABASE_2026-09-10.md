# Nachweis Schritt 1.1a — Einspielen in Supabase

**Stand:** 10. September 2026, 22:38 MESZ
**Repo-Stand:** `main` d12f218 (PR #9), Migrationen vor dem Einspielen im Repo abgelegt
**Status:** 0016 bis 0019 produktiv in Supabase. n8n unverändert.

## 1. Ausgangsstand vor dem Einspielen

Letzte Migration `0015_case_number_seq_sync`; neue Tabellen nicht vorhanden; Register 3 × `approved`, 11 × `draft`; `tool_release_log` 3 Einträge.

## 2. Eingespielt (Supabase `apply_migration`, Inhalt = Repo-Dateien auf `main`)

| Migration | Ergebnis |
|---|---|
| `0016_intake_runtime_tables` | erfolgreich |
| `0017_intake_config_seed` | erfolgreich, Selbstprüfung bestanden (sha256 `1bca1df0…`) |
| `0018_tool_registry_seed_1_1` | erfolgreich, Datenbank rechnet alle drei Prüfwerte nach |
| `0019_deprecate_storage_gdrive_get_file_1_0_0` | erfolgreich, Selbstprüfung bestanden |

## 3. Prüfung gegen Supabase (PostgreSQL 17.6, Administrator ohne Superuser)

Inhalt von `tests/db/p1_1a_runtime_config.sql` als ein `DO`-Block, Abschluss mit erzwungenem Fehler (vollständiges Zurückrollen):

`P11A_ERGEBNIS: 21 von 21 bestanden, Benutzer postgres; Abweichungen: keine`

Danach: `intake_exception` 0 Zeilen, keine angehaltene Bindung. Belegt ist damit auch der Punkt aus dem lokalen Test: Der Administrator wird auf Supabase nicht als Kontextbenutzer erkannt (A01), die Kontextrollen schon (P01, V01).

## 4. Stand danach

| Gegenstand | Wert |
|---|---|
| Register | 3 × `approved`, 13 × `draft`, 1 × `deprecated` (`storage_gdrive.get_file@1.0.0`) |
| `tool_release_log` | 4 Einträge (neu: Ausserbetriebnahme mit Verweis 1.1-E1) |
| `source_binding` | `privat_drive_inbox` (storage_gdrive), `visolva_sharepoint_inbox` (storage_sharepoint), beide aktiv |
| `context_document_settings` | 2 Kontexte, OCR-Positivliste leer |

## 5. Smoke-Test

Ausführung **22498** (per MCP ausgelöst): **104/104 bestanden**, einschliesslich E03/E04 gegen `storage_gdrive.get_file@1.0.0` (wie erwartet, `evidence_verify` prüft den Status nicht). Der Lauf schrieb wie jeder Lauf synthetische Daten (TS-18).

## 6. Nicht getestet

Zugriff über die Login-Benutzer `jv_*_login` und den Session Pooler auf die neuen Tabellen (erstmals mit `context_resolve` aus der Datenbank in 1.1a-Rest).
