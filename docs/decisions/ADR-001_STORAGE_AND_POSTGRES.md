# ADR-001: Dokumentablage und PostgreSQL-Betrieb

- Status: angenommen
- Datum: 29. August 2026
- Betrifft: P1-O1, P1-O5 und P1-O7

## Entscheidung

| Gegenstand | Entscheidung |
|---|---|
| PostgreSQL-Anbieter | Supabase Free fuer Phase 1.0 und den ersten Pilot |
| Private Dokumentablage | Google Drive |
| Arbeitgeber-Dokumentablage | SharePoint |
| Versionsverwaltung | privates Repository `rolfhutz/jarvis-core` |

Supabase wird ausschliesslich als verwaltetes PostgreSQL verwendet. Data API,
Supabase Storage, Supabase Auth, Realtime und Edge Functions sind fuer Phase 1
nicht Bestandteil der Architektur.

## Kontextzuordnung

| Kontext | Originaldokumente | Fachliche Daten und Protokolle |
|---|---|---|
| `privat` | Google Drive, private Ordnerwurzel | PostgreSQL-Schema `jarvis_privat` |
| `arbeitgeber_visolva` | SharePoint, Arbeitgeber-Testbibliothek | PostgreSQL-Schema `jarvis_visolva` |
| technisch gemeinsam | keine Originaldokumente | PostgreSQL-Schema `jarvis_ops`, ausschliesslich technische Metadaten |

In Phase 1 verarbeitet `arbeitgeber_visolva` ausschliesslich synthetische
Testdokumente. Produktive Arbeitgeberdokumente sind nicht freigegeben.

## Zugriff

- n8n verbindet sich direkt mit PostgreSQL beziehungsweise ueber den Session Pooler.
- Je Kontext wird ein eigener PostgreSQL-Benutzer und ein eigenes n8n-Credential verwendet.
- Die Benutzer erhalten keine Schreibrechte auf das jeweils andere Kontextschema.
- Dokument-IDs, Ordner-IDs und Connection Strings werden nur ueber n8n-Credentials
  beziehungsweise Umgebungsvariablen eingebunden.

## Speicheradapter

- `storage_gdrive.get_file` und `storage_gdrive.move_file` sind nur fuer `privat` zulaessig.
- Vor Phase 1.1 werden `storage_sharepoint.get_file` und
  `storage_sharepoint.move_file` fuer `arbeitgeber_visolva` als getrennte
  Werkzeugvertraege ergaenzt.
- Ein automatischer Wechsel zwischen Google Drive und SharePoint ist unzulaessig.
- Ein falsch eingelegtes Dokument erzeugt eine Aufgabe; es wird nicht automatisch
  in einen anderen Kontext geschrieben.

## Betrieb im kostenlosen Tarif

- Nach jedem abgenommenen Umsetzungsschritt wird ein logischer Datenbankexport erstellt.
- Vor dem Pilot wird eine Wiederherstellung praktisch getestet.
- Der Datenbankverbrauch wird waehrend des Pilots beobachtet.
- Ein Wechsel auf einen kostenpflichtigen Tarif wird erst entschieden, wenn
  automatische Backups, dauerhafte Verfuegbarkeit oder mehr Kapazitaet erforderlich sind.

## Folgen

- Die Phase-0- und Phase-1-Hauptspezifikationen bleiben unveraendert.
- Dieser Nachtrag ist fuer die Implementierung verbindlich und konkretisiert die
  zuvor offenen Anbieter- und Speicherentscheidungen.
- Die SharePoint-Werkzeugvertraege werden vor Phase 1.1 erstellt; sie blockieren
  Phase 1.0 nicht.
