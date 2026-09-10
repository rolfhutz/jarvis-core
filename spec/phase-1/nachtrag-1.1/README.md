# Nachtrag 1.1 zur Spezifikation Phase 1 (4.0.2)

**Stand:** 10. September 2026
**Grundlage:** ADR-001 (Speicheradapter je Kontext), Entscheidung 1.1-E1 vom 10.09.2026

Das freigegebene Spezifikationspaket `../jarvis-phase-1/` bleibt unveraendert.
Dieser Nachtrag ergaenzt nur Werkzeugvertraege, die ADR-001 vor Schritt 1.1 verlangt.

| Werkzeug | Version | Kontexte | Freigabe laut Plan |
|---|---|---|---|
| `storage_gdrive.get_file` | 1.1.0 | `privat` | 1.1 (1.0.0 ist `deprecated`, Migration 0019) |
| `storage_sharepoint.get_file` | 1.0.0 | `arbeitgeber_visolva` | 1.1 |
| `storage_sharepoint.move_file` | 1.0.0 | `arbeitgeber_visolva` | 1.4 |

Die SharePoint-Schemata sind inhaltlich gleich den Google-Drive-Vertraegen; nur `$id`,
Titel und Beschreibung weichen ab. `storage_gdrive.get_file@1.1.0` verwendet dieselben
Schemata wie 1.0.0 und unterscheidet sich nur in `version` und `allowed_contexts`.

Laden in die Datenbank ausschliesslich ueber `tools/render_tool_registry.py --set 0018`
(Migration `db/migrations/0018_tool_registry_seed_1_1.sql`).
