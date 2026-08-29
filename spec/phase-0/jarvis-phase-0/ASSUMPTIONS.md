# JARVIS Phase 0 - Getroffene Annahmen

**Version 1.1.0 - 29. August 2026**

Freigegebene Entscheidungen (B1 bis B5, D1, D2, D4, D5, D6, D8, D9 sowie D3 in
der geänderten Fassung) stehen in Abschnitt 2 der Spezifikation, nicht hier.
Diese Liste enthält Annahmen, die ohne ausdrückliche Entscheidung getroffen
wurden. Die Spalte Auswirkung nennt den Aufwand einer späteren Änderung.

## 1. Bestätigte Annahmen aus der Freigabe

| Nr. | Annahme | Auswirkung bei Änderung |
|---|---|---|
| A1 | ULID mit dreistelligem Präfix als globale ID | hoch, betrifft alle Datensätze |
| A2 | Zeitstempel in UTC, Anzeige `Europe/Zurich` | gering |
| A3 | JSON Schema Draft 2020-12, semantische Versionierung | mittel |
| A4 | Git als Versionsquelle, n8n-Export als JSON | gering |
| A5 | Idempotenzschlüssel aus Kontext, Quellreferenz, Aktionstyp, Zielsystem, stabilem Zielobjekt; Dateidubletten über separaten Inhalts-Hash | hoch |
| A6 | Höchstens drei Versuche, Statusabgleich vor jedem Versuch, kein blindes Wiederholen bei unklarem Status | mittel |
| A7 | Fachprotokolle append-only, Korrektur als Gegenbuchung | mittel |
| A8 | Austauschbarer LLM-Adapter, kein festgelegtes Modell in Phase 0 | gering |
| A9 | Speicherziele je Kontext über Speicheradapter | gering |
| A10 | Secrets nur in Credentials, Secret-Store oder Umgebungsvariablen | gering |

## 2. Weiter geltende Annahmen aus Version 1.0.0

| Nr. | Annahme | Begründung | Auswirkung |
|---|---|---|---|
| A11 | Trennung von Aufgabe und Aktion in zwei Objekte | inzwischen als D1 freigegeben | entfällt als Annahme |
| A12 | Gemeinsames technisches Schema ohne `jsonb`-Spalte, Spalten-Positivliste | eine Verbotsliste lässt sich nicht durchsetzen | mittel |
| A13 | `context_id` ist im gemeinsamen technischen Protokoll zulässig | ohne sie keine Fehlersuche; bewusst dokumentierte Restinformation | gering |
| A14 | Freigabe in zwei Schritten | inzwischen als D5 freigegeben | entfällt als Annahme |
| A15 | Freigabefrist standardmässig 72 Stunden privat, 48 Stunden Arbeitgeber | Werktagsbezug im Arbeitgeberkontext | sehr gering, Konfigurationswert |
| A17 | Jede erstmalige produktive Nutzung eines Werkzeugs ist Klasse C bis zur ausdrücklichen Herabstufung | neue Adapter verhalten sich erfahrungsgemäss anders als erwartet | gering |
| A18 | Schutzschalter je Werkzeug: fünf Fehler in 15 Minuten, 30 Minuten Pause | verhindert Fehlerlawinen und Meldungsfluten | sehr gering |
| A20 | Kontextübergreifende Analysen werden nicht in einem Kontextschema gespeichert | **zurückgezogen**, siehe O-10 | entfällt |
| A21 | Aktionstypen und Ereignistypen in Punktnotation `bereich.vorgang` | erweiterbar und filterbar | gering |
| A22 | Klasse-B-Aktion gilt erst mit zugestellter Information als abgeschlossen | sonst entsteht stillschweigende Autonomie in Klasse B | gering |
| A23 | `model_suggestion` reicht für schreibende Aktionen nicht aus | ein Modellvorschlag ist keine belastbare Kontextauflösung | mittel |
| A24 | Gedächtnisschema in Phase 0 definiert, Nutzung erst in Phase 4 | Masterfahrplan 0.2F | gering |
| A25 | `pgvector` nicht Bestandteil von Phase 0 | Entscheidung B1 | gering |

Die früheren Annahmen A16 und A19 sind entfallen: A16 ist durch die geänderte
Entscheidung D3 ersetzt, A19 durch die Präzisierung von D9.

## 3. Neue Annahmen dieser Fassung

| Nr. | Annahme | Begründung | Auswirkung |
|---|---|---|---|
| A26 | Datenbankbenutzer werden nach dem Muster `jv_<kontext>_user` benannt und aus `persistence.credential_ref` abgeleitet | erlaubt dem Rendering-Skript eine geprüfte Ableitung ohne zusätzliches Feld | sehr gering |
| A27 | Append-only wird über Trigger mit `RAISE EXCEPTION` und Fehlercode `42501` durchgesetzt, nicht über Regeln | ein stiller Verlust ist schlimmer als ein Fehler | gering |
| A28 | `workflow_run` wird beim Start eingefügt und über spaltenweises `UPDATE` abgeschlossen | mit reinem `INSERT` liesse sich ein Lauf nie abschliessen; ein zweizeiliges Start-Ende-Modell würde jede Auswertung verkomplizieren | gering |
| A29 | Die Bereinigung von `message_safe` arbeitet nach einer Positivliste zulässiger Zeichen und Muster | eine Verbotsliste müsste jede denkbare Form eines Geheimnisses kennen | mittel, betrifft die Lesbarkeit technischer Meldungen |
| A30 | SQL-Vorlagen werden mit einem eingebetteten PostgreSQL-Parser geprüft statt gegen eine laufende Datenbank | erlaubt einen Grammatiknachweis, ohne eine Datenbank einzurichten | gering |
| A31 | Ein maschinenlesbares Agentenregister entsteht erst in Phase 1 | in Phase 0 existiert noch keine implementierte Rolle; ein zweites unvalidiertes Register wäre eine Fehlerquelle | gering |
| A32 | `deferred_check_after_hours` löst eine terminierte Nachprüfung aus; bleibt sie aus, wird der Erfolg zurückgenommen | ein Ersatznachweis ohne Nachprüfung wäre eine dauerhafte Unsicherheit | gering |

## 4. Bewusst offen gelassen

| Punkt | Grund |
|---|---|
| PostgreSQL-Anbieter | O-1 |
| HTTPS-Erreichbarkeit des Freigabeendpunkts | O-2 |
| Produktives Sprachmodell | A8, Auswahl je Phase |
| Dauerhafte Speicherung kontextübergreifender Erkenntnisse | O-10, Phase 4 |
| Datenschutzrechtliche Bewertung | Entscheidung B5 |
| Konkrete Ordner-IDs, Konten, Adressen | gehören in Umgebungsvariablen |
| Aufbau der Ausnahmeliste als Oberfläche | Phase 2 |
