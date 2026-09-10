# Nachweis Schritt 1.1a — Entwurf, lokaler Test

**Stand:** 10. September 2026
**Status:** Entwurf zur Durchsicht. **Nicht in Supabase eingespielt**, n8n unverändert.
**Grundlage:** Freigabevorlage `docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md`, Entscheidungen 1.1-E1, 1.1-E3, 1.1-E4, 1.1-E6, TS-24

## 1. Umfang

| Gegenstand | Datei |
|---|---|
| Laufzeittabellen Eingang, Ausnahmeliste ohne Kontext | `db/migrations/0016_intake_runtime_tables.sql` |
| Eingangskonfiguration (nur env-Verweise) und Schema | `config/intake_config.json`, `config/schemas/intake_config.schema.json` |
| Generator Eingangskonfiguration, Migration 0017 | `tools/render_intake_config.py`, `db/migrations/0017_intake_config_seed.sql` |
| Registernachtrag 1.1 (ADR-001), Migration 0018 | `spec/phase-1/nachtrag-1.1/`, `tools/render_tool_registry.py` (`--set 0018`), `db/migrations/0018_tool_registry_seed_1_1.sql` |
| `storage_gdrive.get_file@1.0.0` ausser Betrieb | `db/migrations/0019_deprecate_storage_gdrive_get_file_1_0_0.sql` |
| TS-24 `binaryMode` im Export | `tools/normalize_n8n_export.py`, `tests/n8n/check_restore.py` |
| Prüfskript | `tests/db/p1_1a_runtime_config.sql` |

## 2. Ergebnisse (lokal, PostgreSQL 16.15, Administrator = Superuser)

| Prüfung | Ergebnis |
|---|---|
| `render_tool_registry.py --self-test` | bestanden: 14 + 3 Werkzeuge, 7 Gegenproben |
| `render_tool_registry.py --check 0014` | bytegleich zum Stand vor 1.1 |
| `render_tool_registry.py --set 0018 --check 0018` | OK |
| `render_intake_config.py --self-test` | bestanden: deterministisch, Probe zulässig, 8 Gegenproben (K1–K8) |
| `render_intake_config.py --check 0017` | OK |
| `normalize_n8n_export.py --self-test` | bestanden: 5 Prüfungen, 2 Gegenproben |
| 0001–0019 in leere Datenbank | fehlerfrei |
| 0017, 0018, 0019 je zweimal | fehlerfrei, zweiter Lauf ohne Wirkung |
| `tests/db/p1_1a_runtime_config.sql` | **21/21 bestanden**, davon 13 Gegenproben mit erwarteter Fehlerart; 0 Restzeilen |
| Regression `tests/db/phase_1_0_acceptance.py` auf 0001–0019 | 23/23 bestanden |
| Registerstand nach 0019 (leere DB) | 16 × `draft`, 1 × `deprecated`, 1 Eintrag `tool_release_log` |

## 3. Nicht getestet

- Einspielen in Supabase (PostgreSQL 17.6, Administrator ohne Superuser). Relevant für `current_context_id()`: Der Administrator ist dort Mitglied der Kontextrollen mit `INHERIT FALSE` (0010) und wird deshalb nicht als Kontextbenutzer erkannt — lokal über den Superuser-Ausschluss abgedeckt, auf Supabase erst nach dem Einspielen belegt.
- Zugriff über die Login-Benutzer `jv_*_login` und den Session Pooler.
- Smoke-Test nach dem Einspielen. Erwartung 104/104: `evidence_verify` liest das Register ohne Statusfilter, die Fälle E03/E04 mit `storage_gdrive.get_file@1.0.0` bleiben unverändert.

## 4. Hinweise aus dem Entwurf

- `evidence_verify` prüft den Registerstatus nicht; ein Nachweis gegen eine `deprecated`-Version bleibt möglich. Smoke-Fälle E03/E04 auf 1.1.0 umstellen, sobald der Smoke-Test in 1.1b ohnehin geändert wird.
- Die Mehrdeutigkeitsprüfung in `context_resolve` muss auf den **aufgelösten** Ordner-IDs arbeiten, nicht nur auf den env-Namen: Zwei verschiedene Variablen können denselben Ordner enthalten.
- Die K-07-Probe (`purpose: probe`) steht nicht in der Grundkonfiguration. Sie wird für den Nachweis als eigene Konfigurationsversion ergänzt und danach wieder entfernt (0017 deaktiviert sie).
