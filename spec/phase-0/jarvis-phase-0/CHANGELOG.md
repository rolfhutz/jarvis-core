# Änderungsprotokoll - JARVIS Phase 0

## Version 1.1.0 - 29. August 2026

Grundlage: Rückmeldung von Rolf zur Version 1.0.0 vom 29.08.2026.

### Status und Formulierung

| Änderung | Betrifft |
|---|---|
| Eindeutige Statuserklärung eingeführt: Spezifikation freigabefähig, **Phase-Gate nicht bestanden** | Spezifikation Kopf, README, Handover |
| Aussage „Phase 0 als Spezifikationsphase abgeschlossen" entfernt; keine Behauptung einer vollständigen Abnahme mehr | Spezifikation Abschnitt 20, Handover |
| A-3 und A-4 ausdrücklich als offen geführt, praktischer Nachweis als erster technischer Meilenstein von Phase 1 | Abnahmematrix, Phase-Gate, Handover |

### Entscheidungen D1 bis D9

| Entscheidung | Änderung |
|---|---|
| D1, D2, D4, D5, D6, D8 | unverändert, jetzt als **freigegeben** gekennzeichnet statt als selbst gesetzt |
| **D3 geändert** | Die absolute Regel „Erfolg erfordert immer einen separaten Lesevorgang" ist ersetzt durch die vertragsgebundene Nachweisstrategie. Ist ein unabhängiger Readback möglich, bleibt er verpflichtend; sonst gelten die im Werkzeugvertrag festgelegten Ersatznachweise |
| **D7 zurückgezogen** | Das Verbot dauerhafter Speicherung kontextübergreifender Analysen ist keine verbindliche Entscheidung mehr, sondern die offene Architekturentscheidung **O-10 für Phase 4**. Phase 0 legt hier nichts Irreversibles fest |
| **D9 präzisiert** | Die Trennung von Planung, Freigabe, Ausführung und Prüfung ist eine Trennung von Verantwortlichkeiten und Berechtigungen. Sie wird deterministisch über Sub-Workflows umgesetzt. Die acht Basisagenten aus Version 1.0.0 sind auf **drei Sprachmodellrollen** reduziert |

### Umsetzung der geänderten Entscheidung D3

- `schemas/evidence.schema.json` auf 1.1.0 gehoben: neue Methoden `sent_folder_confirmation`, `provider_message_id`, `delivery_receipt`, `provider_status`, `recipient_reply`, `human_confirm`, `deferred_reconciliation`.
- Neues Pflichtfeld `verification.contract_ref` mit Werkzeug-ID, Vertragsversion und `readback_supported`.
- Neues Feld `verification.limitation`, Pflicht bei jeder Methode ausser `readback`.
- Schemaregel: Ist ein Readback möglich, ist er die einzige zulässige Methode.
- Neues Beispiel `examples/evidence_provider_no_readback.json` mit zugehöriger Aktion `examples/action_class_b_message_send.json`.
- Prüfregel R-07 gleicht die verwendete Methode gegen den Werkzeugvertrag ab.

### Werkzeugregister maschinenlesbar

- **Neu:** `registry/tool_registry.json` als einzige Quelle für Risikoklasse, Nachweisstrategie, Idempotenz und erlaubte Kontexte.
- **Neu:** `schemas/tool_registry.schema.json` mit erzwungenen Regeln: externe Wirkung mindestens Klasse B, finanzielle oder rechtliche Wirkung Klasse C, irreversible Schreibvorgänge mindestens Klasse B, Readback schliesst schwächere Methoden aus.
- `tools/validate_schemas.py` liest die Risikoklassen jetzt aus dem Register. Die frühere fest verdrahtete Tabelle im Skript ist entfallen; es gibt keine doppelte Pflege mehr.
- `templates/TOOL_REGISTRY_TEMPLATE.md` ist auf die Erläuterung des Feldvertrags reduziert und enthält keine verbindlichen Werte mehr.

### Aufgabe und Aktion konsistent

- `schemas/action.schema.json`: `actor` ist auf `"jarvis"` als `const` festgelegt. Der Widerspruch zwischen Spezifikation und Schema ist beseitigt.
- Spezifikation Abschnitt 7.2 hält fest: Menschen verantworten Aufgaben, nicht Aktionen. Menschliche Beiträge erscheinen als Freigabe oder als Nachweis mit `human_confirm`.
- Ein Modell für ausdrücklich menschlich ausgeführte Aktionen müsste eigens beschlossen werden; eine stille Enum-Erweiterung ist unzulässig.
- Neuer Negativtest N15 und Vertragsregel R-08.
- In der SQL-Vorlage: `CHECK (actor = 'jarvis')` auf `action`, `CHECK (actor IN (...))` auf `task`.

### SQL und Datenbankrechte

| Punkt | Änderung |
|---|---|
| Stilles Verwerfen | `CREATE RULE ... DO INSTEAD NOTHING` entfernt. Ersetzt durch Trigger mit `RAISE EXCEPTION` und Fehlercode `42501`, zusätzlich Rechteentzug. Prüfung Q2 verhindert die Rückkehr |
| Sequenzrechte | `GRANT USAGE, SELECT ON ALL SEQUENCES` je Kontextschema und auf `jarvis_ops.tech_event_tech_event_id_seq`, dazu `ALTER DEFAULT PRIVILEGES`. Ohne diese Rechte scheitert jedes `INSERT` in eine `bigserial`-Spalte |
| Abschluss von `workflow_run` | Gelöst über spaltenweises `GRANT UPDATE (finished_at, duration_ms, status, error_class, error_code, items_out)` plus Trigger, der bereits abgeschlossene Läufe und unveränderliche Felder schützt |
| Platzhalter | `:schema_name` und `:context_id` ersetzt durch `{{SCHEMA}}`, `{{CONTEXT_ID}}`, `{{DB_USER}}`. Ersetzung ausschliesslich über das geprüfte Skript |
| **Neu:** `db/003_grants_and_isolation.sql` | Rechtevergabe und gegenseitige Entzüge zwischen Kontexten, wird bei jedem neuen Kontext erneut ausgeführt |
| Syntaxprüfung | Alle Vorlagen werden mit dem PostgreSQL-Parser geprüft: 33, 33, 16, 19 und 19 Anweisungen erfolgreich geparst |

### Technische Schulden geschlossen

| Nr. | Schuld | Lösung |
|---|---|---|
| TS-4 | freie Textersetzung in SQL-Vorlagen | `tools/render_context_schema.py`: Werte nur aus der Kontextkonfiguration, Musterprüfung, reservierte Namen gesperrt, Selbsttest mit sieben abgewiesenen Eingaben einschliesslich eines Einschleusungsversuchs |
| TS-5 | keine Bereinigung von `message_safe` | `tools/sanitize_message.py` nach Positivliste, `tools/test_sanitize.py` mit 5 Positiv- und 11 Negativfällen |
| TS-6 | Herabstufungsverbot nicht durchgesetzt | `tools/validate_policy.py` mit sechs Prüfungen und Gegenprobe; zusätzlich Schemaregeln im Werkzeugregister |
| TS-1 | SQL nie ausgeführt | teilweise geschlossen: Grammatik geprüft. Das tatsächliche Einspielen bleibt offen |

**Befund aus TS-6:** Die Prüfung hat in der ausgelieferten Kontextkonfiguration
einen Verweis auf ein nicht registriertes Werkzeug gefunden
(`crm_odoo.update_record`). Der Eintrag wurde auf eine Regel nach Aktionstyp
umgestellt. Das ist genau der Fehlertyp, den die Prüfung künftig verhindert.

### Paketstruktur

- Verzeichnisstruktur `schemas/`, `registry/`, `examples/`, `templates/`, `conventions/`, `db/`, `tools/`, `tests/` bleibt im Archiv erhalten. Alle Pfadangaben in README, Anleitung, Spezifikation, Handover und Skripten stimmen mit dem Archiv überein.
- **Neu:** `requirements.txt` mit festgelegten Versionen.
- **Neu:** `INSTALL_UND_TEST.md`.
- **Neu:** `tools/run_all_tests.py` als Gesamtlauf mit Protokollfunktion.
- **Neu:** `tests/TESTLAUF_2026-08-29.md` mit Datum, Laufzeitumgebung und vollständigem Ergebnis.
- Nachweis in sauberer Umgebung: Archiv entpackt, virtuelle Umgebung erstellt, Abhängigkeiten installiert, Gesamtlauf ausgeführt.

### Offene Entscheidungen

| Nr. | Änderung |
|---|---|
| O-1 | bleibt offen, Entscheidung während der Überarbeitung der Phase-1-Spezifikation. Verbindlich nur: verwaltet, anbieterunabhängig, Sicherung und Export möglich |
| O-2 | bleibt offen. Spezifikation sieht jetzt ausdrücklich den bevorzugten HTTPS-Weg **und** den austauschbaren Freigabeadapter vor |
| O-7 | **freigegeben**: privates Repository unter einem von Rolf kontrollierten Konto, Anbieter austauschbar |
| **O-10 neu** | Dauerhafte Speicherung kontextübergreifender Erkenntnisse, zurückgestellt bis Phase 4 |
| O-9 | ersetzt durch die korrigierte Reihenfolge im Handover |

### Testumfang

| | Version 1.0.0 | Version 1.1.0 |
|---|---|---|
| Prüfschritte | 3 | 7 |
| Einzelprüfungen | 32 | 94 |
| Negativfälle | 14 | 24 |
| SQL-Prüfung | keine | 5 Dateien, 120 Anweisungen, 7 Zusicherungen |

### Nicht geändert

Kontextmodell, ID-Logik, Ereignisformat, Idempotenzverfahren, Fehler- und
Eskalationslogik, Versionierung und Gedächtnisschema sind gegenüber Version
1.0.0 unverändert. Die Änderungen betreffen die Nachweisstrategie, die
Konsistenz von Aufgabe und Aktion, die Durchsetzung in der Datenbank und die
Prüfbarkeit des Pakets.

---

## Version 1.0.0 - 29. August 2026

Erste Ausarbeitung der Phase-0-Verträge auf Grundlage des Masterfahrplans und
der Entscheidungen B1 bis B5.
