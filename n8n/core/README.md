# JARVIS Core Workflows

Exportierte n8n-Workflows des Fundaments: neun Kern-Subworkflows (`JV-CORE-SUB-*`),
drei interne Adapter (`JV-CORE-ADP-*`, seit 1.0.8) und zwei Betriebsworkflows (`JV-CORE-OPS-*`). Uebersicht und Status in
[`MANIFEST.md`](MANIFEST.md).

## Regeln

- Exporte entstehen ausschliesslich ueber n8n "Export JSON" und
  `tools/normalize_n8n_export.py`. Das Skript entfernt instanzspezifische
  Angaben und bricht ab, wenn etwas wie ein Geheimnis aussieht.
- Workflow-IDs und Credential-IDs bleiben erhalten. Beides sind keine
  Geheimnisse, aber beides ist fuer eine korrekte Wiederherstellung noetig
  (Nachweis 1.0-A8). Kennwoerter stehen nie im Export.
- Keine Execution-Daten, keine Pin-Daten.
- Die Aufruferbeschraenkung der Adapter (`settings.callerPolicy`, `settings.callerIds`)
  bleibt im Export erhalten und wird beim Import uebernommen (Befund B-2, 1.0.8).
- Der Veroeffentlichungsstatus ist nicht Teil des Exports; er wird nach dem Import
  von Hand gesetzt (Schritt 4).

## Wiederherstellung in eine leere Instanz

1. Zwei Credentials vom Typ Postgres anlegen, **mit genau diesen IDs und Namen**
   (stehen in `meta.jarvis_required_credentials` jeder Datei):

   | ID | Name | Datenbankbenutzer |
   |---|---|---|
   | `oCkj27EiMe96vXvU` | `jv_privat_postgres` | `jv_privat_login` |
   | `7BblU6FbDds3EZBb` | `jv_visolva_postgres` | `jv_visolva_login` |

   Ueber die Oberflaeche lassen sich keine IDs vorgeben. Deshalb zuerst eine
   Credential-Huelle per CLI importieren (ID, Name, Typ, Platzhalterwerte) und
   danach in der Oberflaeche Host, Benutzer und Kennwort aus dem
   Passwortmanager eintragen. Verbindung: Supabase Session-Pooler, Port 5432,
   SSL erforderlich.

   **Warum die IDs zwingend sind:** Fehlt die ID, ordnet n8n beim Import allen
   Postgres-Knoten das erste vorhandene Credential zu. Die visolva-Knoten
   liefen dann mit dem privat-Zugang.

2. `n8n import:workflow --separate --input=n8n/core`
3. Pruefen:
   `n8n export:workflow --all --separate --output=<ordner>` und
   `n8n export:credentials --all --output=<datei>`, dann
   `python3 tests/n8n/check_restore.py --src n8n/core --out <ordner> --creds <datei>`
   Erwartet (Stand 1.0.8): 14 Workflows, 155 Knoten, 38 Credential-Zuordnungen,
   20 Subworkflow-Verweise, 6 Aufruferregeln, `ERGEBNIS: BESTANDEN`.
4. Veroeffentlichen: alle `JV-CORE-SUB-*`, alle `JV-CORE-ADP-*` und
   `JV-CORE-OPS-db_keepalive-v1` (Regel TS-23). Nur `JV-CORE-OPS-smoke_test-v1` bleibt
   unveroeffentlicht. Unveroeffentlichte Entwuerfe sind fuer Elternworkflows nicht sichtbar.
5. `JV-CORE-OPS-smoke_test-v1` einmal manuell ausfuehren. Erwartet: 104 von 104.
   Achtung: Der Lauf schreibt synthetische Daten in den Fachbestand und verbraucht
   echte Vorgangsnummern (TS-18).

## Aenderungen an einem Workflow (Regel TS-23)

1. In n8n aendern.
2. Veroeffentlichen. Erst dann wirkt die Aenderung fuer Elternworkflows.
3. Pruefen, dass die veroeffentlichte Version dem aktuellen Stand entspricht
   (`versionId` = `activeVersionId`, per MCP `get_workflow_details`).
4. Smoke-Test ausfuehren, erwartet: alle Pruefungen bestanden.
5. Exportieren, normalisieren, per Pull Request ins Repo.
