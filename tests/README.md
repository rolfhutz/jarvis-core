# Tests

Hier liegen ausfuehrbare Vertrags-, Integrations- und Abnahmetests. Die
freigegebenen Referenztests bleiben zusaetzlich in den Spezifikationspaketen.

## db/ — Datenbankabnahme Phase 1.0

| Datei | Zweck |
|---|---|
| `db/phase_1_0_acceptance.py` | Abnahmekriterien 1.0-A1 bis 1.0-A7 aus Spezifikation 7.3, praktisch gegen eine laufende Instanz |
| `db/readback_phase_1_0.py` | Readback: liest Schemata, Tabellen, Rollen, Bedingungen, Trigger, Indizes und Registereintraege aus dem Systemkatalog zurueck |
| `db/i05_new_action_same_source.sql` | Testfall I-05 gegen die Zielinstanz; rollt sich selbst zurueck, Ergebnis steht in der Fehlermeldung |

```bash
python3 tests/db/phase_1_0_acceptance.py --psql-args="-h <host> -p <port> -U <user> -d <db>"
python3 tests/db/readback_phase_1_0.py    --psql-args="-h <host> -p <port> -U <user> -d <db>"
```

Beide Skripte verwenden ausschliesslich synthetische Testdaten. Der
Abnahmelauf setzt eine frisch migrierte, leere Datenbank voraus; er raeumt
seine Zeilen nicht ab, weil `action_log` append-only ist.

Ein erwarteter Fehler ist ein Nachweis: Eine Ablehnung muss als FEHLER
zurueckkommen und darf nicht still verschluckt werden.

Nachweisprotokolle liegen unter `docs/evidence/`.

## n8n/ — Wiederherstellung der Kernworkflows

| Datei | Zweck |
|---|---|
| `n8n/check_restore.py` | Abgleich einer frisch wiederhergestellten n8n-Instanz mit `n8n/core/`: IDs, Knoten, Parameter, Verbindungen, Credential-Zuordnung, Subworkflow-Verweise, Aufruferbeschraenkung. Ablauf in `n8n/core/README.md` |
