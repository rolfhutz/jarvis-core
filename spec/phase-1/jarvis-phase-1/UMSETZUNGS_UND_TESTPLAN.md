# JARVIS Phase 1 — Umsetzungs- und Testplan

**Version 1.2 - 29. August 2026**
**Gilt nach Freigabe der Spezifikation Version 4.0.2**

Der Plan ist so geschnitten, dass nach jedem Schritt etwas Überprüfbares vorliegt. Kein Schritt beginnt, bevor der vorherige abgenommen ist.

---

## Übersicht

| Schritt | Inhalt | Richtwert | Ergebnis |
|---|---|---|---|
| 1.0 | Fundament aktivieren, A-3 und A-4 nachweisen | 1 Woche | Phase-0-Gate geschlossen |
| 1.1 | Eingang, Prüfung, OCR, Dubletten | 1,5 Wochen | Dokumente werden erfasst |
| 1.2 | Extraktion, Verständnis, Vorgang | 2 Wochen | Dokumente werden verstanden |
| 1.3 | Aufgaben, Aktionen, Freigabe | 1,5 Wochen | Arbeit wird abgeleitet |
| 1.4 | Ausführung, Nachweis, Ablage, Bericht | 1,5 Wochen | Dokumente werden abgelegt |
| 1.5 | Pilot und Phase-Gate | 4 Wochen | Betriebsfreigabe |
| | **Gesamt** | **11,5 Wochen** | |

Der Masterfahrplan nennt 4 bis 8 Wochen bis zum stabilen Pilotbetrieb. Der Unterschied entsteht durch Phase 1.0, die im Masterfahrplan noch Phase 0 zugerechnet war, und durch den vierwöchigen Pilot. Die reine Bauzeit bis Pilotbeginn beträgt 7,5 Wochen.

---

## Schritt 1.0 — Fundament aktivieren

**Voraussetzungen:** Entscheidungen P1-O1 (PostgreSQL-Anbieter) und P1-O7 (Git-Ablage) getroffen.

| Nr. | Arbeit | Ergebnis |
|---|---|---|
| 1.0.1 | PostgreSQL bereitstellen, Zugang in n8n-Credentials hinterlegen | erreichbare Instanz |
| 1.0.2 | `002_ops_schema.sql` einspielen | gemeinsames Technikschema |
| 1.0.3 | Je Kontext rendern und einspielen: `001` und `003` | zwei Kontextschemata |
| 1.0.4 | Datenbankbenutzer anlegen, gegenseitige Entzüge ausführen | getrennte Rechte |
| 1.0.5 | Phase-1-Tabellen anlegen (Spezifikation 7.2) | Dokument-, Vorgangs- und Analysetabellen |
| 1.0.6 | Kern-Sub-Workflows bauen | neun wiederverwendbare Bausteine |
| 1.0.7 | Kontextregister befüllen | `jarvis_ops.context_registry` |
| 1.0.8 | Werkzeugfreigabe nach den fuenf Bedingungen aus Spezifikation 12.1.1: nur `docstore_internal.upsert_document`, `casestore_internal.upsert_case` und `tasks_internal.create_task`, und erst nach erfolgreichem Lauf mit Nachweis | drei Werkzeuge auf `approved` |

**Zur Freigabe:** OCR-, Modell- und Freigabewerkzeuge werden in 1.0 ausdruecklich **nicht** freigegeben. Ihr Adapter steht zu diesem Zeitpunkt nicht fest. Der Freigabeplan in `registry/tool_release_plan.json` ist verbindlich; der Prueflauf weist nach, dass kein Werkzeug vor seinem Nachweis auf `approved` steht.

**Tests**

| Test | Erwartung |
|---|---|
| 1.0-A1 bis A8 aus der Spezifikation | alle erfüllt |
| Phase-0-Testfälle K-01 bis K-08 | alle erfüllt |
| Phase-0-Testfälle I-01 bis I-05 | alle erfüllt |
| P1-T-21, P1-T-22, P1-T-23 (Gegenproben) | schlagen fehl wie erwartet |

**Abnahme:** Phase-1.0-Gate. Damit schliesst auch das Phase-0-Gate. Ergebnis wird als Nachweisdokument abgelegt.

---

## Schritt 1.1 — Eingang und Normalisierung

**Voraussetzungen:** 1.0 abgenommen. Eingangs-, Arbeits-, Archiv-, Entwurfs- und Berichtsordner je Kontext eingerichtet.

| Nr. | Arbeit | Ergebnis |
|---|---|---|
| 1.1.1 | 20 repräsentative Testdokumente sammeln und manuell mit Referenzwerten versehen | Messlatte für alle späteren Änderungen |
| 1.1.2 | OCR-Kandidaten anbinden und nach dem Raster aus 8.5 bewerten; Ausschluss jedes Dienstes ohne Positionsbezug je Block | Auswahlentscheidung dokumentiert |
| 1.1.3 | `storage_gdrive.get_file` und Eingangsprüfung bauen | `JV-P1-SUB-document_normalize-v1` |
| 1.1.4 | Hashbildung und zweistufige Dublettenerkennung | harter Stopp und Verdachtsfall |
| 1.1.5 | OCR-Adapter und Qualitätsregeln | `JV-P1-SUB-document_ocr-v1` |
| 1.1.6 | Hauptworkflow mit Zeitplan je Kontext | `JV-P1-MAIN-document_intake-v1` |
| 1.1.7 | Dokumentregister schreiben und lesen | `docstore_internal.upsert_document` |
| 1.1.8 | Freigabe von `storage_gdrive.get_file` und `ocr_default.analyze_document` nach erfolgreichem Lauf mit Nachweis | zwei Werkzeuge auf `approved` |

**Tests**

| Test | Inhalt |
|---|---|
| P1-T-01 bis P1-T-04 | Normalablauf über die vier Dateiarten |
| P1-T-08 bis P1-T-12 | Dubletten, unlesbar, geschützt, zu gross |
| P1-T-19, P1-T-20 | Kontexttrennung im Eingang |
| 1.1-A1 bis A7 | Abnahmekriterien der Teilphase |

**Abnahme:** Alle 20 Testdokumente sind mit Volltext und Qualitätswerten erfasst. Die OCR-Auswahl ist begründet dokumentiert.

---

## Schritt 1.2 — Dokumentverständnis

**Voraussetzungen:** 1.1 abgenommen. Modellzugänge in der Konfiguration hinterlegt.

| Nr. | Arbeit | Ergebnis |
|---|---|---|
| 1.2.1 | Feldkatalog und Dokumentartenliste als versionierte Konfiguration | `config/field_catalog.json`, `config/document_types.json` |
| 1.2.2 | Kategorie-Mapping je Kontext | `config/category_map_privat.json` |
| 1.2.3 | Extraktionsprompt gegen die 20 Testdokumente entwickeln | `extract_fields@1.0.0` |
| 1.2.4 | Deterministische Feldvalidierung: Schwellwerte, zweistufige Belegprüfung nach 9.4.1, Plausibilität. Referenz ist `tools/normalization_reference.py`; die Regelbeispiele muessen reproduzierbar bleiben | Regelmodul, versioniert |
| 1.2.5 | Analyseprompt entwickeln | `analyze_document@1.0.0` |
| 1.2.6 | Vorgangszuordnung über Kennungen, Nummernvergabe | `JV-P1-SUB-case_match-v1` |
| 1.2.7 | Dokumentvergleich mit Vordokumenten | `changes_vs_previous` |
| 1.2.8 | Modellbenchmark für die drei Rollen | Benchmarkbericht |
| 1.2.9 | Freigabe der beiden Modellwerkzeuge nach dem Benchmark | zwei Werkzeuge auf `approved` |

**Tests**

| Test | Inhalt |
|---|---|
| P1-T-05 bis P1-T-07 | Vorgangszuordnung, Vergleich, mehrseitige Dokumente |
| P1-T-13 bis P1-T-18 | unbekannte Art, mehrdeutiger Vorgang, Widersprüche, unplausible Frist, Dokument ohne Handlungsbedarf |
| P1-T-38, P1-T-39 | Gegenproben gegen Halluzination und Schemaverstoss |
| P1-T-45 bis P1-T-47 | Positive Belegpruefung: Datum, Betrag mit Waehrung, Kennung mit Trennzeichen |
| P1-T-59 bis P1-T-62 | Kalenderpruefung: gueltiger Schalttag, 31. Februar, 29. Februar im Nicht-Schaltjahr, unmoegliche Uhrzeit |
| P1-T-63 bis P1-T-66 | Geldwerte: kanonische Zeichenfolge, Decimal-Rechenprobe, Gleitkommazahl und Exponentialschreibweise als Gegenproben |
| P1-T-48 bis P1-T-50 | Gegenproben: manipulierter kanonischer Wert, Positionsbetrag ohne Beleg, abweichender Positionsbetrag |
| 1.2-A1 bis A7 | Abnahmekriterien der Teilphase |

**Besonderheit:** Für P1-T-38 wird ein Modellergebnis eingespeist, dessen `raw_value` im Belegtext nicht vorkommt; Stufe 1 muss es verwerfen. Für P1-T-48 wird ein `normalized_value` manipuliert, das sich nicht aus `raw_value` ableiten lässt; Stufe 2 muss es verwerfen. Ohne beide Nachweise gilt 1.2 nicht als abgenommen.

**Abnahme:** ≥ 90 % Pflichtfelder korrekt, 100 % Fristen erkannt, kein Wert ohne Beleg.

---

## Schritt 1.3 — Aufgaben, Aktionen, Freigabe

**Voraussetzungen:** 1.2 abgenommen. Entscheidung P1-O2 zum Freigabeadapter getroffen.

| Nr. | Arbeit | Ergebnis |
|---|---|---|
| 1.3.1 | Prüfregeln für Aufgabenvorschläge | `JV-P1-SUB-task_derive-v1` |
| 1.3.2 | Aufgaben anlegen mit Idempotenz | `tasks_internal.create_task` produktiv |
| 1.3.3 | Aktionsplanung mit Eingabenprüfung | `JV-P1-SUB-action_plan-v1` |
| 1.3.4 | Klassifizierung aus dem Werkzeugregister | `JV-CORE-SUB-action_classify-v1` produktiv |
| 1.3.5 | Freigabeanforderung mit Token, Frist, Fingerprint | `JV-CORE-SUB-approval_request-v1` |
| 1.3.6 | Bestätigungsendpunkt mit zwei Schritten | `JV-P1-MAIN-approval_callback-v1` |
| 1.3.7 | Testwerkzeug `test.record_approved_action` | abgegrenzter Testbereich |
| 1.3.8 | Ausnahmebehandlung, Prüfgründe und Wiederanlaufpunkte nach `registry/review_resume_map.json` | `JV-P1-SUB-review_queue-v1` |
| 1.3.9 | Freigabe von `approval_email.request_decision` und `test.record_approved_action` nach dem Freigabenachweis | zwei Werkzeuge auf `approved` |

**Tests**

| Test | Inhalt |
|---|---|
| P1-T-24 bis P1-T-31 | vollständiger Freigabenachweis, davon sechs Gegenproben |
| P1-T-54 bis P1-T-57 | Wiederanlauf nach Klärung, zwei positive Fälle und zwei Gegenproben |
| P1-T-67 bis P1-T-72 | Terminale Klärungen: bestätigte Dublette, verworfenes und fehlgeleitetes Dokument, drei Gegenproben |
| P1-T-58 | Gegenprobe: Werkzeug auf `approved` ohne erbrachten Nachweis |
| 1.3-A1 bis A7 | Abnahmekriterien der Teilphase |

**Verbindlich:** Alle neun Nachweispunkte aus Spezifikation 10.5 müssen einzeln belegt sein. Der Nachweis erfolgt ausschliesslich über das Testwerkzeug; keine echte Datei wird gefährdet.

**Abnahme:** Kein Weg führt an der Freigabe vorbei, und keine der sechs Gegenproben lässt eine Ausführung zu.

---

## Schritt 1.4 — Ausführung, Nachweis, Ablage

**Voraussetzungen:** 1.3 abgenommen.

| Nr. | Arbeit | Ergebnis |
|---|---|---|
| 1.4.1 | Nachweisprüfung je Werkzeugvertrag | `JV-CORE-SUB-evidence_verify-v1` produktiv |
| 1.4.2 | Dateibenennung nach den Regeln aus 11.3 | Benennungsmodul, versioniert |
| 1.4.3 | Ablage mit Kontextsperre und Readback | `JV-P1-SUB-document_file-v1` |
| 1.4.4 | Fachprotokollierung aller Übergänge | `JV-CORE-SUB-fach_log_write-v1` produktiv |
| 1.4.5 | Entwurfserstellung | `JV-P1-SUB-draft_compose-v1` |
| 1.4.6 | Fristüberwachung | `JV-P1-MAIN-deadline_watch-v1` |
| 1.4.7 | Tagesbericht | `JV-P1-MAIN-daily_report-v1` |
| 1.4.8 | Wiederholungssteuerung | `JV-P1-MAIN-retry_dispatcher-v1` |
| 1.4.9 | Freigabe von `storage_gdrive.move_file`, `drafts_internal.create_draft` und `report_internal.write_daily_report` nach erfolgreichem Readback | drei Werkzeuge auf `approved` |

**Tests**

| Test | Inhalt |
|---|---|
| P1-T-32 bis P1-T-37 | Nachweis, fehlgeschlagener Readback, Wiederanlauf, Neuverarbeitung |
| P1-T-40 bis P1-T-44 | Betrieb, Bereinigung, Export, Konfigurationsänderung |
| P1-T-51 bis P1-T-53 | Ablage eines Smartphone-Fotos mit `.jpg`, Gegenprobe zur falschen Endung, nicht zugelassener MIME-Typ |
| 1.4-A1 bis A8 | Abnahmekriterien der Teilphase |

**Besonderheit:** Für P1-T-33 wird der Readback künstlich manipuliert, sodass die Datei am Ziel nicht gefunden wird. Die Aktion darf nicht `succeeded` erhalten. Dieser Test ist der eigentliche Beweis, dass die Nachweispflicht wirkt.

**Abnahme:** Kein `succeeded` ohne bestätigten Nachweis, keine Ablage im falschen Kontext.

---

## Schritt 1.5 — Pilot und Phase-Gate

| Woche | Inhalt | Messung |
|---|---|---|
| 1 | **Schattenbetrieb.** Alles wird verarbeitet, nichts abgelegt. Vorschläge werden mit manueller Bearbeitung verglichen | Feldqualität, Vorschlagsqualität |
| 2 | Ablage aktiv, Klasse A aktiv | Ablagequote, Prüfquote |
| 3 | Vollbetrieb | Automationsquote, Fehlerquote |
| 4 | Auswertung, Schwellwerte nachjustieren, Gate | alle Kennzahlen |

**Der Schattenbetrieb ist nicht verhandelbar.** Er kostet eine Woche und verhindert, dass eine fehlerhafte Ablageregel 50 Dokumente falsch einsortiert. Falsch abgelegte Dokumente wieder einzusammeln kostet mehr als eine Woche.

**Wöchentliche Kennzahlen:** Feldqualität je Pflichtfeld, Fristerkennungsquote, Ablagequote ohne Handarbeit, Automationsquote der Klasse-A-Aufgaben, Prüfquote, Fehlerquote je Werkzeug, Laufzeit und Kosten je Dokument, geschätzte Zeitersparnis.

**Reaktionsregel:** Liegt die Prüfquote über 20 %, werden zuerst Schwellwerte und Prompts überarbeitet. Der Pilot wird nicht ausgeweitet, solange das System mehr Arbeit erzeugt als abnimmt.

**Phase-Gate:** G1 bis G9 aus Spezifikation 18.4.

---

## Testreihenfolge im Überblick

| Gruppe | Tests | Wann |
|---|---|---|
| Fundament | 1.0-A1 bis A8, K-01 bis K-08, I-01 bis I-05 | Schritt 1.0 |
| Eingang | P1-T-01 bis 04, 08 bis 12, 19, 20 | Schritt 1.1 |
| Verständnis | P1-T-05 bis 07, 13 bis 18, 38, 39, 45 bis 50, 59 bis 66 | Schritt 1.2 |
| Freigabe | P1-T-24 bis 31, 54 bis 58, 67 bis 72 | Schritt 1.3 |
| Ausführung | P1-T-32 bis 37, 40 bis 44, 51 bis 53 | Schritt 1.4 |
| Trennung | P1-T-21 bis 23 | Schritt 1.0, Wiederholung in 1.4 |
| Gesamtlauf | alle 72 | vor dem Phase-Gate |

**Regel für Gegenproben:** Ein Test, der fehlschlagen muss, gilt nur als bestanden, wenn er mit der erwarteten Fehlerart fehlschlägt. Ein Fehlschlag aus einem anderen Grund ist kein Nachweis.

---

## Risiken im Umsetzungsverlauf

| Risiko | Wirkung | Gegenmassnahme |
|---|---|---|
| Ein Dokument nennt ein unmögliches Datum, etwa durch einen OCR-Fehler | Falsche oder gar keine Frist | Kalenderprüfung weist den Wert ab; das Feld geht in `needs_review` statt in eine Aufgabe |
| OCR-Qualität bei Smartphone-Fotos unzureichend | Hohe Prüfquote | Bewertung in 1.1 mit echten Fotos; notfalls Kanal auf Scanner beschränken |
| Modell erfindet Fristen | Falsche Aufgaben | Belegprüfung, Plausibilitätsfenster, Test P1-T-38 als Abnahmebedingung |
| Vorgangszuordnung über Kennungen greift zu selten | Viele Einzelvorgänge | Bewusst akzeptiert. Ein zusätzlicher Vorgang ist billiger als eine falsche Verknüpfung |
| Freigabeadapter nicht verfügbar (P1-O2) | 1.3 verzögert sich | Alternativer Adapter ist in der Spezifikation vorgesehen |
| Kategorienliste passt nicht zum realen Bestand | Viele `unknown_document_type` | Liste nach Woche 1 des Pilots anpassen; ist Konfiguration, kein Workflow |
| Kosten je Dokument höher als erwartet | Betriebskosten | In 1.2 messen; digitale PDF ohne OCR verarbeiten, Extraktion mit kleinerem Modell |
