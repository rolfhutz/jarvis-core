# Nachweis 1.0-A8 / 1.0.8-A10 — Export und Wiederherstellung, 14 Workflows

**Datum:** 10. September 2026
**Kriterien:** 1.0-A8 „Export und Wiederherstellung der Workflows in eine leere Instanz gelingt“, erneut mit dem Stand nach 1.0.8; 1.0.8-A10
**Zielinstanz:** frische lokale n8n-Instanz **2.35.7** (Node v22.22.2), eigenes Benutzerverzeichnis, leere SQLite-Datenbank, eigener Verschlüsselungsschlüssel
**Quelle:** 14 Downloads aus n8n Cloud (Rolf, 10.09.2026 nachmittags), normalisiert mit `tools/normalize_n8n_export.py` (Stand nach B-2)

## Ergebnis: bestanden

| Prüfung | Umfang | Ergebnis |
|---|---|---|
| Import | 14 Workflows, 2 Credential-Hüllen | `Successfully imported 14 workflows.` |
| Workflow-IDs unverändert | 14 | bestanden |
| Knoten, Parameter, Verbindungen identisch | 155 Knoten | bestanden |
| Credential-Zuordnung je Knoten (ID und Name) | 38 | bestanden |
| Kontext-Credential passend zum Knotennamen | alle Postgres-Knoten | bestanden |
| Subworkflow-Verweise auflösbar | 20 | bestanden |
| Aufruferbeschränkung (`callerPolicy`, `callerIds`) | 3 Adapter × 2 | bestanden |
| Credential-Rückexport ohne Klartext | 2 | verschlüsselt |

Ausgabe `tests/n8n/check_restore.py`:

```
{"workflows": 14, "knoten": 155, "credential_zuordnungen": 38, "subworkflow_verweise": 20, "aufruferregeln": 6}
ERGEBNIS: BESTANDEN
```

## Abgleich der acht unveränderten Workflows mit dem Repo-Stand 54f5f33

Nach Normalisierung **inhaltlich identisch** (einziger Unterschied wäre `meta.jarvis_exported_at`,
auch dieser ist gleich): `context_resolve`, `id_generate`, `idempotency_guard`, `action_classify`,
`fach_log_write`, `tech_log_write`, `error_handler`, `db_keepalive`. Neu: drei Adapter.
Geändert: `tool_invoke` (9 → 14 Knoten), `evidence_verify` (9 → 14), `smoke_test` (25 → 47).

## Befund B-2 und Gegenprobe

Die bisherige Fassung des Normalisierers behielt `callerPolicy`, entfernte aber `callerIds`.
Gegenprobe mit dem alten Normalisierer, gleiche Downloads, frische Instanz:

```
ERGEBNIS: NICHT BESTANDEN
 - JV-CORE-ADP-casestore_internal-v1: settings.callerIds weicht ab: None
 - JV-CORE-ADP-docstore_internal-v1: settings.callerIds weicht ab: None
 - JV-CORE-ADP-tasks_internal-v1: settings.callerIds weicht ab: None
```

Folge ohne Behebung: Nach einer Wiederherstellung hätten die Adapter eine leere Aufruferliste
gehabt. Behebung: `callerIds` in `KEEP_SETTINGS`; `check_restore.py` vergleicht beide Werte.
Selbsttest des Normalisierers: 4 Prüfungen, 2 Gegenproben, bestanden. Zusätzlich geprüft:
n8n 2.35.7 übernimmt `callerIds` beim Import unverändert.

Probelauf vorab mit dem Repo-Stand 54f5f33 (11 Workflows): bestanden, 90 Knoten,
19 Zuordnungen, 9 Verweise — identisch mit `PHASE_1_0_RESTORE_A8_2026-09-10.md`.

## Grenzen

- Geprüft ist Struktur und Zuordnung. Die Datenbankverbindung braucht die Kennwörter aus dem
  Passwortmanager und wurde in der Testinstanz bewusst nicht hergestellt. Lauffähigkeit gegen
  die echte Datenbank: Smoke-Test 22265 (104/104).
- Der Veröffentlichungsstatus ist nicht Teil des Exports. Nach einer echten Wiederherstellung
  sind Keep-Alive und die drei Adapter von Hand zu veröffentlichen (`n8n/core/README.md`, Schritt 4).
- Die Einstellung `binaryMode` aus dem Cloud-Download wird wie bisher nicht übernommen; die
  Instanz setzt ihren Standard. Keiner der 14 Workflows verarbeitet Binärdaten (nur Code-,
  Postgres-, Switch-, Set-, If- und Aufrufknoten). Ab 1.1 (Dateieingang) neu zu bewerten.
