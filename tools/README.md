# Werkzeuge

Hilfsskripte fuer Rendering, Validierung, Export, Backup und Wiederherstellung.
Keine Geheimnisse oder echte Dokumentdaten einchecken.

| Datei | Zweck |
|---|---|
| `render_phase1_tables.py` | Rendert die Phase-1-Erweiterungstabellen (Spezifikation 7.2) aus `db/templates/` je Kontext |

Das Werkzeug uebernimmt Schemaname, Kontextkennung und Datenbankbenutzer
ausschliesslich aus der Kontextkonfiguration und prueft sie gegen dieselben
Muster wie `render_context_schema.py` aus Phase 0. Freie Textersetzung ist
unzulaessig.

```bash
python3 tools/render_phase1_tables.py --list
python3 tools/render_phase1_tables.py --context privat --out build/
python3 tools/render_phase1_tables.py --self-test
```
