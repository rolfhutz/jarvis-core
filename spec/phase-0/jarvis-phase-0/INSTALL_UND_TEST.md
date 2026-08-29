# JARVIS Phase 0 - Installations- und Prüfanleitung

**Version 1.1.0 - 29. August 2026**

Diese Anleitung beschreibt, wie das Artefaktpaket in einer sauberen Umgebung
geprüft wird. Es wird keine Datenbank eingerichtet und kein Workflow gebaut.

---

## 1. Voraussetzungen

| Voraussetzung | Anforderung |
|---|---|
| Python | 3.10 oder neuer, getestet mit 3.12.3 |
| Betriebssystem | beliebig; getestet unter Linux x86_64 |
| Netzwerk | nur für `pip install` |
| Datenbank | **nicht erforderlich** |

Die SQL-Prüfung nutzt `pglast`, einen eingebetteten PostgreSQL-Parser. Sie
prüft die Grammatik der Vorlagen, ohne eine Datenbank zu verbinden oder
einzurichten.

---

## 2. Installation

```bash
unzip jarvis-phase-0-v1.1.0.zip
cd jarvis-phase-0

python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

pip install --upgrade pip
pip install -r requirements.txt
```

Installiert werden ausschliesslich Prüfbibliotheken:
`jsonschema`, `referencing`, `pglast`.

---

## 3. Alle Prüfungen ausführen

```bash
python3 tools/run_all_tests.py
```

Erwartetes Ergebnis:

```
Schritte: 7, davon fehlgeschlagen: 0
Einzelpruefungen bestanden: 94
Gesamtergebnis: ALLE PRUEFUNGEN BESTANDEN
```

Protokoll neu schreiben:

```bash
python3 tools/run_all_tests.py --write-log
```

Der Rückgabewert ist 0 bei Erfolg und 1 bei mindestens einem Fehler. Damit lässt
sich der Aufruf später in eine automatische Prüfung einhängen.

---

## 4. Einzelne Prüfungen

| Aufruf | Prüft | Deckt ab |
|---|---|---|
| `python3 tools/build_examples.py` | erzeugt die elf Beispieldatensätze neu | Grundlage aller weiteren Prüfungen |
| `python3 tools/validate_schemas.py` | Beispiele, Kontextkonfiguration und Werkzeugregister gegen die Schemata; neun Vertragsregeln | A-1, A-2, A-5 |
| `python3 tools/validate_negative.py` | 21 Schemaverstösse und 3 Vertragsverstösse werden abgewiesen | Belastbarkeit der Verträge |
| `python3 tools/validate_policy.py` | Kontextkonfiguration gegen das Werkzeugregister, Herabstufungsverbot | TS-6 |
| `python3 tools/test_sanitize.py` | Bereinigung von `message_safe`, Positiv- und Negativfälle | TS-5, D6 |
| `python3 tools/render_context_schema.py --self-test` | Rendering und Abweisung unzulässiger Bezeichner | TS-4 |
| `python3 tools/validate_sql.py` | PostgreSQL-Grammatik und sieben Strukturzusicherungen | TS-1 (teilweise), D8 |

---

## 5. SQL-Vorlagen rendern

Die Dateien in `db/` enthalten Platzhalter und werden **nicht** direkt
eingespielt. Das Rendering übernimmt ausschliesslich das Skript, das
Schemanamen, Kontextkennung und Datenbankbenutzer gegen die Kontextkonfiguration
und gegen ein enges Muster prüft.

```bash
python3 tools/render_context_schema.py --list
python3 tools/render_context_schema.py --ops --out build/
python3 tools/render_context_schema.py --context privat --out build/
python3 tools/render_context_schema.py --context arbeitgeber_visolva --out build/
```

Ergebnis in `build/`:

```
002_ops_schema.sql
001_context_schema.privat.sql
003_grants_and_isolation.privat.sql
001_context_schema.arbeitgeber_visolva.sql
003_grants_and_isolation.arbeitgeber_visolva.sql
```

Das Skript stellt keine Datenbankverbindung her. Das Einspielen erfolgt später
in Phase 1 bewusst manuell:

```bash
psql "$JV_DB_URL" -v ON_ERROR_STOP=1 -f build/002_ops_schema.sql
psql "$JV_DB_URL" -v ON_ERROR_STOP=1 -f build/001_context_schema.privat.sql
psql "$JV_DB_URL" -v ON_ERROR_STOP=1 -f build/003_grants_and_isolation.privat.sql
```

**Reihenfolge beachten:** zuerst `002`, dann je Kontext `001` und `003`. Die
Datei `003` wird nach jedem neu hinzugekommenen Kontext für alle Kontexte
erneut ausgeführt, damit die gegenseitigen Entzüge vollständig bleiben.

---

## 6. Nachweis in einer sauberen Umgebung

So wurde das ausgelieferte Archiv geprüft:

```bash
mkdir /tmp/clean && cd /tmp/clean
unzip -q .../jarvis-phase-0-v1.1.0.zip
cd jarvis-phase-0
python3 -m venv .venv && . .venv/bin/activate
pip install -q -r requirements.txt
python3 tools/run_all_tests.py
```

Das Ergebnis dieses Laufs ist in `tests/TESTLAUF_2026-08-29.md` gespeichert und
enthält Datum, Python-Version, Betriebssystem, alle Einzelergebnisse und die
Laufzeit.

---

## 7. Prüfung auf Zugangsdaten

Vor jeder Weitergabe:

```bash
grep -rilE "api[_-]?key|password|secret|bearer |token=" . \
  --include="*.json" --include="*.sql" --include="*.py" --include="*.md" \
  --exclude-dir=.venv --exclude-dir=build --exclude-dir=__pycache__ \
  | grep -vE "sanitize_message|test_sanitize|ASSUMPTIONS|SPEC_|INSTALL_|CHANGELOG|TESTLAUF|N8N_CONVENTIONS|approval.schema|HANDOVER"
```

Erwartetes Ergebnis: keine Treffer.

`--exclude-dir=.venv` ist wichtig: Die installierten Fremdbibliotheken enthalten
diese Begriffe naturgemäss und würden das Ergebnis unbrauchbar machen.

Die im zweiten `grep` ausgeschlossenen Dateien enthalten die Begriffe
ausschliesslich als Suchmuster, als Testdaten der Bereinigungsfunktion oder als
Feldbeschreibung (`token_hash` in `approval.schema.json`), niemals als echte
Werte. Das Paket enthält keinen einzigen Zugangsdatenwert.
