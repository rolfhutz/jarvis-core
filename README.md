# JARVIS Core

Persoenliches, arbeitgeberunabhaengiges Repository fuer den schrittweisen Aufbau von JARVIS.

## Verbindlicher Stand (10.09.2026)

- Phase 0: Spezifikation 1.1.0 freigegeben; Gate am 31.08.2026 geschlossen (A-3/A-4 aus n8n nachgewiesen).
- Phase 1: Spezifikation 4.0.2 freigegeben; Schritt 1.0 umgesetzt einschliesslich 1.0.8 (drei interne Werkzeuge freigegeben). Phase-1.0-Gate vorbereitet, Freigabe durch Rolf ausstehend.
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
config/templates/  Konfigurationsvorlagen ohne echte IDs oder Geheimnisse
db/migrations/     versionierte SQL-Migrationen
n8n/core/          exportierte JARVIS-Kernworkflows
n8n/phase-1/       exportierte Workflows des Dokumentenassistenten
prompts/           versionierte Prompts
tests/             ausfuehrbare Vertrags- und Abnahmetests
tools/             Hilfsskripte
```

## Naechster Schritt

Gate-Freigabe Phase 1.0 durch Rolf auf Grundlage von
`docs/evidence/PHASE_1_0_GATE_2026-09-10.md`, danach Schritt 1.1.
Stand und Uebergabe: `docs/handover/HANDOVER_PHASE_1_0_GATE_2026-09-10.md`.

## Verbindliche Regeln

- Keine echten Dokumente, Volltexte, Backups oder fachlichen Protokolle in Git.
- Keine Kennwoerter, API-Schluessel, Tokens, Connection Strings oder Ordner-IDs in Git.
- Originaldokumente bleiben ausschliesslich im Speicher des jeweiligen Kontexts.
- Arbeitgeber- und Privatkontext teilen keine Dokumentablage und kein Fachprotokoll.
- Produktive Aenderungen erfolgen erst nach erfolgreichem Test und dokumentierter Freigabe.
