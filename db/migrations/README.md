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

Wiederholbarkeit: `0001` und `0009` sind ohne Weiteres erneut ausfuehrbar.
`0002` bis `0008` legen Objekte an und scheitern beim zweiten Lauf gegen
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
