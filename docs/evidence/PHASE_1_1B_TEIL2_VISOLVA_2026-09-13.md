# Nachweis Phase 1.1b Teil 2 - Speicheradapter fuer arbeitgeber_visolva

Datum: 13.09.2026
Grundlage: Aenderungspaket 1.1b-E3 (freigegeben Rolf, 13.09.2026), Entscheidung 1.1b-E4 Variante A.

## 1 Ausgangslage

Teil 2 war urspruenglich als SharePoint-Adapter geplant (ADR-001, 1.1-E1). Voraussetzung V-3
liess sich nicht erfuellen: Der Microsoft-365-Mandant `viterma365` verlangt fuer jede
Graph-Berechtigung eine Administratorzustimmung; Rolf ist dort kein Administrator.

Test T1 (13.09.2026), lesende Pruefung ohne Umsetzung:

| Schritt | Ergebnis |
|---|---|
| App-Registrierung durch Benutzer | moeglich (`JARVIS n8n Test`) |
| Berechtigung `Files.Read` (ohne Adminzustimmung laut Microsoft-Standard) | Mandant verlangt trotzdem Adminzustimmung |
| Benutzerzustimmung `Sites.Selected` | Mandant verlangt Adminzustimmung |

Ergebnis: Jeder Graph-Zugriff im Mandanten benoetigt die Viterma-IT. Genehmigungsanforderung
fuer `Sites.Selected` + `offline_access` gestellt, Begleitmail an die IT versendet.
SharePoint bleibt offen als TS-30.

## 2 Umgesetzt

| Gegenstand | Stand |
|---|---|
| Google-Drive-Struktur Visolva (`rolf@visolva.pro`) | `JARVIS_visolva` mit 00_Eingang, 10_Arbeit, 20_Entwuerfe, 30_Berichte, 90_Archiv, 99_Test; daneben `JARVIS_Test_ausserhalb` |
| Testdateien | `SYNTH_test_innen.pdf` (99_Test), `SYNTH_test_aussen.pdf` (ausserhalb) |
| Credential | `jv_visolva_gdrive` (Google Drive OAuth2, Managed OAuth2) |
| Variablen | acht `JV_VISOLVA_*`; `JV_VISOLVA_SP_DRIVE_ID` entfaellt |
| Migration 0024 | `storage_gdrive.get_file@1.2.0` registriert (draft), Kontexte privat + arbeitgeber_visolva |
| Migration 0025 | Konfiguration 1.2.0: Visolva auf `storage_gdrive`, Bindung `visolva_drive_inbox`; `visolva_sharepoint_inbox` deaktiviert |
| Migration 0026 | 1.2.0 auf `approved`, 1.1.0 auf `deprecated` |
| Workflow `JV-CORE-ADP-storage_gdrive_visolva-v1` (IHdbJYSAs2HtMzK6) | angelegt, veroeffentlicht |
| Workflow `JV-CORE-OPS-smoke_test-v1` (P5IlT5RlGBK1aqiO) | 58 auf 69 Knoten erweitert |

Der Visolva-Adapter ist eine geprueft gleiche Kopie des privaten Adapters. Abweichungen genau
in vier Knoten: Kontextweiche (`arbeitgeber_visolva` statt `privat`), drei Google-Knoten
(`jv_visolva_gdrive`), Einstellungsabfrage (`Einstellungen lesen jarvis_visolva`,
`jv_visolva_postgres`). Kein Vorkommen von `privat` im gesamten Workflow.

## 3 Testlaeufe

| Lauf | Ergebnis | Anmerkung |
|---|---|---|
| 23672 | 162/167 | fuenf Befunde: C02 auf deaktivierter Bindung; Variable `JV_VISOLVA_TEST_OUTSIDE_FOLDER_ID` mit Tippfehler (SV-03, SV-07, SV-09, SVG-03) |
| 23802 | **168/168 BESTANDEN** | nach Korrektur beider Ursachen |

Behebung: C02 auf `visolva_drive_inbox` umgestellt, neue Gegenprobe C02b (deaktivierte
Bindung muss `binding_disabled` liefern); Ordner-ID korrigiert.

## 4 Abnahme

| Nr. | Kriterium | Beleg aus Lauf 23802 |
|---|---|---|
| S-A1 | Einrichtungspruefung | SV-00 Adapter=storage_gdrive, Konfiguration=1.2.0; SV-01 bis SV-09 |
| S-A2 | Normalfall, nur Metadaten | SVG-01 (ok, Binaerdatum, sha256, Pruefsumme match), SVG-02 (kein Binaerdatum, gleicher Hash) |
| S-A3 (1.1-A11) | Wurzelpruefung | SVG-03 `outside_context_root`, Stufe `root`, kein Download |
| S-A4 | Gegenproben | SVG-04 `not_a_file`, SVG-05 `not_found`, SVG-07 falsches Werkzeug, SVG-08 Probelauf, SVG-09 Zusatzfeld |
| S-A5 | Kontexttrennung | SG-09 (privat-Adapter weist Visolva ab), SVG-06 (Visolva-Adapter weist privat ab), SV-08 (keine gemeinsame Ordner-ID), C02b |
| S-A6 (1.1-A16) | Freigabe mit Nachweis | `evd_01M2E6A38ZX84HYP8C6WA5HPGE` in `jarvis_visolva.evidence`, Vertrag 1.2.0, `provider_status`, `confirmed`; Migration 0026, genau eine `approved`-Version |
| S-A7 (1.1-A17) | keine Inhalte in jarvis_ops | Adapter speichert keine Ausfuehrungsdaten (`saveData*` = none); Pruefungstexte ohne Ordner- und Datei-IDs |
| S-A8 (1.1-A18/A20) | statische Pruefung, binaryMode | `check_ts10.py --src n8n/core`: 15 Workflows, 72 Knoten, ERGEBNIS BESTANDEN; Selbsttest 6 Faelle; `binaryMode` = `separate` in beiden Exporten |

Generator-Gegenproben: `render_intake_config.py --check` und `render_tool_registry.py --set 0024 --check`
bestaetigen, dass 0024 und 0025 den Quelldateien entsprechen.

## 5 Exportabgleich TS-33a (13.09.2026)

Beide Workflows wurden aus der n8n-Oberflaeche heruntergeladen und mit
`tools/normalize_n8n_export.py --date 2026-09-13` normalisiert
(Adapter zusaetzlich `--phase 1.1b`, Entscheidung E-1). Vergleich gegen die zuvor
handgepflegten Dateien:

| Merkmal | Adapter Visolva | Smoke-Test |
|---|---|---|
| Verbindungen | identisch | identisch |
| Knoten ohne `id` (Parameter, Typ, Position, Credentials) | 19 von 19 identisch | 69 von 69 identisch |
| Knoten-IDs | alle 19 in der alten Datei erfunden | 11 Knoten ohne `id` |
| `settings` | alte Datei fuehrte zusaetzlich `saveExecutionProgress` (kein Feld der Normalisierung) | identisch |
| `meta` | Credential-Reihenfolge | `jarvis_exported_at` 11.09. statt 13.09.; `jv_visolva_gdrive` fehlte in `jarvis_required_credentials` |

Ergebnis: **kein fachlicher Unterschied.** Die laufende Instanz entspricht dem, was in
Lauf 23802 geprueft wurde; der Nachweis bleibt gueltig. Die Repo-Dateien stammen jetzt aus
dem Download und sind byteweise mit ihm identisch.

Zwei Befunde, die nur der echte Download zeigt und die die Wiederherstellung betroffen haetten:
die erfundenen Knoten-IDs und das fehlende Credential `jv_visolva_gdrive` in der
Anforderungsliste des Smoke-Tests (Credential-Huellen werden daraus angelegt).

Gegenprobe nach dem Austausch: `check_ts10.py --src n8n/core` BESTANDEN (15 Workflows,
72 Knoten, 13 Kontextweichen), Selbsttest 6 Faelle; `normalize_n8n_export.py --self-test`
BESTANDEN (7 Pruefungen, 2 Gegenproben, einschliesslich `--phase`).

Ein Zwischenbefund aus der n8n-Leseschnittstelle, `settings.binaryMode` sei in beiden
Workflows nicht gesetzt, hat sich als **Falschbefund** erwiesen: der Download fuehrt
`binaryMode: "separate"` in beiden Workflows. TS-24 ist nicht betroffen.

## 6 Nicht erbracht

- **Wiederherstellungstest in leerer Instanz** (`check_restore.py`): nicht ausgefuehrt. Er
  setzt `n8n import:workflow` und `export:workflow`/`export:credentials` auf der Kommandozeile
  voraus; n8n Cloud bietet diesen Zugang nicht. Offen als **TS-33b**; erforderlich ist eine
  eigene leere Instanz. Faellig vor dem Pilotstart, nicht vor diesem PR (Entscheidung E-2).
