# Spezifikation KI-Dokumentenassistent - JARVIS Phase 1

**Version 4.0.2 - 29. August 2026**
**Ersetzt:** Version 4.0.1 vom 29. August 2026, diese ersetzte Version 4.0, diese Version 3 vom 27. August 2026
**Art der Änderung:** eng begrenzte Korrekturversion K7 bis K9 auf Basis von K1 bis K6. Architektur, Phasenzuschnitt und die Entscheidungen P1-B1 bis P1-B5 sowie P1-D1 bis P1-D13 sind unverändert.
**Grundlagen:** JARVIS-Masterfahrplan Phase 0 bis 6; Phase-0-Paket Version 1.1.0
**Status:** Spezifikation. Keine Datenbank eingerichtet, keine Workflows gebaut, kein Dienst konfiguriert.

---

## 0. Statuserklärung und Einordnung

| Gegenstand | Status |
|---|---|
| Phase-0-Spezifikation 1.1.0 | fachlich freigegeben |
| Phase-0-Phase-Gate | nicht bestanden; A-3 und A-4 offen |
| Diese Spezifikation | vollständig, umsetzungsbereit nach Freigabe |
| Umsetzung Phase 1 | nicht begonnen |

Der praktische Nachweis von A-3 (Kontexttrennung) und A-4 (Dublettenfreiheit) ist **Phase 1.0** und schliesst das Phase-0-Gate. Erst danach beginnt der Dokumentenfluss.

### 0.1 Verhältnis zu Version 3

Version 3 beschrieb den fachlichen Anspruch richtig: lesen, verstehen, handeln, ablegen. Sie entstand jedoch vor Phase 0 und enthält ein eigenes Datenmodell, das mit den Phase-0-Verträgen kollidiert. Version 4.0 übernimmt den fachlichen Kern und ersetzt das Datenmodell vollständig. Die einzelnen Änderungen stehen in `CHANGELOG_V3_ZU_V4.md`.

### 0.2 Was diese Spezifikation nicht ist

Sie ist kein Archivkonzept und keine Ordnerreform. Der Massstab bleibt aus Version 3 unverändert: **nicht wie viele Dokumente abgelegt werden, sondern wie viel administrative Arbeit verlässlich abgenommen wird.**

Datenschutz, DSGVO und Datenstandort sind nicht Gegenstand dieser Spezifikation. Sie werden nur dort erwähnt, wo eine konkrete technische Funktion davon abhängt — das ist an genau einer Stelle der Fall (Abschnitt 10.4, Übermittlung an den OCR-Dienst).

---

## 1. Ziel und messbarer Nutzen

### 1.1 Ziel

JARVIS nimmt Dokumente entgegen, versteht sie, leitet konkrete Arbeit ab, führt das Zulässige selbst aus, weist die Ergebnisse nach und legt die Originale richtig ab. Alle Vorgänge laufen im richtigen Kontext und werden dort getrennt protokolliert.

### 1.2 Messbarer Nutzen

| Nutzen | Messgrösse | Zielwert im Pilot |
|---|---|---|
| Keine manuelle Ablagearbeit | Anteil Dokumente ohne manuelle Umbenennung oder Verschiebung | ≥ 95 % |
| Verlässliches Auslesen | Anteil korrekter Pflichtfelder | ≥ 90 % |
| Keine übersehene Frist | Anteil erkannter Fristen im Testkorpus | 100 % |
| Echte Arbeitsabnahme | Anteil automatisch abgeschlossener risikoarmer Aufgaben | ≥ 70 % |
| Zeitersparnis | Bearbeitungszeit je Dokument gegenüber manuell | Messung ab Pilotbeginn |

### 1.3 Vorbereitung auf das langfristige Ziel

Phase 1 baut drei Dinge, die alle späteren Phasen weiterverwenden:

1. **Den vollständigen Arbeitszyklus** von Wahrnehmung bis Ergebnisnachweis. Phase 2 tauscht nur die Quelle (E-Mail statt Datei) und die Werkzeuge aus.
2. **Den Quellenbestand**, auf dem das Langzeitgedächtnis aus Phase 4 aufsetzt. Jedes Dokument ist ab Phase 1 mit Volltext, strukturierten Feldern, Zusammenfassung und Vorgangsbezug erfasst.
3. **Den Freigabemechanismus**, der ab Phase 2 für echte externe Kommunikation gebraucht wird und deshalb in Phase 1 bereits nachgewiesen sein muss.

---

## 2. Umfang und Nicht-Ziele

### 2.1 Im Umfang

| Nr. | Gegenstand |
|---|---|
| 1 | Inbetriebnahme des Phase-0-Fundaments und Nachweis A-3, A-4 |
| 2 | Dokumenteingang über Dateiablage, Scan und Smartphone-Foto |
| 3 | Technische Erfassung mit OCR, Volltext und Seitenstruktur |
| 4 | Feldweise Extraktion mit Konfidenz und Textbeleg |
| 5 | Dokumentverständnis: Art, Zusammenfassung, Beteiligte, Beträge, Fristen, Verpflichtungen, Risiken, Widersprüche |
| 6 | Vorgangszuordnung und Dokumentvergleich |
| 7 | Ableitung getrennter Aufgaben und Aktionen |
| 8 | Ausführung der Klassen A und B, Freigabeweg für Klasse C |
| 9 | Ergebnisnachweis nach Werkzeugvertrag |
| 10 | Automatische Benennung und Ablage im kontextbezogenen Ziel |
| 11 | Fachprotokollierung je Kontext |
| 12 | Ausnahmeliste und täglicher Bericht |
| 13 | Pilot mit 50 bis 100 Dokumenten und Phase-Gate |

### 2.2 Nicht im Umfang

- E-Mail-Eingang und E-Mail-Versand (Phase 2),
- Kalendereinträge (Phase 2),
- CRM, WhatsApp, Geschäftsprozesse (Phase 3),
- allgemeines Langzeitgedächtnis und Sparring (Phase 4),
- proaktive Überwachung über den Dokumentbestand hinaus (Phase 5),
- eigene JARVIS-Oberfläche und Sprachbedienung (Phase 6),
- produktive Verarbeitung von Arbeitgeberdokumenten (Entscheidung B2),
- Migration des Altbestands,
- dokumentenübergreifende Suche als Benutzerfunktion; der Bestand wird aufgebaut, aber nicht als Suchoberfläche ausgeliefert.

### 2.3 Anschlussstellen, die offen bleiben müssen

Phase 1 darf spätere Phasen nicht verbauen. Konkret:

| Spätere Phase | Anschlussstelle in Phase 1 |
|---|---|
| Phase 2, E-Mail-Eingang | Der Eingang ist ein Adapter. Ein E-Mail-Anhang erzeugt dasselbe `document.received`-Ereignis wie eine Datei; nur `intake.channel` und `intake.adapter_id` unterscheiden sich. Die Verarbeitungskette ab `original_secured` bleibt identisch. |
| Phase 2, Kalender | Fristen liegen in `task.due_at` und `task.reminder_at`. Ein Kalenderadapter spiegelt sie später, ohne dass die Fristerkennung geändert wird. |
| Phase 2, externe Aufgabensysteme | `task.external_refs` ist vorgesehen und bleibt in Phase 1 leer. |
| Phase 3, CRM | Beteiligte werden als `object_ref` mit `system` und `external_id` geführt, nicht als Freitext. Ein CRM-Adapter kann sie später auflösen. |
| Phase 4, Gedächtnis | Jedes Dokument ist mit Volltext, Feldern, Zusammenfassung und Quellenbelegen erfasst und damit als `source_knowledge` verwendbar. |
| Phase 6, Oberfläche | `approval.decision_summary` enthält bereits alle Bestandteile der späteren Aktionskarte. Der Tagesbericht ist eine Datei, keine Oberfläche, und wird später ersetzt statt umgebaut. |

---

## 3. Verbindliche Entscheidungen für Phase 1

Freigegeben am 29.08.2026.

| Nr. | Entscheidung |
|---|---|
| **P1-B1** | Greenfield-Neubau auf den Phase-0-Verträgen. Ältere n8n-Workflows dürfen als Referenz für Ablageregeln, Felder und bekannte Dokumentarten ausgewertet werden, sind aber keine technische Grundlage und werden nicht schrittweise umgebaut. |
| **P1-B1b** | Kein vorgegebener OCR-Dienst. Der OCR-Werkzeugvertrag ist austauschbar. Google Document AI ist bevorzugter Kandidat, wird aber nicht in das Prozessmodell eingebaut. Auswahl in Phase 1.1 durch einen Test mit rund 20 repräsentativen Dokumenten. |
| **P1-B2** | `privat` ist der erste produktive Dokumentenkontext. `arbeitgeber_visolva` wird technisch vollständig eingerichtet — Schema, Benutzer, Credentials, Speicheradapter, Test-Eingangsordner, Fachprotokoll — und verarbeitet in Phase 1 ausschliesslich synthetische Testdokumente. Der Nachweis A-3 wird trotzdem vollständig geführt. |
| **P1-B3** | Der zweistufige Klasse-C-Freigabeweg wird in Phase 1 vollständig implementierbar spezifiziert und technisch getestet, und zwar über das ausdrücklich gekennzeichnete Testwerkzeug `test.record_approved_action`. Keine echte Datei wird zu Testzwecken gelöscht oder gefährdet. |
| **P1-B4** | Keine Modellversion wird festgeschrieben. Drei austauschbare Leistungsprofile: `extraction_model`, `reasoning_model`, `drafting_model`. Modell-IDs ausschliesslich in der Konfiguration. Benchmark vor dem Pilotbetrieb. Ein Modellwechsel darf weder die n8n-Prozesslogik noch die Phase-0-Verträge berühren. |
| **P1-B5** | `tasks_internal` in der JARVIS-Datenbank ist die führende Aufgabenquelle. Kein externes Aufgabensystem in Phase 1. Zusätzlich ein täglicher Bericht als abgeleitete Ansicht, die den Aufgabenbestand niemals verändert. |

---

## 4. Soll-Prozess vom Eingang bis zur Ablage

### 4.1 Überblick

```
  A  Eingang            Datei erscheint im kontextbezogenen Eingangsordner
        │               → Kontext aus dem Ordner (source_binding)
        │               → Ereignis document.received
        ▼
  B  Sicherung          Inhaltshash bilden, Dublettenprüfung
        │               → Original unverändert in den Arbeitsbereich des Kontexts
        ▼
  C  Erfassung          OCR: Volltext, Seiten, Tabellen, Feldkandidaten
        │               → Ereignis document.text_extracted
        ▼
  D  Extraktion         Feldweise Auslesung mit Konfidenz und Textbeleg
        │               → deterministische Feldvalidierung
        ▼
  E  Verständnis        Art, Zusammenfassung, Verpflichtungen, Fristen,
        │               Risiken, Änderungen, Widersprüche, Aufgabenvorschläge
        │               → Ereignis document.analysis_completed
        ▼
  F  Vorgang            Zuordnung über stabile Kennungen oder neuer Vorgang
        ▼
  G  Ableitung          Aufgaben (task) und Aktionen (action) getrennt erzeugen
        │               → Risikoklasse deterministisch aus dem Werkzeugregister
        ▼
  H  Freigabe           nur Klasse C: zweistufige Freigabe einholen
        ▼
  I  Ausführung         Klasse A sofort, Klasse B mit Meldung,
        │               Klasse C nach gültiger Freigabe
        ▼
  J  Nachweis           Ergebnisnachweis nach Werkzeugvertrag
        ▼
  K  Ablage             Benennen, verschieben, Ereignis document.filed
        ▼
  L  Protokoll          Fachprotokoll im Kontextschema, append-only
```

### 4.2 Trennung von Original, Wissen und Arbeit

Aus Version 3 unverändert übernommen und in Phase 4.0 technisch verankert:

| Ebene | Inhalt | Ablage |
|---|---|---|
| **Original** | unveränderte Quelldatei | Speicheradapter des Kontexts |
| **Wissen** | Volltext, Felder, Analyse, Beziehungen | Kontextschema in PostgreSQL |
| **Arbeit** | Aufgaben, Aktionen, Freigaben, Nachweise | Kontextschema, Phase-0-Objekte |

Das Original wird ausschliesslich verschoben und umbenannt. Es wird nie überschrieben, nie beschriftet und nie durch eine neue Aufgabe verändert.

### 4.3 Ablage wartet nicht auf Erledigung

Ein Dokument wird abgelegt, sobald Klassifikation, Vorgangszuordnung und Benennung feststehen. Offene Aufgaben verhindern die Ablage nicht. Dokumentstatus und Aufgabenstatus sind getrennt und laufen unabhängig weiter.

---

## 5. Dokumentzustände und Übergänge

### 5.1 Zustände

| Zustand | Bedeutung | Anzeigelabel |
|---|---|---|
| `received` | Datei erkannt, Kontext aufgelöst, ID vergeben | Eingegangen |
| `original_secured` | Hash gebildet, Original im Arbeitsbereich gesichert | Original gesichert |
| `text_extracted` | Volltext und Seitenstruktur liegen vor | Erfasst |
| `fields_extracted` | Felder ausgelesen und validiert | Ausgelesen |
| `understood` | Analyse abgeschlossen, Vorgang zugeordnet | Verstanden |
| `planned` | Aufgaben und Aktionen erzeugt | Geplant |
| `filed` | Original benannt und am Zielort abgelegt | Abgelegt |
| `duplicate` | Inhaltsgleich zu einem bekannten Dokument | Dublette |
| `unreadable` | Technisch nicht verwertbar | Unlesbar |
| `needs_review` | Manuelle Prüfung erforderlich | Prüfung nötig |
| `failed` | Technischer Fehler nach erschöpften Versuchen | Fehlgeschlagen |
| `quarantined` | Datei abgewiesen: Typ, Grösse oder Sicherheitsprüfung | Zurückgestellt |
| `discarded` | Von Rolf verworfen, terminal | Verworfen |
| `misrouted` | Im falschen Kontext eingegangen, terminal | Fehlgeleitet |

### 5.2 Übergänge

| Von | Nach | Auslöser | Bedingung | Ereignis |
|---|---|---|---|---|
| – | `received` | Datei im Eingangsordner | Kontext aufgelöst über `source_binding` | `document.received` |
| – | `quarantined` | Datei im Eingangsordner | MIME-Typ nicht erlaubt, Grösse über Grenze, Datei passwortgeschützt | `document.quarantined` |
| `received` | `duplicate` | Hashprüfung | `content_hash` bereits im Register | `document.duplicate_detected` |
| `received` | `original_secured` | Hashprüfung | kein Treffer | – |
| `original_secured` | `text_extracted` | OCR | Zeichenzahl über Mindestwert und mittlere OCR-Konfidenz ≥ 0,60 | `document.text_extracted` |
| `original_secured` | `unreadable` | OCR | Zeichenzahl unter Mindestwert oder Konfidenz < 0,60 nach zweitem Versuch | `document.unreadable` |
| `text_extracted` | `fields_extracted` | Extraktion | Ausgabe schemakonform | – |
| `fields_extracted` | `needs_review` | Feldvalidierung | Pflichtfeld fehlt oder handlungsrelevantes Feld unsicher | `document.needs_review` |
| `fields_extracted` | `understood` | Analyse | Ausgabe schemakonform, keine blockierende Unsicherheit | `document.analysis_completed` |
| `understood` | `needs_review` | Vorgangszuordnung | mehrere gleichwertige Vorgangskandidaten | `document.needs_review` |
| `understood` | `planned` | Ableitung | mindestens eine Aufgabe oder ausdrücklich keine Handlung nötig | `task.created`, `action.planned` |
| `planned` | `filed` | Ablage | Ablageaktion mit bestätigtem Nachweis | `document.filed` |
| jeder | `failed` | Fehlerbehandlung | drei Versuche erfolglos | `action.failed`, `system.error` |
| `needs_review` | Stufe aus `resume_from_stage` | manuelle Klärung mit `outcome: resume` | Prüfung abgeschlossen | `document.review_resolved` |
| `needs_review` | `duplicate`, `discarded` oder `misrouted` | manuelle Klärung mit `outcome: terminal` | Prüfung abgeschlossen, keine weitere Verarbeitung | `document.review_resolved` |
| `duplicate` | `filed` | manuelle Entscheidung | Rolf erklärt das Dokument zur eigenständigen Fassung | `document.filed` |

**Zwei Regeln zu den Zuständen:**

1. Ein Dokument in `needs_review` blockiert keine anderen Dokumente. Die Ausnahmeliste wächst, die Verarbeitung läuft weiter.
2. `unreadable` und `quarantined` erzeugen trotzdem einen Dokumentdatensatz und eine Aufgabe für Rolf. Ein nicht lesbares Dokument darf nicht stillschweigend verschwinden.

### 5.3 Verhältnis zum Aufgaben- und Aktionsstatus

Der Dokumentzustand beschreibt die Verarbeitung des Dokuments. Aufgaben und Aktionen haben eigene Zustände aus Phase 0 und laufen unabhängig weiter. Ein Dokument kann `filed` sein, während zwei Aufgaben offen und eine Aktion `awaiting_approval` sind. Es gibt bewusst keinen gemeinsamen Gesamtstatus — er würde suggerieren, dass ein abgelegtes Dokument erledigt ist.

---

## 6. Zuordnung zu den Phase-0-Verträgen

### 6.1 Objekte

| Phase-1-Gegenstand | Phase-0-Objekt | Neu in Phase 1 |
|---|---|---|
| Dokument | `doc_`-ID, `object_ref` | `document.schema.json` |
| Vorgang | `cse_`-ID, `object_ref` | `case.schema.json` |
| Extraktionsergebnis | `field_evidence` aus `common.schema.json` | `extraction_result.schema.json` |
| Dokumentverständnis | – | `document_analysis.schema.json` |
| Aufgabe | `task.schema.json` | unverändert |
| Aktion | `action.schema.json` | unverändert |
| Freigabe | `approval.schema.json` | unverändert |
| Ergebnisnachweis | `evidence.schema.json` | unverändert |
| Fehler | `error_escalation.schema.json` | unverändert |
| Ereignis | `event.schema.json` | unverändert, Katalog erweitert |
| Kontext | `context.schema.json` | Kategorie-Mapping ergänzt |

**Keine Parallelmodelle.** Die vier neuen Schemata verweisen ausschliesslich auf Phase-0-Definitionen und betten weder Aufgaben noch Aktionen ein; sie referenzieren sie über IDs. Das wird durch `tools/validate_phase1.py` maschinell geprüft (Regel V1).

### 6.2 Erweiterung des Ereigniskatalogs

`event.schema.json` prüft `event_type` gegen ein Muster, nicht gegen ein Enum. Die folgenden Typen sind daher eine additive Katalogerweiterung ohne Schemaänderung.

| Neuer Typ | Anzeigelabel | Ausgelöst durch |
|---|---|---|
| `document.text_extracted` | Dokument erfasst | Abschluss der OCR |
| `document.analysis_completed` | Dokument verstanden | Abschluss der Analyse |
| `document.filed` | Dokument abgelegt | bestätigte Ablageaktion |
| `document.needs_review` | Prüfung nötig | Validierungs- oder Zuordnungsregel |
| `document.review_resolved` | Prüfung abgeschlossen | manuelle Klärung |
| `document.unreadable` | Dokument unlesbar | OCR-Qualitätsregel |
| `document.quarantined` | Dokument zurückgestellt | Eingangsprüfung |
| `case.created` | Vorgang angelegt | Vorgangszuordnung |
| `case.document_linked` | Dokument zugeordnet | Vorgangszuordnung |

Bereits in Phase 0 vorhanden und hier verwendet: `document.received`, `document.classified`, `document.duplicate_detected`, `deadline.due_soon`, `task.created`, `task.overdue`, `action.planned`, `action.approval_requested`, `action.approved`, `action.rejected`, `action.executed`, `action.verified`, `action.failed`, `action.escalated`, `system.error`.

### 6.3 Kontextkonfiguration: Ergänzungen für Phase 1

Die Phase-0-Kontextkonfiguration erhält je Kontext einen Block `document_settings`. Er enthält ausschliesslich `env:`-Verweise und Schlüssel, keine Ordner-IDs.

```json
"document_settings": {
  "inbox_config_ref": "env:JV_PRIVAT_INBOX_FOLDER_ID",
  "working_config_ref": "env:JV_PRIVAT_WORKING_FOLDER_ID",
  "archive_root_config_ref": "env:JV_PRIVAT_ARCHIVE_ROOT_ID",
  "drafts_config_ref": "env:JV_PRIVAT_DRAFTS_FOLDER_ID",
  "reports_config_ref": "env:JV_PRIVAT_REPORTS_FOLDER_ID",
  "allowed_mime_types": ["application/pdf", "image/jpeg", "image/png", "image/tiff"],
  "max_file_size_mb": 50,
  "category_folder_map_ref": "config/category_map_privat.json",
  "case_number_prefix": "V",
  "retention_days": 3650
}
```

Das Kategorie-Mapping liegt als eigene versionierte Datei je Kontext vor, nicht im Workflow. Ein neuer Ordner oder eine neue Kategorie ist damit eine Konfigurationsänderung, kein Workflow-Eingriff.

---

## 7. Phase 1.0 — Aktivierung des Phase-0-Fundaments

**Ziel:** Das Phase-0-Gate schliessen. Ohne diesen Schritt beginnt kein Dokumentenfluss.

### 7.1 Umfang

1. Verwaltete PostgreSQL-Instanz bereitstellen (offene Entscheidung O-1).
2. `002_ops_schema.sql` einspielen.
3. Je Kontext über `tools/render_context_schema.py` rendern und einspielen: `001_context_schema.<kontext>.sql`, `003_grants_and_isolation.<kontext>.sql`.
4. Datenbankbenutzer `jv_privat_user` und `jv_visolva_user` anlegen, gegenseitige Entzüge prüfen.
5. Kontextregister in `jarvis_ops.context_registry` befüllen.
6. Phase-1-Erweiterungstabellen anlegen (Abschnitt 7.2).
7. Kern-Sub-Workflows aus den Phase-0-Konventionen bauen: `context_resolve`, `id_generate`, `idempotency_guard`, `action_classify`, `tool_invoke`, `evidence_verify`, `fach_log_write`, `tech_log_write`, `error_handler`.
8. Nachweise A-3 und A-4 führen (Testfälle K-01 bis K-08, I-01 bis I-05 aus der Phase-0-Matrix).
9. Werkzeuge im Register von `draft` auf `approved` setzen, die in Phase 1.1 gebraucht werden.

### 7.2 Zusätzliche Tabellen im Kontextschema

Ergänzend zu den Phase-0-Tabellen:

| Tabelle | Zweck |
|---|---|
| `document` | Dokumentregister nach `document.schema.json` |
| `case` | Vorgänge nach `case.schema.json`, mit Unique-Index auf `case_number` |
| `case_identifier` | normalisierte Kennungen je Vorgang, Unique-Index auf (`identifier_type`, `value_normalized`) |
| `document_text` | Volltext und Seitenstruktur |
| `document_extraction` | Extraktionsergebnisse nach `extraction_result.schema.json` |
| `document_analysis` | Analysen nach `document_analysis.schema.json` |
| `case_number_seq` | fortlaufende Vorgangsnummer je Kontext und Jahr |
| `test_approval_record` | abgegrenzter Testbereich für `test.record_approved_action` |

Alle Tabellen tragen die Prüfbedingung `context_id = '<kontext>'` und die Sequenzrechte aus der Phase-0-Vorlage. `document_index` aus Phase 0 geht in `document` auf; der Unique-Index auf `content_hash` bleibt bestehen.

### 7.3 Abnahme Phase 1.0

| Nr. | Kriterium |
|---|---|
| 1.0-A1 | Schreibversuch mit `jv_privat_user` in `jarvis_visolva.action_log` scheitert mit Berechtigungsfehler |
| 1.0-A2 | Datensatz mit fremdem `context_id` wird von der Prüfbedingung abgewiesen |
| 1.0-A3 | `UPDATE` und `DELETE` auf `action_log` scheitern mit `append_only_violation`, nicht still |
| 1.0-A4 | `INSERT` in `action_log` gelingt, Sequenzrecht greift |
| 1.0-A5 | Ein Workflow-Lauf kann gestartet und abgeschlossen werden |
| 1.0-A6 | Zweimaliges Verarbeiten desselben Quellereignisses erzeugt genau eine Aktion |
| 1.0-A7 | Zwei parallele Läufe: genau einer erhält die Sperre |
| 1.0-A8 | Export und Wiederherstellung der Workflows in eine leere Instanz gelingt |

**Phase-1.0-Gate:** Alle acht Kriterien erfüllt und dokumentiert. Damit ist das Phase-0-Gate geschlossen.

---

## 8. Phase 1.1 — Dokumenteingang und Normalisierung

### 8.1 Eingangskanäle

| Kanal | `intake.channel` | Kontextauflösung |
|---|---|---|
| Eingangsordner der Dateiablage | `drive_inbox` | `source_binding` über den Ordner |
| Scan eines Netzwerkscanners | `scan` | `source_binding`, Scanner schreibt in den Kontextordner |
| Smartphone-Foto | `mobile_photo` | `source_binding`, App schreibt in den Kontextordner |
| Manueller Upload | `manual_upload` | `source_binding` |
| API | `api` | in Phase 1 nicht aktiv, Vertrag vorgesehen |

**Verbindliche Regel:** Jeder Kontext hat einen eigenen Eingangsordner. Es gibt keinen gemeinsamen Eingang. Damit ist die Kontextauflösung immer `source_binding` und nie ein Modellvorschlag. Ein Modellvorschlag würde nach Phase-0-Regel für schreibende Aktionen ohnehin nicht ausreichen.

Landet ein Dokument erkennbar im falschen Eingang, wird es nicht still umgeleitet. Es entsteht eine Aufgabe für Rolf mit dem Vorschlag, und die Verarbeitung im aktuellen Kontext wird angehalten. Grund: Ein stiller Kontextwechsel ist der schwerwiegendste Fehler, den dieses System machen kann.

### 8.2 Eingangsprüfung

In dieser Reihenfolge:

1. **MIME-Typ** gegen `allowed_mime_types`. Abweichung → `quarantined`.
2. **Grösse** gegen `max_file_size_mb`. Überschreitung → `quarantined`.
3. **Lesbarkeit**: passwortgeschützte oder beschädigte PDF → `quarantined`.
4. **Inhaltshash** `sha256` über die Originalbytes.
5. **Dublettenprüfung** gegen `document.content_hash`.

Jede Zurückstellung erzeugt eine Aufgabe mit dem konkreten Grund. Das Original bleibt unverändert im Eingang liegen.

### 8.3 Dublettenerkennung in zwei Stufen

| Stufe | Mechanismus | Wirkung |
|---|---|---|
| 1 | `content_hash`, Unique-Index | **Harter Stopp.** Status `duplicate`, Verweis auf das Original, keine weitere Verarbeitung, keine zweite Aufgabe |
| 2 | `text_fingerprint` über den normalisierten Volltext | **Verdacht.** Status `needs_review` mit Grund `duplicate_suspected`, Rolf entscheidet |

Die zweite Stufe ist nötig, weil zwei Scans desselben Briefes unterschiedliche Bytes haben. Sie ist bewusst kein harter Stopp: Ein Nachtrag kann inhaltlich fast identisch und trotzdem ein eigenständiges Dokument sein.

**Normalisierung für den Fingerprint:** NFKC, Kleinschreibung, Mehrfachleerzeichen zusammenfassen, Ziffernfolgen erhalten, Seitenzahlen und Datumsstempel des Scanners entfernen.

Der Idempotenzschlüssel der Aktionen bleibt davon getrennt und wird nach der Phase-0-Referenz gebildet, mit `source_ref = document_id`.

### 8.4 OCR und Textgewinnung

Aufruf von `ocr_default.analyze_document`. Der Vertrag verlangt vom Dienst mindestens:

| Anforderung | Begründung |
|---|---|
| Volltext je Seite | Grundlage für Extraktion und Fingerprint |
| Mittlere Konfidenz je Seite | Qualitätsschwelle für `unreadable` |
| Konfidenz und Seitenbezug je erkanntem Block | Pflicht für `field_evidence` |
| Tabellen als Struktur, nicht als Fliesstext | Rechnungspositionen |
| Formularfelder als Schlüssel-Wert-Paare | Behördenformulare |
| Verarbeitung gescannter und digitaler PDF | gemischter Bestand |

**Digitale PDF ohne Scan** werden zuerst mit einer Textextraktion ohne OCR verarbeitet. Nur wenn dabei zu wenig Text entsteht, folgt die OCR. Das spart Kosten und erhöht die Genauigkeit.

**Qualitätsregel:** Zeichenzahl unter 200 oder mittlere Konfidenz unter 0,60 → zweiter Versuch mit anderer Voreinstellung, etwa erhöhter Auflösung. Danach `unreadable` mit Aufgabe „Dokument erneut einscannen".

### 8.5 Auswahl des OCR-Dienstes

Nach Entscheidung P1-B1b in Phase 1.1 durch einen Test mit rund 20 repräsentativen Dokumenten, davon mindestens: 5 gescannte Behördenbriefe, 5 Versicherungsschreiben mit Tabellen, 3 Rechnungen, 3 Smartphone-Fotos mit Schräglage, 2 mehrseitige Verträge, 2 digitale PDF.

Bewertungsraster mit Gewichtung:

| Kriterium | Gewicht | Messung |
|---|---|---|
| Texterkennungsqualität | 25 % | Zeichenfehlerrate gegen manuelle Referenz |
| Tabellen- und Formularerkennung | 20 % | Anteil korrekt strukturierter Tabellen |
| Konfidenzwerte | 15 % | Korrelation zwischen gemeldeter Konfidenz und tatsächlichem Fehler |
| Seiten- und Positionsbezug | 15 % | Anteil Felder mit verwertbarem Locator |
| Verarbeitung gescannter PDF | 10 % | Erfolgsquote bei den Fotos und Schrägscans |
| Kosten je Dokument | 5 % | gemessen, kein Ausschlusskriterium |
| Geschwindigkeit | 5 % | Median der Laufzeit |
| Integrationsaufwand in n8n | 5 % | Schätzung in Personentagen |

Die Auswahl wird als Entscheidung dokumentiert. Ein Wechsel danach betrifft nur den Adapter.

### 8.6 Abnahme Phase 1.1

| Nr. | Kriterium |
|---|---|
| 1.1-A1 | Jedes Dokument erhält `context_id` über `source_binding`; kein Dokument wird mit Modellvorschlag verarbeitet |
| 1.1-A2 | Zweimaliges Einlegen derselben Datei erzeugt genau einen Dokumentdatensatz |
| 1.1-A3 | Zwei Scans desselben Briefes erzeugen `duplicate_suspected`, keinen stillen Stopp |
| 1.1-A4 | Unlesbare Dokumente erhalten Status `unreadable` und eine Aufgabe |
| 1.1-A5 | Nicht erlaubte Dateitypen werden zurückgestellt, nicht ignoriert |
| 1.1-A6 | Volltext, Seitenzahl und mittlere Konfidenz liegen für alle Testdokumente vor |
| 1.1-A7 | OCR-Auswahl ist mit dem Bewertungsraster dokumentiert |

---

## 9. Phase 1.2 — Dokumentverständnis

### 9.1 Zwei getrennte Schritte

| Schritt | Werkzeug | Modellrolle | Ausgabe |
|---|---|---|---|
| Extraktion | `llm_default.extract_fields` | `extraction_model` | `extraction_result.schema.json` |
| Verständnis | `llm_default.analyze_document` | `reasoning_model` | `document_analysis.schema.json` |

Die Trennung ist bewusst: Extraktion ist eine eng geführte Aufgabe mit erzwungenem Schema und lässt sich mit einem kleineren Modell zuverlässig lösen. Verständnis erfordert Schlussfolgerung. Ein gemeinsamer Aufruf würde beides verschlechtern und die Fehlersuche erschweren.

### 9.2 Feldkatalog

**Pflichtfelder für jedes Dokument**

| `field_key` | Typ | Bedeutung |
|---|---|---|
| `document_type_key` | string | Dokumentart, siehe 9.3 |
| `document_date` | date | Datum des Dokuments |
| `sender_name` | string | Absender |
| `recipient_name` | string | Empfänger |
| `language` | string | Sprache |
| `has_action_required` | boolean | Ob eine Handlung verlangt wird |

**Bedingte Pflichtfelder je Dokumentart**

| Dokumentart | Zusätzliche Pflichtfelder |
|---|---|
| Rechnung | `total_amount`, `currency`, `due_date`, `invoice_number` |
| Mahnung | `total_amount`, `currency`, `due_date`, `reference_number` |
| Versicherungsschreiben | `policy_number`, `insurer_name` |
| Beitragsanpassung | `policy_number`, `new_amount`, `previous_amount`, `currency`, `effective_date` |
| Behördenschreiben | `authority_name`, `case_number_external` |
| Fristsetzung | `deadline` |
| Vertrag | `contract_number`, `contract_start`, `contract_end` |
| Kontoauszug | `account_reference`, `period_start`, `period_end` |

**Optionale Felder**

`deadline`, `reference_number`, `customer_number`, `iban_reference`, `contact_person`, `phone`, `enclosures_mentioned`, `signature_required`, `payment_method`, `period_start`, `period_end`, `tax_number`, `amount_breakdown`.

**Immer erhoben, unabhängig von der Dokumentart:** jedes im Text genannte Datum, das als Frist gelesen werden kann, landet in `deadline`. Lieber eine Frist zu viel prüfen als eine zu wenig.

### 9.3 Dokumentarten und Kategorien

Die Dokumentart bestimmt die bedingten Pflichtfelder, die Kategorie bestimmt den Ablageordner. Beide sind Schlüssel aus einer versionierten Liste, keine freie Modellausgabe.

Startliste der Kategorien für `privat`, aus Version 3 übernommen:

`person_identitaet_behoerden`, `familie_kinder`, `scheidung_recht`, `wohnen`, `finanzen_banken`, `steuern`, `versicherungen`, `gesundheit_krankenkasse`, `vorsorge_pension`, `arbeit_einkommen`, `fahrzeuge_mobilitaet`, `vertraege_abonnements`, `anschaffungen_garantien`, `reisen`, `ausbildung_qualifikationen`, `archiv_abgeschlossen`, `system_regeln_vorlagen`.

Erkennt das Modell keine passende Kategorie, ist der Wert `unbekannt` und das Dokument geht in `needs_review` mit Grund `unknown_document_type`. Es wird nicht geraten und nicht in einen Sammelordner geschoben.

### 9.4 Qualitäts- und Konfidenzregeln

**Handlungsrelevant** ist ein Feld, wenn es in eine Aufgabe, eine Frist, eine Berechnung, eine Vorgangszuordnung oder eine Aktion einfliesst. Das sind mindestens: `deadline`, alle Betragsfelder, `due_date`, `effective_date`, alle Kennungsfelder, `recipient_name`.

| Konfidenz | Nicht handlungsrelevantes Feld | Handlungsrelevantes Feld |
|---|---|---|
| ≥ 0,90 | übernehmen (`accepted`) | übernehmen (`accepted`) |
| 0,70 – 0,89 | übernehmen, markiert (`accepted_flagged`) | übernehmen, markiert, **und** `needs_review` mit Grund `low_confidence_actionable_field` |
| < 0,70 | verwerfen (`rejected_low_confidence`) | verwerfen **und** `needs_review` |

**Sonderregeln, die über die Konfidenz hinausgehen:**

1. **Kein Wert ohne Beleg.** Ein Feld mit Wert, aber ohne `evidence.snippet`, wird immer verworfen (`rejected_no_evidence`), unabhängig von der Konfidenz. Das Schema erzwingt das bereits.
2. **Zweistufige Belegprüfung.** Siehe Abschnitt 9.4.1. Sie ersetzt die frühere Regel „der Wert muss wörtlich im Beleg vorkommen", die für korrekt normalisierte Werte nicht anwendbar war.
3. **Fristen: Schwelle 0,95.** Jede Frist mit Konfidenz unter 0,95 wird trotzdem übernommen, aber zusätzlich zur Bestätigung vorgelegt. Eine Frist wird nie verworfen, nur weil sie unsicher ist — das Risiko ist asymmetrisch.
4. **Fristen: Plausibilitätsfenster.** Eine Frist muss zwischen dem Dokumentdatum und 5 Jahren danach liegen. Ausserhalb: `deadline_uncertain`.
5. **Beträge: Plausibilität.** Negative Beträge, Beträge über 1 000 000 und Beträge ohne Währung sind `rejected_implausible` und lösen `amount_implausible` aus.
6. **Widersprüche werden nie still aufgelöst.** Zwei verschiedene Beträge für dasselbe Feld, ein Datum, das dem Dokumentdatum widerspricht, oder ein Wert, der einem früheren Dokument desselben Vorgangs widerspricht: Differenz darstellen, Klärungsaufgabe erzeugen, keine Auswahl treffen.

### 9.4.1 Zweistufige Belegprüfung

Ein korrekt ausgelesener Wert steht selten wörtlich so im Dokument, wie er weiterverarbeitet wird. „1. Januar 2027" wird zu `2027-01-01`, „1.234,50 EUR" zu `1234.50` und `EUR`, „KV-4711 882" zu `kv4711882`. Eine Prüfung, die den kanonischen Wert im Belegtext sucht, würde alle drei Fälle fälschlich verwerfen.

Jedes Feld trägt deshalb **beide Darstellungen**:

| Feld | Bedeutung |
|---|---|
| `raw_value` | so, wie es im Dokument steht: „1. Januar 2027" |
| `normalized_value` | kanonisch für die Weiterverarbeitung: `2027-01-01` |
| `data_type` | Zieldatentyp |
| `normalization_rule` | registrierte Regel, die den Übergang leistet |
| `evidence.snippet`, `evidence.page`, optional `evidence.locator` | Textbeleg |
| `validation_status` | Ergebnis der Prüfung, **niemals vom Modell gesetzt** |

**Stufe 1 — Rohwert im Beleg.** `raw_value` muss nach einer rein technischen Textnormalisierung im Belegtext auffindbar sein. Die Normalisierung gleicht nur Darstellungsunterschiede aus: Unicode-Form, Bindestrich- und Anführungszeichenvarianten, geschützte Leerzeichen, Zeilenumbrüche, Gross- und Kleinschreibung. Zusätzlich wird eine Variante ohne Leerzeichen verglichen, damit ein Zeilenumbruch mitten in einer Zahl kein falsches Negativ erzeugt. Schlägt Stufe 1 fehl: `rejected_evidence_mismatch`.

**Stufe 2 — Kanonischer Wert aus dem Rohwert.** `normalized_value` muss sich durch die angegebene registrierte Regel aus `raw_value` ableiten lassen. Schlägt Stufe 2 fehl: `rejected_normalization_mismatch`.

Beide Stufen sind deterministisch und laufen ohne Modellbeteiligung. Referenzimplementierung: `tools/normalization_reference.py`.

**Registrierte Normalisierungsregeln** in `registry/normalization_rules.json`:

| Datentyp | Regeln |
|---|---|
| Datum | `date.de_numeric`, `date.de_long`, `date.iso` |
| Datum und Uhrzeit | `datetime.de_numeric` (ortszeitbezogen, Umrechnung nach UTC erfolgt später mit der Zeitzone des Kontexts) |
| Geldwert | `decimal.de`, `decimal.ch`, `decimal.en` |
| Währungscode | `currency.iso4217` |
| Ganzzahl | `integer.plain` |
| Kennung | `identifier.strip_separators` |
| Zeichenfolge | `string.trim` |
| Boolescher Wert | `boolean.de` |

Jede Regel führt Beispiele **und Ablehnungsfälle** mit sich, die bei jedem Testlauf gegen die Referenzimplementierung geprüft werden. Eine Regel, deren Beispiele nicht reproduzierbar sind oder deren Ablehnungsfälle durchrutschen, lässt den Lauf fehlschlagen.

**Warum drei Geldregeln.** Der reale Posteingang enthält schweizerische (`1'234.50`), deutsche (`1.234,50`) und englische (`1,234.50`) Schreibweisen. Ohne die Unterscheidung wären `1.234` und `1,234` nicht auflösbar — ein Faktor von 1000 beim Betrag.

### 9.4.3 Kalenderprüfung

Datums- und Zeitregeln prüfen das **konkrete gregorianische Kalenderdatum** über `datetime.date` beziehungsweise `datetime.datetime`. Eine Bereichsprüfung von Tag und Monat genügt nicht: Sie würde `31.02.2026` zu `2026-02-31` und `29.02.2023` zu `2023-02-29` normalisieren. Beide Werte existieren nicht und würden anschliessend als Frist geführt.

Verbindlich abgewiesen: `31.02.2026`, `29.02.2023`, `31.04.2026`, `00.01.2026`, `01.13.2026`, dazu unmögliche Datums- und Zeitangaben in Zeitstempeln. Verbindlich akzeptiert: `29.02.2024` → `2024-02-29`, `28.02.2023` → `2023-02-28`, `31.12.2026 23:59`.

**Zweistellige Jahresangaben**, bewusst beibehalten: `00` bis `69` bedeutet `2000` bis `2069`, `70` bis `99` bedeutet `1970` bis `1999`. Die Regel steht in `registry/normalization_rules.json` unter `conventions.two_digit_year` und ist in `expand_two_digit_year` umgesetzt.

### 9.4.4 Geldwerte

Ein Geldwert wird **niemals als Binär-Gleitkommazahl** geführt. `0.1 + 0.2` ergibt in Gleitkommaarithmetik nicht `0.3`; bei Beiträgen, Rechnungen und Fristen mit Geldwirkung ist das unzulässig.

| Regel | Wirkung |
|---|---|
| Kanonische Darstellung | Zeichenfolge mit Dezimalpunkt, exakt zwei Nachkommastellen |
| Keine Exponentialschreibweise | `4.4800e2` ist unzulässig |
| Rundung | kaufmännisch, `ROUND_HALF_UP` |
| Berechnung | ausschliesslich mit `Decimal`, in PostgreSQL mit `NUMERIC`, niemals mit `float` |
| Währung | bleibt ein eigenes Feld, wird nie in den Betrag gemischt |
| Datentyp | `money` im Feldkatalog; `normalized_value`, `unit_amount` und `total_amount` sind Zeichenfolgen |

Beispiele: `1.234,50 EUR` → `"1234.50"`, `CHF 448.00` → `"448.00"`, `12'000.-` → `"12000.00"`, `0,10` → `"0.10"`, `-89,90` → `"-89.90"`.

Der Prüflauf enthält eine Rechenprobe, die `"0.10" + "0.20" = "0.30"` mit `Decimal` nachweist und gleichzeitig belegt, dass dieselbe Rechnung mit `float` ein abweichendes Ergebnis liefert. Eine Gleitkommazahl als `normalized_value` eines Geldfelds wird vom Schema abgewiesen.

**Nicht monetäre Dezimalwerte** mit abweichender Genauigkeit, etwa Mengen oder Prozentsätze, erhalten bei Bedarf eine eigene registrierte Regel und einen eigenen Datentyp. Sie werden nicht über die Geldregeln improvisiert.

### 9.4.2 Belegpflicht für Tabellenpositionen

Ein Betrag in einer Tabellenzeile darf die Belegpflicht nicht umgehen. Jede Position mit einem Betragswert führt `total_amount_raw` beziehungsweise `unit_amount_raw`, eine Normalisierungsregel und **entweder** einen eigenen Beleg **oder** einen `field_ref` auf ein bereits belegtes Extraktionsfeld. Positionen ohne Betrag, etwa reine Hinweiszeilen, brauchen keinen Beleg.

Für beide Wege gilt Stufe 2 unverändert: Der Betrag muss sich aus dem Rohwert ableiten lassen.

### 9.5 Was das Modell nicht darf

| Verbot | Durchsetzung |
|---|---|
| Risikoklassen setzen | `document_analysis.schema.json` hat kein Feld dafür (`additionalProperties: false`) |
| Freigaben erteilen | keine Schnittstelle; Freigabe ist ein eigener Sub-Workflow |
| Werkzeuge aufrufen | Aufrufe laufen ausschliesslich über `tool_invoke` |
| Werte ohne Beleg liefern | Schemabedingung plus Belegprüfung |
| Vage Aufgaben vorschlagen | `title_de` mindestens 10 Zeichen, `success_criterion_de` Pflicht, `consequence_of_inaction_de` Pflicht |
| Unsicherheit verschweigen | `uncertainties` ist ein Pflichtfeld |

`proposed_action_type` ist ausdrücklich ein **Vorschlag**. Das tatsächliche Werkzeug und die Risikoklasse werden in 1.3 deterministisch bestimmt.

### 9.6 Vorgangszuordnung

**Reihenfolge:**

1. Normalisierte Kennungen aus dem Dokument gegen `case_identifier` prüfen. Normalisierung: Kleinschreibung, Trennzeichen entfernen.
2. **Genau ein Treffer** → Zuordnung, `match_method: identifier_match`, Klasse A.
3. **Mehrere Treffer** → `needs_review` mit Grund `case_ambiguous`, Kandidaten werden aufgelistet.
4. **Kein Treffer** → neuer Vorgang mit neuer Vorgangsnummer, `match_method: created_new`, Klasse A.

Eine Zuordnung über Ähnlichkeit von Absender und Betreff ohne stabile Kennung erfolgt in Phase 1 **nicht**. Sie erzeugt erfahrungsgemäss falsche Verknüpfungen, die später schwer zu finden sind. Ein zusätzlicher Vorgang ist der billigere Fehler.

**Vorgangsnummer:** `V-JJJJ-NNNN`, fortlaufend je Kontext und Jahr, vergeben aus `case_number_seq`. Sie steht im Dateinamen, damit die Zusammengehörigkeit auch ohne System erkennbar ist.

### 9.7 Dokumentvergleich

Liegt im Vorgang bereits ein Dokument derselben Art vor, werden die numerischen und datumsbezogenen Felder verglichen und `changes_vs_previous` befüllt, mit absoluter und prozentualer Abweichung. Das ist die Grundlage für Aufgaben wie „Prämie 2027 mit Police 2026 vergleichen und bei mehr als 5 % Abweichung einen Rückfrageentwurf erstellen" — das Beispiel aus Version 3, das jetzt technisch hinterlegt ist.

### 9.8 Abnahme Phase 1.2

| Nr. | Kriterium |
|---|---|
| 1.2-A1 | ≥ 90 % der Pflichtfelder im Testkorpus korrekt |
| 1.2-A2 | 100 % der Fristen im Testkorpus erkannt |
| 1.2-A3 | Kein Feld mit Wert ohne Textbeleg im gesamten Testkorpus |
| 1.2-A4 | Belegprüfung weist mindestens einen absichtlich manipulierten Testfall ab |
| 1.2-A5 | Widersprüchliche Testdokumente erzeugen eine Klärungsaufgabe, keine stille Auswahl |
| 1.2-A6 | Eindeutige Kennungen führen zu korrekter Vorgangszuordnung, mehrdeutige zu `needs_review` |
| 1.2-A7 | Modellbenchmark für die drei Rollen ist dokumentiert |

---

## 10. Phase 1.3 — Aufgaben- und Aktionsableitung

### 10.1 Vom Vorschlag zur Aufgabe

Aus jedem `proposed_task` wird deterministisch geprüft und dann ein `task`-Objekt erzeugt:

| Prüfung | Bei Verstoss |
|---|---|
| `title_de` konkret und im Verbformat | Vorschlag verworfen, Ereignis mit Begründung |
| `success_criterion_de` vorhanden und überprüfbar | Vorschlag verworfen |
| `consequence_of_inaction_de` vorhanden | Vorschlag verworfen |
| Frist plausibel und aus einem validierten Feld | Aufgabe ohne Frist, `needs_review` |
| Bei menschlichem Akteur: `assignee` gesetzt | Standard ist `rolf` |
| Kein handlungsrelevantes Feld im Zustand `rejected` | Aufgabe entsteht, aber blockiert |
| Idempotenzschlüssel noch nicht vorhanden | keine zweite Aufgabe |

**Verbindlich aus Version 3 übernommen:** Vage Aufgaben wie „Dokument prüfen" sind unzulässig. Eine Aufgabe benennt Gegenstand, Massstab und Ergebnis.

### 10.2 Von der Aufgabe zur Aktion

Eine Aufgabe erhält null bis mehrere Aktionen. Aufgaben mit `actor: rolf` erhalten in Phase 1 in der Regel keine Aktion — sie sind Arbeit für einen Menschen.

**Ablauf je Aktion:**

1. Werkzeug aus dem Register wählen, das den Aktionstyp abdeckt und den Kontext erlaubt.
2. Eingaben aus validierten Feldern füllen. Fehlt eine Pflichteingabe: Status `blocked`, `missing_inputs` benennen. Keine geratenen Werte.
3. Idempotenzschlüssel nach Phase-0-Referenz bilden.
4. Risikoklasse deterministisch bestimmen (10.3).
5. Bei Klasse C: `content_fingerprint` bilden und Freigabe anfordern.

### 10.3 Risikoklassifizierung

```
risk_class = max(
    tool.risk_class_default,          aus dem Werkzeugregister
    kontextregel(action_type/tool_id), aus der Kontextkonfiguration
    aussenwirkungsregel,
    manuelle_hochstufung
)
```

Kein Sprachmodell ist beteiligt. Eine Herabstufung ist unmöglich; `tools/validate_policy.py` aus Phase 0 prüft das automatisch.

**Klassen der Phase-1-Aktionen**

| Aktion | Werkzeug | Klasse | Begründung |
|---|---|---|---|
| Dokument erfassen, auslesen, verstehen | `ocr_default.*`, `llm_default.*` | A | keine Zustandsänderung ausserhalb von JARVIS |
| Dokumentregister schreiben | `docstore_internal.upsert_document` | A | intern, reversibel |
| Vorgang anlegen oder verknüpfen | `casestore_internal.upsert_case` | A | intern, reversibel |
| Aufgabe anlegen | `tasks_internal.create_task` | A | intern, reversibel |
| Dokument benennen und ablegen | `storage_gdrive.move_file` | A | reversibel, gleicher Kontext, Undo-Werkzeug vorhanden |
| Entwurf erstellen | `drafts_internal.create_draft` | A | verlässt das System nicht |
| Tagesbericht schreiben | `report_internal.write_daily_report` | A | abgeleitete Ansicht |
| Freigabe anfordern | `approval_email.request_decision` | A | Empfänger ist ausschliesslich Rolf |
| Testaktion mit Freigabe | `test.record_approved_action` | **C** | dient ausdrücklich dem Nachweis des Freigabewegs |

**Warum Klasse B in Phase 1 leer ist.** Klasse B setzt Aussenwirkung voraus. Ohne E-Mail- und Kalenderanbindung gibt es in Phase 1 keine Aktion mit Aussenwirkung. Das ist kein Mangel, sondern die Folge des Zuschnitts. Der Mechanismus bleibt vollständig spezifiziert und wird in Phase 2 mit dem ersten Versandwerkzeug scharf geschaltet.

**Warum die Ablage Klasse A ist.** Sie verschiebt eine Datei innerhalb desselben Kontexts, ist über `undo_tool_id` umkehrbar und hat keine Aussenwirkung. Der eigentliche Schutz liegt nicht in der Freigabe, sondern in der Kontextsperre und im Ergebnisnachweis.

### 10.4 Ausnahmebehandlung

| Situation | Verhalten |
|---|---|
| Pflichtfeld fehlt | Aufgabe „Fehlende Angabe klären" mit konkretem Feldnamen; abhängige Aktion `blocked` |
| Handlungsrelevantes Feld unsicher | Aktion `blocked`, gezielte Rückfrage zu genau diesem Feld, nicht zum ganzen Dokument |
| Widerspruch zwischen Dokumenten | Klärungsaufgabe mit beiden Werten und beiden Dokumentverweisen; keine Auswahl |
| Vorgang mehrdeutig | `needs_review` mit Kandidatenliste |
| Unbekannte Dokumentart | `needs_review`, keine Ablage in einen Sammelordner |
| Kontext nicht auflösbar | Verarbeitung angehalten, Aufgabe für Rolf, keine Aktion |
| Werkzeug nicht `approved` | Aktion entsteht nicht; Ereignis `system.error` |
| Technischer Fehler | Retry nach Phase-0-Regel, danach Ausnahmeliste |

**Zur einzigen datenschutzrelevanten Funktion:** Die OCR-Verarbeitung übermittelt Dokumentinhalte an einen externen Dienst. Deshalb steht in der Kontextkonfiguration je Kontext eine Positivliste erlaubter OCR-Adapter, und die Auswahl in 8.5 wird als Entscheidung dokumentiert. Weitergehende Bewertungen sind nicht Gegenstand dieser Spezifikation.

### 10.5 Freigabeweg für Klasse C

Vollständig nach Phase 0, Abschnitt 9. In Phase 1 nachzuweisen über `test.record_approved_action`.

| Schritt | Ergebnis |
|---|---|
| 1 | Aktion mit `risk_class: C`, Status `awaiting_approval`, `content_fingerprint` gebildet |
| 2 | Freigabedatensatz mit Einmal-Token (nur Hash gespeichert), Ablauffrist aus der Kontextkonfiguration |
| 3 | `decision_summary` mit Sachverhalt, geplanter Aktion, Empfänger, Folgen und Quellen |
| 4 | Zustellung über den Freigabeadapter |
| 5 | Rolf öffnet den Link → Bestätigungsseite, noch keine Freigabe |
| 6 | Ausdrückliche zweite Bestätigung → Prüfung von Token, Ablauf, Verbrauch, Fingerprint und Kontext |
| 7 | Aktion `approved`, Freigabe `consumed` |
| 8 | Ausführung ohne weitere Modellbeteiligung |

**Freigabeadapter.** Bevorzugt ist ein per HTTPS erreichbarer Bestätigungsendpunkt als Webhook. Ist er nicht verfügbar, wird ein alternativer Adapter eingesetzt — etwa eine lokal erreichbare Bestätigungsseite im eigenen Netz oder ein manuelles Bestätigungsverfahren mit protokollierter Zweitbestätigung. Alle sieben Sicherheitsregeln aus Phase 0 gelten unverändert. Das Aktions- und Freigabemodell ändert sich nicht; die spätere Freigabe über die JARVIS-Oberfläche ist derselbe Adaptertausch. Entscheidung vor Beginn von 1.3 (P1-O2).

**Nachzuweisen sind neun Punkte:**

1. Freigabe erfolgt in zwei Schritten.
2. Freigabe ist an genau eine Aktion gebunden.
3. Freigabe besitzt eine Ablauffrist.
4. Freigabe kann nur einmal verwendet werden.
5. Erneuter Aufruf führt nicht zu einer zweiten Ausführung.
6. Ablehnung verhindert die Ausführung.
7. Abgelaufene Freigabe verhindert die Ausführung.
8. Falscher Kontext verhindert die Ausführung.
9. Ausführung und Ergebnisnachweis werden protokolliert.

### 10.6 Abnahme Phase 1.3

| Nr. | Kriterium |
|---|---|
| 1.3-A1 | Jede Aufgabe hat Titel im Verbformat, Erfolgskriterium, Akteur und Priorität |
| 1.3-A2 | Keine Aufgabe enthält eine vage Formulierung aus der Verbotsliste |
| 1.3-A3 | Keine Aktion trägt eine Klasse unter dem Werkzeugminimum |
| 1.3-A4 | Aktionen mit fehlenden Eingaben sind `blocked` und benennen die Felder |
| 1.3-A5 | Alle neun Freigabepunkte aus 10.5 sind nachgewiesen |
| 1.3-A6 | Widersprüchliche Testdokumente erzeugen genau eine Klärungsaufgabe |
| 1.3-A7 | Wiederholte Verarbeitung erzeugt keine zweite Aufgabe |

---

## 11. Phase 1.4 — Ausführung, Nachweis und automatische Ablage

### 11.1 Ausführungsreihenfolge

Nach den Phase-0-Konventionen, ohne Ausnahme:

```
context_resolve → idempotency_guard → action_plan → action_classify
  → [Klasse C: approval_request → approval_callback]
  → tool_invoke → evidence_verify → fach_log_write
```

`tool_invoke` läuft nur mit erteilter Sperre und, bei Klasse C, mit gültiger Freigabe.

### 11.2 Nachweisstrategie je Werkzeug

Nach Entscheidung D3. Alle schreibenden Phase-1-Werkzeuge unterstützen einen unabhängigen Readback, daher ist der Readback bei allen verpflichtend.

| Werkzeug | Readback | Was geprüft wird |
|---|---|---|
| `storage_gdrive.move_file` | ja | Neue Datei-ID, Zielpfad und Name werden nach dem Verschieben erneut gelesen; zusätzlich Grössenvergleich mit dem Original |
| `docstore_internal.upsert_document` | ja | Datensatz wird nach dem Schreiben erneut gelesen, Status und Zeitstempel verglichen |
| `casestore_internal.upsert_case` | ja | Vorgang und Dokumentzuordnung werden erneut gelesen |
| `tasks_internal.create_task` | ja | Aufgaben-ID wird erneut gelesen |
| `drafts_internal.create_draft` | ja | Entwurfsdatei wird erneut gelesen, Inhaltshash verglichen |
| `report_internal.write_daily_report` | ja | Berichtsdatei wird erneut gelesen |
| `test.record_approved_action` | ja | Testdatensatz wird erneut gelesen |
| `ocr_default.analyze_document` | nein | Ersatznachweis `provider_status` mit ausdrücklicher Grenzangabe: belegt eine Antwort zum übermittelten Inhaltshash, nicht die Richtigkeit der Erkennung |
| `llm_default.*` | nein | Ersatznachweis `provider_status`: belegt eine schemakonforme Antwort, nicht die fachliche Richtigkeit |

Die Antwort des Schreibaufrufs ist nie allein ausreichend. Bei `inconclusive` bleibt die Aktion `running` und wird zur Ausnahme.

### 11.3 Dateibenennung

```
JJJJ-MM-TT__Absender__Dokumenttyp__Kurzbetreff__V-JJJJ-NNNN.<endung>
```

Beispiele:

```
2026-08-25__Krankenversicherung__Beitragsanpassung__Praemie-2027__V-2026-0042.pdf
2026-08-29__Elektrofachmarkt__Quittung__Waschmaschine__V-2026-0043.jpg
```

**Die Endung stammt aus dem geprueften MIME-Typ, niemals aus dem urspruenglichen Dateinamen.** Das Original wird nicht konvertiert; ein Foto bleibt ein Foto. Eine feste Endung `.pdf` waere ein Widerspruch zu den erlaubten Eingangsformaten.

| MIME-Typ | Endung |
|---|---|
| `application/pdf` | `.pdf` |
| `image/jpeg` | `.jpg` |
| `image/png` | `.png` |
| `image/tiff` | `.tif` |

Ein Dokument mit einem anderen MIME-Typ wird nicht abgelegt, sondern zurueckgestellt (`quarantined`). Die Zuordnung ist in `tools/normalization_reference.py` als `MIME_EXTENSION_MAP` hinterlegt und wird bei jedem Testlauf geprueft. Stimmt die Endung des Zieldateinamens nicht mit dem MIME-Typ ueberein, wird die Ablageaktion abgewiesen; der Werkzeugvertrag `storage_gdrive.move_file` verlangt dafuer das Feld `expected_mime_type`.

**Regeln:**

| Regel | Begründung |
|---|---|
| Datum ist das Dokumentdatum, nicht das Eingangsdatum | Sortierung nach fachlicher Zeit |
| Fehlt das Dokumentdatum: Eingangsdatum mit Präfix `E-` | erkennbar, dass das Datum unsicher ist |
| Nur ASCII, Umlaute transliteriert (ä→ae) | Portabilität zwischen Speichersystemen |
| Trennzeichen: doppelter Unterstrich zwischen Bestandteilen, einfacher Bindestrich innerhalb | eindeutige maschinelle Zerlegbarkeit |
| Absender auf 30, Kurzbetreff auf 40 Zeichen gekürzt | Gesamtlänge unter 150 Zeichen |
| Bei Namenskollision: Suffix `__2`, `__3` | keine Überschreibung |
| Nicht im Dateinamen: Status, Frist, offene Aufgabe, Konfidenz | aus Version 3 unverändert; diese Werte ändern sich, der Name nicht |

Die Originaldatei wird verschoben und umbenannt. Ihr Inhalt bleibt unverändert.

### 11.4 Ablageregeln je Kontext

**Zielpfad:**

```
<archive_root>/<Ordner aus category_folder_map>/<Jahr des Dokumentdatums>/
```

Die Ordnerstruktur je Kontext bleibt aus Version 3 erhalten (`01_Person_Identitaet_Behoerden` bis `99_System_Regeln_Vorlagen`). Die Zuordnung Kategorie → Ordner steht in `config/category_map_<kontext>.json`, nicht im Workflow.

**Verbindliche Ablageregeln:**

1. Ablage erfolgt ausschliesslich in die Wurzel des eigenen Kontexts. Der Speicheradapter erhält die Wurzel aus der Kontextkonfiguration; ein Pfad ausserhalb wird abgewiesen.
2. Ohne Kategorie keine Ablage. Unbekannte Kategorie → `needs_review`, das Dokument bleibt im Arbeitsbereich.
3. Ohne Vorgangsnummer keine Ablage.
4. Die Ablage ist erst abgeschlossen, wenn der Readback Zielpfad und Name bestätigt.
5. Der Eingangsordner ist danach leer. Eine Datei, die dort liegen bleibt, ist ein Fehlerzustand und erscheint im Tagesbericht.
6. `arbeitgeber_visolva` verwendet in Phase 1 eine eigene Testwurzel mit einer minimalen Struktur (`00_Eingang`, `10_Test`, `90_Archiv`). Eine fachliche Ordnerstruktur für den Arbeitgeber ist nicht Gegenstand von Phase 1.

### 11.5 Fachprotokollierung

Jeder Zustandsübergang und jede Aktion erzeugt einen Eintrag in `<kontext>.action_log`, append-only:

| Feld | Inhalt |
|---|---|
| `entry_kind` | `document_received`, `document_understood`, `task_created`, `action_planned`, `approval_granted`, `action_executed`, `action_verified`, `document_filed`, `review_opened`, `review_resolved` |
| `summary_de` | ein Satz auf Deutsch, was fachlich geschehen ist |
| `body` | strukturierte Kopie der entscheidungsrelevanten Felder |
| `document_id`, `case_id`, `task_id`, `action_id` | Verweise |

Korrekturen erfolgen als neuer Eintrag mit `corrects_log_id`. Das technische Protokoll in `jarvis_ops` erhält ausschliesslich IDs, Zeiten, Statuscodes und die bereinigte Meldung nach `sanitize_message.py`.

### 11.6 Täglicher Bericht

Erzeugt durch `JV-P1-MAIN-daily_report-v1`, geschrieben mit `report_internal.write_daily_report` in den Berichtsordner des Kontexts. Format: Markdown, ein Bericht je Kontext und Tag.

**Inhalt, nach Entscheidung P1-B5:**

1. neue Aufgaben,
2. heute fällige Aufgaben,
3. überfällige Aufgaben,
4. bevorstehende Fristen (14 Tage),
5. wartende Freigaben,
6. fehlgeschlagene Aktionen,
7. Dokumente mit manueller Prüfung,
8. nicht eindeutig zuordenbare Dokumente,
9. automatisch erledigte Arbeiten des Vortags als kompakte Liste.

**Verbindlich:** Der Bericht ist eine abgeleitete Ansicht. Sein Verlust, seine doppelte Erzeugung oder seine Löschung verändern den Aufgabenbestand nicht. Er wird bei jedem Lauf vollständig neu erzeugt und ersetzt die Vortagesdatei nicht, sondern liegt als eigene Datei je Tag.

### 11.7 Abnahme Phase 1.4

| Nr. | Kriterium |
|---|---|
| 1.4-A1 | ≥ 95 % der Pilotdokumente ohne manuelle Umbenennung abgelegt |
| 1.4-A2 | Kein Dokument im falschen Kontext abgelegt |
| 1.4-A3 | Kein Fachprotokolleintrag im falschen Kontextschema |
| 1.4-A4 | Jede ausgeführte Aktion hat einen vertragskonformen Nachweis |
| 1.4-A5 | Kein `succeeded` ohne bestätigten Nachweis |
| 1.4-A6 | Namenskollisionen werden aufgelöst, keine Datei überschrieben |
| 1.4-A7 | Eingangsordner ist nach dem Lauf leer oder Reste erscheinen im Bericht |
| 1.4-A8 | Zweifache Erzeugung des Tagesberichts verändert keinen Aufgabendatensatz |

---

## 12. Werkzeuge, Modellrollen und Agenten

### 12.1 Werkzeuge

Neun neue Werkzeuge in `registry/tool_registry_phase1.json`, validiert gegen das Phase-0-Registerschema. Aus Phase 0 werden `storage_gdrive.move_file`, `tasks_internal.create_task` und `approval_email.request_decision` weiterverwendet.

| Werkzeug | Operation | Klasse | Kontexte |
|---|---|---|---|
| `storage_gdrive.get_file` | read | A | beide |
| `ocr_default.analyze_document` | read | A | beide |
| `llm_default.extract_fields` | read | A | beide |
| `llm_default.analyze_document` | read | A | beide |
| `docstore_internal.upsert_document` | write | A | beide |
| `casestore_internal.upsert_case` | write | A | beide |
| `drafts_internal.create_draft` | write | A | beide |
| `report_internal.write_daily_report` | write | A | beide |
| `test.record_approved_action` | write | **C** | beide |

Alle stehen im Status `draft`.

### 12.1.1 Wann ein Werkzeug auf `approved` wechselt

Ein Werkzeug wird nicht pauschal in Phase 1.0 freigegeben. Der Statuswechsel setzt fünf erfüllte und belegte Bedingungen voraus, in dieser Reihenfolge:

| Schritt | Bedingung |
|---|---|
| 1 | Vertrag vollständig, Ein- und Ausgabeschema vorhanden und auflösbar |
| 2 | Konkreter Adapter ausgewählt und mit Credentials konfiguriert |
| 3 | Testlauf oder Dry Run im Zielsystem erfolgreich |
| 4 | Ergebnisnachweis nach Werkzeugvertrag erfolgreich erbracht |
| 5 | erst danach Status `approved` |

Daraus folgt, dass OCR- und Modellwerkzeuge in Phase 1.0 nicht freigegeben werden können: Ihr Adapter steht zu diesem Zeitpunkt noch gar nicht fest. Dasselbe gilt für das Freigabewerkzeug, dessen Kanal an der offenen Entscheidung P1-O2 hängt.

**Freigabe je Teilphase**, verbindlich geführt in `registry/tool_release_plan.json`:

| Teilphase | Werkzeuge | Adapterauswahl offen |
|---|---|---|
| 1.0 | `docstore_internal.upsert_document`, `casestore_internal.upsert_case`, `tasks_internal.create_task` | nein |
| 1.1 | `storage_gdrive.get_file`, `ocr_default.analyze_document` | OCR ja |
| 1.2 | `llm_default.extract_fields`, `llm_default.analyze_document` | ja |
| 1.3 | `approval_email.request_decision`, `test.record_approved_action` | Freigabekanal ja |
| 1.4 | `storage_gdrive.move_file`, `drafts_internal.create_draft`, `report_internal.write_daily_report` | nein |

Phase 1.0 gibt damit nur drei Kernwerkzeuge frei, und zwar solche mit internem Adapter, die im Rahmen der Trennungs- und Idempotenznachweise ohnehin tatsächlich ausgeführt und mit Readback belegt werden.

**Warum `storage_gdrive.move_file` erst in 1.4 freigegeben wird.** Es ist das einzige Werkzeug, das ein Original bewegt. Die Freigabe erfolgt erst, wenn Zielordner, Benennung und Readback zusammen erfolgreich geprüft sind — nicht früher, nur weil der Adapter feststeht.

### 12.2 Werkzeugspezifische Ein- und Ausgabeschemata

Die Ausgabeverträge der beiden inhaltlich kritischen Werkzeuge liegen als vollständige Schemata vor:

| Werkzeug | Eingabe | Ausgabe |
|---|---|---|
| `llm_default.extract_fields` | Volltext, Seitenstruktur, OCR-Kandidaten, Feldkatalog der Dokumentart | `extraction_result.schema.json` |
| `llm_default.analyze_document` | validiertes Extraktionsergebnis, Vorgangskontext, Vergleichsdokumente | `document_analysis.schema.json` |
| `docstore_internal.upsert_document` | `document.schema.json` | `document.schema.json` |
| `casestore_internal.upsert_case` | `case.schema.json` | `case.schema.json` |

**Alle Vertragsschemata liegen vor.** Kein in Phase 1 verwendetes Werkzeug verweist auf eine Datei, die erst während der Implementierung entstehen soll. Die vierzehn schmalen Verträge liegen unter `schemas/tools/`:

| Werkzeug | Eingabe | Ausgabe |
|---|---|---|
| `storage_gdrive.get_file` | `schemas/tools/storage_gdrive.get_file.input.json` | `…get_file.output.json` |
| `storage_gdrive.move_file` | `…move_file.input.json` | `…move_file.output.json` |
| `ocr_default.analyze_document` | `…analyze_document.input.json` | `…analyze_document.output.json` |
| `llm_default.extract_fields` | `…extract_fields.input.json` | `schemas/extraction_result.schema.json` |
| `llm_default.analyze_document` | `…analyze_document.input.json` | `schemas/document_analysis.schema.json` |
| `docstore_internal.upsert_document` | `schemas/document.schema.json` | `schemas/document.schema.json` |
| `casestore_internal.upsert_case` | `schemas/case.schema.json` | `schemas/case.schema.json` |
| `drafts_internal.create_draft` | `…create_draft.input.json` | `…create_draft.output.json` |
| `report_internal.write_daily_report` | `…write_daily_report.input.json` | `…write_daily_report.output.json` |
| `tasks_internal.create_task` | `schemas/task.schema.json` (Phase 0) | `schemas/task.schema.json` |
| `approval_email.request_decision` | `schemas/approval.schema.json` (Phase 0) | `schemas/approval.schema.json` |
| `test.record_approved_action` | `…record_approved_action.input.json` | `…record_approved_action.output.json` |

Die Prüfung stellt für jedes dieser zwölf Werkzeuge sicher, dass beide Verweise auf eine vorhandene Datei zeigen, dass diese gültiges JSON Schema Draft 2020-12 ist, dass alle `$id`-Werte eindeutig sind und dass jeder `$ref` auflösbar ist. Ein fehlender oder nicht auflösbarer Verweis lässt den Testlauf fehlschlagen.

**Der Ausgabevertrag von `ocr_default.analyze_document` ist zugleich das Ausschlusskriterium der Dienstauswahl:** Volltext je Seite, mittlere Konfidenz je Seite, Blöcke mit Text, Konfidenz und **Positionsbezug**, Tabellen als Zeilen- und Spaltenstruktur, Formularfelder als Schlüssel-Wert-Paare. Ein Dienst, der keinen Positionsbezug je Block liefert, macht die Belegpflicht aus 9.4.1 unerfüllbar und scheidet unabhängig von seiner Textqualität aus.

**Der Eingabevertrag von `storage_gdrive.move_file`** verlangt `expected_mime_type` und `target_filename` mit passender Endung. Damit ist die Regel aus 11.3 nicht nur beschrieben, sondern im Vertrag verankert.

### 12.3 Modellrollen

Nach Entscheidung P1-B4:

| Rolle | Einsatz | Anforderungen |
|---|---|---|
| `extraction_model` | Feldextraktion, Klassifikation | erzwungene Schemaausgabe, Dokument- oder Bildverarbeitung, hohe Schematreue |
| `reasoning_model` | Verständnis, Verpflichtungen, Fristen, Risiken, Widersprüche, Aufgabenvorschläge | Schlussfolgerung über längere Texte, Zurückhaltung bei Unsicherheit |
| `drafting_model` | Zusammenfassungen, Hinweise, Entwürfe | gute deutsche Formulierung |

Modell-IDs stehen ausschliesslich in der Konfiguration (`env:JV_MODEL_EXTRACTION`, `env:JV_MODEL_REASONING`, `env:JV_MODEL_DRAFTING`). Claude kann anfänglicher Standardanbieter sein. Ein Modellwechsel ist eine Konfigurationsänderung.

**Benchmark vor dem Pilotbetrieb** auf dem Testkorpus, bewertet: Feldqualität, Fristerkennung, Schemaeinhaltung, Halluzinationsrate (gemessen über die Belegprüfung), Laufzeit, Kosten. Kosten sind Messgrösse, kein Ausschlusskriterium; Pflichtfeldqualität und Fristerkennung haben Vorrang.

### 12.4 Agenten

Nach Phase-0-Entscheidung D9 keine sieben Agenten wie in Version 3, sondern deterministische Sub-Workflows plus drei Modellrollen. Die Rollen aus Version 3 bleiben als Verantwortlichkeiten erhalten, werden aber nicht als eigenständige KI-Agenten gebaut:

| Version-3-Rolle | Umsetzung in Version 4.0 |
|---|---|
| Eingangsagent | `JV-P1-SUB-document_normalize-v1`, deterministisch |
| Leseagent | `JV-P1-SUB-document_ocr-v1` plus `extraction_model` |
| Verstehensagent | `JV-P1-SUB-document_understand-v1` plus `reasoning_model` |
| Aktionsagent | `JV-P1-SUB-task_derive-v1` und `JV-P1-SUB-action_plan-v1`, Vorschlag vom Modell, Entscheidung deterministisch |
| Ausführungsagent | `JV-CORE-SUB-tool_invoke-v1`, deterministisch |
| Ablageagent | `JV-P1-SUB-document_file-v1`, deterministisch |
| Kontrollagent | `JV-P1-MAIN-deadline_watch-v1` und `JV-P1-MAIN-daily_report-v1`, deterministisch |

Nur drei der sieben Schritte nutzen ein Sprachmodell.

---

## 13. n8n-Workflowübersicht

Namensschema nach den Phase-0-Konventionen.

### 13.1 Hauptworkflows

| Workflow | Auslöser | Aufgabe |
|---|---|---|
| `JV-P1-MAIN-document_intake-v1` | Zeitplan, Abfrage der Eingangsordner je Kontext | Vollständige Kette Eingang bis Ablage |
| `JV-P1-MAIN-daily_report-v1` | Zeitplan, werktäglich morgens | Tagesbericht je Kontext |
| `JV-P1-MAIN-deadline_watch-v1` | Zeitplan, täglich | `deadline.due_soon` und `task.overdue` erzeugen |
| `JV-P1-MAIN-retry_dispatcher-v1` | Zeitplan, viertelstündlich | Aktionen mit fälligem `next_attempt_at` erneut anstossen |
| `JV-P1-MAIN-approval_callback-v1` | Webhook | Freigabeentscheidung entgegennehmen (Adapter nach 10.5) |

### 13.2 Sub-Workflows Phase 1

| Workflow | Aufgabe | Modell |
|---|---|---|
| `JV-P1-SUB-document_normalize-v1` | Eingangsprüfung, Hash, Dublette, Original sichern | nein |
| `JV-P1-SUB-document_ocr-v1` | OCR-Adapter aufrufen, Qualität bewerten | nein |
| `JV-P1-SUB-document_extract-v1` | Feldextraktion und deterministische Validierung | ja |
| `JV-P1-SUB-document_understand-v1` | Analyse, Vergleich mit Vordokumenten | ja |
| `JV-P1-SUB-case_match-v1` | Vorgangszuordnung über Kennungen, Nummernvergabe | nein |
| `JV-P1-SUB-task_derive-v1` | Vorschläge prüfen, Aufgaben anlegen | nein |
| `JV-P1-SUB-action_plan-v1` | Aktionen erzeugen, Eingaben füllen | nein |
| `JV-P1-SUB-document_file-v1` | Benennen, verschieben, Readback | nein |
| `JV-P1-SUB-draft_compose-v1` | Entwurf erzeugen und ablegen | ja |
| `JV-P1-SUB-review_queue-v1` | Ausnahme eröffnen, Grund festhalten | nein |

### 13.3 Wiederverwendete Kern-Sub-Workflows

`JV-CORE-SUB-context_resolve-v1`, `id_generate-v1`, `idempotency_guard-v1`, `action_classify-v1`, `approval_request-v1`, `approval_callback-v1`, `tool_invoke-v1`, `evidence_verify-v1`, `fach_log_write-v1`, `tech_log_write-v1`, `JV-CORE-OPS-error_handler-v1`.

### 13.4 Einstellungen

Für alle fachlichen Workflows: Speichern der Ausführungsdaten aus, Error-Workflow gesetzt, Zeitzone UTC intern, Anzeige `Europe/Zurich`, Timeout je Werkzeugvertrag. Credentials nach `jv_<kontext>_<system>`. Ein Workflow enthält keinen Arbeitgebernamen, keine Ordner-ID und keinen Schlüssel.

---

## 14. Idempotenz und Wiederanlauf

### 14.1 Drei Ebenen

| Ebene | Mechanismus | Wirkt gegen |
|---|---|---|
| Datei | `content_hash`, Unique-Index | dieselbe Datei zweimal einlegen |
| Aktion | `idempotency_key`, Unique-Index plus `action_lock` | dieselbe Aktion zweimal ausführen |
| Verarbeitungsschritt | `document.processing_stage` | denselben Schritt zweimal durchlaufen |

### 14.2 Wiederanlauf

Jeder Sub-Workflow schreibt nach Abschluss seine Stufe in `processing_stage.last_completed`. Ein erneuter Lauf desselben Dokuments beginnt bei der Folgestufe. Konkret:

| `last_completed` | Wiederanlauf beginnt bei |
|---|---|
| `intake` | OCR |
| `ocr` | Extraktion |
| `extraction` | Analyse |
| `analysis` | Vorgangszuordnung |
| `case_match` | Aufgabenableitung |
| `task_derive` | Aktionsplanung |
| `action_plan` | Ablage |
| `filing` | nichts, Dokument ist fertig |

Teure Schritte werden dadurch nicht wiederholt. OCR- und Modellergebnisse bleiben gespeichert und werden nur bei einer neuen Analyseversion neu erzeugt.

### 14.3 Neuverarbeitung

Eine bewusste Neuverarbeitung, etwa nach einer verbesserten Prompt-Version, ist möglich: `analysis_version` ändert sich, die Extraktion und Analyse laufen erneut, das Dokument behält seine ID, und alte Aufgaben bleiben bestehen. Neue Aufgaben entstehen nur, wenn ihr Idempotenzschlüssel noch nicht vergeben ist. Die alte Analyse wird nicht überschrieben, sondern als frühere Version behalten.

---

## 15. Fehler, manuelle Prüfung und Eskalation

### 15.1 Fehlerbehandlung

Vollständig nach Phase 0, Abschnitt 16. Höchstens drei Versuche mit exponentiellem Abstand, Statusabgleich vor jedem Versuch, kein blinder Retry bei unklarem Status, Schutzschalter je Werkzeug.

### 15.2 Manuelle Prüfung

Die Ausnahmeliste ist in Phase 1 keine Oberfläche, sondern ein Datenbestand: alle Dokumente mit `review.required = true` plus alle Aktionen im Zustand `blocked`, `failed` oder `awaiting_approval`. Sie erscheint im Tagesbericht.

| Grund | Was Rolf entscheiden muss |
|---|---|
| `context_unresolved` | richtiger Kontext |
| `ocr_quality_low` | erneut scannen oder verwerfen |
| `mandatory_field_missing` | Wert nachtragen |
| `low_confidence_actionable_field` | Wert bestätigen oder korrigieren |
| `deadline_uncertain` | Frist bestätigen |
| `amount_implausible` | Betrag korrigieren |
| `case_ambiguous` | Vorgang auswählen |
| `duplicate_suspected` | Dublette oder eigenständiges Dokument |
| `document_conflict` | welcher Wert gilt |
| `unknown_document_type` | Kategorie zuweisen |
| `tool_error` | technische Klärung |

### 15.2.1 Deterministischer Wiederanlauf nach der Klärung

„Setzt an der Stelle auf, an der sie angehalten wurde" ist für eine Umsetzung nicht ausreichend. Eine korrigierte OCR-Zahl darf nicht denselben Wiederanlauf erzeugen wie eine nachgetragene Vorgangszuordnung.

Der Prüfeintrag führt deshalb diese Pflichtangaben:

| Feld | Bedeutung |
|---|---|
| `blocked_stage` | Stufe, in der die Prüfung ausgelöst wurde |
| `resolution_type` | Art der Klärung |
| `outcome` | `resume` oder `terminal` |
| `resume_from_stage` | Stufe, ab der erneut verarbeitet wird; nur bei `resume` |
| `terminal_status` | Endzustand; nur bei `terminal` |
| `resolved_values` | von Rolf gesetzte oder bestätigte Werte; sie gelten als menschlich belegt und ersetzen die extrahierten |
| `resolved_at` | Zeitpunkt der Klärung |
| `resolved_by` | Entscheider |

Der Prüfeintrag trägt zusätzlich `outcome`. Es gibt genau zwei Ausgänge, und sie werden nicht vermischt:

| Ausgang | Bedeutung |
|---|---|
| `resume` | Die Verarbeitung wird ab `resume_from_stage` fortgesetzt. `terminal_status` ist unzulässig |
| `terminal` | Es findet **keine** weitere Verarbeitung statt. Der Datensatz erhält `terminal_status` und bleibt zur Nachvollziehbarkeit bestehen. `resume_from_stage` ist `null` |

Der Zusammenhang steht in `registry/review_resume_map.json` und wird bei jedem Testlauf gegen das Schema abgeglichen. Es gibt keine zweite Pflege.

**Neun fortzusetzende Klärungen**

| Klärungsart | Wiederanlauf ab | Warum |
|---|---|---|
| `value_corrected` | `analysis` | Ein korrigierter Wert verändert das Verständnis. OCR und Extraktion werden nicht wiederholt |
| `deadline_confirmed` | `task_derive` | Das Verständnis bleibt gültig, nur die Aufgabenableitung läuft erneut |
| `category_assigned` | `filing` | Es fehlte ausschliesslich das Ablageziel |
| `case_selected` | `task_derive` | Aufgaben werden mit dem richtigen Vorgangsbezug neu abgeleitet |
| `case_created` | `task_derive` | wie `case_selected`, mit neuem Vorgang |
| `duplicate_rejected` | `extraction` | Der Volltext liegt vor, die Auswertung beginnt bei der Extraktion |
| `rescan_provided` | `ocr` | Eine neue Vorlage ersetzt die unlesbare |
| `conflict_resolved` | `analysis` | Das Verständnis wird mit dem entschiedenen Wert neu gebildet |
| `technical_fixed` | `intake` | Bei einem technischen Fehler ist unklar, welche Stufe vollständig war; die Idempotenz verhindert Dubletten |

**Drei terminale Klärungen**

| Klärungsart | Endzustand | Warum kein Wiederanlauf |
|---|---|---|
| `duplicate_confirmed` | `duplicate` | Das Original ist bereits erfasst. Ein Wiederanlauf ab `intake` würde die bestätigte Dublette erneut durch die Kette schicken |
| `document_discarded` | `discarded` | Rolf hat das Dokument verworfen. Es wird nicht weiterverarbeitet |
| `context_corrected` | `misrouted` | siehe unten |

Vier Klärungsarten erfordern `resolved_values`: `value_corrected`, `deadline_confirmed`, `category_assigned`, `conflict_resolved`. Eine Klärung ohne die geforderten Werte wird abgewiesen.

### 15.2.2 Fehlgeleitete Dokumente

Ein Dokument im falschen Eingang ist kein Wiederanlauffall desselben Datensatzes. Der Kontext eines Datensatzes wird nach AR-1 nicht nachträglich geändert.

Verbindlicher Ablauf:

1. Der Datensatz im falschen Kontext wird **terminal** als `misrouted` abgeschlossen.
2. **JARVIS schreibt nicht in das andere Kontextschema.** Es gibt keinen automatischen kontextübergreifenden Schreibzugriff, auch nicht als Komfortfunktion.
3. Rolf legt das Original manuell in den richtigen Eingangsordner.
4. Dort entsteht über `source_binding` ein neuer Dokumentdatensatz mit eigener ID.
5. Der alte Datensatz darf höchstens über `successor_intake_hint` auf den erwarteten neuen Eingang verweisen, etwa `reintake:arbeitgeber_visolva/inbox`. Dieser Hinweis trägt keinen fachlichen Inhalt und nennt keine Dokument-ID des anderen Kontexts.
6. Ablage und Fachprotokoll bleiben strikt getrennt. Ein fehlgeleitetes Dokument erzeugt keine Aufgaben, keine Aktionen, keine Vorgangszuordnung und keine Ablage.

Das kostet einen manuellen Handgriff. Der Alternativweg — JARVIS verschiebt selbst — wäre genau der kontextübergreifende Schreibzugriff, den die Architektur seit Phase 0 ausschliesst.

Die Entscheidung wird im Fachprotokoll festgehalten und ist Grundlage für spätere Regelverbesserungen.

### 15.3 Eskalationsstufen

Nach Phase 0: `L0_retry`, `L1_exception_list`, `L2_notify`, `L3_halt`. In Phase 1 gilt zusätzlich:

- Eine Frist, die in weniger als 7 Tagen abläuft und zu einem Dokument in `needs_review` gehört, wird zu `L2_notify`.
- Fünf zurückgestellte Dokumente desselben Eingangsordners innerhalb einer Stunde deuten auf einen Konfigurationsfehler und lösen `L3_halt` für diesen Ordner aus.

---

## 16. Abnahmekriterien Phase 1

### 16.1 Aus dem Masterfahrplan

| Nr. | Kriterium | Zielwert | Messung |
|---|---|---|---|
| P1-A1 | Ablage ohne manuelle Umbenennung | ≥ 95 % | Anteil der Pilotdokumente |
| P1-A2 | Pflichtfelder korrekt | ≥ 90 % | Stichprobe gegen manuelle Referenz |
| P1-A3 | Keine übersehene Frist | 100 % | vollständiger Abgleich des Testkorpus |
| P1-A4 | Jede Aufgabe konkret, terminiert, zugeordnet | 100 % | Prüfung aller erzeugten Aufgaben |
| P1-A5 | Risikoarme Aufgaben automatisch abgeschlossen | ≥ 70 % | Anteil der Klasse-A-Aufgaben mit Nachweis |
| P1-A6 | Keine Aktion und keine Ablage im falschen Kontext | 0 Verstösse | Prüfung aller Protokolleinträge |
| P1-A7 | Jede Aktion mit Ergebnisnachweis | 100 % | Abgleich `action` gegen `evidence` |
| P1-A8 | Wiederholte Verarbeitung ohne Dubletten | 0 Dubletten | Wiederholungslauf über den Testkorpus |

### 16.2 Zusätzlich für Phase 1

| Nr. | Kriterium | Zielwert |
|---|---|---|
| P1-A9 | Kein Feldwert ohne Textbeleg | 0 Verstösse |
| P1-A10 | Kein `succeeded` ohne vertragskonformen Nachweis | 0 Verstösse |
| P1-A11 | Alle neun Freigabepunkte nachgewiesen | vollständig |
| P1-A12 | Widersprüche erzeugen Klärungsaufgaben statt stiller Auswahl | 100 % der Testfälle |
| P1-A13 | Anteil Dokumente in `needs_review` | ≤ 20 % im Pilot |
| P1-A14 | Kein Dokumentinhalt im gemeinsamen technischen Protokoll | 0 Verstösse, Stichprobe über alle Einträge |
| P1-A15 | Tagesbericht ist reproduzierbar und verändert keinen Bestand | nachgewiesen |
| P1-A16 | Jedes Original behält sein Format; die Endung stammt aus dem geprüften MIME-Typ | 0 Verstösse |
| P1-A17 | Jeder kanonische Wert ist aus dem Rohwert ableitbar und der Rohwert im Beleg auffindbar | 0 Verstösse |
| P1-A18 | Kein Positionsbetrag ohne Beleg oder Feldverweis | 0 Verstösse |
| P1-A19 | Jede geklärte Prüfung hat einen Wiederanlaufpunkt, der der Registry entspricht | 100 % |
| P1-A20 | Kein Werkzeug steht auf `approved`, bevor Adapter, Testlauf und Nachweis belegt sind | 0 Verstösse |
| P1-A21 | Kein unmögliches Kalenderdatum gelangt in eine Frist oder ein Feld | 0 Verstösse |
| P1-A22 | Kein Geldwert wird als Gleitkommazahl geführt oder gerechnet | 0 Verstösse |
| P1-A23 | Keine terminal abgeschlossene Klärung löst eine erneute Verarbeitung aus | 0 Verstösse |
| P1-A24 | Kein automatischer kontextübergreifender Schreibzugriff bei fehlgeleiteten Dokumenten | 0 Verstösse |

**Zu P1-A13:** Eine Prüfquote über 20 % bedeutet, dass das System mehr Arbeit erzeugt als abnimmt. Dann werden zuerst die Schwellwerte und Prompts überarbeitet, nicht der Pilot ausgeweitet.

---

## 17. Testfälle

Kennung `P1-T-nn`. Gegenproben sind mit **G** markiert: sie müssen fehlschlagen.

### 17.1 Normalablauf

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-01 | Digitales PDF, Versicherungsschreiben mit Police | Vollständig verarbeitet, Vorgang zugeordnet, abgelegt |
| P1-T-02 | Gescannter Behördenbrief mit Frist | Frist erkannt, Aufgabe mit Frist und Erfolgskriterium |
| P1-T-03 | Rechnung mit Tabelle | Positionen erfasst, Betrag und Fälligkeit korrekt |
| P1-T-04 | Smartphone-Foto, leicht schräg | OCR erfolgreich oder `unreadable` mit Aufgabe |
| P1-T-05 | Zweites Dokument zu bestehendem Vorgang | Über Policennummer zugeordnet, kein neuer Vorgang |
| P1-T-06 | Beitragsanpassung mit Vordokument | `changes_vs_previous` mit absoluter und prozentualer Abweichung |
| P1-T-07 | Mehrseitiger Vertrag | Alle Seiten erfasst, Vertragsnummer als Kennung übernommen |

### 17.2 Ausnahmen

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-08 | Dieselbe Datei zweimal eingelegt | Zweite als `duplicate`, keine zweite Aufgabe |
| P1-T-09 | Derselbe Brief zweimal gescannt | `duplicate_suspected`, `needs_review` |
| P1-T-10 | Unlesbarer Scan | `unreadable`, Aufgabe „erneut einscannen" |
| P1-T-11 | Passwortgeschütztes PDF | `quarantined` mit Grund |
| P1-T-12 | Datei über Grössengrenze | `quarantined` |
| P1-T-13 | Unbekannte Dokumentart | `needs_review`, keine Ablage |
| P1-T-14 | Zwei Vorgangskandidaten | `case_ambiguous`, Kandidatenliste |
| P1-T-15 | Widersprüchliche Beträge im Dokument | Klärungsaufgabe mit beiden Werten |
| P1-T-16 | Betrag widerspricht früherem Dokument | Klärungsaufgabe, keine stille Auswahl |
| P1-T-17 | Frist ausserhalb des Plausibilitätsfensters | `deadline_uncertain` |
| P1-T-18 | Dokument ohne erkennbare Handlung | Abgelegt, keine erfundene Aufgabe |

### 17.3 Kontext und Trennung

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-19 | Testdokument im Arbeitgeber-Eingang | Verarbeitung ausschliesslich im Arbeitgeberkontext |
| P1-T-20 | Privates Dokument im Arbeitgeber-Eingang | Aufgabe für Rolf, kein stiller Wechsel |
| **P1-T-21 G** | Schreibversuch in das fremde Fachprotokoll | Berechtigungsfehler |
| **P1-T-22 G** | Ablagepfad ausserhalb der Kontextwurzel | Abgewiesen |
| **P1-T-23 G** | Datensatz mit fremdem `context_id` | Prüfbedingung greift |

### 17.4 Freigabe

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-24 | Klasse-C-Testaktion, vollständige Freigabe | Ausgeführt, Nachweis vorhanden |
| **P1-T-25 G** | Ausführung ohne Freigabe | Verweigert |
| **P1-T-26 G** | Freigabelink zweimal verwendet | Zweite Verwendung abgewiesen |
| **P1-T-27 G** | Freigabe nach Ablauf | Abgewiesen, Aktion `expired` |
| **P1-T-28 G** | Inhalt nach Freigabe geändert | Fingerprint weicht ab, neue Freigabe nötig |
| **P1-T-29 G** | Nur Link geöffnet, nicht bestätigt | Keine Freigabe |
| **P1-T-30 G** | Freigabe im falschen Kontext eingelöst | Abgewiesen |
| P1-T-31 | Ablehnung durch Rolf | Aktion `rejected`, protokolliert |

### 17.5 Nachweis und Idempotenz

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-32 | Ablage erfolgreich | Readback bestätigt Pfad und Name |
| **P1-T-33 G** | Werkzeug meldet Erfolg, Datei fehlt am Ziel | `not_confirmed`, kein `succeeded`, Eskalation |
| P1-T-34 | Readback nicht eindeutig | `inconclusive`, Aktion bleibt `running` |
| P1-T-35 | Wiederanlauf nach Abbruch bei `extraction` | Beginnt bei Analyse, OCR wird nicht wiederholt |
| P1-T-36 | Netzwerkfehler beim Verschieben | Drei Versuche, Statusabgleich, kein zweites Verschieben |
| P1-T-37 | Neuverarbeitung mit neuer Analyseversion | Keine doppelten Aufgaben |
| **P1-T-38 G** | Modellantwort mit erfundenem Betrag, dessen Rohwert nicht im Beleg steht | Stufe 1 der Belegprüfung verwirft den Wert |
| **P1-T-39 G** | Modellausgabe verletzt das Schema | Abgewiesen, Retry, danach Ausnahme |
| P1-T-45 | Datum „1. Januar 2027" im Beleg | `raw_value` gefunden, `normalized_value` = `2027-01-01` |
| P1-T-46 | Betrag „1.234,50 EUR" im Beleg | Betrag `1234.50`, Währung `EUR` |
| P1-T-47 | Kennung „KV-4711 882" im Beleg | `kv4711882`, Vorgangszuordnung greift |
| **P1-T-48 G** | Manipuliertes `normalized_value`, nicht aus `raw_value` ableitbar | Stufe 2 verwirft den Wert |
| **P1-T-49 G** | Positionsbetrag ohne Beleg und ohne Feldverweis | Abgewiesen |
| **P1-T-50 G** | Positionsbetrag weicht vom eigenen Rohwert ab | Abgewiesen |
| P1-T-51 | Smartphone-Foto wird abgelegt | Zieldatei endet auf `.jpg`, Original unverändert |
| **P1-T-52 G** | Zieldateiname `.pdf` bei MIME-Typ `image/jpeg` | Ablage abgewiesen |
| **P1-T-53 G** | Dokument mit MIME-Typ ausserhalb der erlaubten Formate | `quarantined`, keine Ablage |
| P1-T-54 | Klärung `deadline_confirmed` | Wiederanlauf ab `task_derive`, OCR und Extraktion laufen nicht erneut |
| P1-T-55 | Klärung `rescan_provided` | Wiederanlauf ab `ocr` |
| **P1-T-56 G** | Klärung mit Wiederanlaufpunkt, der der Registry widerspricht | Abgewiesen |
| **P1-T-57 G** | Wertkorrektur ohne korrigierte Werte | Abgewiesen |
| **P1-T-58 G** | Werkzeug auf `approved` ohne erbrachten Nachweis | Abgewiesen |
| P1-T-59 | Datum `29.02.2024` im Beleg | `2024-02-29` |
| **P1-T-60 G** | Datum `31.02.2026` im Beleg | Abgewiesen, kein gültiges Kalenderdatum |
| **P1-T-61 G** | Datum `29.02.2023` im Beleg | Abgewiesen |
| **P1-T-62 G** | Uhrzeit `25:00` in einem Zeitstempel | Abgewiesen |
| P1-T-63 | Betrag `1.234,50 EUR` | `"1234.50"` als Zeichenfolge, Währung `EUR` getrennt |
| P1-T-64 | Summe zweier Beiträge `0,10` und `0,20` | `"0.30"`, gerechnet mit `Decimal` |
| **P1-T-65 G** | Geldwert als Gleitkommazahl im Extraktionsergebnis | Abgewiesen |
| **P1-T-66 G** | Geldwert in Exponentialschreibweise | Abgewiesen |
| P1-T-67 | Bestätigte Dublette | Terminal, keine weitere Verarbeitung, keine zweite Aufgabe |
| P1-T-68 | Verworfenes Dokument | Terminal, Status `discarded` |
| P1-T-69 | Fehlgeleitetes Dokument | Terminal, Status `misrouted`, kein Schreibzugriff im anderen Kontext |
| **P1-T-70 G** | Terminale Klärung mit gesetztem Wiederanlaufpunkt | Abgewiesen |
| **P1-T-71 G** | Fortzusetzende Klärung ohne Wiederanlaufpunkt | Abgewiesen |
| **P1-T-72 G** | Fehlgeleitetes Dokument erzeugt Aufgaben oder Ablage | Abgewiesen |

### 17.6 Betrieb

| ID | Fall | Erwartung |
|---|---|---|
| P1-T-40 | Tagesbericht zweimal erzeugt | Aufgabenbestand unverändert |
| P1-T-41 | Fehlermeldung mit Zugangsdaten | `message_safe` bereinigt |
| **P1-T-42 G** | Dokumentinhalt gelangt in `jarvis_ops` | Keine Spalte nimmt ihn auf |
| P1-T-43 | Export und Wiederherstellung aller Workflows | Vollständig lauffähig |
| P1-T-44 | Kategorie-Mapping geändert | Nur Konfiguration, kein Workflow-Eingriff |

---

## 18. Phase 1.5 — Pilotbetrieb und Phase-Gate

### 18.1 Testkorpus

**Vor dem Pilot:** 20 repräsentative Dokumente für die OCR-Auswahl und den Modellbenchmark, manuell mit Referenzwerten versehen. Diese 20 Dokumente sind die Messlatte für alle späteren Änderungen an Prompts und Modellen.

**Pilot:** 50 bis 100 neue Versicherungs- und Behördenunterlagen im Kontext `privat`, wie im Masterfahrplan §1.6 festgelegt. **Keine Migration des Altbestands.**

**Arbeitgeberkontext:** 10 synthetische Testdokumente, ausschliesslich für die Trennungsnachweise.

### 18.2 Ablauf

| Woche | Inhalt |
|---|---|
| 1 | Schattenbetrieb: alles wird verarbeitet, aber nichts abgelegt. Vergleich der Vorschläge mit manueller Bearbeitung |
| 2 | Ablage aktiv, Klasse A aktiv, Klasse C nur Testwerkzeug |
| 3 | Vollbetrieb, wöchentliche Messung |
| 4 | Auswertung, Schwellwerte nachjustieren, Phase-Gate |

Der Schattenbetrieb in Woche 1 ist verbindlich. Er kostet eine Woche und verhindert, dass eine fehlerhafte Ablageregel 50 Dokumente falsch einsortiert.

### 18.3 Wöchentliche Messung

Feldqualität je Pflichtfeld, Fristerkennungsquote, Automationsquote, Prüfquote, Fehlerquote je Werkzeug, mittlere Laufzeit und Kosten je Dokument, geschätzte Zeitersparnis.

### 18.4 Phase-Gate Phase 1

Phase 1 gilt als abgeschlossen, wenn:

| Nr. | Kriterium |
|---|---|
| G1 | Alle Abnahmekriterien P1-A1 bis P1-A15 erfüllt und belegt |
| G2 | Alle Testfälle P1-T-01 bis P1-T-72 ausgeführt, alle Gegenproben schlagen fehl wie erwartet |
| G3 | Phase-1.0-Gate geschlossen, damit auch das Phase-0-Gate |
| G4 | Fehler- und Ausnahmewege getestet, nicht nur der Normalablauf |
| G5 | Dokumentation entspricht dem tatsächlichen Stand |
| G6 | Export und Wiederherstellung aller Workflows geprüft |
| G7 | Offene technische Schulden dokumentiert |
| G8 | Übergabedatei für Phase 2 vorhanden |
| G9 | Pilotbericht mit Feldqualität, Automationsquote, Prüfquote und Fehlern liegt vor |

---

## 19. Was Phase 1 bewusst nicht löst

Damit später niemand eine Lücke für ein Versehen hält:

| Punkt | Begründung | Vorgesehen für |
|---|---|---|
| Kein E-Mail-Eingang | Zuschnitt | Phase 2 |
| Keine Kalendereinträge | Zuschnitt | Phase 2 |
| Klasse B ohne produktives Werkzeug | keine Aussenwirkung in Phase 1 | Phase 2 |
| Keine Suche über den Bestand | Bestand wird aufgebaut, Oberfläche fehlt | Phase 4 |
| Keine Ähnlichkeitszuordnung von Vorgängen | erzeugt falsche Verknüpfungen | Phase 4, mit Gedächtnis |
| Keine Arbeitgeber-Dokumentkategorien | Entscheidung P1-B2 | eigener Arbeitgeber-Pilot |
| Kein Altbestand | Masterfahrplan §1.6 | selektiv nach Phase 1 |
| Keine Oberfläche | Tagesbericht als Datei genügt | Phase 6 |

---

## Anhang A — Artefakte dieser Spezifikation

| Datei | Inhalt |
|---|---|
| `SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.md` | dieses Dokument |
| `CHANGELOG_V3_ZU_V4.md` | Änderungen gegenüber Version 3 |
| `UMSETZUNGS_UND_TESTPLAN.md` | Schrittfolge, Aufwand, Testreihenfolge |
| `OPEN_DECISIONS_PHASE_1.md` | offene Entscheidungen mit spätestem Zeitpunkt |
| `HANDOVER_PHASE_1_SPEC_2026-08-29.md` | Übergabe an den Implementierungs-Chat |
| `schemas/document.schema.json` | Dokumentregister |
| `schemas/case.schema.json` | Vorgang |
| `schemas/extraction_result.schema.json` | Extraktionsergebnis |
| `schemas/document_analysis.schema.json` | Dokumentverständnis |
| `schemas/tools/*.json` | vierzehn Ein- und Ausgabeverträge der Werkzeuge |
| `registry/tool_registry_phase1.json` | neun neue Werkzeugverträge |
| `registry/normalization_rules.json` | zwölf registrierte Normalisierungsregeln mit Beispielen |
| `registry/review_resume_map.json` | Wiederanlaufpunkt je Klärungsart |
| `registry/tool_release_plan.json` | Freigabeplan der zwölf verwendeten Werkzeuge |
| `examples/*.json` | sieben validierte Beispieldatensätze |
| `tools/normalization_reference.py` | Referenz für Belegprüfung, Normalisierung und Dateiendung |
| `tools/validate_phase1.py` | Prüfung gegen die Phase-0-Verträge |
| `README.md` | Einstieg, Prüfaufruf, Abhängigkeiten |
| `CHANGELOG_V4.0_ZU_V4.0.1.md` | Korrekturen K1 bis K6 |
| `CHANGELOG_V4.0.1_ZU_V4.0.2.md` | Korrekturen K7 bis K9 |

**Nachweisstand:** 108 Prüfungen ausgeführt am 29.08.2026 aus einer frisch entpackten Kopie des
Archivs gegen das unveränderte Phase-0-Paket 1.1.0, alle bestanden. Reproduzierbar mit
`python3 tools/validate_phase1.py --phase0 <pfad_zum_phase0_paket>`.
