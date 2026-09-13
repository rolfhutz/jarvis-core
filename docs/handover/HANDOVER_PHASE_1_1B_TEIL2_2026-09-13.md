# Uebergabe Phase 1.1b Teil 2 - Speicheradapter arbeitgeber_visolva

Datum: 13.09.2026
Vorgaenger: `docs/handover/HANDOVER_PHASE_1_1B_TEIL1_2026-09-11.md` (main `b763ea9`, PR #11)
Nachweis: `docs/evidence/PHASE_1_1B_TEIL2_VISOLVA_2026-09-13.md`

## 1 Ziel des Moduls

Der Kontext `arbeitgeber_visolva` kann eine Datei aus seiner eigenen Ablage lesen, begrenzt
auf die Kontextwurzel, mit eigenem Zugang und eigener Nachweis-Datenbank. Damit ist der
Speicherteil von 1.1b fuer beide Kontexte abnahmefaehig.

## 2 Verbindliche Entscheidungen

| Nr. | Inhalt |
|---|---|
| V3-E1 | SharePoint-Zugang A2 (delegiert, `Sites.Selected`). Test T1: Mandant `viterma365` verlangt fuer jede Graph-Berechtigung Adminzustimmung; Rolf ist dort kein Administrator. Genehmigungsanforderung gestellt, Begleitmail an die IT versendet. Ausgang offen |
| 1.1b-E3 | `arbeitgeber_visolva` laeuft vorlaeufig ueber Google Drive (`rolf@visolva.pro`). Abweichung von ADR-001: Trennung nicht mehr ueber verschiedene Anbieter, sondern ueber Kontext, Credential, Wurzel und Nachweis-Datenbank |
| 1.1b-E4 | Eigener Adapter-Workflow je Kontext (Variante A) statt Kontextverzweigung im privaten Adapter. Grund: n8n bindet Credentials fest je Knoten |
| REL-1.1b-2 | `storage_gdrive.get_file@1.2.0` `approved` (beide Kontexte), 1.1.0 `deprecated`. Genau eine freigegebene Version je Werkzeug |
| TS-28 | Drive-Adapter liest fuer die Wurzelpruefung die Ordnerliste des Kontos. Vor 1.1d bewerten |
| 1.1b-E5 | `normalize_n8n_export.py` erhaelt `--phase` (Standard `1.0`); der Adapter wird mit `--phase 1.1b` normalisiert. Grund: Bauabschnitt war im Skript hart auf `1.0` gesetzt |
| 1.1b-E6 | TS-33 aufgeteilt: **TS-33a** (Exporttreue) erledigt, **TS-33b** (Wiederherstellung) offen. `check_restore.py` braucht n8n-CLI und eine leere Instanz; auf n8n Cloud nicht verfuegbar. PR erfolgt ohne diesen Nachweis |
| unveraendert | 1.1b-E1 (Kontextwurzel als eigenes Feld), 1.1b-E2 (Verdrahtung in `tool_invoke` erst in 1.1d), TS10-E1/E2/E3, TS-23 |

## 3 Umgesetzte Komponenten

- Drive-Struktur Visolva: `JARVIS_visolva` mit sechs Rollenordnern, daneben `JARVIS_Test_ausserhalb`;
  zwei synthetische PDF (`SYNTH_test_innen.pdf`, `SYNTH_test_aussen.pdf`)
- Credential `jv_visolva_gdrive`; acht Variablen `JV_VISOLVA_*` (`JV_VISOLVA_SP_DRIVE_ID` entfaellt)
- Migrationen 0024, 0025, 0026 (eingespielt und nachgeprueft)
- Registerdatei `spec/phase-1/nachtrag-1.1b/registry/tool_registry_phase1_1b.json`
- Workflow `JV-CORE-ADP-storage_gdrive_visolva-v1`, veroeffentlicht
- Smoke-Test um den Visolva-Speicherteil erweitert (58 auf 69 Knoten)
- Beide Workflowdateien aus dem n8n-Download uebernommen und normalisiert (TS-33a);
  `normalize_n8n_export.py` um `--phase` erweitert

## 4 Dateien und Workflow-Namen

| Datei | Art |
|---|---|
| `config/intake_config.json` | geaendert (1.2.0) |
| `db/migrations/0024_tool_registry_seed_1_1b.sql` | neu, erzeugt |
| `db/migrations/0025_intake_config_seed_1_2.sql` | neu, erzeugt |
| `db/migrations/0026_release_storage_gdrive_get_file_1_2_0.sql` | neu |
| `db/migrations/README.md` | geaendert |
| `docs/decisions/DECISION_LOG.md` | geaendert |
| `docs/evidence/PHASE_1_1B_TEIL2_VISOLVA_2026-09-13.md` | neu |
| `docs/handover/HANDOVER_PHASE_1_1B_TEIL2_2026-09-13.md` | neu |
| `n8n/core/JV-CORE-ADP-storage_gdrive_visolva-v1.json` | neu |
| `n8n/core/JV-CORE-OPS-smoke_test-v1.json` | geaendert |
| `n8n/core/MANIFEST.md` | geaendert |
| `spec/phase-1/nachtrag-1.1b/registry/tool_registry_phase1_1b.json` | neu |
| `tools/normalize_n8n_export.py` | geaendert (`--phase`, 1.1b-E5) |
| `tools/render_intake_config.py` | geaendert (Version 1.2.0 -> Migration 0025) |
| `tools/render_tool_registry.py` | geaendert (Satz 0024) |

Workflow-IDs: Adapter Visolva `IHdbJYSAs2HtMzK6`, Adapter privat `qZpVoKoKuPRyOGg7`,
Smoke-Test `P5IlT5RlGBK1aqiO`, `evidence_verify` `UKcnRE0eJzyl8T1V`.
Credential-IDs: `jv_visolva_gdrive` `r79T8YvgoloadnXV`, `jv_visolva_postgres` `7BblU6FbDds3EZBb`.

## 5 Datenmodelle und Schnittstellen

- `jarvis_ops.context_document_settings`: beide Kontexte auf `config_version` 1.2.0,
  `storage_adapter_id` = `storage_gdrive`, `storage_container_ref` = NULL
- `jarvis_ops.source_binding`: `privat_drive_inbox` und `visolva_drive_inbox` aktiv,
  `visolva_sharepoint_inbox` deaktiviert (nicht geloescht)
- `jarvis_ops.tool_registry`: `storage_gdrive.get_file` 1.0.0/1.1.0 `deprecated`, 1.2.0 `approved`;
  `storage_sharepoint.*` bleiben `draft`
- Adapter-Vertrag unveraendert (Ein- und Ausgabeschema aus Nachtrag 1.1)

## 6 Tests und Ergebnisse

| Lauf | Ergebnis |
|---|---|
| 23672 | 162/167, fuenf Befunde (deaktivierte Bindung im Fall C02; Tippfehler in `JV_VISOLVA_TEST_OUTSIDE_FOLDER_ID`) |
| 23802 | **168/168 BESTANDEN** |

Zusaetzlich: `check_ts10.py --src n8n/core` BESTANDEN (15 Workflows, 72 Knoten) und Selbsttest
6 Faelle; `render_intake_config.py --check` und `render_tool_registry.py --set 0024 --check` ok;
Nachweis `evd_01M2E6A38ZX84HYP8C6WA5HPGE` in Supabase gegengeprueft.

Exportabgleich TS-33a (13.09.2026): beide Workflows aus n8n heruntergeladen, normalisiert
und uebernommen. Verbindungen, `settings` und alle Knoten (19 bzw. 69) inhaltlich identisch,
kein fachlicher Unterschied; Lauf 23802 bleibt gueltig. Korrigiert wurden 19 erfundene
Knoten-IDs im Adapter, 11 Knoten ohne `id` im Smoke-Test und das fehlende Credential
`jv_visolva_gdrive` in dessen Anforderungsliste. Gegenproben danach: `check_ts10.py --src n8n/core`
BESTANDEN (15 Workflows, 72 Knoten) und `normalize_n8n_export.py --self-test` BESTANDEN
(7 Pruefungen, 2 Gegenproben).

Abnahme S-A1 bis S-A8: erfuellt, Belege je Kriterium in der Nachweisdatei.

## 7 Bekannte Fehler

Keine offenen Fehler. Beide Befunde aus Lauf 23672 sind behoben und im Folgelauf gruen.

## 8 Technische Schulden

| Nr. | Inhalt |
|---|---|
| TS-28 | Wurzelpruefung liest die Ordnerliste des Kontos; vor 1.1d bewerten |
| TS-30 | SharePoint-Adapter offen; setzt die Freigabe der Viterma-IT voraus. Site `Visolva-JARVIS-Test`, App `JARVIS n8n Test` und Credential `jv_visolva_sharepoint_test` bleiben dafuer bestehen |
| TS-31 | `jv_visolva_gdrive` hat vollen Lese- und Schreibzugriff auf Drive und Google Fotos von `rolf@visolva.pro`; einzige fachliche Grenze ist die Wurzelpruefung. Vor Echtdaten eigener OAuth-Client mit `drive.readonly` oder SharePoint |
| TS-32 | Adapterlogik doppelt (privat und Visolva); Aenderungen immer in beiden Workflows |
| TS-33a | erledigt: Exporte stammen aus dem Download und sind byteweise mit ihm identisch |
| TS-33b | Wiederherstellungstest `check_restore.py` nicht ausgefuehrt; braucht eine leere n8n-Instanz mit CLI. Faellig vor dem Pilotstart |
| Bestand | TS-10b, TS-11, TS-12, TS-18, TS-19, TS-24, TS-26, TS-27 (erledigt bis auf geloeschte Laeufe) |

## 9 Offene Entscheidungen

- Antwort der Viterma-IT auf die Genehmigungsanforderung. Bei Zustimmung: Rueckkehr zu
  SharePoint als eigener Bauabschnitt unter TS-30, sonst Entscheidung ueber einen eigenen
  Microsoft-365-Testmandanten
- Zeitpunkt fuer TS-31 (engerer Drive-Zugang)

## 10 Exakt naechster Bauschritt

1. PR gegen `main` (Basis `b763ea9`) mit den 15 Dateien aus Abschnitt 4, mergen,
   Transfer-Branch loeschen.
2. Danach Bauabschnitt **1.1c** (OCR-Adapter) beginnen; Voraussetzungen V-5 (OCR-Zugaenge)
   und V-6 (20 Testdokumente) zuerst klaeren.
3. TS-33b terminieren: leere n8n-Instanz fuer `check_restore.py`, faellig vor dem Pilotstart.

Bestehende Entscheidungen nicht neu erfinden. Aenderungen nur ausdruecklich begruendet und nach Freigabe.
