# JARVIS Phase 0 - Test- und Abnahmematrix

**Version 1.1.0 - 29. August 2026**
**Gespeicherter Lauf:** `tests/TESTLAUF_2026-08-29.md`

**Statusbedeutung**

| Status | Bedeutung |
|---|---|
| **bestanden** | ausgeführt am 29.08.2026, Ergebnis im gespeicherten Testlauf belegt |
| **offen (DB)** | spezifiziert, erfordert eine laufende PostgreSQL-Instanz |
| **offen (n8n)** | spezifiziert, erfordert eine n8n-Instanz |
| **offen (P1)** | spezifiziert, wird mit dem ersten fachlichen Anwendungsfall geprüft |

Reproduktion sämtlicher ausgeführter Tests:

```
pip install -r requirements.txt
python3 tools/run_all_tests.py
```

---

## 1. Ausgeführte Tests

**Ergebnis: 7 Prüfschritte, 94 Einzelprüfungen, alle bestanden.**

### 1.1 Schemavalidierung (`validate_schemas.py`)

| ID | Prüfung | Status |
|---|---|---|
| S-01 | Dokumentereignis gegen `event.schema.json` | bestanden |
| S-02 | E-Mail-Ereignis gegen `event.schema.json` | bestanden |
| S-03 | Aktion aus Dokument gegen `action.schema.json` | bestanden |
| S-04 | Aktion aus E-Mail gegen `action.schema.json` | bestanden |
| S-05 | Klasse-C-Aktion gegen `action.schema.json` | bestanden |
| S-06 | Klasse-B-Aktion ohne Readback gegen `action.schema.json` | bestanden |
| S-07 | Freigabe gegen `approval.schema.json` | bestanden |
| S-08 | Nachweis mit Readback gegen `evidence.schema.json` | bestanden |
| S-09 | Nachweis ohne Readback gegen `evidence.schema.json` | bestanden |
| S-10 | Fehlerdatensatz gegen `error_escalation.schema.json` | bestanden |
| S-11 | Aufgabe gegen `task.schema.json` | bestanden |
| S-12 | Kontext `privat` gegen `context.schema.json` | bestanden |
| S-13 | Kontext `arbeitgeber_visolva` gegen `context.schema.json` | bestanden |
| S-14 | Werkzeugregister mit fünf Einträgen gegen `tool_registry.schema.json` | bestanden |

### 1.2 Vertragsregeln im Normalablauf

| ID | Prüfung | Bezug | Status |
|---|---|---|---|
| R-01 | Aktionsobjekte aus Dokument und E-Mail sind strukturgleich | A-2 | bestanden |
| R-02 | Ereignisse aus beiden Quellen nutzen dasselbe Format | A-1 | bestanden |
| R-03 | Keine Aktion verweist auf einen fremden Kontext | A-3 (Vertragsebene) | bestanden |
| R-04 | Idempotenzschlüssel sind je Aktion eindeutig | A-4 (Vertragsebene) | bestanden |
| R-05 | Klasse C nur mit gültiger, einmalig verbrauchter Freigabe und passendem Fingerprint | D5 | bestanden |
| R-06 | Keine Herabstufung unter das Werkzeugminimum | D2 | bestanden |
| R-07 | Jeder Erfolg beruht auf einer vertraglich zugelassenen Nachweismethode | **D3 neu** | bestanden |
| R-08 | Technische Aktionen tragen ausschliesslich den Akteur `jarvis` | Konsistenz Aufgabe/Aktion | bestanden |
| R-09 | Werkzeuge werden nur in erlaubten Kontexten verwendet | AR-3 | bestanden |

### 1.3 Gegenprobe, Schemaverstösse (`validate_negative.py`, Teil 1)

| ID | Unzulässiger Fall | Status |
|---|---|---|
| N-01 | Klasse-C-Aktion ohne Freigabe ausgeführt | bestanden |
| N-02 | Erfolg ohne Ergebnisnachweis | bestanden |
| N-03 | Ereignis ohne Kontext | bestanden |
| N-04 | Umlaut im technischen Bezeichner | bestanden |
| N-05 | Zeitstempel nicht in UTC | bestanden |
| N-06 | Aufgabe ohne Erfolgskriterium | bestanden |
| N-07 | Menschliche Aufgabe ohne benannten Verantwortlichen | bestanden |
| N-08 | Ungültiger Idempotenzschlüssel | bestanden |
| N-09 | Unbekanntes Zusatzfeld in der Aktion | bestanden |
| N-10 | Blinde Wiederholung bei unklarem Ausführungsstatus | bestanden |
| N-11 | Wiederholung ohne dokumentierten Statusabgleich | bestanden |
| N-12 | Entschiedene Freigabe ohne Entscheidungsnachweis | bestanden |
| N-13 | Objektverweis ohne jede Identifikation | bestanden |
| N-14 | Langzeitgedächtniseintrag ohne Quelle | bestanden |
| N-15 | Technische Aktion mit menschlichem Akteur | bestanden |
| N-16 | Ersatznachweis ohne Angabe seiner Grenzen | bestanden |
| N-17 | Ersatznachweis trotz möglichem Readback | bestanden |
| N-18 | Nachweis ohne Bezug auf einen Werkzeugvertrag | bestanden |
| N-19 | Werkzeug mit Aussenwirkung als Klasse A eingetragen | bestanden |
| N-20 | Werkzeugvertrag ohne Readback und ohne Grenzangabe | bestanden |
| N-21 | Vertrag lässt trotz Readback eine schwächere Methode zu | bestanden |

### 1.4 Gegenprobe, Vertragsverstösse (`validate_negative.py`, Teil 2)

| ID | Unzulässiger Fall | Status |
|---|---|---|
| N-22 | Nachweismethode ausserhalb des Werkzeugvertrags | bestanden |
| N-23 | Herabstufung einer Klasse-C-Aktion | bestanden |
| N-24 | Werkzeug im nicht erlaubten Kontext | bestanden |

### 1.5 Kontextkonfiguration, TS-6 (`validate_policy.py`)

| ID | Prüfung | Status |
|---|---|---|
| P-01 | Ausgelieferte Konfiguration ohne Beanstandung (P1 bis P6) | bestanden |
| P-02 | Herabstufung eines Klasse-C-Werkzeugs wird beanstandet | bestanden |
| P-03 | Klasse C als autonom erlaubt wird beanstandet | bestanden |
| P-04 | Klartextadresse statt `env:`-Verweis wird beanstandet | bestanden |
| P-05 | Nicht konfigurierter Freigabekanal wird beanstandet | bestanden |
| P-06 | Override auf unbekanntes Werkzeug wird beanstandet | bestanden |

**Befund:** Die Prüfung hat beim ersten Lauf eine tatsächliche Inkonsistenz in
der ausgelieferten Konfiguration gefunden (Verweis auf das nicht registrierte
Werkzeug `crm_odoo.update_record`). Der Eintrag wurde auf eine Regel nach
Aktionstyp umgestellt.

### 1.6 Bereinigung von `message_safe`, TS-5 (`test_sanitize.py`)

| ID | Prüfung | Status |
|---|---|---|
| B-01 bis B-05 | Fünf zulässige Meldungen bleiben unverändert | bestanden |
| B-06 | Zugangsschlüssel wird entfernt | bestanden |
| B-07 | Bearer-Token wird entfernt | bestanden |
| B-08 | JWT wird entfernt | bestanden |
| B-09 | E-Mail-Adresse wird ersetzt | bestanden |
| B-10 | URL mit Query-Parametern wird ersetzt | bestanden |
| B-11 | Dateipfad mit Klarnamen wird ersetzt | bestanden |
| B-12 | Fachinhalt in Anführungszeichen wird ersetzt | bestanden |
| B-13 | IBAN wird entfernt | bestanden |
| B-14 | Belegnummer wird ersetzt | bestanden |
| B-15 | IP-Adresse wird ersetzt | bestanden |
| B-16 | Zeilenumbrüche und Steuerzeichen werden entfernt | bestanden |
| B-17 | Längenbegrenzung auf 500 Zeichen wird eingehalten | bestanden |
| B-18 | Umgang mit leerer Eingabe | bestanden |
| B-19 | Zweifache Bereinigung liefert dasselbe Ergebnis | bestanden |

### 1.7 Rendering der SQL-Vorlagen, TS-4 (`render_context_schema.py --self-test`)

| ID | Prüfung | Status |
|---|---|---|
| T-01 | Kontext `privat` wird vollständig gerendert | bestanden |
| T-02 | Kontext `arbeitgeber_visolva` wird vollständig gerendert | bestanden |
| T-03 | Gemeinsames technisches Schema wird ausgegeben | bestanden |
| T-04 | Unbekannter Kontext wird abgewiesen | bestanden |
| T-05 | SQL-Einschleusung im Kontextnamen wird abgewiesen | bestanden |
| T-06 | Schemaname ohne Präfix wird abgewiesen | bestanden |
| T-07 | Reserviertes Schema wird abgewiesen | bestanden |
| T-08 | Benutzername ohne Präfix wird abgewiesen | bestanden |
| T-09 | Anführungszeichen im Schemanamen werden abgewiesen | bestanden |
| T-10 | Credential-Referenz ohne Konvention wird abgewiesen | bestanden |

### 1.8 SQL-Grammatik und Struktur (`validate_sql.py`)

| ID | Prüfung | Status |
|---|---|---|
| Q-01 | `001_context_schema.privat.sql`, 33 Anweisungen geparst | bestanden |
| Q-02 | `001_context_schema.arbeitgeber_visolva.sql`, 33 Anweisungen geparst | bestanden |
| Q-03 | `002_ops_schema.sql`, 16 Anweisungen geparst | bestanden |
| Q-04 | `003_grants_and_isolation.privat.sql`, 19 Anweisungen geparst | bestanden |
| Q-05 | `003_grants_and_isolation.arbeitgeber_visolva.sql`, 19 Anweisungen geparst | bestanden |
| Q-06 | Alle Platzhalter sind ersetzt | bestanden |
| Q-07 | Kein `CREATE RULE ... DO INSTEAD NOTHING` | bestanden |
| Q-08 | Für jedes fremde Kontextschema existiert ein Entzug | bestanden |
| Q-09 | Gemeinsames technisches Schema ohne `jsonb`-Spalte | bestanden |
| Q-10 | Append-only wird mit einem Fehler durchgesetzt | bestanden |
| Q-11 | Sequenzrechte für `bigserial` sind vergeben | bestanden |
| Q-12 | Läufe können spaltenweise abgeschlossen werden | bestanden |

---

## 2. Spezifizierte, noch nicht ausgeführte Tests

### 2.1 Kontexttrennung (Abnahmekriterium A-3)

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| K-01 | Schreibversuch mit `jv_privat_user` in `jarvis_visolva.action_log` | Fehler wegen fehlender Berechtigung | offen (DB) |
| K-02 | Datensatz mit `context_id = privat` in `jarvis_visolva.action` einfügen | Prüfbedingung verletzt, Abweisung | offen (DB) |
| K-03 | Zwei Testaktionen in beiden Kontexten ausführen | zwei getrennte Fachprotokolle, kein gemeinsamer Eintrag mit Inhalt | offen (DB) |
| K-04 | Technisches Protokoll nach dem Lauf prüfen | ausschliesslich IDs, Zeiten, Statuscodes, bereinigte Meldung | offen (DB) |
| K-05 | `UPDATE` und `DELETE` auf `action_log` | Fehler `append_only_violation`, kein stilles Verwerfen | offen (DB) |
| K-06 | `INSERT` in `action_log` mit einfachem Kontextbenutzer | erfolgreich; Sequenzrecht greift | offen (DB) |
| K-07 | Ereignis ohne auflösbaren Kontext | Ereignis entsteht, keine Aufgabe, keine Aktion, Ausnahmeliste | offen (n8n) |
| K-08 | Kontextübergreifende Analyse mit anschliessender Aktion | Aktion trägt genau einen Zielkontext und wird nur dort protokolliert | offen (P1) |

### 2.2 Idempotenz (Abnahmekriterium A-4)

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| I-01 | Dasselbe Quellereignis zweimal verarbeiten | eine Aktion, zweiter Lauf endet mit `already_processed` | offen (DB) |
| I-02 | Dieselbe Datei mit anderem Namen erneut einlegen | Dublette über `content_hash` erkannt | offen (DB) |
| I-03 | Zwei parallele Läufe derselben Aktion | genau ein Lauf erhält die Sperre | offen (DB) |
| I-04 | Wiederholung nach technischem Fehler | identischer Schlüssel, kein zweiter Zieldatensatz | offen (n8n) |
| I-05 | Fachlich neue Aktion aus derselben Quelle | neuer Schlüssel, neue Aktion, keine Blockade | offen (DB) |

### 2.3 Freigabe

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| F-01 | Klasse-C-Aktion ohne Freigabe starten | Ausführung verweigert, zusätzlich Prüfbedingung in der Datenbank | offen (n8n) |
| F-02 | Freigabelink zweimal verwenden | zweite Verwendung abgewiesen | offen (n8n) |
| F-03 | Freigabelink nach Ablauf verwenden | abgewiesen, Aktion auf `expired` | offen (n8n) |
| F-04 | Aktionsinhalt nach Freigabe ändern | Fingerprint weicht ab, neue Anforderung nötig | offen (n8n) |
| F-05 | Automatischer Linkaufruf durch einen Sicherheitsscanner | keine Freigabe, zweiter Bestätigungsschritt fehlt | offen (n8n) |
| F-06 | Ablehnung durch Rolf | Aktion `rejected`, protokolliert, keine Ausführung | offen (n8n) |
| F-07 | Retry innerhalb gültiger Freigabe | idempotente Wiederholung ohne neue Freigabe | offen (n8n) |
| F-08 | Retry nach Ablauf der Freigabe | neue Freigabe wird angefordert | offen (n8n) |
| F-09 | Freigabeadapter austauschen | Aktions- und Freigabemodell unverändert | offen (P1) |

### 2.4 Ergebnisnachweis nach D3

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| E-01 | Werkzeug meldet Erfolg, Zielobjekt fehlt beim Readback | `not_confirmed`, kein Erfolg, Eskalation | offen (n8n) |
| E-02 | Readback nicht eindeutig | `inconclusive`, Aktion bleibt `running`, Ausnahme | offen (n8n) |
| E-03 | Werkzeug mit Readback, erfolgreicher Ablauf | Nachweis `readback` und `confirmed` | offen (n8n) |
| E-04 | Werkzeug ohne Readback, Anbieter liefert Nachrichten-ID | Nachweis `provider_message_id` mit Grenzangabe, Erfolg zulässig | offen (n8n) |
| E-05 | Werkzeug ohne Readback, Anbieter liefert keine ID | kein Erfolg, Eskalation | offen (n8n) |
| E-06 | Nachgelagerter Abgleich nach 24 Stunden bleibt aus | Erfolg wird zurückgenommen und eskaliert | offen (n8n) |

### 2.5 Fehler und Eskalation

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| X-01 | Vorübergehender Netzwerkfehler | drei Versuche mit steigendem Abstand, dann Erfolg oder L1 | offen (n8n) |
| X-02 | Fehlende Berechtigung | kein Retry, sofort L2 | offen (n8n) |
| X-03 | Unklarer Ausführungsstatus | Statusabgleich, keine blinde Wiederholung | offen (n8n) |
| X-04 | Fünf Fehler desselben Werkzeugs in 15 Minuten | Schutzschalter öffnet, ein Ereignis statt vieler | offen (n8n) |
| X-05 | Fehlermeldung mit Zugangsdaten aus einem echten Adapter | `message_safe` bereinigt, kein Token im Protokoll | offen (n8n) |
| X-06 | Abbruch durch Rolf | Status `cancelled`, protokolliert | offen (n8n) |

### 2.6 Betrieb und Wiederherstellung

| ID | Testfall | Erwartetes Ergebnis | Status |
|---|---|---|---|
| B-01 | Konfiguration und Schemata aus Git in eine leere Umgebung einspielen | vollständig wiederherstellbar | offen |
| B-02 | Kontext hinzufügen | nur Konfigurationseintrag und ein Lauf des Rendering-Skripts nötig | offen (DB) |
| B-03 | Adapter austauschen | nur Kontextkonfiguration ändert sich | offen (P1) |
| B-04 | Suche nach Zugangsdaten in Git, Prompts und Übergabedateien | keine Treffer | bestanden für dieses Paket, offen für das Repository |

---

## 3. Messbare Abnahmekriterien Phase 0

| Nr. | Kriterium | Messung | Ergebnis |
|---|---|---|---|
| A-1 | Beispieldokument und Beispiel-E-Mail als standardisierte Ereignisse darstellbar | S-01, S-02, R-02 | **erfüllt** |
| A-2 | Aus beiden entsteht dasselbe universelle Aktionsobjekt | S-03, S-04, R-01 | **erfüllt** |
| A-3 | Private und arbeitgeberbezogene Aktionen in getrennten Fachprotokollen | R-03, Q-08, Q-10 auf Vertrags- und Grammatikebene erfüllt; K-01 bis K-06 stehen aus | **offen** |
| A-4 | Wiederholte Testaktion erzeugt keine Dublette | R-04 auf Vertragsebene erfüllt; I-01 bis I-03 stehen aus | **offen** |
| A-5 | Spätere Phasen kommen ohne Parallelmodelle aus | elf Schemata decken alle in den Phasen 1 bis 6 genannten Objekte ab | **erfüllt** |

**Bewertung:** A-1, A-2 und A-5 sind nachgewiesen. A-3 und A-4 sind auf Ebene der
Datenverträge, der Datenbankbedingungen und der SQL-Grammatik vorbereitet, aber
**nicht praktisch nachgewiesen**. Der Nachweis erfolgt im ersten technischen
Meilenstein von Phase 1, nach Freigabe der überarbeiteten Phase-1-Spezifikation.
