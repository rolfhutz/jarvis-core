# Phase 1, Schritt 1.1 — Eingang und Normalisierung: Freigabevorlage

**Stand:** 10. September 2026
**Status:** **Von Rolf am 10.09.2026 freigegeben** (Vorlage vollständig, einschliesslich 1.1-E1 bis 1.1-E6, TS-10b, TS-11 → 1.3).
**Grundlage:** Masterfahrplan; Spezifikation 4.0.2 (Abschnitte 5, 8, 12.1.1, 13, 14, 15, 17); Umsetzungs- und Testplan 1.2; `HANDOVER_PHASE_1_0_GATE_2026-09-10.md`; ADR-001, ADR-002, DECISION_LOG
**Vorgesehener Ablageort im Repo:** `docs/plan/PHASE_1_1_FREIGABEVORLAGE_2026-09-10.md`

---

## 0. Geprüfter Ausgangsstand (nur gelesen)

| Quelle | Befund |
|---|---|
| Repo `main` | `a0d7229`, Folge-PR #8 (G-1, Gate, TS-23) ist gemergt |
| Supabase | Migrationen 0001–0015; Werkzeugregister 3 × `approved`, 11 × `draft`; `context_registry`: beide Kontexte `active`, `1.0.0` |
| n8n Credentials | nur `jv_privat_postgres`, `jv_visolva_postgres`. **Kein** Speicher- oder OCR-Credential nach Konvention. Einziges Google-Drive-Credential: `Google Drive rolf@visolva.com` (Arbeitgeberkonto) |
| n8n Workflows | nicht erneut geprüft; Stand laut Übergabe |

---

## 1. Ziel

Dokumente aus dem kontextbezogenen Eingangsordner werden deterministisch dem Kontext zugeordnet, geprüft, gehasht, dublettenfrei registriert und technisch erfasst (Volltext, Seiten, Konfidenz). Jede Ausnahme erscheint in der Ausnahmeliste oder als Aufgabe, keine Datei verschwindet still. Ergebnis: Status `text_extracted` (oder ein begründeter Ausnahmestatus) für jedes Testdokument, OCR-Dienst begründet ausgewählt.

---

## 2. Umfang

**Im Umfang**

| Nr. | Gegenstand |
|---|---|
| U-1 | Abfrage der Eingangsordner je aktivem Kontext, Kontextauflösung über `source_binding` |
| U-2 | Eingangsprüfung: MIME-Typ, Grösse, Lesbarkeit; Zurückstellung mit Aufgabe |
| U-3 | Inhaltshash `sha256`, Dublettenstufe 1 (harter Stopp) und Stufe 2 (Verdacht) |
| U-4 | OCR-Bewertung mit 20 Testdokumenten und mindestens zwei Kandidaten, Entscheidung P1-O3 |
| U-5 | OCR-Adapter, Qualitätsregel (200 Zeichen, Konfidenz 0,60), zweiter Versuch, `unreadable` mit Aufgabe |
| U-6 | Dokumentregister und Volltextablage (`document`, `document_text`), Ereignisse nach Katalog 6.2 |
| U-7 | Ausnahmeliste für Eingänge ohne auflösbaren Kontext (K-07) |
| U-8 | Wiederholungssteuerung nach `retry_policy` (TS-19, I-04) |
| U-9 | Speicheradapter und Freigabe `get_file` je Kontext, Freigabe `ocr_default.analyze_document` |
| U-10 | Laufzeitkonfiguration je Kontext aus der Datenbank statt aus Code-Knoten (TS-10) |
| U-11 | Regel 15.3: fünf Zurückstellungen je Eingangsordner und Stunde → `L3_halt` für diesen Ordner |
| U-12 | `binaryMode` im Export erhalten (TS-24); Export, Wiederherstellung, Smoke-Test nach TS-23 |

**Nicht im Umfang**

Extraktion, Analyse, Modellwerkzeuge (1.2) · Vorgangszuordnung (1.2) · Aufgabenableitung aus Inhalten (1.3) · Klärung und Wiederanlauf von Prüffällen, terminale Status `misrouted`/`discarded` (1.3, TS-17) · Verschieben, Umbenennen, Ablage (1.4) · Tagesbericht, Fristüberwachung (1.4) · aktive Benachrichtigung (O-5, Phase 2) · E-Mail, API, eigene Scan-/Foto-Kanäle (P1-O5) · Klasse-C-Weg (1.3).

---

## 3. Voraussetzungen

| Nr. | Voraussetzung | Wer | blockiert |
|---|---|---|---|
| V-1 | **Privates Google-Konto** für die private Ablage und Credential `jv_privat_gdrive`. Das vorhandene `Google Drive rolf@visolva.com` ist ein Arbeitgeberkonto und darf für `privat` **nicht** verwendet werden | Rolf | gesamten privaten Eingang |
| V-2 | Ordner je Kontext: Eingang, Arbeit, Archivwurzel, Entwürfe, Berichte. Zusätzlich je Kontext ein Testordner **ausserhalb** der Wurzel (P1-T-22) und ein Testordner für die Kontextprobe K-07 | Rolf | Bau ab 1.1b |
| V-3 | SharePoint-Testbibliothek Visolva und Credential `jv_visolva_sharepoint` (nur bei 1.1-E1 = Empfehlung) | Rolf | P1-T-19, P1-T-20, Adapter Visolva |
| V-4 | n8n-Variablen in der Instanz verfügbar (Einstellungen → Variables; planabhängig). Träger der `env:`-Verweise nach ADR-001 | Rolf prüft | 1.1-E4 |
| V-5 | OCR-Zugänge: Google-Cloud-Projekt mit Document AI und Abrechnung; zweiter Kandidat (Empfehlung: Azure AI Document Intelligence). Je Kontext eigener Zugang `jv_<kontext>_<ocr>` | Rolf | U-4, U-5 |
| V-6 | 20 Testdokumente nach Mischung 8.5 mit Referenzwerten (AA-9); mindestens 3 synthetische Arbeitgeberdokumente | Rolf | U-4, 1.1-A6, 1.1-A7 |

**Freigabe `storage_*.get_file` und `ocr_default.analyze_document`** ist keine Voraussetzung, sondern Ergebnis von 1.1 (Arbeit 1.1.8, Bedingungen 12.1.1).

---

## 4. Bestehende Entscheidungen, die 1.1 bindet

P1-B1 bis P1-B5 · P1-D1 bis P1-D13 · AR-1 bis AR-10 · ADR-001 (Arbeitgeber = SharePoint; `storage_gdrive.*` nur `privat`; SharePoint-Verträge vor 1.1) · ADR-002 (Register zur Laufzeit aus Repo-Dateien) · ADR-003 (Freitext nur als base64-JSON) · P1-O1, P1-O5 (Eingang `privat` Google Drive, `arbeitgeber_visolva` SharePoint) · P1-O7 (PR durch Claude Code, Merge durch Rolf) · E-1 (neuer Adapter = versionierte Änderung an `tool_invoke`) · E-2 · A-6 (Freigabelauf ruft Adapter direkt aus dem Smoke-Test) · A-7 · REL-1 · G-1 · GATE-1.0 · TS-23 (ändern → veröffentlichen → `versionId` = `activeVersionId` → Smoke-Test → Export).

---

## 5. Zur Freigabe: Entscheidungen

### 1.1-E1 — Speicher des Arbeitgeberkontexts

**Betroffen:** Registereintrag `storage_gdrive.get_file@1.0.0` erlaubt beide Kontexte; ADR-001 erlaubt Google Drive nur für `privat` und verlangt `storage_sharepoint.*` vor 1.1. Die SharePoint-Verträge existieren nicht.

| Variante | Inhalt |
|---|---|
| **A (Empfehlung)** | ADR-001 umsetzen: Verträge `storage_sharepoint.get_file` und `.move_file` als additive Registerdatei (Spezifikationspaket 4.0.2 bleibt unverändert), Adapter `JV-CORE-ADP-storage_sharepoint-v1`, Freigabe nur `get_file` in 1.1. `storage_gdrive.get_file@1.1.0` mit `allowed_contexts: [privat]`; 1.0.0 wird nie freigegeben |
| B | Arbeitgeber-Testeingang vorläufig auf Google Drive. Abweichung von ADR-001 und P1-O5, SharePoint-Adapter später trotzdem nötig |

**Begründung A:** Getrennte Systeme und Credentials machen die Trennung auch auf Speicherebene nachweisbar; der Adapter wird für den Arbeitgeberpilot ohnehin gebraucht. **Kosten:** ein zusätzlicher Adapter, rund zwei bis drei Tage.

### 1.1-E2 — Original bleibt in 1.1 im Eingang

**Widerspruch:** 4.1/5.1 verlangen „Original im Arbeitsbereich gesichert“; 12.1.1 gibt `move_file` erst in 1.4 frei.

**Empfehlung:** In 1.1 wird nichts bewegt. `original_secured` heisst: Hash gebildet und Dokumentdatensatz geschrieben. Das physische Verschieben in den Arbeitsbereich folgt mit `move_file` in 1.4. Folge: Dateien bleiben bis 1.4 im Eingang; jede Abfrage sieht sie erneut, die Quellidempotenz (AA-1) verhindert Doppelverarbeitung.
**Alternative:** `move_file` nach 1.1 vorziehen — widerspricht der Begründung in 12.1.1.

### 1.1-E3 — Ausnahmeliste für Eingänge ohne Kontext (K-07)

**Lücke:** Ereignisse liegen im Kontextschema mit `CHECK (context_id = '<kontext>')`. Ein Ereignis ohne Kontext hat dort keinen Platz. Zusätzlich widersprechen sich 10.4 („Aufgabe für Rolf“) und K-07 („keine Aufgabe“); ohne Kontext ist keine Aufgabe anlegbar, K-07 und AR-1 gehen vor.

| Variante | Inhalt |
|---|---|
| **A (Empfehlung)** | Neue Tabelle `jarvis_ops.intake_exception` (Migration 0016): append-only, ohne Inhaltsspalten (Bindung, Adapter, externe Datei-ID, Grundcode, Zeitpunkt, `trace_id`), eindeutig je (Bindung, Datei-ID, Grund) |
| B | Eintrag in `jarvis_ops.tech_event` mit Vorprüfung gegen Mehrfacheintrag. Keine Migration, aber keine harte Eindeutigkeit, und die Liste hängt an der Aufbewahrung des technischen Protokolls |

**Begründung A:** harte Idempotenz über den Index, dauerhafte Liste, sechs Spalten.

### 1.1-E4 — Laufzeitkonfiguration je Kontext (TS-10)

**Empfehlung:** analog ADR-002 zwei Tabellen in `jarvis_ops` (Migration 0016), erzeugt aus einer versionierten Repo-Datei: `source_binding` (Bindung, Kontext, Adapter, Kanal, `env:`-Verweis auf den Ordner, Status `active`/`halted`) und `context_document_settings` (erlaubte MIME-Typen, Grössengrenze, Positivliste OCR-Adapter nach 10.4, Pflicht zur Synthetik-Kennzeichnung). **Ordner-IDs stehen nur in n8n-Variablen** (ADR-001), nie im Repo — das Repo ist derzeit öffentlich (OFFEN-1).
**Falls V-4 negativ:** Ich lege eine begründete Ausweichlösung vor; sie wäre eine Abweichung von ADR-001.

### 1.1-E5 — Wiederholungssteuerung (TS-19, I-04)

**Empfehlung:** `JV-P1-MAIN-retry_dispatcher-v1` (Testplan 1.4.8) in 1.1 vorziehen, allgemein über `action.next_attempt_at`, Regeln aus `retry_policy` des Registers, Statusabgleich vor jedem Versuch, nach drei Versuchen `failed` und `L1_exception_list`. In 1.4 kommt nur der Statusabgleich für `move_file` hinzu.
**Alternative:** Warteknoten im laufenden Ablauf — blockiert Läufe bis 31 Minuten (1 + 5 + 25), nicht empfohlen.

### 1.1-E6 — Fehlgeleitetes Dokument im Arbeitgebereingang (P1-T-20)

**Lücke:** 8.1 verlangt, ein „erkennbar“ fehlgeleitetes Dokument anzuhalten. In 1.1 gibt es kein Dokumentverständnis.

**Empfehlung:** deterministische Schutzregel für Phase 1: Im Arbeitgebereingang werden nur Dokumente mit Synthetik-Kennzeichnung (Dateinamenpräfix `SYNTH_`, konfigurierbar) verarbeitet. Ohne Kennzeichnung: Datensatz im Arbeitgeberkontext, `needs_review` mit Grund `context_unresolved`, Aufgabe für Rolf, **Halt vor OCR**, kein Kontextwechsel. Setzt P1-B2 zugleich technisch durch.
**Alternative:** P1-T-20 nach 1.2 verschieben und über Modellhinweis erkennen.

### Zwei Hinweise zu technischen Schulden

- **TS-10 ist nur teilweise lösbar.** Kontextliste und Bindungen kommen aus der Datenbank. Die Weiche auf das Datenbank-Credential je Kontext bleibt, weil n8n das Credential je Knoten fest bindet. Vorschlag: neue Restschuld **TS-10b**, ein neuer Kontext erfordert dort weiterhin einen Zweig je Workflow.
- **TS-11** (`context_risk_override` leer) steht in der Übergabe 1.0 auf „1.1“. In 1.1 laufen nur Klasse-A-Lesewerkzeuge und freigegebene interne Schreibwerkzeuge. Vorschlag: Fälligkeit auf **1.3** (Risikoklassifizierung produktiv).

---

## 6. Arbeitsannahmen (gelten bis zur Korrektur)

| Nr. | Annahme | Grund |
|---|---|---|
| AA-1 | Das Ereignis `document.received` ist der Anker: eindeutig über (Kontext, Adapter, externe Datei-ID, Inhaltshash), trägt die vergebene `document_id`. Jede Wiederholung verwendet diese ID weiter | I-01, I-04 ohne zweiten Datensatz |
| AA-2 | Hashgleiche Datei unter anderer Datei-ID: **kein zweiter Dokumentdatensatz** (Unique-Index `content_hash`, 1.1-A2), sondern Ereignis `document.duplicate_detected` mit Verweis. Status `duplicate` am Datensatz entsteht nur über die Klärung `duplicate_confirmed` (1.3) | 5.2 und Unique-Index widersprechen sich sonst |
| AA-3 | `text_fingerprint` ist ein Ähnlichkeitswert (SimHash über normalisierte Wortfolgen), kein exakter Hash; Verdacht unter einer konfigurierten Hamming-Distanz, kalibriert mit echten Doppelscans | Zwei Scans ergeben nie denselben OCR-Text; ein exakter Hash würde 1.1-A3 nicht erfüllen |
| AA-4 | Objekte ohne herunterladbare Bytes (Ordner, Google-eigene Dokumente) und Dateien über der harten Grenze ohne Anbieterprüfsumme: Ereignis `document.quarantined` und Aufgabe, **kein** Dokumentdatensatz | `content_hash` ist Pflichtfeld; 5.1 Regel 2 hier nicht erfüllbar |
| AA-5 | „Laufstatus `already_processed`“ ist der Ergebniscode je Eingangselement (Rückgabe und `tech_event`). `workflow_run.status` bleibt `succeeded`, der CHECK kennt keinen weiteren Wert | I-01 |
| AA-6 | Dateiinhalt fliesst als n8n-Binärdatum durch `tool_invoke` zum Adapter und wird nirgends gespeichert; `tool_invoke` reicht Binärdaten durch (versionierte Änderung nach E-1). Ausführungsdaten aller P1-Workflows werden nicht gespeichert (13.4) | kein Adapter ruft einen anderen Adapter |
| AA-7 | Abfrage alle 15 Minuten, ein Lauf für alle aktiven Kontexte, Fehler je Kontext isoliert. Mit dem Ausführungskontingent des n8n-Plans abgleichen | 8.1, 13.1 |
| AA-8 | Systemaufgaben aus 1.1 (zurückgestellt, unlesbar, Kontextverdacht) laufen über `tasks_internal.create_task` mit Aktion, Nachweis, Idempotenz je (Dokument, Grund), Fälligkeit Eingang + 7 Tage | P1-A4 |
| AA-9 | OCR-Referenz: je Testdokument 3 festgelegte Textstellen und die Pflichtfelder, keine Volltranskription. Bewertung über einen manuellen n8n-Workflow im Kontext `privat`; Inhalte gelangen nicht in Chat oder Repo, nur Kennzahlen | Aufwand, AR-2 |
| AA-10 | Weg für digitale PDF (`text_only`) wird mit P1-O3 festgelegt. Bedingung: Blöcke mit Seitenbezug, sonst ist die Belegpflicht 9.4.1 in 1.2 unerfüllbar | 8.4, 12.2 |
| AA-11 | Kanal für beide Eingangsordner ist `drive_inbox` (generisch „Eingangsordner der Dateiablage“); `intake_adapter_id` unterscheidet Google Drive und SharePoint | DB-CHECK `intake_channel` |

---

## 7. Bauabschnitte

| Abschnitt | Inhalt | hängt an |
|---|---|---|
| 1.1a | Migration 0016, Konfigurationsdatei und Generator, Registerdatei SharePoint und `storage_gdrive.get_file@1.1.0`; Normalisierer TS-24; `context_resolve` aus DB | 1.1-E1, E3, E4; V-4 |
| 1.1b | Speicheradapter Google Drive und SharePoint, Wurzelprüfung, Freigabe `get_file`; hier wird 1.1-A14 ausgelöst (Freigabe vor Verdrahtung) | V-1, V-2, V-3 |
| 1.1c | OCR-Bewertung, Entscheidung P1-O3, OCR-Adapter, Freigabe | V-5, V-6; parallel zu 1.1b |
| 1.1d | `JV-P1-SUB-document_normalize-v1`, `JV-P1-SUB-document_ocr-v1`, `JV-P1-MAIN-document_intake-v1`, `JV-P1-MAIN-retry_dispatcher-v1` | 1.1a–c |
| 1.1e | Gesamttest, Gegenproben, Wiederherstellung, Nachweisdokument, Übergabe | 1.1d |

Richtwert Testplan: 1,5 Wochen. Mit SharePoint-Adapter und vorgezogenem Dispatcher realistisch rund zwei Wochen; die OCR-Bewertung startet erst mit den 20 Testdokumenten.

---

## 8. Abnahmekriterien

Jedes Kriterium gilt nur mit Beleg (Ausführungs-ID, SQL-Abfrage mit Ergebnis oder Exportprüfung). Gegenproben bestehen nur mit der erwarteten Fehlerart.

| Nr. | Kriterium | Messung |
|---|---|---|
| 1.1-A1 | Jedes Dokument erhält `context_id` über `source_binding`, keines über Modellvorschlag | alle Testdatensätze beider Kontexte: Methode = `source_binding`, 0 Abweichungen |
| 1.1-A2 | Dieselbe Datei zweimal (P1-T-08) → genau ein Dokumentdatensatz, keine zweite Aufgabe | 1 Zeile je `content_hash`; 1 Ereignis `duplicate_detected` mit Verweis; Aufgaben unverändert |
| 1.1-A3 | Zwei Scans desselben Briefes (P1-T-09) → `needs_review`, Grund `duplicate_suspected`, kein stiller Stopp; Gegenprobe: ähnlicher, eigenständiger Nachtrag löst keinen Verdacht aus | Status und Grund am zweiten Datensatz; Nachtrag erreicht `text_extracted` |
| 1.1-A4 | Unlesbar (P1-T-10) → zweiter Versuch mit anderer Voreinstellung, dann `unreadable` und genau eine Aufgabe „erneut einscannen“ | 2 OCR-Versuche belegt, Status, 1 Aufgabe auch nach erneuter Abfrage |
| 1.1-A5 | Nicht erlaubter Typ, passwortgeschützt, zu gross (P1-T-11, P1-T-12, Eingangsteil P1-T-53) → `quarantined` mit konkretem Grund, genau eine Aufgabe, Original unverändert im Eingang | je Fall Status, Grund, 1 Aufgabe, Datei-ID und Prüfsumme im Eingang unverändert |
| 1.1-A6 | Volltext, Seitenzahl und mittlere Konfidenz liegen für alle 20 Testdokumente vor (oder `unreadable` mit Grund) | 20 von 20 in `document_text` bzw. begründet |
| 1.1-A7 | OCR-Auswahl nach Raster 8.5 dokumentiert: mindestens zwei Kandidaten, Ausschlussprüfung Positionsbezug, gewichtete Werte; Entscheidung P1-O3 durch Rolf | Bewertungsbericht, Eintrag DECISION_LOG |
| 1.1-A8 | **K-07:** Eingang ohne auflösbaren Kontext (mehrdeutige Bindung, Bindung auf nicht aktiven Kontext) → genau ein Eintrag in der Ausnahmeliste, 0 Dokumente, 0 Aufgaben, 0 Aktionen, 0 Werkzeugaufrufe in beiden Kontexten, auch nach drei Abfragen | Zählungen vor und nach dem Test |
| 1.1-A9 | **I-01:** Unveränderte Datei bei erneuter Abfrage → Ergebniscode `already_processed`, 1 Dokument, je Werkzeug 1 Aktion | Ausführungs-IDs zweier Läufe, Zählungen |
| 1.1-A10 | **I-04 mit TS-19:** echter technischer Fehler (OCR-Zeitlimit per Konfiguration auf 1 s) → Wiederholung durch den Dispatcher nach `retry_policy` → Erfolg; 1 Dokument, 1 Volltext, 1 Aktion mit `attempt_count` = 2. Nach drei Fehlschlägen: Aktion `failed`, `error_event` mit `L1_exception_list`, kein vierter Versuch | Aktion, Versuche, Zeitabstände, Fehlereintrag |
| 1.1-A11 | **P1-T-22 G:** `get_file` auf eine Datei ausserhalb der Kontextwurzel → abgewiesen mit Wurzelfehler, kein Inhalt gelesen, kein Datensatz; beide Speicheradapter | Rückgabecode je Adapter, 0 Zeilen |
| 1.1-A12 | **TS-20/A4:** zwei gleichzeitig gestartete Läufe auf dieselbe Datei → genau ein Dokument, je Werkzeug genau ein Schreib- bzw. Leseaufruf; der zweite Lauf endet mit Sperre bzw. `already_processed` | zwei Ausführungs-IDs, `action_lock`, Zählungen |
| 1.1-A13 | **TS-20/A7:** Readback-Abweichung im Hauptablauf → Nachweis `not_confirmed`, Aktion nicht `succeeded` (Endstatus `failed`, nicht `planned`), `error_event` mit Eskalationsstufe, Dokument rückt nicht vor | gezielt erzeugte Abweichung an einem unveränderlichen Feld |
| 1.1-A14 | **TS-20/A8:** `adapter_unknown` im Hauptablauf → kein Adapteraufruf, Aktion `failed` (nicht wiederholbar), Ereignis `system.error`. Auslösung ohne Testeintrag: Werkzeug nach A-6 freigegeben, bevor sein Zweig in `tool_invoke` verdrahtet ist; danach verdrahten, Lauf gelingt | zwei Ausführungs-IDs vor und nach Verdrahtung |
| 1.1-A15 | **P1-T-19, P1-T-20:** synthetisches Dokument im Arbeitgebereingang → Verarbeitung ausschliesslich in `jarvis_visolva`; Dokument ohne Kennzeichnung → Halt vor OCR, `needs_review`, Aufgabe, kein Kontextwechsel | 0 Zeilen in `jarvis_privat`; kein OCR-Aufruf im zweiten Fall |
| 1.1-A16 | Freigabe nach 12.1.1: `storage_gdrive.get_file@1.1.0` (`privat`), `storage_sharepoint.get_file` (`arbeitgeber_visolva`), `ocr_default.analyze_document` (beide) mit Nachweis-IDs in `tool_release_log`; kein Werkzeug `approved` ohne Nachweis (P1-A20) | Register- und Protokollabfrage |
| 1.1-A17 | Kein Dokumentinhalt in `jarvis_ops` (P1-A14): kein Dateiname, kein Text in `tech_event`, `workflow_run`, neuen Tabellen; Ausführungsdaten der P1-Workflows nicht gespeichert | Stichprobe über alle Einträge der Testläufe; Workflow-Einstellungen im Export |
| 1.1-A18 | **TS-10:** Kontextliste und Bindungen kommen aus der Datenbank; 0 Bindungsschlüssel, Ordner-IDs oder Kontextlisten in Code-Knoten (Ausnahme dokumentiert: Credential-Weiche, TS-10b) | statische Prüfung aller Exporte |
| 1.1-A19 | Fünf Zurückstellungen im selben Eingangsordner innerhalb einer Stunde → Bindung `halted`, keine weitere Verarbeitung aus diesem Ordner, Ausnahmeeintrag; Wiederaufnahme nur manuell | Testlauf mit sechs unzulässigen Dateien |
| 1.1-A20 | **TS-24 und Betrieb:** `binaryMode` bleibt im Export erhalten; alle neuen und geänderten Workflows exportiert und in leerer Instanz wiederhergestellt (`check_restore.py` inkl. `binaryMode`, `callerIds`); nach jeder Veröffentlichung `versionId` = `activeVersionId` und Smoke-Test grün | Wiederherstellungsnachweis, Smoke-Ausführungs-IDs |
| 1.1-A21 | Dokumentation entspricht dem Stand: MANIFEST, DECISION_LOG, Nachweisdokument 1.1, Übergabedatei; offene Schulden aufgeführt | Review durch Rolf, PR |

**Normalablauf P1-T-01 bis P1-T-04** wird in 1.1 bis `text_extracted` geprüft; Vorgang und Ablage folgen in 1.2 und 1.4.

---

## 9. Risiken

| Risiko | Wirkung | Gegenmassnahme |
|---|---|---|
| n8n-Instanz ist die Visolva-Instanz mit weiteren Nutzern | Admins können je nach Rolle Workflows und Credentials im persönlichen Projekt einsehen oder nutzen | Rollen prüfen; Ausführungsdaten nicht speichern (AA-6) |
| iPhone speichert Fotos als HEIC | jedes Foto `quarantined` | Kamera auf „Maximale Kompatibilität“ (JPEG) oder Scan-Funktion der Drive-App (PDF) |
| Grenzen der synchronen OCR-Verarbeitung (Seiten, Grösse) | mehrseitige Verträge scheitern | in der Bewertung mit den 2 mehrseitigen Verträgen prüfen |
| Ausführungskontingent des n8n-Plans | Abbruch im Monat | Intervall nach AA-7 abstimmen |
| Arbeitgeber-Testbibliothek im Visolva-Tenant | Berechtigungen, Tenant-Richtlinien | Test-App mit Zugriff nur auf die Testbibliothek |

---

## 10. Nächster Schritt

1. Rolf entscheidet 1.1-E1 bis 1.1-E6 sowie TS-10b und TS-11.
2. Rolf klärt V-1 und V-4 und beginnt V-6 (Testdokumente).
3. Danach Bauabschnitt 1.1a: Migration 0016, Konfigurationsdatei und Registerdatei als Entwurf zur Durchsicht, vor dem Einspielen.

---

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
