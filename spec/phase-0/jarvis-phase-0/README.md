# JARVIS Phase 0 - Artefaktpaket

**Version 1.1.0 - 29. August 2026**

## Status

| Gegenstand | Status |
|---|---|
| Phase-0-Spezifikation | inhaltlich abgeschlossen, freigabefähig |
| Phase-0-Phase-Gate | **noch nicht vollständig bestanden** |
| Abnahmekriterien A-3 und A-4 | offen, praktischer Nachweis mit PostgreSQL und n8n erforderlich |
| Datenbank, Workflows, Adapter | nicht eingerichtet, nicht gebaut |

## Einstieg

1. `SPEC_PHASE_0_JARVIS_FUNDAMENT_v1.1.md` - die Spezifikation
2. `CHANGELOG.md` - was sich gegenüber Version 1.0.0 geändert hat
3. `HANDOVER_PHASE_0_2026-08-29.md` - Übergabe und nächster Bauschritt
4. `INSTALL_UND_TEST.md` - wie das Paket geprüft wird

## Prüfungen reproduzieren

```
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python3 tools/run_all_tests.py
```

Erwartete Ausgabe: 7 Schritte, 94 Einzelprüfungen, `ALLE PRUEFUNGEN BESTANDEN`.
Der gespeicherte Referenzlauf liegt in `tests/TESTLAUF_2026-08-29.md`.

Ausführliche Anleitung einschliesslich Einzelaufrufen: `INSTALL_UND_TEST.md`.

## Verzeichnisstruktur

```
jarvis-phase-0/
├── README.md
├── INSTALL_UND_TEST.md
├── CHANGELOG.md
├── requirements.txt
├── SPEC_PHASE_0_JARVIS_FUNDAMENT_v1.1.md
├── ASSUMPTIONS.md
├── OPEN_DECISIONS.md
├── HANDOVER_PHASE_0_2026-08-29.md
├── schemas/      11 JSON-Schemata nach Draft 2020-12
├── registry/     tool_registry.json, einzige Quelle für Risikoklassen
├── examples/     11 Beispieldatensätze für die Abnahme
├── templates/    Kontextkonfiguration, Werkzeug- und Agentenvertrag
├── conventions/  n8n-Namens-, Modul- und Fehlerkonventionen
├── db/           SQL-Vorlagen, nicht ausgeführt
├── tools/        Referenzimplementierungen und Prüfskripte
└── tests/        Abnahmematrix und gespeicherter Testlauf
```

Alle Befehle in diesem Paket werden aus dem Wurzelverzeichnis `jarvis-phase-0/`
aufgerufen. Die Skripte lösen ihre Pfade relativ zu dieser Struktur auf und
funktionieren nur, wenn die Verzeichnisse erhalten bleiben.

## Was dieses Paket nicht enthält

Keine Zugangsdaten, keine Ordner-IDs, keine Konten, keine Arbeitgebernamen in
der Prozesslogik, keine produktiven Workflows und keine eingerichtete Datenbank.
Die SQL-Dateien sind Vorlagen mit Platzhaltern und werden ausschliesslich über
`tools/render_context_schema.py` gerendert.
