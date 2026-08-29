# Änderungsprotokoll — KI-Dokumentenassistent Version 3 zu Version 4.0

**29. August 2026**

> Hinweis: Dieses Protokoll beschreibt den Schritt von Version 3 zu Version 4.0.
> Die eng begrenzten Korrekturen K1 bis K6 der Fassung 4.0.1 stehen in
> `CHANGELOG_V4.0_ZU_V4.0.1.md`.

Version 3 vom 27.08.2026 entstand vor der Phase-0-Ausarbeitung. Sie beschrieb den fachlichen Anspruch richtig, brachte aber ein eigenes Datenmodell mit. Version 4.0 übernimmt den fachlichen Kern und ersetzt das Datenmodell durch die Phase-0-Verträge.

---

## 1. Unverändert übernommen

Diese Inhalte aus Version 3 waren richtig und stehen unverändert in Version 4.0:

| Inhalt | Fundstelle V4.0 |
|---|---|
| Kernauftrag lesen, verstehen, handeln, ablegen | Abschnitt 1 und 4 |
| Qualitätsmassstab: abgenommene Arbeit statt archivierter Menge | Abschnitt 0.2 |
| Trennung von Original, Wissen und Arbeit | Abschnitt 4.2 |
| Ablage wartet nicht auf Erledigung aller Aufgaben | Abschnitt 4.3 |
| Feldweise Extraktion mit Quelle, Seitenverweis und Konfidenz | Abschnitt 9.2 und 9.4 |
| Die acht Verstehensfragen | Abschnitt 9, in `document_analysis.schema.json` überführt |
| Verbot vager Aufgaben wie „Dokument prüfen" | Abschnitt 10.1 |
| Das Beispiel „Prämie 2027 mit Police 2026 vergleichen, bei mehr als 5 % Rückfrageentwurf" | Abschnitt 9.7, technisch hinterlegt |
| Fehler- und Unsicherheitsregeln | Abschnitt 9.4 und 10.4, verschärft |
| Ordnerstruktur 00 bis 99 je Kontext | Abschnitt 11.4 |
| Dateinamensformat mit Datum, Absender, Typ, Betreff, Vorgang | Abschnitt 11.3, präzisiert; die Endung stammt ab 4.0.1 aus dem MIME-Typ |
| Status, Frist und Konfidenz gehören nicht in den Dateinamen | Abschnitt 11.3 |
| Kontext bestimmt Ablage und Protokoll | Abschnitt 6.3 und 11.4 |
| Speicherneutralität über Adapter | Abschnitt 12.1 |
| Portable n8n-Prozessplattform | Abschnitt 13 |
| Abnahmekriterien 95 %, 90 %, 70 % | Abschnitt 16.1 |
| Pilot mit 50 bis 100 neuen Dokumenten, keine Migration | Abschnitt 18.1 |
| Tägliche Kontrollansicht zeigt nur Ausnahmen und Entscheidungen | Abschnitt 11.6, als Datei statt Oberfläche |

---

## 2. Ersetzt: Datenmodell

Version 3 definierte in Kapitel 7 ein eigenes Modell. Es wird vollständig durch die Phase-0-Verträge ersetzt.

| Version 3 | Version 4.0 | Grund |
|---|---|---|
| Ein Objekt „Aufgabe und Aktion" mit `aktion_id` | Getrennte Objekte `task` und `action` | Entscheidung D1. Eine Aufgabe kann offen bleiben, obwohl Aktionen scheitern, und umgekehrt |
| `akteur: KI oder Mensch` bei der Aktion | `action.actor` ist immer `jarvis`; menschliche Arbeit ist eine Aufgabe | Widerspruch zwischen Modell und Ausführung beseitigt |
| Deutsche technische Feldnamen (`dokument_id`, `faelligkeit`, `kontext`) | Englische Bezeichner, deutsche Anzeigelabels | Entscheidung B3 |
| `dokument` mit eingebetteten Aufgaben und Ablagestatus | `document.schema.json` verweist über IDs auf Aufgaben und Aktionen | Vermeidet Parallelmodelle; maschinell geprüft durch Regel V1 |
| `vorgang` als lose Feldliste | `case.schema.json` mit normalisierten Kennungen und Vorgangsnummer | Grundlage für die automatische Zuordnung |
| `extrahiertes Feld` als flache Liste | `extraction_result.schema.json` mit Pflichtbeleg und Validierungsstatus | Ein Wert ohne Beleg wird jetzt verworfen |
| `fachprotokoll` mit `vorher`/`nachher` | `action_log` aus Phase 0, append-only mit `corrects_log_id` | Entscheidung D8 |
| Kein Freigabeobjekt | `approval.schema.json` mit Token-Hash, Frist, Fingerprint | Entscheidung D5 |
| `ergebnisnachweis` als Freitextfeld | `evidence.schema.json` mit vertragsgebundener Methode | Entscheidung D3 |

---

## 3. Ersetzt: Agentenmodell

Version 3 definierte sieben Agenten. Version 4.0 setzt nach Entscheidung D9 auf deterministische Sub-Workflows und nur drei Sprachmodellrollen.

| Version-3-Agent | Version 4.0 | Sprachmodell |
|---|---|---|
| Eingangsagent | `JV-P1-SUB-document_normalize-v1` | nein |
| Leseagent | `JV-P1-SUB-document_ocr-v1` und `document_extract-v1` | ja, `extraction_model` |
| Verstehensagent | `JV-P1-SUB-document_understand-v1` | ja, `reasoning_model` |
| Aktionsagent | `task_derive-v1` und `action_plan-v1` | Vorschlag ja, Entscheidung nein |
| Ausführungsagent | `JV-CORE-SUB-tool_invoke-v1` | nein |
| Ablageagent | `JV-P1-SUB-document_file-v1` | nein |
| Kontrollagent | `deadline_watch-v1` und `daily_report-v1` | nein |

Nur drei von sieben Schritten nutzen überhaupt ein Modell. Klassifizierung, Freigabe, Ausführung und Nachweis sind vollständig regelbasiert.

---

## 4. Verschärft

| Punkt | Version 3 | Version 4.0 |
|---|---|---|
| Ergebnisnachweis | „Erfolgsnachweis" als Feld | Nachweisstrategie je Werkzeugvertrag; kein `succeeded` ohne vertragskonformen Nachweis; Antwort des Schreibaufrufs genügt nie |
| Freigabe | „Die Freigabe zeigt Sachverhalt, Aktion, Empfänger, Frist, Risiko" | Zusätzlich: Einmal-Token, nur Hash gespeichert, Ablauffrist, Inhaltsfingerprint, **zweistufige Bestätigung**, Kontextprüfung |
| Konfidenz | „unsicheres handlungsrelevantes Feld: Aktion blockieren" | Vollständige Schwellwerttabelle, Fristsonderregel 0,95, Belegprüfung gegen den Textbeleg, Plausibilitätsfenster für Fristen und Beträge |
| Halluzinationen | nicht behandelt | Jeder Wert braucht einen Beleg; bei Datums-, Betrags- und Kennungsfeldern wird deterministisch geprüft, ob der Wert im Belegtext vorkommt |
| Dubletten | „Hash bildet und echte Dubletten stoppt" | Zwei Stufen: `content_hash` als harter Stopp, `text_fingerprint` als Verdacht mit manueller Entscheidung |
| Idempotenz | „jeder Workflow ist idempotent" | Drei Ebenen: Datei, Aktion, Verarbeitungsschritt; definierter Wiederanlaufpunkt je Stufe |
| Vorgangszuordnung | „Vorgangsvorschlag und Verknüpfung bei eindeutigem Treffer" | Nur über normalisierte stabile Kennungen. Ähnlichkeitszuordnung ausdrücklich ausgeschlossen |
| Kontextfehler | „ohne gültigen Kontext keine Ablage" | Zusätzlich: eigener Eingangsordner je Kontext, damit die Auflösung immer `source_binding` ist; ein falsch eingelegtes Dokument wird nicht still umgeleitet |
| Dokumentstatus | fünf Zustände | Zwölf Zustände mit vollständiger Übergangstabelle einschliesslich `quarantined` und `review_resolved` |

---

## 5. Zeitlich verschoben

| Inhalt aus Version 3 | Verschoben nach | Grund |
|---|---|---|
| E-Mail-Anhang als Eingangskanal | Phase 2 | Leitplanke; der Adapter ist vorbereitet |
| „Kalendertermin oder Erinnerung eintragen" (Klasse A) | Phase 2 | Kalender ist nicht Phase 1. Fristen laufen über `task.due_at` |
| „Eindeutig definierte Standardantwort senden" (Klasse B) | Phase 2 | Kein Versand in Phase 1 |
| „Fehlende Standardunterlage bei bekanntem Empfänger anfordern" (Klasse B) | Phase 2 | Kein Versand. In Phase 1 entsteht ein Entwurf |
| „Aufgabe an Person oder Queue delegieren" (Klasse B) | Phase 3 | Delegation setzt Empfängersysteme voraus |
| „Individuelle externe E-Mail versenden" (Klasse C) | Phase 2 | Der Freigabeweg wird in Phase 1 mit einem Testwerkzeug nachgewiesen |
| „Datei endgültig löschen" (Klasse C) | offen | In Phase 1 wird zu Testzwecken keine Datei gefährdet (Entscheidung P1-B3) |
| Stufe 3: Suche über den Gesamtbestand, Chat, Sprache | Phasen 4 und 6 | Masterfahrplan |
| Spezialisierte Fachagenten für Versicherung, Steuern, Behörden | Phase 4 | Erst mit Gedächtnis sinnvoll |
| Tägliche Kontrollansicht als Oberfläche | Phase 6 | In Phase 1 ein Bericht als Datei |

---

## 6. Gestrichen

| Inhalt | Grund |
|---|---|
| Kapitel 2 „Nicht-Ziele" mit Datenschutz, DSGVO und Datenstandort | Leitplanke. Version 4.0 erwähnt Datenschutz an genau einer Stelle, wo eine technische Funktion davon abhängt: der Übermittlung an den OCR-Dienst |
| Kapitel 12 „Umsetzung in drei Stufen" | Ersetzt durch die Gliederung 1.0 bis 1.5 |
| Kapitel 13 „Die zehn nächsten Schritte" | Ersetzt durch den Umsetzungs- und Testplan |
| Kapitel 14 „Verbindliche Gesamtentscheidung" | Inhaltlich in die Phase-0-Entscheidungen B1 bis B5 übergegangen |
| „Rückgängig-Link" bei Klasse B | Phase 0 kennt Kompensationsaktionen und `undo_tool_id`. Ein Link, der eine Aktion rückgängig macht, wäre selbst eine ungeschützte Aktion |
| „Kontext: arbeitgeber_" als offener Platzhalter | Ersetzt durch die feste Kontextliste `privat` und `arbeitgeber_visolva` |

---

## 7. Neu in Version 4.0

| Neuerung | Abschnitt |
|---|---|
| Phase 1.0 als eigener Schritt: Fundament aktivieren, A-3 und A-4 nachweisen | 7 |
| Vollständige Zustands- und Übergangstabelle des Dokuments | 5 |
| Vier Schemata: Dokument, Vorgang, Extraktionsergebnis, Dokumentverständnis | Anhang A |
| Neun Werkzeugverträge, maschinenlesbar und validiert | 12.1 |
| Ereigniskatalog um neun Dokumentereignisse erweitert | 6.2 |
| Vorgangsnummer `V-JJJJ-NNNN` als menschenlesbare Klammer | 9.6 |
| Bewertungsraster für die OCR-Auswahl mit Gewichtung | 8.5 |
| Modellrollen mit Benchmarkverfahren | 12.3 |
| Wiederanlaufpunkte je Verarbeitungsstufe | 14.2 |
| Elf definierte Gründe für manuelle Prüfung | 15.2 |
| Testfälle einschliesslich Gegenproben | 17 |
| Schattenbetrieb in der ersten Pilotwoche | 18.2 |
| Prüfquote als Abnahmekriterium mit Obergrenze 20 % | 16.2 |
| Abschnitt „Was Phase 1 bewusst nicht löst" | 19 |
| Validierungsskript gegen die Phase-0-Verträge | `tools/validate_phase1.py` |

---

## 8. Widersprüche, die Version 3 enthielt

Zur Nachvollziehbarkeit festgehalten:

1. **Aufgabe und Aktion vermischt.** Ein Objekt hatte sowohl `beschreibung` und `faelligkeit` (Aufgabe) als auch `zielsystem` und `ausfuehrungsstatus` (Aktion). Damit lässt sich nicht abbilden, dass eine Aufgabe nach zwei gescheiterten Aktionen weiterhin offen ist.
2. **Menschen als Akteure technischer Aktionen.** `akteur: KI oder Mensch` bei einem Objekt mit `ausfuehrungsstatus` führt dazu, dass JARVIS den Ausführungsstand eines Menschen führen müsste, ohne ihn zu kennen.
3. **Ergebnisnachweis ohne Prüfverfahren.** Das Feld existierte, aber es war nicht festgelegt, woraus ein gültiger Nachweis besteht. Ein Workflow ohne Fehler hätte als Nachweis genügt.
4. **Freigabe ohne Schutz gegen Doppelausführung.** Kein Token, keine Frist, keine Einmalverwendung, keine Bindung an den Inhalt.
5. **Kalender in Klasse A.** Ein Kalendereintrag mit externem Bezug stand gleichzeitig in Klasse A („Kalenderblocker anlegen") und in Klasse B („Fristen mit externem Bezug in Kalender eintragen").
6. **Dublettenprüfung nur über den Dateihash.** Zwei Scans desselben Briefes wären als verschiedene Dokumente durchgelaufen.
7. **Kontext `arbeitgeber_` unvollständig.** Der Platzhalter liess offen, wie viele Arbeitgeberkontexte es gibt und wie sie heissen.

Alle sieben sind in Version 4.0 aufgelöst.
