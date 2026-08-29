# HANDOVER_PHASE_1_SPEC_2026-08-29

**Modul:** Phase 1 — KI-Dokumentenassistent, Spezifikationsphase
**Paketversion:** 4.0.2
**Erstellt:** 29. August 2026
**Vorgänger:** Phase-0-Paket 1.1.0, `HANDOVER_PHASE_0_2026-08-29.md`
**Nachfolger:** Implementierungs-Chat, beginnend mit Schritt 1.0

---

## 1. Ziel des Moduls

Die bestehende Spezifikation „KI-Dokumentenassistent Version 3" wurde zur umsetzbaren Phase-1-Spezifikation Version 4.0.2 überarbeitet und technisch eindeutig an die Phase-0-Verträge gebunden.

**Status:** Spezifikation vollständig, umsetzungsbereit nach Freigabe. Keine Datenbank eingerichtet, kein Workflow gebaut, kein Dienst konfiguriert.

---

## 2. Verbindliche Entscheidungen

### 2.1 Von Rolf für Phase 1 freigegeben

| Nr. | Entscheidung |
|---|---|
| P1-B1 | Greenfield-Neubau auf den Phase-0-Verträgen. Ältere n8n-Workflows nur als Referenz, kein schrittweiser Umbau |
| P1-B1b | Kein vorgegebener OCR-Dienst. Austauschbarer Vertrag, Auswahl in 1.1 über einen Test mit rund 20 Dokumenten und einem gewichteten Bewertungsraster |
| P1-B2 | `privat` ist produktiv. `arbeitgeber_visolva` wird technisch vollständig eingerichtet und verarbeitet nur synthetische Testdokumente. A-3 wird trotzdem vollständig nachgewiesen |
| P1-B3 | Zweistufiger Klasse-C-Freigabeweg wird in Phase 1 gebaut und über `test.record_approved_action` nachgewiesen. Keine echte Datei wird zu Testzwecken gefährdet. Neun Nachweispunkte |
| P1-B4 | Keine Modellversion festgeschrieben. Drei Rollen: `extraction_model`, `reasoning_model`, `drafting_model`. IDs nur in der Konfiguration. Benchmark vor dem Pilot. Kosten sind Messgrösse, kein Ausschlusskriterium |
| P1-B5 | `tasks_internal` ist führende Aufgabenquelle. Kein externes Aufgabensystem. Zusätzlich ein täglicher Bericht als abgeleitete Ansicht, die nie führend ist |

### 2.2 Aus Phase 0 unverändert gültig

B1 bis B5, D1, D2, D3 in der geänderten Fassung, D4, D5, D6, D8, D9. Kontexte `privat` und `arbeitgeber_visolva`. Klassen A, B, C. Zweistufige Freigabe. Nachweis nach Werkzeugvertrag. Trennung von Dokumentablage und Fachprotokoll je Kontext.

### 2.3 In dieser Spezifikation zusätzlich festgelegt

| Nr. | Entscheidung | Begründung |
|---|---|---|
| P1-D1 | Je Kontext ein eigener Eingangsordner. Kontextauflösung immer `source_binding`, nie Modellvorschlag | Ein Modellvorschlag reicht nach Phase-0-Regel für schreibende Aktionen nicht aus |
| P1-D2 | Ein falsch eingelegtes Dokument wird nicht still umgeleitet, sondern erzeugt eine Aufgabe | Stiller Kontextwechsel ist der schwerwiegendste mögliche Fehler |
| P1-D3 | Vorgangszuordnung ausschliesslich über normalisierte stabile Kennungen. Keine Ähnlichkeitszuordnung in Phase 1 | Ein zusätzlicher Vorgang ist billiger als eine falsche Verknüpfung |
| P1-D4 | Zweistufige Dublettenerkennung: `content_hash` harter Stopp, `text_fingerprint` Verdacht mit manueller Entscheidung | Zwei Scans desselben Briefes haben verschiedene Bytes |
| P1-D5 | Kein Feldwert ohne Textbeleg; bei Datums-, Betrags- und Kennungsfeldern wird geprüft, ob der Wert im Belegtext vorkommt | Wirksamste verfügbare Massnahme gegen erfundene Werte |
| P1-D6 | Fristen werden nie wegen niedriger Konfidenz verworfen, sondern zur Bestätigung vorgelegt | Das Risiko ist asymmetrisch |
| P1-D7 | Vorgangsnummer `V-JJJJ-NNNN` je Kontext und Jahr, Bestandteil des Dateinamens | Zusammengehörigkeit ohne System erkennbar |
| P1-D8 | Extraktion und Verständnis sind zwei getrennte Modellaufrufe | Unterschiedliche Anforderungen; getrennte Fehlersuche |
| P1-D9 | Schattenbetrieb in der ersten Pilotwoche ist verbindlich | Verhindert, dass eine fehlerhafte Regel 50 Dokumente falsch einsortiert |
| P1-D10 | Prüfquote über 20 % führt zur Überarbeitung von Schwellwerten und Prompts, nicht zur Ausweitung des Pilots | Sonst erzeugt das System mehr Arbeit, als es abnimmt |
| P1-D11 | Die Dateiendung wird aus dem geprüften MIME-Typ abgeleitet, nie aus dem alten Dateinamen. Originale werden nicht konvertiert | Version 4.0 hatte `.pdf` festgeschrieben und damit den erlaubten Bildformaten widersprochen |
| P1-D12 | Belegprüfung in zwei Stufen über `raw_value` und `normalized_value` mit registrierter Normalisierungsregel | Die frühere Regel hätte korrekt normalisierte Werte verworfen |
| P1-D13 | Ein Werkzeug wechselt erst nach Vertrag, Adapter, Testlauf und Nachweis auf `approved`; die Zuordnung zur Teilphase steht in `registry/tool_release_plan.json` | Ein Werkzeug ohne ausgewählten Adapter kann nicht geprüft und damit nicht freigegeben sein |
| P1-D14 | Datums- und Zeitwerte werden gegen das gregorianische Kalendermodell geprüft, nicht gegen Wertebereiche | Eine Bereichsprüfung lässt den 31. Februar und den 29. Februar eines Nicht-Schaltjahrs durch |
| P1-D15 | Geldwerte sind kanonische Zeichenfolgen mit zwei Nachkommastellen; gerechnet wird mit `Decimal` beziehungsweise `NUMERIC`, niemals mit `float` | Gleitkommaarithmetik ist für Beiträge, Rechnungen und Fristen mit Geldwirkung nicht zulässig |
| P1-D16 | Eine Klärung hat entweder einen Wiederanlaufpunkt oder einen Endzustand, nie beides | Sonst würden bestätigte Dubletten und verworfene Dokumente erneut verarbeitet |
| P1-D17 | Ein fehlgeleitetes Dokument wird terminal als `misrouted` abgeschlossen; JARVIS schreibt nicht in das andere Kontextschema, Rolf legt das Original manuell neu ein | Ein automatischer Kontextwechsel wäre der kontextübergreifende Schreibzugriff, den die Architektur seit Phase 0 ausschliesst |

---

## 3. Umgesetzte Komponenten

| Komponente | Zustand |
|---|---|
| Spezifikation Version 4.0 | fertig |
| Änderungsprotokoll gegenüber Version 3 | fertig |
| Umsetzungs- und Testplan für 1.0 bis 1.5 | fertig |
| Offene Entscheidungen mit spätestem Zeitpunkt | fertig |
| Vier Phase-1-Schemata | fertig, validiert |
| Vierzehn Ein- und Ausgabeverträge unter `schemas/tools/` | fertig, vollständig auflösbar |
| Neun neue Werkzeugverträge | fertig, gegen das Phase-0-Registerschema validiert, alle Status `draft` |
| Drei Registrierungen: Normalisierungsregeln, Klärungsausgänge, Freigabeplan | fertig, geprüft |
| Referenzimplementierung für Belegprüfung, Kalender, Geldwerte und Dateiendung | fertig, 37 Regelbeispiele und 12 Ablehnungsfälle geprüft |
| Sieben Beispieldatensätze | fertig, validiert |
| Validierungsskript gegen die Phase-0-Verträge | fertig, **108 Prüfungen bestanden** |

**Nicht umgesetzt und ausdrücklich nicht Bestandteil:** Datenbank, Workflows, OCR-Anbindung, Modellanbindung, Prompts, Konfigurationsdateien mit echten Werten.

---

## 4. Dateien

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
├── schemas/
│   ├── document.schema.json
│   ├── case.schema.json
│   ├── extraction_result.schema.json
│   ├── document_analysis.schema.json
│   └── tools/            (14 Ein- und Ausgabevertraege)
├── registry/
│   ├── tool_registry_phase1.json
│   ├── normalization_rules.json
│   ├── review_resume_map.json
│   └── tool_release_plan.json
├── examples/             (7 Beispieldatensaetze)
└── tools/
    ├── normalization_reference.py
    └── validate_phase1.py
```

Die Verzeichnisstruktur ist Teil des Vertrags: Das Prüfskript löst seine Pfade
relativ zum Wurzelverzeichnis auf. Das Phase-0-Paket wird nicht dupliziert und
über `--phase0` übergeben.

**Workflow-Namen:** noch keine gebaut. Fünf Hauptworkflows und zehn Sub-Workflows sind in Spezifikation Abschnitt 13 benannt und vertraglich festgelegt.

---

## 5. Datenmodelle und Schnittstellen

- Vier neue Schemata, die ausschliesslich Phase-0-Definitionen referenzieren. Aufgaben und Aktionen werden über IDs verwiesen, nicht eingebettet.
- Neun neue Werkzeugverträge, keine Doppelpflege mit dem Phase-0-Register.
- Ereigniskatalog additiv um neun Dokumentereignisse erweitert; keine Schemaänderung nötig, da `event_type` gegen ein Muster prüft.
- Kontextkonfiguration erhält je Kontext den Block `document_settings` mit ausschliesslich `env:`-Verweisen.
- Idempotenz auf drei Ebenen: Datei, Aktion, Verarbeitungsschritt.

---

## 6. Zugangsvoraussetzungen

Für Schritt 1.0 erforderlich, ohne Angabe von Zugangsdaten:

- verwaltete PostgreSQL-Instanz mit administrativem Benutzer (P1-O1),
- n8n-Instanz mit Rechten für Credentials und Umgebungsvariablen,
- erreichbarer Bestätigungsendpunkt oder ein Ersatzadapter (P1-O2),
- privates Git-Repository (P1-O7),
- je Kontext: Eingangs-, Arbeits-, Archiv-, Entwurfs- und Berichtsordner,
- Zugang zu einem OCR-Dienst für den Vergleichstest (P1-O3),
- Modellzugang für die drei Rollen (P1-O4).

**Keine Zugangsdaten in Dokumenten, Prompts oder Übergabedateien.**

---

## 7. Ausgeführte Tests

Ausgeführt am 29.08.2026 mit `python3 tools/validate_phase1.py --phase0 <pfad>`:

Ausgeführt aus einer frisch entpackten Kopie des Archivs `jarvis-phase-1-v4.0.2.zip`
gegen das unveränderte Phase-0-Paket Version 1.1.0.

| Teil | Umfang | Ergebnis |
|---|---|---|
| 1 Schemata gültig, nur interne Verweise | 4 | bestanden |
| 2 Beispieldatensätze gegen ihre Schemata | 7 | bestanden |
| 3 Werkzeugregister, keine Doppelpflege | 3 | bestanden |
| 4 Werkzeugverträge vorhanden, gültig, auflösbar, `$id` eindeutig | 2 | bestanden |
| 5 Normalisierungsregeln, Kalenderablehnungen, Decimal-Rechenprobe | 15 | bestanden |
| 6 Vertragsregeln V1 bis V17 | 17 | bestanden |
| 7 Freigabeplan der Werkzeuge | 4 | bestanden |
| 8 Gegenproben G01 bis G56 | 56 | alle korrekt abgewiesen |
| **Gesamt** | **108** | **alle bestanden** |

Nachgewiesen ist damit: keine Parallelmodelle, konsistente Kontexte über Dokument, Vorgang, Extraktion und Analyse, wechselseitige Verweise, Vorgangsnummer im Dateinamen, belegte Aufgabenvorschläge, vertragskonforme Nachweisstrategien, genau ein Klasse-C-Werkzeug, kein Werkzeug mit Aussenwirkung, vollständig auflösbare Werkzeugverträge, zweistufige Belegprüfung für Felder und Tabellenpositionen, Dateiendung aus dem geprüften MIME-Typ, deterministischer Wiederanlauf und kein vorzeitig freigegebenes Werkzeug, Abweisung unmöglicher Kalenderdaten, Geldwerte ausschliesslich als kanonische Zeichenfolgen und terminale Klärungen ohne Wiederanlauf.

**Nicht getestet:** alles, was eine Datenbank, n8n, einen OCR-Dienst oder ein Modell voraussetzt. Das sind die 72 Testfälle P1-T-01 bis P1-T-72 aus der Spezifikation.

---

## 8. Bekannte Fehler

Keine.

---

## 9. Technische Schulden

| Nr. | Schuld | Auswirkung |
|---|---|---|
| P1-TS1 | Fehlende Vertragsschemata | **geschlossen** in Version 4.0.1: alle vierzehn Dateien liegen unter `schemas/tools/` und werden bei jedem Lauf auf Existenz, Gültigkeit und Auflösbarkeit geprüft |
| P1-TS2 | Feldkatalog, Dokumentartenliste und Kategorie-Mapping sind in der Spezifikation beschrieben, aber noch keine Konfigurationsdateien | offen, Schritt 1.2.1 und 1.2.2 |
| P1-TS3 | Klasse B hat in Phase 1 kein produktives Werkzeug | bewusst offen. Der Meldeweg wird erst in Phase 2 scharf geschaltet; der Mechanismus ist vollständig spezifiziert |
| P1-TS4 | Aus Phase 0 offen: TS-2 (praktischer Nachweis A-3, A-4), TS-3 (kein Werkzeug im Status `approved`), TS-7 (kein maschinenlesbares Agentenregister), TS-8 (nachgelagerter Abgleich nicht implementiert) | TS-2 schliesst in Schritt 1.0, TS-3 gestaffelt über 1.0 bis 1.4 nach dem Freigabeplan. TS-7 und TS-8 bleiben offen |
| P1-TS5 | Die Verbotsliste vager Aufgabenformulierungen ist als Regel beschrieben, aber noch nicht als Prüfliste ausformuliert | offen, Schritt 1.3.1 |
| P1-TS6 | Die Normalisierungsregeln decken deutsche, schweizerische und englische Schreibweisen ab. Weitere Sprachen und Formate, etwa französische Datumsangaben, fehlen | offen, nicht blockierend. Ergänzung ist ein Registryeintrag plus Funktion, kein Eingriff in die Prozesslogik |
| P1-TS7 | Für nicht monetäre Dezimalwerte, etwa Mengen mit Nachkommastellen oder Prozentsätze, gibt es noch keine registrierte Regel. `quantity` ist derzeit ganzzahlig | offen, nicht blockierend. Wird bei Bedarf als eigene Regel mit eigenem Datentyp ergänzt und nicht über die Geldregeln improvisiert |

---

## 10. Offene Entscheidungen

Zehn Punkte in `OPEN_DECISIONS_PHASE_1.md`, jeweils mit Empfehlung und spätestem Zeitpunkt.

**Vor dem ersten Bauschritt zu klären:** P1-O1 (PostgreSQL-Anbieter), P1-O7 (Git-Repository), P1-O5 (Eingangskanäle).
**Vor Schritt 1.3:** P1-O2 (Freigabeadapter), P1-O10 (Dokumente ohne Handlungsbedarf).
**Innerhalb der Umsetzung:** P1-O3 (OCR), P1-O4 (Modelle), P1-O6 (Kategorien).
**Später:** P1-O8 (Aufbewahrung), P1-O9 (Altbestand).

---

## 11. Exakter nächster Bauschritt

**Schritt 1.0.1 bis 1.0.8 aus dem Umsetzungsplan: das Phase-0-Fundament in Betrieb nehmen.**

Reihenfolge:

1. Spezifikation Version 4.0 freigeben.
2. P1-O1, P1-O5 und P1-O7 entscheiden.
3. PostgreSQL bereitstellen, `002_ops_schema.sql` einspielen.
4. Je Kontext über `tools/render_context_schema.py` aus dem Phase-0-Paket rendern und einspielen.
5. Datenbankbenutzer anlegen, gegenseitige Entzüge ausführen.
6. Phase-1-Tabellen nach Spezifikation 7.2 anlegen.
7. Neun Kern-Sub-Workflows bauen.
8. Nachweise A-3 und A-4 führen. Damit schliesst das Phase-0-Gate.

**Vor Schritt 3 wird nichts eingerichtet.**

**Für den Implementierungs-Chat mitgeben:** Masterfahrplan, Phase-0-Paket 1.1.0 vollständig, das Phase-1-Paket 4.0.2 vollständig (39 Dateien), insbesondere diese Übergabedatei, die Spezifikation, den Umsetzungsplan sowie die Verzeichnisse `schemas/`, `registry/` und `tools/`.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
