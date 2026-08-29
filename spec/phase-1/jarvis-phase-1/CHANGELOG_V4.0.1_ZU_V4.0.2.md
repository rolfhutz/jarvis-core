# Änderungsprotokoll — Phase-1-Spezifikation 4.0.1 zu 4.0.2

**29. August 2026**

Letzte Korrekturversion. Grundlage sind drei Laufzeitfehler, die bei
zusätzlichen semantischen Gegenproben gefunden wurden.

**Unverändert:** Architektur, Phasenzuschnitt 1.0 bis 1.5, die Entscheidungen
P1-B1 bis P1-B5 und P1-D1 bis P1-D13, alle Phase-0-Verträge, die Korrekturen
K1 bis K6. Es wurde keine Funktion ergänzt.

---

## K7 — Echte Kalenderprüfung

**Befund:** Die Referenzimplementierung prüfte nur `1 <= Tag <= 31` und
`1 <= Monat <= 12`. Damit wurde `31.02.2026` zu `2026-02-31` und `29.02.2023`
zu `2023-02-29` normalisiert. Beide Daten existieren nicht. Ein solcher Wert
wäre anschliessend als Frist geführt und hätte im Kalender oder bei einer
Sortierung Folgefehler ausgelöst.

**Korrektur:** Alle Datums- und Zeitregeln erzeugen das Ergebnis über
`datetime.date` beziehungsweise `datetime.datetime`. Das Kalendermodell prüft
Monatslängen und Schaltjahre.

| Verbindliche Gegenprobe | Ergebnis |
|---|---|
| `31.02.2026` | abgewiesen |
| `29.02.2023` | abgewiesen |
| `31.04.2026` | abgewiesen |
| `00.01.2026` | abgewiesen |
| `01.13.2026` | abgewiesen |
| `31.02.2026 10:00` | abgewiesen |
| `01.01.2026 25:00` | abgewiesen |
| `2026-02-31` (ISO) | abgewiesen |
| `30. Februar 2026` | abgewiesen |

| Verbindliche positive Prüfung | Ergebnis |
|---|---|
| `29.02.2024` | `2024-02-29` |
| `28.02.2023` | `2023-02-28` |
| `31.12.2026 23:59` | `2026-12-31T23:59:00` |

**Zweijahresregel, bewusst beibehalten und jetzt ausdrücklich dokumentiert:**
`00` bis `69` bedeutet `2000` bis `2069`, `70` bis `99` bedeutet `1970` bis
`1999`. Sie steht in `registry/normalization_rules.json` unter
`conventions.two_digit_year` und ist in `expand_two_digit_year` umgesetzt.

Die Registry führt je Regel neben den Beispielen jetzt auch `rejects`. Zwölf
Ablehnungsfälle werden bei jedem Lauf geprüft; ein durchrutschender Fall lässt
den Lauf fehlschlagen.

Umgesetzt in: `tools/normalization_reference.py` (`_iso_date`,
`_iso_datetime`, `expand_two_digit_year`), `registry/normalization_rules.json`,
Spezifikation 9.4.3, Gegenproben G48 bis G56, Testfälle P1-T-59 bis P1-T-62.

---

## K8 — Geldwerte niemals als Binär-Gleitkommazahl

**Befund:** Die Normalisierung wandelte Beträge mit `float(Decimal(text))` in
eine Gleitkommazahl. Das ist für Beiträge, Rechnungen und Fristen mit
Geldwirkung unzulässig: `0.1 + 0.2` ergibt in Gleitkommaarithmetik nicht `0.3`.

**Korrektur:** Die drei Regeln `decimal.de`, `decimal.ch` und `decimal.en`
liefern eine **Zeichenfolge**.

| Rohwert | Kanonischer Wert |
|---|---|
| `1.234,50 EUR` | `"1234.50"` |
| `CHF 448.00` | `"448.00"` |
| `12'000.-` | `"12000.00"` |
| `0,10` | `"0.10"` |
| `-89,90` | `"-89.90"` |

**Verbindliche Regeln:**

- keine Exponentialschreibweise,
- Dezimalpunkt im kanonischen Wert,
- exakt zwei Nachkommastellen, kaufmännische Rundung (`ROUND_HALF_UP`),
- Berechnung ausschliesslich mit `Decimal`, in PostgreSQL mit `NUMERIC`, niemals mit `float`,
- Währung bleibt ein getrenntes Feld.

**Schema- und Datenänderungen:**

| Ort | Änderung |
|---|---|
| `extraction_result.schema.json` | Datentyp `decimal` heisst jetzt `money`; `normalized_value` bei `money` muss dem Muster `^-?[0-9]+\.[0-9]{2}$` entsprechen; `number` als Typ entfernt |
| `extraction_result.schema.json`, `line_items` | `total_amount` und `unit_amount` sind Zeichenfolgen mit demselben Muster; `quantity` ist ganzzahlig |
| `document_analysis.schema.json` | `previous_value`, `current_value`, `delta_absolute`, `delta_percent` sind Zeichenfolgen |
| `schemas/tools/llm_default.analyze_document.input.json` | `validated_field.normalized_value` ohne `number` |
| `examples/extraction_result_beitragsanpassung.json` | Beträge als `"448.00"`, `"412.00"`, `"1234.50"` |
| `examples/document_analysis_beitragsanpassung.json` | Vergleichswerte als Zeichenfolgen |

**Neue Prüfungen:** Eine Rechenprobe weist mit `Decimal` nach, dass
`"0.10" + "0.20" = "0.30"` ergibt, und belegt zugleich, dass dieselbe Rechnung
mit `float` ein abweichendes Ergebnis liefert — die Probe wäre sonst ohne
Aussagekraft. Zusätzlich prüft `values_match`, dass eine Gleitkommazahl auf
einer der beiden Seiten grundsätzlich als Abweichung gilt.

Gegenproben G34 bis G37: Geldwert als `float`, Geldwert mit einer
Nachkommastelle, Exponentialschreibweise, Positionsbetrag als `float`.
Vertragsregel V17 prüft alle Geldfelder, Positionsbeträge und Vergleichswerte.

**Nicht monetäre Dezimalwerte** mit abweichender Genauigkeit erhalten bei Bedarf
eine eigene registrierte Regel und einen eigenen Datentyp. Das ist in
`registry/normalization_rules.json` unter `conventions.non_monetary_decimals`
festgehalten, damit es später nicht über die Geldregeln improvisiert wird.

---

## K9 — Terminale Klärungen lösen keinen Wiederanlauf aus

**Befund:** `duplicate_confirmed` und `document_discarded` trugen
`resume_from_stage: intake`, während ihre Begründung sagte, es finde keine
weitere Verarbeitung statt. Eine Implementierung, die dem Feld folgt, hätte
bestätigte Dubletten und verworfene Dokumente erneut durch die Kette geschickt.

**Korrektur — zwei ausdrücklich getrennte Ausgänge:**

| `outcome` | Bedeutung | Pflichtfeld | Unzulässig |
|---|---|---|---|
| `resume` | Verarbeitung wird fortgesetzt | `resume_from_stage` | `terminal_status` |
| `terminal` | keine weitere Verarbeitung | `terminal_status` | `resume_from_stage` ungleich `null` |

Neun Klärungsarten sind `resume`, drei sind `terminal`:

| Klärungsart | Endzustand |
|---|---|
| `duplicate_confirmed` | `duplicate` |
| `document_discarded` | `discarded` |
| `context_corrected` | `misrouted` |

Der Dokumentstatus wurde um `discarded` und `misrouted` ergänzt. Das Schema
erzwingt, dass ein Endzustand auf den Dokumentstatus durchschlägt.

**`context_corrected` ist kein Wiederanlauf.** Der Kontext eines Datensatzes
wird nach AR-1 nicht nachträglich geändert. Verbindlicher Ablauf:

1. Der Datensatz im falschen Kontext wird terminal als `misrouted` abgeschlossen.
2. **Kein automatischer Schreibzugriff in das andere Kontextschema.**
3. Rolf legt das Original manuell in den richtigen Eingangsordner.
4. Dort entsteht über `source_binding` ein neuer Dokumentdatensatz.
5. Der alte Datensatz darf höchstens über das neue Feld `successor_intake_hint` auf den erwarteten Eingang verweisen, etwa `reintake:arbeitgeber_visolva/inbox`. Format und Inhaltsfreiheit werden geprüft.
6. Ein fehlgeleitetes Dokument erzeugt keine Aufgaben, keine Aktionen, keine Vorgangszuordnung und keine Ablage.

Der manuelle Handgriff ist beabsichtigt. Die Alternative — JARVIS verschiebt
selbst — wäre genau der kontextübergreifende Schreibzugriff, den die
Architektur seit Phase 0 ausschliesst.

**Neue Prüfungen:** Vertragsregeln V15 (Trennung der Ausgänge) und V16 (kein
kontextübergreifender Schreibzugriff), Gegenproben G38 bis G42 auf Schemaebene
und G43 bis G47 auf Vertragsebene, darunter die erneut verarbeitete Dublette,
das erneut verarbeitete verworfene Dokument und der Hinweis mit fachlichem
Inhalt. Testfälle P1-T-67 bis P1-T-72.

---

## Neue und geänderte Dateien

| Datei | Änderung |
|---|---|
| `SPEC_…_v4.0.2.md` | Abschnitte 9.4.3, 9.4.4, 15.2.1, 15.2.2 neu oder ersetzt; zwei neue Dokumentzustände; vier neue Abnahmekriterien; vierzehn neue Testfälle |
| `CHANGELOG_V4.0.1_ZU_V4.0.2.md` | neu, dieses Dokument |
| `tools/normalization_reference.py` | Kalenderprüfung, Geldzeichenfolgen, `to_decimal`, `is_canonical_money`, `expand_two_digit_year` |
| `tools/validate_phase1.py` | Ablehnungsfälle, Decimal-Rechenprobe, V15 bis V17, 23 neue Gegenproben |
| `registry/normalization_rules.json` | Version 1.1.0, `conventions`, `rejects` je Regel, Datentyp `money` |
| `registry/review_resume_map.json` | Version 1.1.0, `outcome`, `terminal_status`, `terminal_statuses` |
| `schemas/document.schema.json` | Version 1.2.0, `outcome`, `terminal_status`, `successor_intake_hint`, Zustände `discarded` und `misrouted` |
| `schemas/extraction_result.schema.json` | Version 1.2.0, Datentyp `money`, Geldmuster, ganzzahlige Menge |
| `schemas/document_analysis.schema.json` | Version 1.1.0, Vergleichswerte als Zeichenfolgen |
| `schemas/tools/llm_default.analyze_document.input.json` | `normalized_value` ohne `number` |
| `examples/document_misrouted.json` | neu: terminal abgeschlossenes, fehlgeleitetes Dokument |
| `examples/extraction_result_…`, `document_analysis_…`, `document_needs_review.json`, `document_filed*.json` | Geldwerte, `outcome`, Schemaversionen |
| `README.md`, `HANDOVER_…md`, `UMSETZUNGS_UND_TESTPLAN.md` | Zahlen, Prüfteile, Testreihenfolge |

## Prüfumfang

| Teil | 4.0.1 | 4.0.2 |
|---|---|---|
| 1 Schemata | 4 | 4 |
| 2 Beispiele | 6 | 7 |
| 3 Werkzeugregister | 3 | 3 |
| 4 Werkzeugverträge | 2 | 2 |
| 5 Normalisierungsregeln | 13 | 15 |
| 6 Vertragsregeln | 14 | 17 |
| 7 Freigabeplan | 4 | 4 |
| 8 Gegenproben | 33 | 56 |
| **Gesamt** | **79** | **108** |
