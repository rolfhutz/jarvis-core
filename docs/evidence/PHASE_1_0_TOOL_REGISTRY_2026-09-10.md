# Nachweis Phase 1.0 — Werkzeugregister zur Laufzeit

**Datum:** 10. September 2026
**Entscheidung:** Variante A (Rolf, 10.09.2026): Register als Tabelle in `jarvis_ops`
**Zielprojekt:** Supabase `slatmyyxwruxvihcaklk`, Zugriff über MCP
**Status:** Datenbankteil umgesetzt und getestet. Umbau der Workflows `action_classify`,
`tool_invoke` und `evidence_verify` sowie Kriterien R-3 bis R-5 **offen**.

---

## 1. Anlass

Beim Auslesen der neun Kern-Subworkflows am 10.09.2026 zeigte sich, dass drei davon
eigene, abweichende Kopien des Werkzeugregisters im Code führen. Das verletzt die
Phase-0-Regel „Werkzeugregister ist einzige Quelle für Risikoklasse, Nachweisstrategie
und Freigabestatus, keine Doppelpflege".

| Workflow | Abweichung |
|---|---|
| `action_classify` | Klassen nach Aktionsart statt Werkzeug; vier Aktionen B statt A laut Register; Aussenwirkung führt zu C statt mindestens B |
| `tool_invoke` | Register nach Adapter statt Werkzeug-ID; die drei in 1.0 freizugebenden Werkzeuge fehlen |
| `evidence_verify` | Readback-Fähigkeit vom Aufrufer statt aus dem Register; Methodenliste weicht vom Nachweisschema 1.1.0 ab |

## 2. Umgesetzt

| Datei | Inhalt |
|---|---|
| `db/migrations/0013_tool_registry_schema.sql` | Tabellen `tool_registry`, `tool_release_log`, `context_risk_override`; Schemaregeln als Prüfbedingungen; Unveränderlichkeit der Vertragsfelder; Statuswechsel nur mit Nachweisverweis; Kontextbenutzer nur lesend |
| `db/migrations/0014_tool_registry_seed.sql` | erzeugt, 14 Werkzeuge, prüft sich beim Einspielen selbst |
| `tools/render_tool_registry.py` | Validierung gegen `tool_registry.schema.json`, Doppelpflegeprüfung, deterministische Erzeugung |
| `db/migrations/0011_*.sql`, `0012_*.sql` | im Wortlaut aus `supabase_migrations.schema_migrations` nachgetragen |

Selbsttest des Erzeugungsskripts: bestanden, 14 Werkzeuge, 5 Gegenproben.
Syntaxprüfung mit dem PostgreSQL-Parser (pglast): 0011 bis 0014 fehlerfrei.
Serialisierungsabgleich Python gegen PostgreSQL `jsonb::text`: identischer Prüfwert.

## 3. Ergebnisse gegen Supabase

| Nr. | Prüfung | Ergebnis |
|---|---|---|
| R-1a | Anzahl Werkzeuge | 14, erwartet 14 |
| R-1b | Prüfwert aus gespeicherter Definition nachgerechnet | 0 Abweichungen |
| R-1c | Status nach Erstbefüllung | alle `draft` |
| — | Selbstprüfung in 0014 (Prüfwert und alle Einzelspalten gegen Definition) | bestanden, sonst wäre die Migration abgebrochen |
| R-2a | `UPDATE` als `jv_privat_user` | abgewiesen, `42501 permission denied for table tool_registry` |
| R-2b | `INSERT` ins Freigabeprotokoll als `jv_visolva_user` | abgewiesen, `42501 permission denied for table tool_release_log` |
| R-2c | Lesen als `jv_privat_user` | 14 Zeilen |
| R-2d | Vertragsfeld ändern als Eigentümer | abgewiesen, `42501 registry_immutable` |
| R-2e | Freigabe ohne Nachweisverweis als Eigentümer | abgewiesen, `42501 release_evidence_missing` |
| R-2f | Löschen als Eigentümer | abgewiesen, `42501 append_only_violation` |
| R-2g | Freigabe mit Nachweisverweis, danach zurückgerollt | Status `approved` und genau ein Protokolleintrag; nach Rückrollen `draft`, 0 Einträge |

## 4. Offen

- R-3 bis R-5: Umbau der drei Workflows auf das Register und Test aus n8n.
- `context_risk_override` ist bewusst leer; Befüllung mit der echten Kontextkonfiguration in Schritt 1.1.
