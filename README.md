# JARVIS Core

Persoenliches, arbeitgeberunabhaengiges Repository fuer den schrittweisen Aufbau von JARVIS.

## Verbindlicher Stand (11.09.2026)

- Phase 0: Spezifikation 1.1.0 freigegeben; Gate am 31.08.2026 geschlossen (A-3/A-4 aus n8n nachgewiesen).
- Phase 1: Spezifikation 4.0.2 freigegeben; Schritt 1.0 abgeschlossen, Phase-1.0-Gate am 10.09.2026 freigegeben (G-1: Restumfang an 1.1/1.2 uebertragen). Drei interne Werkzeuge `approved`.
- PostgreSQL: Supabase Free fuer Phase 1.0 und den ersten Pilot, Keep-Alive produktiv.
- Dokumentablage privat: Google Drive, Eingang ueber Drive-Eingangsordner.
- Dokumentablage `arbeitgeber_visolva`: SharePoint, in Phase 1 nur synthetische Testdokumente.
- Workflow-Orchestrierung: n8n; Kernworkflows in `n8n/core/`.

Die verbindliche Entscheidung zu Infrastruktur und Ablage steht in
[`docs/decisions/`](docs/decisions/), Uebersicht im [`DECISION_LOG.md`](docs/decisions/DECISION_LOG.md).

## Struktur

```text
spec/              freigegebene Spezifikationspakete
docs/decisions/    verbindliche Architektur- und Umsetzungsentscheidungen
config/            Laufzeitkonfiguration (nur env-Verweise) und Schemata
config/templates/  Konfigurationsvorlagen ohne echte IDs oder Geheimnisse
docs/plan/         freigegebene Vorlagen je Umsetzungsschritt
db/migrations/     versionierte SQL-Migrationen
n8n/core/          exportierte JARVIS-Kernworkflows
n8n/phase-1/       exportierte Workflows des Dokumentenassistenten
prompts/           versionierte Prompts
tests/             ausfuehrbare Vertrags- und Abnahmetests
tools/             Hilfsskripte
```

## Naechster Schritt

Schritt 1.1 (Eingang und Normalisierung) nach der freigegebenen Vorlage
`docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md`. Bauabschnitt 1.1a
(Migrationen 0016 bis 0019, Eingangskonfiguration, Registernachtrag) ist seit
10.09.2026 in Supabase eingespielt (`docs/evidence/PHASE_1_1A_SUPABASE_2026-09-10.md`).
Seit 11.09.2026 abgeschlossen: Kontextaufloesung aus der Datenbank, keine Kontextwerte
mehr im Code der Kern-Workflows (TS-10, `docs/evidence/PHASE_1_1A_TS10_2026-09-11.md`).
Naechster Bauabschnitt 1.1b (Speicheradapter) nach V-4 und V-1.
Stand und Uebergabe: `docs/handover/HANDOVER_PHASE_1_1A_REST_2026-09-11.md`.
Kern-Subworkflows sind veroeffentlicht (TS-23); Aenderungsablauf in `n8n/core/README.md`.

## Verbindliche Regeln

- Keine echten Dokumente, Volltexte, Backups oder fachlichen Protokolle in Git.
- Keine Kennwoerter, API-Schluessel, Tokens, Connection Strings oder Ordner-IDs in Git.
- Originaldokumente bleiben ausschliesslich im Speicher des jeweiligen Kontexts.
- Arbeitgeber- und Privatkontext teilen keine Dokumentablage und kein Fachprotokoll.
- Produktive Aenderungen erfolgen erst nach erfolgreichem Test und dokumentierter Freigabe.
