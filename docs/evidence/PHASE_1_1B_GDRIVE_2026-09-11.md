# Nachweis Phase 1.1, Bauabschnitt 1.1b Teil 1 — Kontextwurzel und Speicheradapter Google Drive

**Datum:** 11. September 2026
**Grundlage:** Freigabevorlage 1.1 (1.1-A11, A16, A17, A18, A20), SPEC 4.0.2 Abschnitt 12.1.1, ADR-001, Entscheidungen 1.1b-E1, 1.1b-E2, REL-1.1b, TS-27 (DECISION_LOG)
**Status:** Datenbank, Adapter und Freigabe produktiv und getestet; Export, statische Pruefung und Wiederherstellung bestanden (Abschnitt 6). Repo-Uebernahme per PR offen. SharePoint (Teil 2): wartet auf V-3.

## 1. Ergebnis

`storage_gdrive.get_file@1.1.0` ist nach 12.1.1 freigegeben (nur `privat`). Der Adapter liest
eine Datei nur innerhalb der Kontextwurzel `JARVIS_privat`, prueft die Wurzel vor jedem
Download, bildet den sha256 selbst und gleicht ihn mit der Pruefsumme von Google Drive ab.
In `tool_invoke` ist er nach 1.1b-E2 noch nicht verdrahtet (1.1-A14 in 1.1d).

## 2. Datenbank (1.1b-E1)

| Schritt | Beleg | Ergebnis |
|---|---|---|
| 0020 Spalte `context_root_ref`, Eindeutigkeit der Rollen | `apply_migration` | erfolgreich |
| 0021 erzeugt aus `intake_config.json` 1.1.0 | `apply_migration`, Selbstpruefung | erfolgreich, `--check` bytegleich |
| 0022 Pflichtspalte | `apply_migration`, Selbstpruefung | erfolgreich |
| `tests/db/p1_1b_context_root.sql` | Supabase, erzwungener Rollback | 9/9 |
| `tests/db/p1_1a_runtime_config.sql` (Rueckwaerts) | Supabase, erzwungener Rollback | 21/21, keine Restzeilen |
| Lokal PostgreSQL 16 | 0001–0022, Gegenproben | `0022` vor `0021` bricht ab; `0017` erneut scheitert an der Pflichtspalte (gewollt); `0021`/`0022` wiederholbar |
| Generator | `render_intake_config.py --self-test` | 11 Gegenproben; alter Stand erzeugt `0017` weiterhin bytegleich |

## 3. Adapter `JV-CORE-ADP-storage_gdrive-v1` (`qZpVoKoKuPRyOGg7`)

Ablauf: Eingabe → Kontextweiche (nur `privat`, Ausweichausgang verbunden) → Einstellungen
(`jv_privat_postgres`) → Wurzel ueber n8n-Variable → Metadaten → Grundpruefung
(geteilte Ablage, Elternordner) → Ordnerliste und Aufstieg bis zur Wurzel → Typ und Groesse
→ **erst dann** Download → sha256, Groessen- und Pruefsummenabgleich.

- Veroeffentlicht, `versionId` = `activeVersionId` (MCP).
- `callerPolicy` = `workflowsFromAList`, `callerIds` = `tool_invoke`, Smoke-Test (A-6).
- `saveDataSuccessExecution` = `saveDataErrorExecution` = `none`, `saveManualExecutions` = false (AA-B5, 1.1-A17).
- `check_ts10.py`: 0 Befunde, auch gegen den echten Export (Abschnitt 6).
- Lokaler Logiktest der Codeknoten: 22 Faelle bestanden.

## 4. Smoke-Test und Freigabe

| Lauf | Zeit (UTC) | Zustand | Ergebnis |
|---|---|---|---|
| 22880 | 10:59 | Speicherteil neu, vor Freigabe | 142/142 |
| 23001 | 11:03 | mit Freigabenachweis, vor Freigabe | **143/143 = Freigabenachweis** |
| — | 11:14:36 | Migration 0023 | `approved`, `tool_release_log` mit Verweis |
| 23123 | 11:17 | nach Freigabe, TS-27 A | **143/143** |

Freigabenachweis nach Vertrag (12.1.1 Schritt 4): `evd_01M2826973HJ0PPK7SJH6PTVA8` in
`jarvis_privat.evidence`, `provider_status`, `confirmed`, erwartet `{provider_status: 200,
provider_checksum: match}`, Einschraenkung „Leseoperation“ gesetzt. Nachlauf 23123:
`evd_01M282Z7GJDD5B4GQARZZ7ZGJ1`.

### Einrichtungspruefung (B-A1), Stand 23123

SE-01 alle 9 Variablen reine IDs · SE-02 9 verschiedene Ordner · SE-03 alle lesbar ·
SE-04 Wurzel lesbar · SE-05 fuenf Rollenordner direkt unter der Wurzel · SE-06 Testordner
innen unter der Wurzel · SE-07 Testordner aussen und SE-08 K-07-Ordner neben der Wurzel ·
SE-09 Testobjekte vollstaendig. Alle bestanden.

### Adapterfaelle (A-6, Adapter direkt)

| Fall | Erwartung | Abnahme |
|---|---|---|
| SG-01 Datei in der Wurzel | `ok`, Binaerdatum, sha256, Pruefsumme `match` | B-A2 |
| SG-02 `include_content=false` | `ok`, kein Binaerdatum, gleicher Hash | B-A2 |
| SG-03 Datei ausserhalb | `outside_context_root`, Stufe `root`, kein Binaerdatum | **1.1-A11** |
| SG-04 Verknuepfung auf aussen | `shortcut_not_allowed`, Stufe `type` | B-A3 |
| SG-05 Google-Dokument | `no_binary_content` | B-A4 |
| SG-06 Ordner | `not_a_file` | B-A4 |
| SG-07 Grenze 1 MB | `file_too_large` | B-A4 |
| SG-08 unbekannte Datei | `not_found`, Stufe `metadata` | B-A4 |
| SG-09 fremder Kontext | abgewiesen ohne Kontextweiche | B-A4 |
| SG-10 falsches Werkzeug, SG-11 Pfad statt ID, SG-13 Zusatzfeld | abgewiesen, Stufe `input` | B-A4 |
| SG-12 Probelauf | `dry_run`, kein Aufruf | B-A2 |

Nicht im Smoke-Test, sondern lokal belegt: fehlende oder als Link eingetragene Variable
(`config_unresolved`), falscher Adapter fuer den Kontext, unvollstaendige Ordnerliste,
Zyklus, Einordnung von 404/403/429/5xx.

## 5. Kein Dokumentinhalt in `jarvis_ops` (1.1-A17)

Der Adapter schreibt nichts. Der Freigabenachweis liegt im Kontextschema und enthaelt nur
`provider_status`, Hash und Pruefsummenstatus, keinen Dateinamen. Die Ausfuehrungsdaten des
Adapters werden nicht gespeichert.

## 6. Export und Wiederherstellung

- **Quelle:** Downloads aus n8n Cloud (Rolf, 11.09.2026, 11:32): `JV-CORE-ADP-storage_gdrive-v1` (`versionId` = `activeVersionId` `59673e98…`) und `JV-CORE-OPS-smoke_test-v1` (`versionId` `a8f924e9…`, zuletzt geaendert 11:16:31, also vor Lauf 23123). Die uebrigen 13 Exporte sind unveraendert aus `eb190cf`.
- **Abgleich Adapter gegen Quellstand:** 19 Knoten, Code bytegleich. Vier Abweichungen nur durch von n8n weggelassene Standardwerte (`method` GET, `paginationMode`, Parametertyp `qs`, `outputPropertyName` `data`, Ausgangsschluessel der Weiche).
- **Abgleich Smoke-Test gegen `eb190cf`:** 11 Knoten neu, geaendert nur `Auswertung` (Speicherpruefungen angehaengt), eine Kante ersetzt; neue Codeknoten bytegleich mit dem getesteten Stand.
- **Normalisiert** mit `tools/normalize_n8n_export.py` (Selbsttest 5 Pruefungen, 2 Gegenproben). `binaryMode` = `separate` bei Adapter und Smoke-Test erhalten (TS-24).
- **Keine Drive-IDs** in den Exporten (Suche nach allen im Test verwendeten Datei- und Ordnerkennungen: 0 Treffer); Ordner und Dateien kommen nur ueber `$vars`.
- **`check_ts10.py`** gegen `n8n/core`: 14 gepruefte Workflows, 1 Ausnahme (Smoke-Test), 12 Kontextweichen, **0 Befunde**; Selbsttest 6 Faelle.
- **Wiederherstellung:** frische lokale n8n-Instanz 2.35.7 (Node v22.22.2), leere SQLite-Datenbank, eigener Schluessel, drei Credential-Huellen mit den festen IDs.
  - Import: `Successfully imported 15 workflows.`
  - `check_restore.py`: `{"workflows": 15, "knoten": 194, "credential_zuordnungen": 48, "subworkflow_verweise": 22, "aufruferregeln": 8, "binaermodus": 14}` → **BESTANDEN**
  - `binaermodus` 14 von 15: `db_keepalive` fuehrt die Einstellung seit 1.0 nicht (unveraendert, kein Binaerdatum).

**Noch offen:** PR ueber Claude Code, Merge durch Rolf; danach Laeufe 22880 und 23001 loeschen (TS-27).

## 7. Befunde

1. TS-27: Die erste Fassung der Einrichtungspruefung las die Ordnerliste des privaten Kontos (IDs, keine Namen); n8n legte sie in 22880 und 23001 ab. Behoben mit Massnahme A (23123).
2. Leistung: Der Adapter liest je Aufruf die Ordnerliste des Kontos (heute eine Seite). In 1.1d neu bewerten.
3. Die Ordnerwerte in den n8n-Variablen waren zuerst als Links eingetragen; die Einrichtungspruefung erkennt das jetzt (SE-01).
4. Jeder Smoke-Lauf legt eine Aktion und einen Nachweis fuer `storage_gdrive.get_file` im Kontext `privat` an (wie 1.0.8).
