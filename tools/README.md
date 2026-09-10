# Werkzeuge

Hilfsskripte fuer Rendering, Validierung, Export, Backup und Wiederherstellung.
Keine Geheimnisse oder echte Dokumentdaten einchecken.

| Datei | Zweck |
|---|---|
| `render_phase1_tables.py` | Rendert die Phase-1-Erweiterungstabellen (Spezifikation 7.2) aus `db/templates/` je Kontext |
| `render_tool_registry.py` | Validiert beide Registerdateien und erzeugt Migration 0014 fuer `jarvis_ops.tool_registry` |
| `normalize_n8n_export.py` | Bereinigt n8n-Exporte fuer `n8n/core/`, prueft Namenskonvention und bricht bei moeglichen Geheimnissen ab |

Das Werkzeug uebernimmt Schemaname, Kontextkennung und Datenbankbenutzer
ausschliesslich aus der Kontextkonfiguration und prueft sie gegen dieselben
Muster wie `render_context_schema.py` aus Phase 0. Freie Textersetzung ist
unzulaessig.

```bash
python3 tools/render_phase1_tables.py --list
python3 tools/render_phase1_tables.py --context privat --out build/
python3 tools/render_phase1_tables.py --self-test
```

## Werkzeugregister

```bash
python3 tools/render_tool_registry.py --self-test
python3 tools/render_tool_registry.py --out db/migrations/
python3 tools/render_tool_registry.py --check db/migrations/0014_tool_registry_seed.sql
```

Abhaengigkeiten: `jsonschema==4.26.0`, `referencing==0.37.0`. Der Pruefwert je
Werkzeug wird so gebildet, wie PostgreSQL `jsonb::text` ausgibt. Die Datenbank
rechnet ihn beim Einspielen aus der gespeicherten Definition nach.
