# Änderungsprotokoll — Phase-1-Spezifikation 4.0 zu 4.0.1

**29. August 2026**

Eng begrenzte Korrekturversion auf Grundlage der Rückmeldung zu Version 4.0.
**Unverändert geblieben:** Architektur, Phasenzuschnitt 1.0 bis 1.5, die
Entscheidungen P1-B1 bis P1-B5 und P1-D1 bis P1-D10, alle Phase-0-Verträge.
Es wurde keine Funktion ergänzt und keine Grundsatzfrage neu aufgemacht.

---

## K1 — Kanonisches, reproduzierbares Paket

**Befund:** Das Archiv enthielt 14 Dateien flach. `validate_phase1.py` erwartet
`schemas/`, `registry/`, `examples/` und `tools/`. Die Prüfung war aus dem
Archiv heraus nicht reproduzierbar.

**Korrektur:**

- Archiv `jarvis-phase-1-v4.0.1.zip` mit Wurzelverzeichnis `jarvis-phase-1/` und erhaltener Verzeichnisstruktur einschliesslich `schemas/tools/`.
- Neue `README.md` mit dem exakten Prüfaufruf, den Abhängigkeiten samt Versionen und der erwarteten Ausgabe.
- Das Phase-0-Paket wird nicht dupliziert. Der Pfad wird weiterhin über `--phase0` übergeben; die Voreinstellung `../jarvis-phase-0` passt zum Entpacken beider Archive nebeneinander.
- Die Prüfung wurde aus einer frisch entpackten Kopie des ausgelieferten Archivs gegen das unveränderte Phase-0-Paket ausgeführt.

---

## K2 — Alle Werkzeugverträge vollständig aufgelöst

**Befund:** Vierzehn Schemadateien waren im Register referenziert, existierten
aber nicht. Ein in Phase 1 verwendetes Werkzeug darf nicht auf eine erst
während der Implementierung entstehende Vertragsdatei verweisen.

**Korrektur:** Alle vierzehn Dateien liegen unter `schemas/tools/`:

| Werkzeug | Dateien |
|---|---|
| `storage_gdrive.get_file` | `.input.json`, `.output.json` |
| `storage_gdrive.move_file` | `.input.json`, `.output.json` |
| `ocr_default.analyze_document` | `.input.json`, `.output.json` |
| `llm_default.extract_fields` | `.input.json` |
| `llm_default.analyze_document` | `.input.json` |
| `drafts_internal.create_draft` | `.input.json`, `.output.json` |
| `report_internal.write_daily_report` | `.input.json`, `.output.json` |
| `test.record_approved_action` | `.input.json`, `.output.json` |

`validate_phase1.py` prüft für alle zwölf in Phase 1 verwendeten Werkzeuge:
Eingabeschema existiert, Ausgabeschema existiert, beide sind gültiges JSON
Schema Draft 2020-12, alle `$id`-Werte sind eindeutig, alle `$ref`-Verweise
sind auflösbar. Ein fehlender oder nicht auflösbarer Verweis lässt den Lauf
fehlschlagen.

Ein Verweis wird zuerst im Phase-1-Paket, dann im Phase-0-Paket gesucht. Damit
liefert Phase 1 die beiden Verträge zu `storage_gdrive.move_file` nach, ohne
das Phase-0-Register zu verändern.

**Technische Schuld P1-TS1 ist geschlossen.**

Inhaltlich bemerkenswert: Der Ausgabevertrag von `ocr_default.analyze_document`
verlangt je Textblock einen Positionsbezug. Damit wird das Ausschlusskriterium
der OCR-Auswahl aus Abschnitt 8.5 zu einer prüfbaren Vertragsbedingung statt
einer Absichtserklärung.

---

## K3 — Originaldateityp im Dateinamen erhalten

**Befund:** Die Spezifikation erlaubte PDF, JPEG, PNG und TIFF und erklärte
gleichzeitig, dass Originale nicht konvertiert werden. Das feste Format mit der
Endung `.pdf` widersprach dem.

**Korrektur:**

```
JJJJ-MM-TT__Absender__Dokumenttyp__Kurzbetreff__V-JJJJ-NNNN.<endung>
```

| MIME-Typ | Endung |
|---|---|
| `application/pdf` | `.pdf` |
| `image/jpeg` | `.jpg` |
| `image/png` | `.png` |
| `image/tiff` | `.tif` |

- Die Endung wird deterministisch aus dem **geprüften MIME-Typ** abgeleitet, niemals aus dem ursprünglichen Dateinamen. Umgesetzt in `tools/normalization_reference.py` als `MIME_EXTENSION_MAP` und `extension_for_mime`.
- `document.schema.json` prüft `storage.final_filename` gegen ein Muster, das nur die vier erlaubten Endungen zulässt.
- Der Eingabevertrag von `storage_gdrive.move_file` verlangt `expected_mime_type`; damit ist die Prüfung im Werkzeug verankert, nicht nur in der Prosa.
- Ein MIME-Typ ausserhalb der vier führt zu `quarantined`, nicht zu einer Ablage mit geratener Endung.

**Neue Tests:** P1-T-51 (Smartphone-JPEG wird mit `.jpg` abgelegt), P1-T-52 G
(Endung `.pdf` bei `image/jpeg` wird abgewiesen), P1-T-53 G (nicht zugelassener
MIME-Typ). Im Prüflauf: Regel V12 sowie die Gegenproben G20, G32 und G33.

---

## K4 — Belegprüfung für rohe und normalisierte Werte

**Befund:** Die Regel „der normalisierte Wert muss wörtlich im Beleg vorkommen"
war für korrekte Werte nicht anwendbar. `2027-01-01` steht nicht im Text, wenn
dort „1. Januar 2027" geschrieben ist. Die Regel hätte richtige Werte verworfen.

**Korrektur — jedes Feld führt beide Darstellungen:**

| Feld | Inhalt |
|---|---|
| `raw_value` | wie im Dokument: „1. Januar 2027" |
| `normalized_value` | kanonisch: `2027-01-01` |
| `data_type` | Zieldatentyp |
| `normalization_rule` | registrierte Regel |
| `evidence.snippet`, `evidence.page`, optional `evidence.locator` | Textbeleg |
| `validation_status` | Ergebnis der Prüfung, weiterhin **nie vom Modell gesetzt** |

**Zweistufige deterministische Prüfung:**

1. `raw_value` muss nach rein technischer Textnormalisierung im Beleg auffindbar sein. Die Normalisierung gleicht nur Darstellung aus: Unicode-Form, Bindestrich- und Anführungszeichenvarianten, geschützte Leerzeichen, Zeilenumbrüche, Gross- und Kleinschreibung. Zusätzlich wird eine Variante ohne Leerzeichen geprüft, damit ein Zeilenumbruch mitten in einer Zahl kein falsches Negativ erzeugt. Fehlschlag → `rejected_evidence_mismatch`.
2. `normalized_value` muss sich über die angegebene Regel aus `raw_value` ableiten lassen. Fehlschlag → `rejected_normalization_mismatch`.

**Zwölf registrierte Regeln** in `registry/normalization_rules.json`, Referenz
in `tools/normalization_reference.py`:

| Datentyp | Regeln |
|---|---|
| Datum | `date.de_numeric`, `date.de_long`, `date.iso` |
| Datum und Uhrzeit | `datetime.de_numeric` |
| Dezimalbetrag | `decimal.de`, `decimal.ch`, `decimal.en` |
| Währungscode | `currency.iso4217` |
| Ganzzahl | `integer.plain` |
| Kennung | `identifier.strip_separators` |
| Zeichenfolge | `string.trim` |
| Boolescher Wert | `boolean.de` |

Jede Regel führt Beispiele mit sich; alle 33 werden bei jedem Lauf gegen die
Implementierung reproduziert.

**Drei Dezimalregeln statt einer**, weil der reale Posteingang schweizerische
(`1'234.50`), deutsche (`1.234,50`) und englische (`1,234.50`) Schreibweisen
enthält. Ohne die Unterscheidung wären `1.234` und `1,234` nicht auflösbar —
ein Faktor 1000 beim Betrag.

**Tabellenpositionen** umgehen die Belegpflicht nicht mehr. Jede Position mit
einem Betrag führt `total_amount_raw` beziehungsweise `unit_amount_raw`, eine
Normalisierungsregel und entweder einen eigenen Beleg oder einen `field_ref`
auf ein bereits belegtes Extraktionsfeld. Positionen ohne Betrag brauchen
keinen Beleg.

**Neue Tests:** P1-T-45 bis P1-T-50. Im Prüflauf: Regeln V9, V10, V11 sowie die
Gegenproben G10 bis G15 und G24 bis G29, darunter der erfundene Betrag und das
manipulierte `normalized_value`.

---

## K5 — Deterministischer Wiederanlauf nach manueller Prüfung

**Befund:** Der Übergang `needs_review → vorheriger Zustand` war für eine
Umsetzung nicht eindeutig. Eine korrigierte OCR-Zahl darf nicht denselben
Wiederanlauf erzeugen wie eine nachgetragene Vorgangszuordnung.

**Korrektur — sechs Pflichtangaben im Prüfeintrag:** `blocked_stage`,
`resolution_type`, `resume_from_stage`, `resolved_values`, `resolved_at`,
`resolved_by`.

Die Zuordnung Klärungsart → Wiederanlaufpunkt steht in
`registry/review_resume_map.json` und ist die einzige Quelle. Zwölf
Klärungsarten, drei Beispiele:

| Klärungsart | Wiederanlauf ab | Begründung |
|---|---|---|
| `value_corrected` | `analysis` | OCR und Extraktion werden nicht wiederholt; der korrigierte Wert gilt als menschlich belegt |
| `rescan_provided` | `ocr` | Eine neue Vorlage ersetzt die unlesbare |
| `category_assigned` | `filing` | Es fehlte ausschliesslich das Ablageziel |

Fünf Klärungsarten erfordern `resolved_values`. Das Schema erzwingt, dass eine
geklärte Prüfung Art, Wiederanlaufpunkt und Entscheider nennt, und dass
korrigierte Werte nur bei einer wertändernden Klärungsart vorkommen.

**Neue Tests:** P1-T-54 bis P1-T-57. Im Prüflauf: Regeln V13 und V14 sowie die
Gegenproben G16 bis G19, G30 und G31.

---

## K6 — Werkzeugstatus und Prüfzahlen

**Befund:** Version 4.0 sah vor, Werkzeuge pauschal in Phase 1.0 auf `approved`
zu setzen. Das ist für OCR- und Modellwerkzeuge unmöglich: Ihr Adapter steht zu
diesem Zeitpunkt noch nicht fest.

**Korrektur — fünf Bedingungen in fester Reihenfolge:**

1. Vertrag und Schemata vollständig
2. Adapter konfiguriert
3. Testlauf oder Dry Run erfolgreich
4. Ergebnisnachweis erfolgreich
5. erst danach Status `approved`

**Freigabe je Teilphase**, geführt in `registry/tool_release_plan.json`:

| Teilphase | Werkzeuge |
|---|---|
| 1.0 | `docstore_internal.upsert_document`, `casestore_internal.upsert_case`, `tasks_internal.create_task` |
| 1.1 | `storage_gdrive.get_file`, `ocr_default.analyze_document` |
| 1.2 | `llm_default.extract_fields`, `llm_default.analyze_document` |
| 1.3 | `approval_email.request_decision`, `test.record_approved_action` |
| 1.4 | `storage_gdrive.move_file`, `drafts_internal.create_draft`, `report_internal.write_daily_report` |

Phase 1.0 gibt nur die drei Kernwerkzeuge mit internem Adapter frei, die im
Rahmen der Trennungs- und Idempotenznachweise ohnehin ausgeführt werden.
`storage_gdrive.move_file` wird erst in 1.4 freigegeben, obwohl sein Adapter
feststeht: Es ist das einzige Werkzeug, das ein Original bewegt.

Der Prüflauf weist nach, dass kein Werkzeug vor dem Nachweis auf `approved`
steht und dass kein Werkzeug mit offener Adapterauswahl für 1.0 vorgesehen ist.

**Prüfzahlen korrigiert.** In Version 4.0 stand an einer Stelle „27 Prüfungen",
tatsächlich waren es 29. Version 4.0.1 nennt überall dieselbe Zahl: **79**.

---

## Neu hinzugekommene Dateien

| Datei | Zweck |
|---|---|
| `README.md` | Einstieg, Prüfaufruf, Abhängigkeiten (K1) |
| `CHANGELOG_V4.0_ZU_V4.0.1.md` | dieses Dokument |
| `schemas/tools/` (14 Dateien) | Ein- und Ausgabeverträge (K2) |
| `registry/normalization_rules.json` | zwölf Regeln mit 33 Beispielen (K4) |
| `registry/review_resume_map.json` | Wiederanlaufpunkt je Klärungsart (K5) |
| `registry/tool_release_plan.json` | Freigabeplan der Werkzeuge (K6) |
| `tools/normalization_reference.py` | Referenz für Belegprüfung, Normalisierung, Dateiendung (K3, K4) |
| `examples/extraction_result_beitragsanpassung.json` | Extraktion mit Roh- und Normwerten (K4) |
| `examples/document_filed_photo.json` | Smartphone-Foto mit `.jpg` (K3) |
| `examples/document_needs_review.json` | geklärte Prüfung mit Wiederanlaufpunkt (K5) |

## Geänderte Dateien

| Datei | Änderung |
|---|---|
| `SPEC_…_v4.0.1.md` | Abschnitte 9.4.1, 9.4.2, 11.3, 12.1.1, 12.2, 15.2.1 neu oder ersetzt; fünf neue Abnahmekriterien; vierzehn neue Testfälle |
| `schemas/document.schema.json` | Wiederanlaufblock, Stufenschlüssel, Dateinamensmuster |
| `schemas/extraction_result.schema.json` | Roh- und Normwerte, Regelbezug, Positionsbelege |
| `tools/validate_phase1.py` | acht Prüfteile statt fünf, 79 statt 29 Prüfungen |
| `UMSETZUNGS_UND_TESTPLAN.md` | Freigabeschritte je Teilphase, neue Tests |
| `HANDOVER_…md` | Zahlen, geschlossene Schulden, Dateiliste |

## Prüfumfang vorher und nachher

| Teil | Version 4.0 | Version 4.0.1 |
|---|---|---|
| Schemata | 4 | 4 |
| Beispiele | 3 | 6 |
| Werkzeugregister | 2 | 3 |
| Werkzeugverträge | – | 2 |
| Normalisierungsregeln | – | 13 |
| Vertragsregeln | 8 | 14 |
| Freigabeplan | – | 4 |
| Gegenproben | 12 | 33 |
| **Gesamt** | **29** | **79** |
