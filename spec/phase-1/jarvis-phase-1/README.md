# JARVIS Phase 1 — KI-Dokumentenassistent

**Spezifikation Version 4.0.2 — 29. August 2026**

## Status

| Gegenstand | Status |
|---|---|
| Spezifikation Version 4.0.2 | vollständig, umsetzungsbereit nach Freigabe |
| Umsetzung Phase 1 | nicht begonnen |
| Datenbank, n8n-Workflows, OCR- und Modellanbindung | nicht eingerichtet |
| Phase-0-Gate | offen; schliesst mit Schritt 1.0 dieser Phase |

## Einstieg

1. `SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.2.md` — die Spezifikation
2. `CHANGELOG_V4.0.1_ZU_V4.0.2.md` — was gegenüber Version 4.0.1 korrigiert wurde
3. `CHANGELOG_V4.0_ZU_V4.0.1.md` — was gegenüber Version 4.0 korrigiert wurde
4. `CHANGELOG_V3_ZU_V4.md` — was gegenüber Version 3 geändert wurde
5. `UMSETZUNGS_UND_TESTPLAN.md` — Schrittfolge 1.0 bis 1.5 mit Tests
6. `OPEN_DECISIONS_PHASE_1.md` — offene Entscheidungen mit spätestem Zeitpunkt
7. `HANDOVER_PHASE_1_SPEC_2026-08-29.md` — Übergabe an den Implementierungs-Chat

## Prüfung reproduzieren

Voraussetzung ist das **unveränderte Phase-0-Paket Version 1.1.0**. Es wird hier
bewusst nicht dupliziert, sondern über `--phase0` übergeben.

```bash
# 1. Beide Archive nebeneinander entpacken
unzip -q jarvis-phase-1-v4.0.2.zip
unzip -q jarvis-phase-0-v1.1.0.zip

# 2. Umgebung vorbereiten
cd jarvis-phase-1
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install "jsonschema==4.26.0" "referencing==0.37.0"

# 3. Prüfung ausführen
python3 tools/validate_phase1.py --phase0 ../jarvis-phase-0
```

Erwartete Ausgabe: acht Prüfteile, **108 Einzelprüfungen**, Abschluss mit
`ERGEBNIS: alle Pruefungen bestanden`. Der Rückgabewert ist 0 bei Erfolg und
1 bei mindestens einem Befund.

Liegt das Phase-0-Paket woanders, wird der Pfad entsprechend angegeben:

```bash
python3 tools/validate_phase1.py --phase0 /pfad/zum/jarvis-phase-0
```

### Abhängigkeiten

| Paket | Version | Zweck |
|---|---|---|
| `jsonschema` | 4.26.0 | Validierung nach Draft 2020-12 |
| `referencing` | 0.37.0 | Auflösung der `$ref`-Verweise zwischen den Schemata |

Python 3.10 oder neuer, getestet mit 3.12.3. Es wird keine Datenbank und kein
Netzwerkzugang benötigt.

Beide Pakete sind auch in der `requirements.txt` des Phase-0-Pakets enthalten;
wer dieses bereits eingerichtet hat, kann dessen Umgebung weiterverwenden.

## Was geprüft wird

| Teil | Inhalt | Prüfungen |
|---|---|---|
| 1 | Schemata gültig, nur interne Verweise | 4 |
| 2 | Beispieldatensätze gegen ihre Schemata | 7 |
| 3 | Werkzeugregister, keine Doppelpflege | 3 |
| 4 | Werkzeugverträge vorhanden, gültig, auflösbar, eindeutige `$id` | 2 |
| 5 | Normalisierungsregeln, Kalenderablehnungen, Decimal-Rechenprobe | 15 |
| 6 | Vertragsregeln V1 bis V17 | 17 |
| 7 | Freigabeplan der Werkzeuge | 4 |
| 8 | Gegenproben G01 bis G56 | 56 |
| | **Gesamt** | **108** |

## Verzeichnisstruktur

```
jarvis-phase-1/
├── README.md
├── SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.2.md
├── CHANGELOG_V3_ZU_V4.md
├── CHANGELOG_V4.0_ZU_V4.0.1.md
├── CHANGELOG_V4.0.1_ZU_V4.0.2.md
├── UMSETZUNGS_UND_TESTPLAN.md
├── OPEN_DECISIONS_PHASE_1.md
├── HANDOVER_PHASE_1_SPEC_2026-08-29.md
├── schemas/          vier Phase-1-Schemata
│   └── tools/        vierzehn Ein- und Ausgabeverträge der Werkzeuge
├── registry/         Werkzeuge, Normalisierungsregeln, Klärungsausgänge, Freigabeplan
├── examples/         sieben validierte Beispieldatensätze
└── tools/            Referenzimplementierung und Prüfskript
```

Die Skripte lösen ihre Pfade relativ zum Wurzelverzeichnis `jarvis-phase-1/`
auf und funktionieren nur, wenn die Verzeichnisse erhalten bleiben.

## Was dieses Paket nicht enthält

Keine Zugangsdaten, keine Ordner-IDs, keine Konten, keine Modellnamen, keine
produktiven Workflows und keine eingerichtete Datenbank. Das Phase-0-Paket ist
nicht enthalten und wird nicht verändert.
