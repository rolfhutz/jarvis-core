# ADR-002: Werkzeugregister zur Laufzeit

- Status: angenommen
- Datum: 10. September 2026
- Entscheidung durch: Rolf (Variante A)

## Anlass

Drei Kern-Subworkflows (`action_classify`, `tool_invoke`, `evidence_verify`)
fuehrten eigene, abweichende Kopien des Werkzeugregisters im Code. Das verletzte
die Phase-0-Regel: Das Werkzeugregister ist die einzige Quelle fuer
Risikoklasse, Nachweisstrategie und Freigabestatus, keine Doppelpflege.

## Entscheidung

| Gegenstand | Entscheidung |
|---|---|
| Definitionsquelle | die Registerdateien im Repository (`spec/.../registry/tool_registry*.json`) |
| Laufzeitquelle | Tabelle `jarvis_ops.tool_registry`, erzeugt ausschliesslich mit `tools/render_tool_registry.py` |
| Veraenderlich | nur der Freigabestatus; jede Aenderung braucht einen Nachweisverweis und wird in `tool_release_log` protokolliert |
| Unveraenderlich | alle Vertragsfelder; eine Aenderung erfordert eine neue Werkzeugversion |
| Rechte | Kontextbenutzer lesen nur; JARVIS kann kein Werkzeug selbst freigeben |

Verworfen: Register als eingebetteter Block im Workflow-Code (Variante B) und
Laufzeitabruf aus GitHub.

## Umsetzung und Nachweis

Migrationen `0013`, `0014`; Nachweise R-1 bis R-5 in
`docs/evidence/PHASE_1_0_TOOL_REGISTRY_2026-09-10.md` und
`docs/evidence/PHASE_1_0_SMOKE_TEST_2026-09-10.md`.
