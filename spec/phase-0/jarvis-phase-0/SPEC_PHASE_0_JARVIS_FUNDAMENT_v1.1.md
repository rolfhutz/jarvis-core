# Detail-Spezifikation Phase 0 - JARVIS-Fundament und Architekturverträge

**Version 1.1.0 - 29. August 2026**
**Grundlage:** Jarvis_Masterfahrplan_Phase_0_bis_6.md, Version 1.0
**Freigaben:** Entscheidungen B1 bis B5 und Annahmen A1 bis A10 vom 29.08.2026; Rückmeldung zur Version 1.0.0 vom 29.08.2026
**Vorgängerversion:** 1.0.0, siehe `CHANGELOG.md`

## Statuserklärung

| Gegenstand | Status |
|---|---|
| **Phase-0-Spezifikation** | inhaltlich abgeschlossen, nach den Korrekturen dieser Fassung freigabefähig |
| **Phase-0-Phase-Gate** | **noch nicht vollständig bestanden** |
| Abnahmekriterien A-1, A-2, A-5 | nachgewiesen |
| Abnahmekriterien A-3, A-4 | **offen**, praktischer Nachweis mit PostgreSQL und n8n erforderlich |
| Datenbank, Workflows, Adapter | nicht eingerichtet und nicht gebaut |

Der praktische Nachweis von A-3 und A-4 bildet den ersten technischen Meilenstein von Phase 1 und erfolgt erst nach Freigabe der überarbeiteten Phase-1-Spezifikation.

---

## 1. Ziel, Umfang und Nicht-Ziele

### 1.1 Ziel

Phase 0 legt die verbindlichen Datenverträge und Architekturregeln fest, an die alle späteren JARVIS-Module angeschlossen werden. Ziel ist, dass keine spätere Phase ein eigenes Parallelmodell für Kontext, Ereignis, Aufgabe, Aktion, Freigabe, Nachweis oder Gedächtnis einführen muss.

Phase 0 baut keinen Assistenten. Sie baut das Fundament, auf dem alle Assistenzfunktionen stehen.

### 1.2 Umfang

| Nr. | Gegenstand | Ergebnis |
|---|---|---|
| 1 | Gesamtarchitektur des Fundaments | Abschnitt 3 |
| 2 | Kontextmodell | Abschnitt 4, `schemas/context.schema.json` |
| 3 | Globale Objekt- und Identifikationslogik | Abschnitt 5, `schemas/object_ref.schema.json` |
| 4 | Einheitliches Ereignisformat | Abschnitt 6, `schemas/event.schema.json` |
| 5 | Universelles Aufgaben- und Aktionsobjekt | Abschnitt 7, `schemas/task.schema.json`, `schemas/action.schema.json` |
| 6 | Aktionsklassen A, B, C | Abschnitt 8 |
| 7 | Freigabe-, Ausführungs- und Nachweismodell | Abschnitt 9, `schemas/approval.schema.json`, `schemas/evidence.schema.json` |
| 8 | Werkzeugregister und Werkzeugverträge | Abschnitt 10, `registry/tool_registry.json`, `schemas/tool_registry.schema.json` |
| 9 | Agenten und Verantwortungstrennung | Abschnitt 11, `templates/AGENT_REGISTRY_TEMPLATE.md` |
| 10 | Gedächtnismodell | Abschnitt 12, `schemas/memory_entry.schema.json` |
| 11 | n8n-Konventionen | Abschnitt 13, `conventions/N8N_CONVENTIONS.md` |
| 12 | Zentrale Kontextkonfiguration | Abschnitt 14, `templates/context_config.example.json` |
| 13 | Idempotenz und Schutz vor Mehrfachausführung | Abschnitt 15, `tools/idempotency_reference.py` |
| 14 | Fehler-, Retry-, Abbruch- und Eskalationslogik | Abschnitt 16, `schemas/error_escalation.schema.json` |
| 15 | Versionierung | Abschnitt 17 |
| 16 | Protokollierungs- und Trennungsmodell | Abschnitt 18, `db/` |
| 17 | Testfälle und Abnahmekriterien | Abschnitt 19, `tests/TEST_ABNAHMEMATRIX.md` |
| 18 | Phase-Gate | Abschnitt 20 |
| 19 | Übergabestruktur | Abschnitt 21 |

### 1.3 Nicht-Ziele

Ausdrücklich **nicht** Bestandteil von Phase 0:

- produktive n8n-Workflows jeder Art,
- Einrichtung einer Datenbank,
- Dokumentenautomation, OCR, E-Mail-Verarbeitung, Kalender- oder CRM-Anbindung,
- Implementierung des Gedächtnisses; Phase 0 definiert nur Schema und Regeln,
- Sprach- oder Chatoberfläche,
- Auswahl eines produktiven Sprachmodells,
- Einrichtung von `pgvector` oder einer Suchindexierung,
- Auswahl des PostgreSQL-Anbieters,
- datenschutzrechtliche Grundsatzprüfung,
- Festlegung, wie kontextübergreifende Erkenntnisse dauerhaft gespeichert werden (zurückgestellt bis Phase 4, siehe O-10),
- Überarbeitung der Spezifikation KI-Dokumentenassistent.

### 1.4 Nutzen von Phase 0

Der Nutzen ist nicht sichtbare Funktionalität, sondern vermiedener Umbau. Messbar an drei Punkten:

1. Ein Dokumentereignis und ein E-Mail-Ereignis erzeugen strukturgleiche Aktionsobjekte, obwohl die Quellsysteme nichts gemeinsam haben.
2. Eine Verwechslung des Fachprotokolls ist technisch ausgeschlossen, nicht nur per Konvention verboten.
3. Eine wiederholte Verarbeitung erzeugt keine Dublette, unabhängig davon, welcher Workflow sie auslöst.

Punkt 1 ist nachgewiesen. Punkte 2 und 3 sind auf Ebene der Datenverträge und der SQL-Grammatik nachgewiesen, praktisch noch nicht.

---

## 2. Stand der Grundsatzentscheidungen

### 2.1 Freigegeben

| Nr. | Entscheidung |
|---|---|
| B1 | Verwaltetes PostgreSQL als zentrale Wahrheitsquelle, anbieterunabhängige Architektur, `pgvector` später |
| B2 | Trennung über eigene Schemas, Datenbankbenutzer und n8n-Credentials je Kontext; gemeinsame n8n-Infrastruktur erlaubt |
| B3 | Technische Bezeichner englisch, deutsche Anzeigelabels und Freitexte |
| B4 | Freigabe über austauschbaren Kanaladapter, zunächst E-Mail mit signiertem Einmal-Link |
| B5 | Zwei Startkontexte, Modell offen für weitere |
| D1 | Aufgabe und Aktion bleiben getrennte Objekte |
| D2 | Die Risikoklasse darf gegenüber dem Werkzeugminimum nur erhöht, niemals gesenkt werden |
| D4 | Zwischen Freigabe und Werkzeugaufruf darf kein Sprachmodell den freigegebenen Inhalt verändern |
| D5 | Freigabe erfolgt in zwei Schritten; das Öffnen eines Links allein ist keine Freigabe |
| D6 | Gemeinsame technische Protokolle enthalten keine fachlichen Payloads; `message_safe` bleibt auf 500 Zeichen begrenzt und wird technisch bereinigt |
| D8 | Fachprotokolle sind append-only |
| D9 | Planung, Freigabe, Ausführung und Prüfung sind logisch getrennte Verantwortlichkeiten |

### 2.2 Geändert

**D3 in der Fassung vom 29.08.2026 (verbindlich).** Die frühere Formulierung „Erfolg erfordert immer einen separaten Lesevorgang" war zu absolut und hätte Werkzeuge ohne Lesezugriff unbrauchbar gemacht.

Es gilt: Jeder Werkzeugvertrag definiert eine zulässige Nachweisstrategie. Ermöglicht das Zielsystem einen unabhängigen Readback, ist dieser verpflichtend. Ist kein Readback möglich, kann der Vertrag andere Nachweise als ausreichend festlegen: bestätigter Eintrag im Ordner der gesendeten Nachrichten, unveränderliche Anbieter- oder Nachrichten-ID, Zustellbeleg, Providerstatus, Antwort des Empfängers, menschliche Bestätigung oder ein definierter nachgelagerter Abgleich.

Die unmittelbare Antwort eines Schreibaufrufs belegt grundsätzlich nur die Annahme des Auftrags, nicht die vollständige fachliche Wirkung. Eine Aktion erhält den Status `succeeded` nur, wenn der Werkzeugvertrag die tatsächlich verwendete Nachweismethode ausdrücklich als ausreichend definiert.

Umsetzung: Abschnitt 9.3, `schemas/evidence.schema.json`, `schemas/tool_registry.schema.json`, `registry/tool_registry.json`, Prüfregel R-07.

### 2.3 Nicht freigegeben

**D7 ist keine verbindliche Entscheidung.** Die Regel, dass kontextübergreifende Analysen grundsätzlich nicht dauerhaft gespeichert werden dürfen, wird nicht festgelegt. Sie wird als offene Architekturentscheidung **O-10 für Phase 4** geführt.

Für Phase 0 gilt stattdessen nur (Abschnitt 4.5):

- Kontextübergreifende Analyse ist ausschliesslich auf ausdrückliche Anweisung von Rolf zulässig.
- Jede daraus entstehende schreibende Aktion besitzt genau einen Zielkontext.
- Dokumentablagen und fachliche Aktionsprotokolle bleiben getrennt.
- Phase 0 legt keine irreversible Einschränkung für die spätere Speicherung fest.

---

## 3. Gesamtarchitektur des Fundaments

### 3.1 Schichten

```
  Auslöser         Dateiablage | Postfach | Kalender | Zeitplan | Dialog
        |
  Adapterschicht   austauschbare Systemadapter, je Kontext konfiguriert
        |
  Wahrnehmung      context_resolve -> event_normalize -> Ereignis
        |
  Ableitung        Aufgabe (was zu erreichen ist)
                   Aktion + Risikoklasse (was technisch geschieht)
        |
  Kontrolle        idempotency_guard -> approval_request/callback
        |
  Ausführung       tool_invoke (nur registrierte Werkzeuge)
        |
  Nachweis         evidence_verify nach Werkzeugvertrag
        |
  Protokoll        Fachprotokoll je Kontext | technisches Protokoll gemeinsam
```

### 3.2 Verbindliche Architekturregeln

**AR-1 Kontextpflicht.** Kein Objekt ohne `context_id`. Keine fachliche Aktion ohne aufgelösten Kontext. Ein Ereignis mit `context_resolution.method = unresolved` darf ausschliesslich in die Ausnahmeliste, niemals in die Ableitung.

**AR-2 Trennung der Fachdaten.** Fachliche Inhalte liegen ausschliesslich im Kontextschema. Das gemeinsame Schema `jarvis_ops` enthält keine Freitexte aus Quellsystemen. Durchsetzung über getrennte Datenbankbenutzer und eine Spalten-Positivliste.

**AR-3 Registerpflicht.** Es werden nur Werkzeuge aufgerufen, die im Werkzeugregister mit Status `approved` stehen und den Kontext erlauben.

**AR-4 Klassifizierung ist nicht verhandelbar (D2).** Die Risikoklasse ergibt sich aus dem Werkzeugvertrag und den Kontextregeln. Sie darf erhöht, niemals gesenkt werden. Ein Sprachmodell darf sie vorschlagen, aber nicht bestimmen.

**AR-5 Getrennte Verantwortlichkeiten (D9).** Planung, Freigabe, Ausführung und Prüfung sind vier getrennte Verantwortlichkeiten mit getrennten Berechtigungen. Sie werden bevorzugt als deterministische Sub-Workflows umgesetzt; vier eigenständige KI-Agenten oder vier Modellaufrufe sind ausdrücklich **nicht** erforderlich.

**AR-6 Nachweispflicht nach Vertrag (D3).** Eine Aktion gilt erst als erfolgreich, wenn ein Nachweis vorliegt, den der Werkzeugvertrag als ausreichend definiert. Ist ein unabhängiger Readback möglich, ist er verpflichtend. Die blosse Antwort des Schreibaufrufs genügt nie.

**AR-7 Idempotenz vor Ausführung.** Vor jedem Werkzeugaufruf wird die Sperre erhoben. Ohne Sperre keine Ausführung.

**AR-8 Keine Bindung an Anbieter.** Systemnamen erscheinen ausschliesslich als Adapter-IDs. Kein Arbeitgebername, keine Ordner-ID, kein Konto in der Prozesslogik.

**AR-9 Anhalten schlägt Raten.** Bei fehlendem Kontext, fehlender Freigabe, fehlender Berechtigung oder unklarem Ausführungsstatus wird angehalten und eskaliert, nicht geschätzt.

**AR-10 Keine Sackgassen für die Oberfläche.** Keine technische Festlegung darf die spätere einheitliche JARVIS-Oberfläche aus Phase 6 verhindern. Freigabe, Benachrichtigung und Dialog laufen über austauschbare Adapter; das Aktions- und Freigabemodell bleibt beim Wechsel des Kanals unverändert.

---

## 4. Kontextmodell

### 4.1 Startkontexte

| `context_id` | Anzeige | Art | DB-Schema | DB-Benutzer |
|---|---|---|---|---|
| `privat` | Privat | `private` | `jarvis_privat` | `jv_privat_user` |
| `arbeitgeber_visolva` | Arbeitgeber | `employer` | `jarvis_visolva` | `jv_visolva_user` |

Weitere Kontexte werden ausschliesslich durch einen zusätzlichen Konfigurationseintrag und einen Lauf von `tools/render_context_schema.py` ergänzt. Eine Änderung der Prozesslogik ist nicht erforderlich; das ist der Prüfmassstab für die Erweiterbarkeit.

### 4.2 Was der Kontext steuert

Speicherziel, Fachprotokoll, E-Mail-Konto, Kalender, Aufgabenbereich, Geschäftssystem, Berechtigungen, erlaubte Aktionsklassen, Freigabekanal und Aufbewahrung. Alle Werte stehen in der Kontextkonfiguration, nicht im Workflow.

### 4.3 Kontextauflösung

| Methode | Beschreibung | Vertrauensgrad |
|---|---|---|
| `user_declared` | Rolf hat den Kontext im Dialog gesetzt | höchste |
| `source_binding` | Quelle ist fest einem Kontext zugeordnet | hoch |
| `rule` | deterministische Regel, z. B. Absenderdomäne | mittel |
| `model_suggestion` | Vorschlag eines Sprachmodells | niedrig |
| `unresolved` | keine Auflösung möglich | keine |

Regeln:

- Für schreibende Aktionen reicht `model_suggestion` allein nicht aus. Erforderlich ist `source_binding`, `rule` oder eine Bestätigung durch Rolf.
- Bei `unresolved` entsteht ein Ereignis, aber keine Aufgabe und keine Aktion. Der Vorgang geht in die Ausnahmeliste.
- Eine aufgelöste `context_id` wird innerhalb einer Verarbeitungskette nicht mehr verändert. Eine Korrektur erfordert einen neuen Vorgang mit Verweis auf den alten.

### 4.4 Kontextwechsel im Dialog

Der aktive Kontext ist immer sichtbar. Ein Wechsel ist ausdrücklich zu erklären und wird protokolliert. Passt eine Anfrage erkennbar nicht zum aktiven Kontext, fragt JARVIS nach, statt still zu wechseln.

### 4.5 Kontextübergreifendes Denken

Verbindlich in Phase 0:

1. Kontextübergreifende Analyse erfolgt ausschliesslich auf ausdrückliche Anweisung von Rolf.
2. Der Vorgang wird als solcher gekennzeichnet und in beiden betroffenen Fachprotokollen vermerkt.
3. Jede daraus entstehende schreibende Aktion trägt genau einen Zielkontext und wird ausschliesslich dort protokolliert. Kontextübergreifendes Schreiben gibt es nicht.
4. Dokumentablagen und fachliche Aktionsprotokolle bleiben getrennt.

**Offen (O-10):** Ob und wie kontextübergreifende Erkenntnisse und Erinnerungen dauerhaft gespeichert werden, wird in Phase 4 entschieden. Das Feld `visibility` in `memory_entry.schema.json` und die Kennzeichnung solcher Vorgänge halten beide Wege offen. Phase 0 trifft hier bewusst keine irreversible Festlegung.

---

## 5. Globale Objekt- und Identifikationslogik

### 5.1 ID-Format

```
<präfix>_<ULID>          Beispiel: act_01JBQ8Z4K7M3N9P2R5T6V8W0XY
```

ULID mit 26 Zeichen in Crockford-Base32: zeitlich sortierbar, indexfreundlich, in Protokollen lesbar.

### 5.2 Präfixe

| Objekt | Präfix | Objekt | Präfix |
|---|---|---|---|
| Dokument | `doc` | Aktion | `act` |
| E-Mail | `eml` | Termin | `cal` |
| Gespräch | `cnv` | Entscheidung | `dec` |
| Person | `per` | Gedächtniseintrag | `mem` |
| Organisation | `org` | Wissenseintrag | `knw` |
| Projekt | `prj` | Freigabe | `apr` |
| Vorgang | `cse` | Ergebnisnachweis | `evd` |
| Aufgabe | `tsk` | Ereignis | `evt` |
| Datei | `fil` | Fehler | `err` |

IDs sind global eindeutig, kontextunabhängig und werden nie wiederverwendet. Die Kontextzugehörigkeit ergibt sich aus dem Datensatz, nicht aus der ID.

### 5.3 Objektverweis

Jeder Verweis nutzt `object_ref.schema.json` und enthält entweder eine JARVIS-ID oder die Kombination aus Adapter und Fremd-ID, immer aber die `context_id`.

Das Feld `label` kann fachlichen Inhalt enthalten und ist deshalb im gemeinsamen technischen Protokoll unzulässig. Dort steht ausschliesslich `object_id`.

---

## 6. Einheitliches Ereignisformat

### 6.1 Prinzip

Jede Wahrnehmung wird in denselben Umschlag überführt, unabhängig von der Quelle. Nur der Inhalt von `payload` unterscheidet sich. Das ist die Voraussetzung dafür, dass spätere Phasen neue Quellen anschliessen können, ohne die Ableitungslogik zu ändern.

### 6.2 Ereignistypen und Anzeigelabels

| Technischer Typ | Anzeigelabel |
|---|---|
| `document.received` | Dokument eingegangen |
| `document.classified` | Dokument eingeordnet |
| `document.duplicate_detected` | Dublette erkannt |
| `email.received` | E-Mail eingegangen |
| `email.sent` | E-Mail versendet |
| `calendar.event_upcoming` | Termin bevorsteht |
| `deadline.due_soon` | Frist bald fällig |
| `task.created` | Aufgabe angelegt |
| `task.overdue` | Aufgabe überfällig |
| `task.completed` | Aufgabe erledigt |
| `crm.status_changed` | CRM-Status geändert |
| `decision.recorded` | Entscheidung getroffen |
| `action.planned` | Aktion geplant |
| `action.approval_requested` | Freigabe angefordert |
| `action.approved` | Aktion freigegeben |
| `action.rejected` | Aktion abgelehnt |
| `action.executed` | Aktion ausgeführt |
| `action.verified` | Ergebnis bestätigt |
| `action.failed` | Aktion fehlgeschlagen |
| `action.escalated` | Aktion eskaliert |
| `system.error` | Systemfehler |

Neue Ereignistypen werden ausschliesslich über eine Erweiterung dieser Tabelle eingeführt, immer mit deutschem Label.

### 6.3 Pflichtfelder

`schema_version`, `event_id`, `event_type`, `event_time`, `received_at`, `context_id`, `context_resolution`, `source`, `subject`, `idempotency_key`, `producer`, `trace`.

`event_time` ist der fachliche Eintritt, `received_at` die Aufnahme durch JARVIS. Fristen bemessen sich am fachlichen Zeitpunkt, Dubletten- und Verzögerungsanalysen am Aufnahmezeitpunkt.

---

## 7. Universelles Aufgaben- und Aktionsobjekt

### 7.1 Trennung von Aufgabe und Aktion (D1)

| | Aufgabe (`task`) | Aktion (`action`) |
|---|---|---|
| Beantwortet | Was muss erreicht werden? | Was wird technisch ausgeführt? |
| Verantwortlicher | `jarvis`, `rolf`, `mitarbeiter`, `externer` | ausschliesslich `jarvis` |
| Erfolgsmass | `success_criterion` | Ergebnisnachweis nach Werkzeugvertrag |
| Anzahl | eine je Verpflichtung | null bis mehrere je Aufgabe |
| Beispiel | „Sonderkündigungsrecht prüfen und entscheiden" | `task.create`, `mail.send`, `file.move` |

Eine Aufgabe kann bestehen bleiben, obwohl mehrere Aktionen fehlgeschlagen sind. Umgekehrt kann eine Aktion erfolgreich sein, ohne dass die Aufgabe erledigt ist. Ein gemeinsames Objekt würde beide Zustände vermischen.

### 7.2 Wer führt aus

Verbindlich und im Schema durchgesetzt:

- **Aufgaben** können von Menschen verantwortet werden. `task.actor` erlaubt `jarvis`, `rolf`, `mitarbeiter`, `externer`. Bei menschlichem Akteur ist `assignee` Pflicht.
- **Aktionen** sind technische Ausführungen durch einen registrierten Executor. `action.actor` ist auf den Wert `jarvis` festgelegt (`const`).
- Arbeit, die ein Mensch erledigt, wird als Aufgabe abgebildet, niemals als Aktion. Es gibt in Phase 0 kein Modell für eine „menschlich ausgeführte Aktion".
- Menschliche Beiträge erscheinen an zwei anderen Stellen: als Freigabe (`approval`) und als Nachweis mit der Methode `human_confirm`.

Sollte später eine ausdrücklich menschlich ausgeführte Aktion nötig werden, ist dafür ein eigenes, benanntes Modell zu beschliessen. Eine stille Erweiterung des Enums ist unzulässig.

### 7.3 Pflichtregeln Aufgabe

- `success_criterion` ist Pflicht. Ohne überprüfbares Kriterium ist „erledigt" interpretierbar.
- Aufgaben für Menschen benötigen einen benannten `assignee`.
- Abschluss erfordert `closed_at` und mindestens einen Nachweis in `closing_evidence_ids`.
- `consequence_of_inaction` wird ab Phase 1 verpflichtend befüllt.

### 7.4 Pflichtregeln Aktion

- Ohne aufgelösten Kontext entsteht keine Aktion.
- `risk_class_source` dokumentiert die Herkunft der Klasse.
- Fehlen Pflichteingaben, ist der Status `blocked` und `missing_inputs` benennt sie. Geratene Werte sind unzulässig.
- Erfolg setzt `executed_at`, `verified_at` und mindestens einen vertragskonformen Nachweis voraus.
- `content_fingerprint` ist Pflicht für alle Klasse-C-Aktionen.

### 7.5 Statusmodell

```
planned ──> blocked ──> planned
   │
   ├─(Klasse C)─> awaiting_approval ──> approved ──> running ──> succeeded
   │                      │                                 └─> failed ──> (Retry) running
   │                      ├─> rejected
   │                      └─> expired
   └─(Klasse A/B)──────────────────────> running ──> succeeded
```

Zusätzlich: `cancelled` (durch Rolf), `superseded` (durch eine neuere Aktion ersetzt).

---

## 8. Aktionsklassen A, B und C

### 8.1 Definition

| Klasse | Verhalten | Merkmale |
|---|---|---|
| **A** | automatisch ausführen | reversibel, keine Aussenwirkung, geringe Auswirkung |
| **B** | automatisch ausführen und Rolf informieren | korrigierbar, begrenzte Aussenwirkung |
| **C** | vor Ausführung freigeben lassen | extern, finanziell, rechtlich oder schwer reversibel |

### 8.2 Zuordnungsregeln

```
risk_class = max(
    tool.risk_class_default,        aus registry/tool_registry.json
    kontextregel(action_type oder tool_id),
    aussenwirkungsregel,
    manuelle_hochstufung
)
```

**Aussenwirkungsregel:** Enthält `target.recipients` mindestens einen externen Empfänger, gilt mindestens Klasse B. Bei individueller, nicht standardisierter Kommunikation Klasse C.

**Immer Klasse C, ohne Ausnahme:** individuelle kritische E-Mails, Kündigungen, Vertragsänderungen, Zahlungen und Zahlungsfreigaben, rechtsverbindliche Erklärungen, unwiederbringliches Löschen oder Überschreiben fachlicher Daten sowie jede erstmalige produktive Nutzung eines Werkzeugs bis zur ausdrücklichen Herabstufung.

**Herabstufungsverbot (D2).** Eine Regel darf die Klasse nur erhöhen. Das Werkzeugregister und die Kontextkonfiguration werden dagegen automatisch geprüft (`tools/validate_policy.py`, Prüfung P1). Zusätzlich erzwingt `schemas/tool_registry.schema.json`, dass Werkzeuge mit externer, finanzieller oder rechtlicher Wirkung nicht als Klasse A eingetragen werden können.

### 8.3 Klasse B ohne Meldung ist unzulässig

Eine Klasse-B-Aktion gilt erst als abgeschlossen, wenn die Information an Rolf zugestellt wurde. Bleibt die Zustellung aus, wird die Aktion nicht rückgängig gemacht, aber als Ausnahme geführt. Andernfalls entstünde stillschweigende Autonomie in Klasse B.

---

## 9. Freigabe-, Ausführungs- und Ergebnisnachweismodell

### 9.1 Freigabeablauf

```
1. Aktion wird mit risk_class = C und status = awaiting_approval erzeugt
2. content_fingerprint wird über die entscheidungsrelevanten Felder gebildet
3. Freigabedatensatz mit Einmal-Token und Ablauffrist entsteht
4. Freigabeanforderung geht über den Kanaladapter des Kontexts an Rolf
5. Rolf öffnet den signierten Link -> Bestätigungsseite mit der Aktionskarte
6. Zweiter ausdrücklicher Schritt bestätigt oder lehnt ab (D5)
7. Prüfung: Token gültig, nicht abgelaufen, nicht verbraucht, Fingerprint stimmt
8. Bei Erfolg: Aktion auf approved, Freigabe auf consumed
9. Ausführung ohne weitere Modellbeteiligung (D4)
```

### 9.2 Sicherheitsregeln des Freigabekanals

| Regel | Grund |
|---|---|
| Token nur in der Nachricht, in der Datenbank nur der Hash | Ein Datenbankzugriff darf keine Freigabe ermöglichen |
| Zwei Schritte: Link öffnen, dann bestätigen | E-Mail-Sicherheitsscanner und Vorschaufunktionen rufen Links automatisch auf. Ein einfacher Linkaufruf würde die Freigabe vom Virenscanner erteilen lassen |
| Ablauffrist, Standard 72 Stunden privat, 48 Stunden Arbeitgeber | Alte Freigaben dürfen nicht später greifen |
| Einmalige Verwendung, Status `consumed` | Verhindert Doppelausführung durch mehrfaches Klicken |
| Bindung an `content_fingerprint` | Ändert sich der Inhalt, verfällt die Freigabe |
| Genau eine offene Anforderung je Aktion und Inhaltsstand | Verhindert widersprüchliche Entscheidungen |
| Ablehnung ist ebenso protokollpflichtig wie Zustimmung | Nachvollziehbarkeit in beide Richtungen |

**Austauschbarkeit (B4, AR-10).** Der Freigabekanal ist ein Adapter (`policy.approval.channel_adapter`). Bevorzugt ist der Weg über einen per HTTPS erreichbaren Bestätigungsendpunkt. Ist dieser nicht verfügbar, kann ein anderer Adapter eingesetzt werden, solange er dieselben sieben Regeln erfüllt. Das Aktions- und Freigabemodell bleibt unverändert; die spätere Freigabe über die JARVIS-Oberfläche aus Phase 6 ist derselbe Adaptertausch. Die technische Erreichbarkeit wird in O-2 geführt.

### 9.3 Ergebnisnachweis nach Werkzeugvertrag (D3)

Der Werkzeugvertrag in `registry/tool_registry.json` legt für jedes Werkzeug fest:

| Feld | Bedeutung |
|---|---|
| `readback_supported` | Erlaubt das Zielsystem einen unabhängigen Lesevorgang des geschriebenen Objekts? |
| `accepted_methods` | Abschliessende Liste der Nachweismethoden, die für `succeeded` ausreichen |
| `required_types` | Welche Nachweisarten erhoben werden müssen |
| `verify_delay_seconds` | Wartezeit vor der Prüfung |
| `limitation` | Was der Ersatznachweis ausdrücklich nicht belegt |
| `deferred_check_after_hours` | Zeitpunkt eines vereinbarten nachgelagerten Abgleichs |

**Regeln:**

1. Ist `readback_supported` wahr, ist `readback` die einzige zulässige Methode. Das Schema lässt in diesem Fall keine schwächere Methode im Vertrag zu.
2. Ist `readback_supported` falsch, muss der Vertrag `limitation` benennen. Ein Ersatznachweis ohne Angabe seiner Grenzen ist unzulässig.
3. Jeder Nachweis trägt `verification.contract_ref` mit Werkzeug-ID, Vertragsversion und `readback_supported`. Damit ist später nachvollziehbar, auf welcher vertraglichen Grundlage ein Erfolg festgestellt wurde.
4. Die unmittelbare Antwort des Schreibaufrufs ist nie allein ausreichend. Sie belegt die Annahme des Auftrags.
5. Bei `result = inconclusive` bleibt die Aktion auf `running` und wird zur Ausnahme. Sie wird weder als erfolgreich markiert noch blind wiederholt.
6. Ist `deferred_check_after_hours` gesetzt, entsteht mit dem Nachweis eine terminierte Nachprüfung. Bleibt sie aus, wird der Erfolg zurückgenommen und eskaliert.

**Beispiele aus dem ausgelieferten Register:**

| Werkzeug | Readback | Zulässige Methode | Grenze |
|---|---|---|---|
| `storage_gdrive.move_file` | ja | `readback` | – |
| `tasks_internal.create_task` | ja | `readback` | – |
| `mail_default.send_message` | ja | `readback` im Ordner der gesendeten Nachrichten | – |
| `messaging_superchat.send_template_message` | nein | `provider_message_id`, `delivery_receipt`, `recipient_reply` | belegt Annahme und Auslieferung, nicht das Lesen durch den Empfänger |

---

## 10. Werkzeugregister und Werkzeugverträge

**Einzige Quelle ist `registry/tool_registry.json`**, validiert gegen `schemas/tool_registry.schema.json`. Risikoklasse, Nachweisstrategie, Idempotenz und erlaubte Kontexte werden ausschliesslich dort gepflegt. Prüfskripte und die spätere Klassifizierung lesen dieselbe Datei; es gibt keine zweite Pflege in Markdown oder Skriptcode.

`templates/TOOL_REGISTRY_TEMPLATE.md` ist ausschliesslich Erläuterung des Feldvertrags und enthält selbst keine verbindlichen Werte.

Kernpunkte:

- Ein nicht registriertes Werkzeug existiert für JARVIS nicht.
- Ein schreibendes Werkzeug ohne definierte Nachweisstrategie kann den Status `approved` nicht erhalten.
- `allowed_contexts` ist eine Positivliste; leer bedeutet nicht erlaubt.
- Das Schema erzwingt: externe Wirkung mindestens Klasse B, finanzielle oder rechtliche Wirkung Klasse C, irreversible Schreibvorgänge mindestens Klasse B.
- Änderungen an Risikoklasse, erlaubten Kontexten oder Nachweisstrategie erzwingen eine neue Hauptversion des Werkzeugs.

Alle fünf ausgelieferten Einträge stehen im Status `draft`. Vor der ersten Ausführung in Phase 1 muss mindestens ein Eintrag ausdrücklich auf `approved` gesetzt werden.

---

## 11. Agenten und Verantwortungstrennung

### 11.1 Umsetzung von D9

Planung, Freigabe, Ausführung und Prüfung sind vier getrennte Verantwortlichkeiten. Die Trennung wird **deterministisch** umgesetzt, nicht durch vier KI-Agenten:

| Verantwortlichkeit | Umsetzung | Sprachmodell beteiligt |
|---|---|---|
| Planung | `SUB-action_plan` mit `SUB-action_classify` | nur für Vorschlag von Ziel und Inhalt |
| Freigabe | `SUB-approval_request` und `SUB-approval_callback` | nein |
| Ausführung | `SUB-tool_invoke` | nein |
| Prüfung | `SUB-evidence_verify` | nein |

Nach der Freigabe steht kein Sprachmodell mehr im Pfad (D4). Klassifizierung, Freigabeprüfung, Ausführung und Nachweis sind reine Regel- und Adapterlogik.

### 11.2 Verbleibende Sprachmodellrollen

Nur dort, wo Interpretation tatsächlich nötig ist:

| Rolle | Aufgabe | Darf auslösen |
|---|---|---|
| `event_interpreter` | Quellsignal verstehen, Felder extrahieren, Kontext vorschlagen | nichts, erzeugt nur Ereignisinhalte |
| `task_deriver` | Aufgaben mit Akteur, Frist und Erfolgskriterium ableiten | Aufgaben, keine Aktionen |
| `draft_composer` | Entwürfe und Zusammenfassungen formulieren (ab Phase 1) | Entwurfsinhalte, keine Ausführung |

Alle drei verweisen auf den `llm`-Adapter des Kontexts und eine versionierte Prompt-ID. Kein Modellname wird in Phase 0 festgelegt.

### 11.3 Guardrails

- Kein Sprachmodell setzt eine Risikoklasse fest oder senkt sie.
- Kein Sprachmodell erteilt eine Freigabe.
- Kein Sprachmodell ruft ein Werkzeug direkt auf.
- Kein Sprachmodell ändert Berechtigungen, Registereinträge oder Freigaberegeln.
- Ein Modellvorschlag zur Kontextauflösung genügt für schreibende Aktionen nicht.

Vollständiger Vertrag in `templates/AGENT_REGISTRY_TEMPLATE.md`. Ein maschinenlesbares Agentenregister entsteht in Phase 1, sobald die erste Rolle tatsächlich implementiert wird.

---

## 12. Gedächtnismodell

### 12.1 Vier Speicher

| Speicher | Inhalt | Lebensdauer | Quelle nötig |
|---|---|---|---|
| `session` | laufendes Gespräch, aktuelle Aufgabe | Tage, konfigurierbar | nein |
| `profile` | stabile Fakten, Präferenzen, Beziehungen | dauerhaft, mit Gültigkeit | ja |
| `working` | Ziele, Projekte, Entscheidungen, offene Punkte, Fristen | bis zum Abschluss | ja |
| `source_knowledge` | Dokumente, E-Mails, Protokolle, verlinkte Originale | dauerhaft | ja |

### 12.2 Schreibregeln

1. `epistemic_status` ist Pflicht: `fact`, `assumption`, `interpretation` oder `user_statement`. Eine Vermischung ist unzulässig.
2. Einträge in `profile`, `working` und `source_knowledge` benötigen mindestens eine Quelle.
3. Widersprüche werden markiert (`conflict_with`), nicht stillschweigend aufgelöst.
4. Veraltete Einträge werden auf `superseded` gesetzt und verweisen auf den Nachfolger. Keine parallele zweite Wahrheit.
5. Nicht jeder Gesprächssatz wird gespeichert. In `profile` gelangt nur, was Rolf bestätigt hat oder aus einer belegten Quelle stammt.
6. Gedächtniseinträge sind kontextgebunden. Das Feld `visibility` bereitet den späteren kontextübergreifenden Zugriff vor; die verbindliche Regelung erfolgt in Phase 4 (O-10).

### 12.3 Leseregeln

- Eine Klasse-C-Aktion darf sich nicht allein auf einen Gedächtniseintrag stützen. Erforderlich ist eine Quelle aus `source_knowledge` oder eine Bestätigung durch Rolf.
- Einträge mit `epistemic_status = assumption` oder `interpretation` werden bei der Ausgabe als solche gekennzeichnet.

### 12.4 Korrektur und Löschung

Rolf kann jeden Eintrag anzeigen, korrigieren und löschen. Korrektur erzeugt einen neuen Eintrag mit `supersedes_memory_id`. Löschung entfernt den Inhalt und hinterlässt einen Grabstein mit ID, Zeitpunkt und Anlass, damit spätere Verweise nicht ins Leere zeigen.

**Umfang in Phase 0:** ausschliesslich Schema und Regeln. Produktive Nutzung ab Phase 4.

---

## 13. n8n-Konventionen

Vollständig in `conventions/N8N_CONVENTIONS.md`. Kernpunkte:

- Namensschema `JV-<PHASE>-<TYP>-<name>-v<MAJOR>`.
- Einheitlicher Umschlag mit `trace`, `context_id`, `payload`, `result`.
- Zwölf Pflicht-Sub-Workflows mit verbindlicher Aufrufreihenfolge, überwiegend deterministisch.
- Speichern der Ausführungsdaten für fachliche Workflows deaktiviert; Diagnose über `jarvis_ops.tech_event` mit bereinigtem `message_safe`.
- Kein Sprachmodell zwischen Freigabe und Werkzeugaufruf.

---

## 14. Zentrale kontextabhängige Konfiguration

### 14.1 Aufbau

Vorlage in `templates/context_config.example.json`, validiert gegen `schemas/context.schema.json` und zusätzlich gegen das Werkzeugregister durch `tools/validate_policy.py`.

| Ebene | Inhalt | Ablage |
|---|---|---|
| Kontextkonfiguration | Adapterzuordnung, Regeln, Fristen, Aufbewahrung | Git, versioniert |
| Umgebungsvariablen | konkrete IDs, Ordner, Adressen | n8n-Umgebung, nicht in Git |
| Credentials | Zugangsdaten und Schlüssel | n8n-Credential-Speicher oder Secret-Store |

Die Trennung ist zwingend. Die Konfiguration in Git muss gelesen werden können, ohne dass daraus Zugriff entsteht. Sie enthält deshalb ausschliesslich `env:`-Verweise; Prüfung P6 in `validate_policy.py` erzwingt das.

### 14.2 Regel für Arbeitgeberwechsel

Ausgetauscht werden: Kontexteintrag, Umgebungsvariablen, Credentials, gegebenenfalls Adapter. Nicht ausgetauscht werden: Schemata, Prozesslogik, Register, Sub-Workflows.

Prüffrage für jede spätere Umsetzung: Würde diese Änderung bei einem Arbeitgeberwechsel eine Anpassung der Prozesslogik erfordern? Wenn ja, gehört der Wert in die Konfiguration.

---

## 15. Idempotenz und Schutz vor Mehrfachausführung

### 15.1 Schlüsselbildung

Referenzimplementierung: `tools/idempotency_reference.py`.

```
idempotency_key = sha256(
    normalize(context_id)        ⟼
    normalize(source_ref)        ⟼   ⟼ = ASCII Unit Separator
    normalize(action_type)       ⟼
    normalize(target_system)     ⟼
    normalize(target_object_ref)
)
```

`normalize` = NFKC, trimmen, Kleinschreibung, Mehrfachleerzeichen zusammenfassen. Leere Felder führen zum Abbruch.

Ausdrücklich nicht Bestandteil: Betreff, Dateiname, Betrag, Zusammenfassung, Modellausgaben und alle anderen veränderlichen Werte. Andernfalls würde eine geringfügige Umformulierung eine Dublette erzeugen.

### 15.2 Zwei getrennte Mechanismen

| Mechanismus | Zweck | Ablage |
|---|---|---|
| `idempotency_key` | verhindert die doppelte **Aktion** | Unique-Index auf `action.idempotency_key` |
| `content_hash` | erkennt die doppelte **Datei** | Unique-Index auf `document_index.content_hash` |

Notwendig, weil dieselbe Datei in zwei Vorgängen auftreten kann und derselbe Vorgang in zwei Dateiversionen.

### 15.3 Ausführungssperre

```sql
INSERT INTO action_lock (idempotency_key, action_id, claimed_by, expires_at)
VALUES (...) ON CONFLICT DO NOTHING RETURNING idempotency_key;
```

Kommt keine Zeile zurück, läuft die Aktion bereits. Es wird nicht erneut ausgeführt, sondern der bestehende Vorgang beobachtet. Eine abgelaufene Sperre wird erst nach einem Statusabgleich freigegeben.

### 15.4 Idempotenz bei Wiederholung

Der Schlüssel bleibt über alle Wiederholungsversuche identisch. Ein neuer Schlüssel entsteht nur bei einer fachlich neuen Aktion.

---

## 16. Fehler-, Retry-, Abbruch- und Eskalationslogik

### 16.1 Fehlerklassen

| Klasse | Wiederholbar | Standardstufe |
|---|---|---|
| `transient_network`, `timeout`, `dependency_unavailable` | ja | L0 |
| `rate_limited` | ja, mit längerem Abstand | L0 |
| `auth_failed`, `permission_denied` | nein | L2 |
| `validation_error`, `business_rule_violation` | nein | L1 |
| `not_found` | nein | L1 |
| `conflict` | nach Statusabgleich | L1 |
| `unknown_state` | **nein** | L1, Pflichtabgleich |
| `context_missing` | nein | L2 |
| `approval_invalid` | nein | L2 |
| `internal_error` | einmal | L1 |

### 16.2 Wiederholungsregeln

1. Höchstens drei automatische Versuche, exponentieller Abstand 1 min, 5 min, 25 min, mit Streuung.
2. Vor jedem Versuch Statusabgleich: Wurde die Aktion vielleicht bereits erfolgreich ausgeführt? Ergebnis in `reconciliation`.
3. Der Idempotenzschlüssel bleibt unverändert.
4. Bei `already_succeeded` kein weiterer Versuch; die Aktion wird abgeschlossen und der Nachweis nachgeholt.
5. Bei unklarem Ausführungsstatus keine blinde Wiederholung, sondern Abgleich; bei fortbestehender Unklarheit Eskalation.
6. Klasse C: Eine freigegebene Aktion darf bei eindeutig technischem Fehler innerhalb der Freigabegültigkeit idempotent wiederholt werden. Nach Ablauf oder bei Inhaltsänderung ist eine neue Freigabe erforderlich.

### 16.3 Eskalationsstufen

| Stufe | Bedeutung | Auslöser |
|---|---|---|
| `L0_retry` | automatisch wiederholen | vorübergehender technischer Fehler |
| `L1_exception_list` | Ausnahmeliste, Sichtung im Tagesbriefing | drei Versuche erfolglos, fachlicher Fehler |
| `L2_notify` | Rolf aktiv benachrichtigen | Klasse C betroffen, Frist bedroht, Berechtigung oder Kontext fehlt |
| `L3_halt` | Prozesszweig anhalten | Schutzschalter offen, wiederholter Kontextfehler, Verdacht auf Fehlkonfiguration |

**Schutzschalter:** Fünf Fehler desselben Werkzeugs im selben Kontext in 15 Minuten öffnen ihn. Das Werkzeug pausiert 30 Minuten und geht danach in einen Probelauf. Ein defekter Adapter erzeugt so keine hundert Fehlversuche und keine hundert Meldungen.

### 16.4 Abbruch

Kein Fehler, sondern getrennt geführt: `cancelled` bei Abbruch durch Rolf, `expired` bei abgelaufener Freigabe, `superseded` bei Ersetzung. Alle drei sind protokollpflichtig.

---

## 17. Versionierung

| Gegenstand | Verfahren | Ort |
|---|---|---|
| JSON-Schema | semantische Version im Feld `schema_version` | Git, `schemas/` |
| Werkzeugregister | `registry_version` und Version je Werkzeug | Git, `registry/` |
| Workflow | Hauptversion im Namen, JSON-Export | Git, `n8n/` |
| Prompt | `prompt_id@version` | Git, `prompts/` |
| Regelwerk | Version im Kopf der Kontextkonfiguration | Git, `templates/` bzw. `config/` |
| Aktive Versionen | Registrierung mit Aktivierungszeitpunkt | `jarvis_ops.contract_version` |

**Kompatibilitätsregel:** Eine Minor-Version darf ausschliesslich optionale Felder ergänzen. Jede Änderung an Pflichtfeldern, jede Enum-Erweiterung mit Verhaltensfolge und jede Bedeutungsänderung eines bestehenden Feldes erzeugt eine Hauptversion.

Jeder gespeicherte Datensatz trägt die Version, mit der er erzeugt wurde. Eine spätere Auswertung kann alte Datensätze dadurch korrekt interpretieren, ohne sie zu migrieren.

---

## 18. Protokollierungs- und Trennungsmodell

### 18.1 Drei Protokollarten

| Protokoll | Inhalt | Ablage | Trennung |
|---|---|---|---|
| **Fachprotokoll** | Entscheidungen, Aktionen, Zusammenfassungen, Nachweise | `<kontext>.action_log` | strikt je Kontext |
| **Technisches Protokoll** | IDs, Zeiten, Workflow-Version, Statuscode, Fehlerklasse, bereinigte Meldung | `jarvis_ops.tech_event` | gemeinsam |
| **n8n-Ausführungsdaten** | für fachliche Workflows deaktiviert | – | – |

### 18.2 Durchsetzung der Trennung

Vier Ebenen, bewusst mehrfach abgesichert:

1. **Berechtigung.** `jv_privat_user` hat keinerlei Rechte auf `jarvis_visolva` und umgekehrt. Für jedes fremde Schema erzeugt `render_context_schema.py` einen ausdrücklichen Entzug. Ein falsch konfigurierter Workflow kann nicht ins falsche Protokoll schreiben, er scheitert.
2. **Prüfbedingung.** Jede Tabelle im Kontextschema trägt `CHECK (context_id = '<kontext>')`. Ein Datensatz mit fremder Kontextkennung wird abgewiesen.
3. **Spalten-Positivliste.** `jarvis_ops` hat keine `jsonb`-Spalte und nur ein Freitextfeld: `message_safe` mit 500 Zeichen.
4. **Bereinigung.** `tools/sanitize_message.py` entfernt Zugangsdaten, Adressen, URLs, Pfade, IBAN, lange Bezeichner und in Anführungszeichen eingebettete Fachinhalte, bevor eine Meldung geschrieben wird. Das Verfahren arbeitet nach einer Positivliste zulässiger Zeichen, nicht nach einer Verbotsliste bekannter Geheimnisse.

### 18.3 Append-only mit Fehler statt stillem Verwerfen (D8)

Das Fachprotokoll erlaubt kein UPDATE und kein DELETE. Die Durchsetzung erfolgt zweifach:

- **Rechteentzug:** Der Kontextbenutzer erhält auf `action_log` ausschliesslich `SELECT` und `INSERT`.
- **Trigger:** Jeder verbleibende Versuch wird mit `RAISE EXCEPTION` und Fehlercode `42501` abgewiesen.

Ausdrücklich **nicht** verwendet wird `CREATE RULE ... DO INSTEAD NOTHING`. Eine solche Regel würde den Änderungsversuch stillschweigend verwerfen und dem Aufrufer Erfolg melden. Ein stiller Verlust ist schlimmer als ein Fehler. Prüfung Q2 in `tools/validate_sql.py` stellt sicher, dass keine solche Regel zurückkehrt.

Korrekturen erfolgen als neuer Eintrag mit `corrects_log_id`.

### 18.4 Rechte, die häufig vergessen werden

| Recht | Warum nötig |
|---|---|
| `USAGE, SELECT` auf allen Sequenzen im Kontextschema | Ohne dieses Recht scheitert jedes `INSERT` in die `bigserial`-Spalte von `action_log` mit „permission denied for sequence" |
| `USAGE, SELECT` auf `jarvis_ops.tech_event_tech_event_id_seq` | dasselbe für das technische Protokoll |
| Spaltenweises `GRANT UPDATE (finished_at, duration_ms, status, error_class, error_code, items_out)` auf `jarvis_ops.workflow_run` | Ein Lauf wird beim Start eingefügt und beim Ende abgeschlossen. Mit reinem `INSERT` könnte er nie abgeschlossen werden. Das spaltenweise Recht erlaubt genau den Abschluss und nichts sonst; ein Trigger verhindert zusätzlich die Änderung bereits abgeschlossener Läufe und unveränderlicher Felder |
| `ALTER DEFAULT PRIVILEGES` für künftige Sequenzen | Damit spätere Tabellen nicht dasselbe Problem erzeugen |

### 18.5 Bewusst akzeptierte Restvermischung

Im gemeinsamen technischen Protokoll steht die `context_id`. Daraus ist ablesbar, dass zu einem Zeitpunkt in einem Kontext etwas geschehen ist, nicht aber was. Diese Restinformation wird bewusst akzeptiert, weil ohne sie keine Fehlersuche möglich wäre. Sie ist hier ausdrücklich dokumentiert, damit sie nicht später als unbemerkte Abweichung auffällt.

---

## 19. Testfälle und Abnahmekriterien

Vollständige Matrix in `tests/TEST_ABNAHMEMATRIX.md`, gespeicherter Lauf in `tests/TESTLAUF_2026-08-29.md`.

Ausgeführt am 29.08.2026: **7 Prüfschritte mit 94 Einzelprüfungen, alle bestanden.** Reproduzierbar mit `python3 tools/run_all_tests.py`.

Alle übrigen Testfälle sind spezifiziert, aber nicht ausgeführt, weil sie eine Datenbank oder eine n8n-Instanz voraussetzen.

---

## 20. Phase-Gate zu Phase 1

**Das Phase-Gate ist nicht bestanden.** Erfüllt sind die spezifikationsseitigen Kriterien; die praktischen Nachweise stehen aus.

| Nr. | Kriterium | Status |
|---|---|---|
| G1 | Elf Schemata liegen vor und validieren die Beispiele | erfüllt und nachgewiesen |
| G2 | Negativfälle werden nachweislich abgewiesen (24 Fälle) | erfüllt und nachgewiesen |
| G3 | Dokumentereignis und E-Mail-Ereignis erzeugen strukturgleiche Aktionsobjekte | erfüllt und nachgewiesen |
| G4 | Kontextkonfiguration validiert und gegen das Werkzeugregister geprüft | erfüllt und nachgewiesen |
| G5 | SQL-Vorlagen sind grammatikalisch gültig und frei von stillem Verwerfen | erfüllt und nachgewiesen |
| G6 | Einspielskript weist unzulässige Bezeichner ab | erfüllt und nachgewiesen |
| G7 | Bereinigung von `message_safe` nachgewiesen | erfüllt und nachgewiesen |
| G8 | Paket ist aus dem Archiv heraus in einer sauberen Umgebung reproduzierbar | erfüllt und nachgewiesen |
| G9 | Datenbankschemata angelegt, Rechtevergabe praktisch geprüft | **offen**, Phase 1 |
| G10 | Kontexttrennung praktisch nachgewiesen (A-3) | **offen**, Phase 1 |
| G11 | Dublettenfreiheit praktisch nachgewiesen (A-4) | **offen**, Phase 1 |
| G12 | Freigabeablauf mit Ablauf, Einmalverwendung und Fingerprintprüfung getestet | **offen**, Phase 1 |
| G13 | Mindestens ein Werkzeug im Status `approved` | **offen**, Phase 1 |
| G14 | Offene technische Schulden dokumentiert | erfüllt |
| G15 | Übergabedatei vorhanden | erfüllt |

Die Phase-0-Spezifikation ist damit freigabefähig. Das Phase-Gate schliesst erst, wenn G9 bis G13 im ersten technischen Meilenstein von Phase 1 nachgewiesen sind.

---

## 21. Übergabestruktur

Am Ende jedes Umsetzungsabschnitts entsteht `HANDOVER_<MODUL>_<DATUM>.md` mit den zehn Pflichtabschnitten aus Masterfahrplan §6 und dem abschliessenden Hinweis:

> „Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe."

Ein neuer Chat erhält: Masterfahrplan, aktuelle Phasenspezifikation, Übergabedatei des vorherigen Chats. Mehr nicht, damit der Kontext beherrschbar bleibt.

---

## Anhang A - Verzeichnis der Artefakte

Alle Pfade beziehen sich auf das Wurzelverzeichnis `jarvis-phase-0/` im Archiv.

| Datei | Inhalt |
|---|---|
| `README.md` | Einstieg und Paketübersicht |
| `INSTALL_UND_TEST.md` | Installations- und Prüfanleitung |
| `CHANGELOG.md` | Änderungen gegenüber Version 1.0.0 |
| `requirements.txt` | Abhängigkeiten der Prüfwerkzeuge |
| `SPEC_PHASE_0_JARVIS_FUNDAMENT_v1.1.md` | dieses Dokument |
| `ASSUMPTIONS.md` | getroffene Annahmen |
| `OPEN_DECISIONS.md` | offene Entscheidungen |
| `HANDOVER_PHASE_0_2026-08-29.md` | Übergabedatei |
| `schemas/common.schema.json` | gemeinsame Basistypen |
| `schemas/context.schema.json` | Kontext |
| `schemas/object_ref.schema.json` | Objektverweis |
| `schemas/event.schema.json` | Ereignis |
| `schemas/task.schema.json` | Aufgabe |
| `schemas/action.schema.json` | Aktion |
| `schemas/approval.schema.json` | Freigabe |
| `schemas/evidence.schema.json` | Ergebnisnachweis |
| `schemas/error_escalation.schema.json` | Fehler und Eskalation |
| `schemas/memory_entry.schema.json` | Gedächtnis |
| `schemas/tool_registry.schema.json` | Werkzeugregister |
| `registry/tool_registry.json` | Werkzeugregister, einzige Quelle |
| `templates/context_config.example.json` | Kontextkonfiguration |
| `templates/TOOL_REGISTRY_TEMPLATE.md` | Erläuterung des Werkzeugvertrags |
| `templates/AGENT_REGISTRY_TEMPLATE.md` | Verantwortungstrennung und Modellrollen |
| `conventions/N8N_CONVENTIONS.md` | n8n-Konventionen |
| `db/001_context_schema_template.sql` | Kontextschema, Vorlage mit Platzhaltern |
| `db/002_ops_schema.sql` | gemeinsames technisches Schema |
| `db/003_grants_and_isolation.sql` | Rechtevergabe und Kontexttrennung |
| `tools/idempotency_reference.py` | Referenz für Schlüsselbildung |
| `tools/sanitize_message.py` | Bereinigung von `message_safe` (TS-5) |
| `tools/render_context_schema.py` | sicheres Rendern der SQL-Vorlagen (TS-4) |
| `tools/build_examples.py` | Erzeugung der Beispiele |
| `tools/validate_schemas.py` | Schema- und Vertragsvalidierung |
| `tools/validate_negative.py` | Gegenprobe |
| `tools/validate_policy.py` | Prüfung der Kontextkonfiguration (TS-6) |
| `tools/validate_sql.py` | SQL-Grammatik und Strukturzusicherungen |
| `tools/test_sanitize.py` | Tests der Bereinigung |
| `tools/run_all_tests.py` | Gesamtlauf mit Protokoll |
| `examples/*.json` | elf Beispieldatensätze |
| `tests/TEST_ABNAHMEMATRIX.md` | Test- und Abnahmematrix |
| `tests/TESTLAUF_2026-08-29.md` | gespeicherter Testlauf |
