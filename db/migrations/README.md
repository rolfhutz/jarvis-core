# Datenbankmigrationen

Hier liegen ausschliesslich versionierte, wiederholbar testbare SQL-Migrationen.
Produktive SQL-Aenderungen duerfen nicht nur im Supabase SQL Editor existieren,
sondern muessen vor der Ausfuehrung hier abgelegt werden.

## Reihenfolge

Die Nummerierung ist bindend. Sie ergibt sich nicht aus Bequemlichkeit,
sondern aus Abhaengigkeiten:

| Datei | Inhalt | haengt ab von |
|---|---|---|
| `0001_create_context_roles.sql` | Rollen `jv_privat_user`, `jv_visolva_user` | — |
| `0002_ops_schema.sql` | Schema `jarvis_ops` | — |
| `0003_context_schema_privat.sql` | Schema `jarvis_privat`, Phase-0-Tabellen | 0001 (GRANT an die Rolle) |
| `0004_context_schema_visolva.sql` | Schema `jarvis_visolva`, Phase-0-Tabellen | 0001 |
| `0005_phase1_tables_privat.sql` | Phase-1-Tabellen (Abschnitt 7.2) | 0003 |
| `0006_phase1_tables_visolva.sql` | Phase-1-Tabellen (Abschnitt 7.2) | 0004 |
| `0007_grants_and_isolation_privat.sql` | Rechte, Entzug auf `jarvis_visolva` | 0004, 0006 |
| `0008_grants_and_isolation_visolva.sql` | Rechte, Entzug auf `jarvis_privat` | 0003, 0005 |
| `0009_context_registry_seed.sql` | Kontextregister und Vertragsversionen | 0002 |
| `0010_admin_role_membership.sql` | `SET`-Recht des Administrators auf die Kontextrollen | 0001 |
| `0011_context_login_users.sql` | Login-Benutzer je Kontext, erben die Gruppenrolle (E1) | 0001 |
| `0012_context_login_search_path.sql` | fester Suchpfad der Login-Benutzer | 0011 |
| `0013_tool_registry_schema.sql` | Werkzeugregister zur Laufzeit, Freigabeprotokoll, Kontextregeln | 0002 |
| `0014_tool_registry_seed.sql` | **erzeugt** aus den Registerdateien, prueft sich selbst | 0013 |
| `0015_case_number_seq_sync.sql` | Vorgangsnummern-Zaehler je Kontext und Jahr auf hoechste vergebene Nummer anheben (Befund B-1, 1.0.8), prueft sich selbst | 0005, 0006 |
| `0016_intake_runtime_tables.sql` | Eingang 1.1: `context_document_settings`, `source_binding` (Anhalten nur im eigenen Kontext, Aufheben nur Administrator), `intake_exception` (K-07, append-only) | 0001, 0002 |
| `0017_intake_config_seed.sql` | **erzeugt** aus `config/intake_config.json` (`tools/render_intake_config.py`), prueft sich selbst | 0016 |
| `0018_tool_registry_seed_1_1.sql` | **erzeugt** aus dem Registernachtrag 1.1 (`tools/render_tool_registry.py --set 0018`), prueft sich selbst | 0013 |
| `0019_deprecate_storage_gdrive_get_file_1_0_0.sql` | `storage_gdrive.get_file@1.0.0` auf `deprecated` mit Nachweisverweis 1.1-E1, prueft sich selbst | 0014, 0018 |
| `0020_context_root_ref.sql` | Spalte `context_root_ref` (noch ohne Pflicht), Rollen-Eindeutigkeit um die Wurzel erweitert (1.1b-E1) | 0016, 0017 |
| `0021_intake_config_seed_1_1.sql` | **erzeugt** aus `config/intake_config.json` 1.1.0, setzt die Wurzel, prueft sich selbst; loest `0017` ab | 0020 |
| `0022_context_root_ref_not_null.sql` | Wurzel verpflichtend, bricht ohne vorheriges `0021` ab, prueft sich selbst | 0020, 0021 |
| `0023_release_storage_gdrive_get_file_1_1_0.sql` | Freigabe `storage_gdrive.get_file@1.1.0` nach 12.1.1; prueft den gespeicherten Nachweis, prueft sich selbst | 0013, 0018 |

Die Rechtevergabe steht bewusst am Ende: `REVOKE ALL ON ALL TABLES IN SCHEMA`
wirkt nur auf Tabellen, die zu diesem Zeitpunkt bereits vorhanden sind. Wuerde
`0007` vor `0006` laufen, blieben die Phase-1-Tabellen des fremden Kontexts
zugaenglich.

## Herkunft der Dateien

`0002` bis `0008` werden **gerendert, nicht von Hand geschrieben**. Quelle und
Werkzeug stehen im Kopf jeder Datei. Eine Aenderung erfolgt an der Vorlage und
wird neu gerendert:

```bash
# Phase-0-Vorlagen
python3 spec/phase-0/jarvis-phase-0/tools/render_context_schema.py --ops --out build/
python3 spec/phase-0/jarvis-phase-0/tools/render_context_schema.py --context privat --out build/
python3 spec/phase-0/jarvis-phase-0/tools/render_context_schema.py --context arbeitgeber_visolva --out build/

# Phase-1-Erweiterung
python3 tools/render_phase1_tables.py --context privat --out build/
python3 tools/render_phase1_tables.py --context arbeitgeber_visolva --out build/
```

Beide Werkzeuge lehnen jeden Schemanamen, jede Kontextkennung und jeden
Datenbankbenutzer ab, der nicht in der Kontextkonfiguration steht. Freie
Textersetzung ist unzulaessig.

## Einspielen

```bash
for f in db/migrations/00*.sql; do
  psql "$JV_DB_URL" -v ON_ERROR_STOP=1 -f "$f"
done
```

`0010` wird auf Instanzen gebraucht, deren Verwaltungsrolle kein Superuser ist
(Supabase). Ohne sie kann niemand die Kontextrollen annehmen und die Abnahme
1.0-A1 bis 1.0-A4 ist nicht pruefbar. Begruendung im Kopf der Datei.

Wiederholbarkeit: `0001`, `0009`, `0010`, `0011`, `0012`, `0014`, `0015`, `0018`, `0019`, `0021`, `0022` und `0023` sind ohne Weiteres erneut ausfuehrbar.
`0017` ist seit 1.1b Historie (erzeugt aus Konfiguration 1.0.0) und wird nicht erneut ausgefuehrt; nach `0022` scheitert sie an der Pflichtspalte `context_root_ref` (beabsichtigt, fail closed). Massgeblich ist `0021`.
`0021` (wie zuvor `0017`) setzt Konfigurationsfelder auf den Stand der Datei, laesst den Laufzeitzustand (`halted_at`) unberuehrt
und deaktiviert Bindungen, die nicht mehr in der Datei stehen.
`0015` hebt Zaehler nur an, senkt sie nie ab.
`0014` wird ausschliesslich mit `tools/render_tool_registry.py` erzeugt und bricht ab,
wenn eine bereits geladene Werkzeugversion eine abweichende Definition haette.
`0002` bis `0008`, `0013`, `0016` und `0020` legen Objekte an und scheitern beim zweiten Lauf gegen
dieselbe Instanz — beabsichtigt, weil ein stiller zweiter Lauf gefaehrlicher
waere als ein Fehler.

## Kennwoerter

In diesen Dateien steht kein Kennwort und kein Geheimnis. Die Kontextrollen
sind `NOLOGIN`. Das Anmelderecht wird erst bei der n8n-Anbindung vergeben und
ausschliesslich im Anmeldeinformationsspeicher von n8n gehalten.

## Pruefung

```bash
python3 tests/db/phase_1_0_acceptance.py --psql-args="-h <host> -p <port> -U <user> -d <db>"
python3 tests/db/readback_phase_1_0.py    --psql-args="-h <host> -p <port> -U <user> -d <db>"
```

Der Abnahmelauf setzt eine frisch migrierte, leere Datenbank voraus. Er
schreibt synthetische Zeilen und raeumt sie nicht ab: `action_log` ist
append-only, ein Testlauf darf diese Eigenschaft nicht unterlaufen.
