# HANDOVER_PHASE_0_2026-08-29

**Modul:** Phase 0 - JARVIS-Fundament und Architekturverträge
**Paketversion:** 1.1.0
**Erstellt:** 29. August 2026
**Vorgänger:** Version 1.0.0 desselben Moduls, siehe `CHANGELOG.md`
**Nachfolger:** Überarbeitung der Spezifikation KI-Dokumentenassistent zur Phase-1-Spezifikation

---

## 1. Ziel des Moduls

Verbindliche Datenverträge und Architekturregeln festlegen, damit alle späteren
JARVIS-Module dieselben Modelle für Kontext, Ereignis, Aufgabe, Aktion, Freigabe,
Ergebnisnachweis, Fehler und Gedächtnis verwenden.

## 1.1 Status

| Gegenstand | Status |
|---|---|
| **Phase-0-Spezifikation** | inhaltlich abgeschlossen, freigabefähig |
| **Phase-0-Phase-Gate** | **noch nicht vollständig bestanden** |
| Abnahmekriterien A-1, A-2, A-5 | nachgewiesen |
| Abnahmekriterien A-3, A-4 | **offen**, praktischer Nachweis mit PostgreSQL und n8n erforderlich |
| Datenbank | nicht eingerichtet |
| Workflows und Adapter | nicht gebaut |

Der praktische Nachweis von A-3 und A-4 ist der erste technische Meilenstein von
Phase 1 und erfolgt erst nach Freigabe der überarbeiteten Phase-1-Spezifikation.

---

## 2. Verbindliche Entscheidungen

### 2.1 Von Rolf freigegeben

| Nr. | Entscheidung |
|---|---|
| B1 | Verwaltetes PostgreSQL als zentrale Wahrheitsquelle, Anbieter offen, anbieterunabhängige Architektur, `pgvector` später |
| B2 | Eigene Schemas, Datenbankbenutzer und n8n-Credentials je Kontext; gemeinsame n8n-Infrastruktur von Visolva ausdrücklich erlaubt; keine dauerhafte Speicherung fachlicher Payloads in gemeinsamen Ausführungsdaten |
| B3 | Technische Bezeichner englisch in `snake_case` und Punktnotation, deutsche Anzeigelabels und Freitexte, keine Umlaute in technischen Schlüsseln |
| B4 | Freigabe über austauschbaren, kontextabhängigen Adapter; zunächst E-Mail mit signiertem Einmal-Link, Aktions-ID, Ablauffrist und Schutz vor Mehrfachausführung |
| B5 | Zwei Startkontexte `privat` und `arbeitgeber_visolva`, Modell offen für weitere; Berechtigung im Arbeitgeberkontext als gegeben angenommen |
| D1 | Aufgabe und Aktion bleiben getrennte Objekte |
| D2 | Risikoklasse darf gegenüber dem Werkzeugminimum nur erhöht, niemals gesenkt werden |
| D4 | Zwischen Freigabe und Werkzeugaufruf darf kein Sprachmodell den freigegebenen Inhalt verändern |
| D5 | Freigabe in zwei Schritten; das Öffnen eines Links allein ist keine Freigabe |
| D6 | Gemeinsame technische Protokolle ohne fachliche Payloads; `message_safe` auf 500 Zeichen begrenzt und technisch bereinigt |
| D8 | Fachprotokolle sind append-only |
| D9 | Planung, Freigabe, Ausführung und Prüfung sind logisch getrennte Verantwortlichkeiten, umgesetzt über deterministische Sub-Workflows und getrennte Berechtigungen, nicht über vier KI-Agenten |

### 2.2 Geändert

**D3 in der Fassung vom 29.08.2026.** Jeder Werkzeugvertrag definiert eine
zulässige Nachweisstrategie. Ermöglicht das Zielsystem einen unabhängigen
Readback, ist dieser verpflichtend. Sonst können Ersatznachweise zulässig sein:
bestätigter Eintrag im Ordner der gesendeten Nachrichten, unveränderliche
Anbieter- oder Nachrichten-ID, Zustellbeleg, Providerstatus, Antwort des
Empfängers, menschliche Bestätigung, definierter nachgelagerter Abgleich.

Die unmittelbare Antwort eines Schreibaufrufs belegt nur die Annahme des
Auftrags. Der Status `succeeded` ist nur zulässig, wenn der Werkzeugvertrag die
verwendete Methode ausdrücklich als ausreichend definiert.

### 2.3 Nicht freigegeben

**D7 ist zurückgezogen.** Das Verbot dauerhafter Speicherung
kontextübergreifender Analysen ist keine verbindliche Entscheidung, sondern die
offene Architekturentscheidung **O-10 für Phase 4**. Phase 0 legt hier nichts
Irreversibles fest.

---

## 3. Umgesetzte Komponenten

| Komponente | Zustand |
|---|---|
| Detail-Spezifikation Version 1.1.0 | fertig |
| Elf JSON-Schemata | fertig, validiert |
| Maschinenlesbares Werkzeugregister mit fünf Einträgen | fertig, validiert, alle im Status `draft` |
| Elf Beispieldatensätze | fertig, validiert |
| Kontextkonfiguration für zwei Kontexte | fertig, gegen Schema und Register geprüft |
| Werkzeug- und Agentenvertrag als Erläuterung | fertig |
| n8n-Konventionen | fertig |
| SQL-Vorlagen für Kontext-, Technikschema und Rechtevergabe | fertig, Grammatik geprüft, **nicht eingespielt** |
| Rendering- und Installationsskript (TS-4) | fertig, Selbsttest bestanden |
| Bereinigung von `message_safe` (TS-5) | fertig, Tests bestanden |
| Prüfung der Kontextkonfiguration (TS-6) | fertig, Tests bestanden |
| Testrunner mit Protokoll | fertig |
| Änderungsprotokoll und Installationsanleitung | fertig |

**Nicht umgesetzt und ausdrücklich nicht Bestandteil:** produktive Workflows,
Datenbankinstanz, Adapter, OCR, E-Mail-Verarbeitung, Gedächtnisimplementierung,
Oberfläche, Auswahl eines Sprachmodells, Auswahl des PostgreSQL-Anbieters.

---

## 4. Dateien und Workflow-Namen

Wurzelverzeichnis im Archiv: `jarvis-phase-0/`

```
README.md
INSTALL_UND_TEST.md
CHANGELOG.md
requirements.txt
SPEC_PHASE_0_JARVIS_FUNDAMENT_v1.1.md
ASSUMPTIONS.md
OPEN_DECISIONS.md
HANDOVER_PHASE_0_2026-08-29.md
schemas/common.schema.json
schemas/context.schema.json
schemas/object_ref.schema.json
schemas/event.schema.json
schemas/task.schema.json
schemas/action.schema.json
schemas/approval.schema.json
schemas/evidence.schema.json
schemas/error_escalation.schema.json
schemas/memory_entry.schema.json
schemas/tool_registry.schema.json
registry/tool_registry.json
templates/context_config.example.json
templates/TOOL_REGISTRY_TEMPLATE.md
templates/AGENT_REGISTRY_TEMPLATE.md
conventions/N8N_CONVENTIONS.md
db/001_context_schema_template.sql
db/002_ops_schema.sql
db/003_grants_and_isolation.sql
tools/idempotency_reference.py
tools/sanitize_message.py
tools/render_context_schema.py
tools/build_examples.py
tools/validate_schemas.py
tools/validate_negative.py
tools/validate_policy.py
tools/validate_sql.py
tools/test_sanitize.py
tools/run_all_tests.py
examples/  (11 JSON-Dateien)
tests/TEST_ABNAHMEMATRIX.md
tests/TESTLAUF_2026-08-29.md
```

Die Verzeichnisstruktur ist Teil des Vertrags: Alle Skripte lösen ihre Pfade
relativ zum Wurzelverzeichnis auf.

**Workflow-Namen:** noch keine gebaut. Die dreizehn Pflicht-Sub-Workflows sind in
`conventions/N8N_CONVENTIONS.md` Abschnitt 4 benannt und vertraglich festgelegt.

---

## 5. Datenmodelle und Schnittstellen

- Elf Schemata nach JSON Schema Draft 2020-12, referenziert über `$id` unter `https://jarvis.local/schemas/`.
- `registry/tool_registry.json` ist die einzige Quelle für Risikoklasse, Nachweisstrategie, Idempotenz und erlaubte Kontexte.
- Einheitlicher n8n-Umschlag mit `trace`, `context_id`, `payload`, `result`.
- Idempotenzschlüssel: SHA-256 über Kontext, Quellreferenz, Aktionstyp, Zielsystem und stabiles Zielobjekt. Referenz in `tools/idempotency_reference.py`.
- Dateidubletten getrennt über `content_hash`.
- Datenbank: je Kontext ein Schema mit eigenem Benutzer, dazu ein gemeinsames `jarvis_ops` ohne Fachdaten.
- `action.actor` ist auf `jarvis` festgelegt. Menschen verantworten Aufgaben, nicht Aktionen.

---

## 6. Zugangsvoraussetzungen

Für den nächsten technischen Schritt erforderlich, ohne Angabe von Zugangsdaten:

- verwaltete PostgreSQL-Instanz mit einem administrativen Benutzer für die Schemaerstellung,
- je Kontext ein Datenbankbenutzer nach dem Muster `jv_<kontext>_user`,
- n8n-Instanz mit Berechtigung zum Anlegen von Credentials und Umgebungsvariablen,
- von aussen per HTTPS erreichbarer Endpunkt für die Freigabebestätigung oder ein Ersatzadapter (O-2),
- privates Git-Repository unter einem von Rolf kontrollierten Konto (O-7, freigegeben),
- Zugriff auf den privaten Dokumentenspeicher und ein Postfach für den Freigabekanal.

**Keine Zugangsdaten in Dokumenten, Prompts oder Übergabedateien.**

---

## 7. Ausgeführte Tests und Ergebnisse

Ausgeführt am 29.08.2026 aus dem entpackten Archiv in einer leeren virtuellen
Umgebung. Protokoll in `tests/TESTLAUF_2026-08-29.md`.

| Prüfschritt | Einzelprüfungen | Ergebnis |
|---|---|---|
| Beispiele erzeugen | – | bestanden |
| Schema- und Vertragsvalidierung | 23 | bestanden |
| Gegenprobe Negativfälle | 24 | bestanden |
| Kontextkonfiguration (TS-6) | 6 | bestanden |
| Bereinigung `message_safe` (TS-5) | 19 | bestanden |
| Rendering der SQL-Vorlagen (TS-4) | 10 | bestanden |
| SQL-Syntax und Struktur | 12 | bestanden |
| **Gesamt** | **94** | **alle bestanden** |

Reproduktion: `pip install -r requirements.txt` und `python3 tools/run_all_tests.py`.

**Nicht getestet:** alles, was eine laufende Datenbank oder n8n-Instanz
voraussetzt. Vollständige Aufstellung in `tests/TEST_ABNAHMEMATRIX.md`
Abschnitt 2.

---

## 8. Bekannte Fehler

Keine offenen Fehler.

Behoben gegenüber Version 1.0.0:

- flaches Archiv ohne Verzeichnisstruktur, dadurch nicht reproduzierbare Befehle,
- Widerspruch zwischen Spezifikation und Schema beim Feld `actor`,
- stilles Verwerfen von Änderungen am Fachprotokoll durch `CREATE RULE`,
- fehlende Sequenzrechte für `bigserial`,
- kein Weg, einen Workflow-Lauf abzuschliessen,
- Verweis auf ein nicht registriertes Werkzeug in der Kontextkonfiguration,
- doppelte Pflege der Risikoklassen in Skript und Markdown.

---

## 9. Technische Schulden

| Nr. | Schuld | Zustand |
|---|---|---|
| TS-1 | SQL-Vorlagen wurden nie gegen eine echte Datenbank ausgeführt | **teilweise geschlossen:** Grammatik mit dem PostgreSQL-Parser geprüft, 120 Anweisungen. Das tatsächliche Einspielen bleibt offen |
| TS-2 | Kontexttrennung und Dublettenfreiheit nur auf Vertrags- und Grammatikebene nachgewiesen | **offen**, betrifft A-3 und A-4 |
| TS-3 | Werkzeugregister enthält nur Einträge im Status `draft` | **offen**, vor der ersten Ausführung ist mindestens ein `approved`-Eintrag nötig |
| TS-4 | freie Textersetzung in SQL-Vorlagen | **geschlossen** durch `tools/render_context_schema.py` mit Musterprüfung und Selbsttest |
| TS-5 | keine Bereinigung von `message_safe` | **geschlossen** durch `tools/sanitize_message.py` mit 19 Tests |
| TS-6 | Herabstufungsverbot nicht durchgesetzt | **geschlossen** durch `tools/validate_policy.py` und Schemaregeln im Werkzeugregister |
| TS-7 | kein maschinenlesbares Agentenregister | **bewusst offen**, entsteht in Phase 1 mit der ersten implementierten Rolle |
| TS-8 | Zeitpunkt der Nachprüfung bei Ersatznachweisen ist definiert, aber nicht implementiert | **offen**, mit dem ersten Werkzeug ohne Readback in Phase 3 |

---

## 10. Offene Entscheidungen

Zehn Punkte in `OPEN_DECISIONS.md`, jeweils mit Empfehlung.

| Nr. | Gegenstand | Status |
|---|---|---|
| O-1 | PostgreSQL-Anbieter | offen, Entscheidung mit der Phase-1-Spezifikation |
| O-2 | HTTPS-Erreichbarkeit des Freigabeendpunkts | offen, separat zu prüfen |
| O-3 | Aufbewahrungsfristen | offen |
| O-4 | Umgang mit dem Altbestand | offen |
| O-5 | Benachrichtigungskanal für Klasse B | offen |
| O-6 | erste Werkzeuge im Status `approved` | offen |
| O-7 | Git-Ablage | **freigegeben** |
| O-8 | Sprachmodell je Aufgabenart | offen |
| O-9 | technische Phase-1-Umgebung | offen |
| O-10 | dauerhafte Speicherung kontextübergreifender Erkenntnisse | offen, zurückgestellt bis Phase 4 |

---

## 11. Exakter nächster Bauschritt

Die Reihenfolge aus Version 1.0.0 ist ersetzt. Verbindlich gilt:

1. **Korrigiertes Phase-0-Artefaktpaket prüfen und freigeben.**
2. Bestehende Spezifikation „KI-Dokumentenassistent, Version 3 vom 27.08.2026" bereitstellen. Sie lag in den bisherigen Chats nicht vor.
3. Dokumentenspezifikation anhand der Phase-0-Verträge zur verbindlichen Phase-1-Spezifikation überarbeiten und freigeben.
4. PostgreSQL-Anbieter (O-1) und technische Phase-1-Umgebung (O-2, O-9) festlegen.
5. Datenbank und Kern-Sub-Workflows aufbauen.
6. A-3 und A-4 praktisch nachweisen (Testfälle K-01 bis K-08, I-01 bis I-05). Damit schliesst das Phase-0-Phase-Gate.
7. Erst danach den Dokumentenpilot starten.

**Vor Schritt 3 wird keine Datenbank eingerichtet und kein produktiver Workflow
gebaut.**

**Für den nächsten Chat mitgeben:** Masterfahrplan, diese Übergabedatei,
`SPEC_PHASE_0_JARVIS_FUNDAMENT_v1.1.md`, die elf Schemata, `registry/tool_registry.json`
sowie die bestehende Spezifikation KI-Dokumentenassistent Version 3.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
