# JARVIS Core

Persoenliches, arbeitgeberunabhaengiges Repository fuer den schrittweisen Aufbau von JARVIS.

## Verbindlicher Stand

- Phase 0: Spezifikation 1.1.0 freigegeben; technisches Gate A-3/A-4 noch offen.
- Phase 1: Spezifikation 4.0.2 freigegeben; Umsetzung noch nicht begonnen.
- PostgreSQL: Supabase Free fuer Phase 1.0 und den ersten Pilot.
- Dokumentablage privat: Google Drive.
- Dokumentablage `arbeitgeber_visolva`: SharePoint, in Phase 1 nur synthetische Testdokumente.
- Workflow-Orchestrierung: n8n.

Die verbindliche Entscheidung zu Infrastruktur und Ablage steht in
[`docs/decisions/ADR-001_STORAGE_AND_POSTGRES.md`](docs/decisions/ADR-001_STORAGE_AND_POSTGRES.md).

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

Phase 1.0 implementieren und zuerst die offenen Phase-0-Nachweise A-3 und A-4 erbringen:

1. SQL-Migrationen aus Phase 0 gegen Supabase PostgreSQL vorbereiten.
2. `jarvis_ops`, `jarvis_privat` und `jarvis_visolva` einrichten.
3. Getrennte Datenbankrollen und n8n-Credentials anlegen.
4. Kern-Subworkflows fuer Kontext, Idempotenz und Fachprotokollierung bauen.
5. Kontexttrennung und Dublettenfreiheit praktisch nachweisen.
6. Export und Wiederherstellung testen.

## Verbindliche Regeln

- Keine echten Dokumente, Volltexte, Backups oder fachlichen Protokolle in Git.
- Keine Kennwoerter, API-Schluessel, Tokens, Connection Strings oder Ordner-IDs in Git.
- Originaldokumente bleiben ausschliesslich im Speicher des jeweiligen Kontexts.
- Arbeitgeber- und Privatkontext teilen keine Dokumentablage und kein Fachprotokoll.
- Produktive Aenderungen erfolgen erst nach erfolgreichem Test und dokumentierter Freigabe.
