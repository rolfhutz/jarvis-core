# Gate-Matrix Phase 1 – Ist-Umfang (CR-19 E1 A)

Stand: 31.10.2026 (Fassung 6) · Status: **G-2 bis G-5, B-1 und B-2 von Rolf entschieden (31.10.2026, je Variante A); keine Gate-Freigabe**
Grundlage: SPEC_PHASE_1 v4.0.2 (§7.3, §8.6, §9.8, §10.6, §11.7, §16, §17, §18.4), UMSETZUNGS_UND_TESTPLAN, DECISION_LOG (Repo `main` = `ab66189`), Projekt-CR-Dokumente CR-02 bis CR-19, Datenbankabfragen vom 31.10.2026 (Supabase, nur lesend).

## Legende

| Zeichen | Status | Bedeutung |
|---|---|---|
| ✅ | erfüllt | überprüfbarer Nachweis genannt |
| 🔁 | ersetzt durch CR-x | Spec-Anforderung durch eine freigegebene Änderung abgelöst; Nachweis gilt für die Ersatzregel |
| ⏭ | nach Phase 2 | von Rolf entschieden mit G-2 A (31.10.2026), inkl. Modellbenchmark |
| ⬜ | offen | Nachweis fehlt; Priorität in Abschnitt 9 |

Abkürzungen der Nachweise: **GATE-1.0** = `docs/evidence/PHASE_1_0_GATE_2026-09-10.md` · **S1** = `claude/HANDOVER_S1_DOKUMENTENASSISTENT_WEB_2026-09-27.md` (Live-Tests 27.09.) · **DB-31.10** = Abfrage dieser Sitzung (Werte unten) · **CODE-31.10** = Test der Prüffunktionen aus dem Repo-Export `JV-P1-MAIN-document_desk-v1.json` (Knoten «Analyse auswerten»). **GEGEN-31.10** = Gegenproben gegen den exportierten Code der Knoten «Anfrage pruefen», «Archiv bewerten», «Dublette bewerten» (Prüfstand mit nachgebildeten Eingaben, nicht live; Grundlage Export der Version `85e52d54`, für B-1 der neue Knotencode der aktiven Version `0a96392a`).

## 1. Ergebnis auf einen Blick

| Bereich | Anzahl | ✅ | 🔁 | ⏭ | ⬜ |
|---|---|---|---|---|---|
| 1.0-A1–A8 | 8 | 8 | 0 | 0 | 0 |
| 1.1-A1–A7 | 7 | 3 | 3 | 1 | 0 |
| 1.2-A1–A7 | 7 | 1 | 1 | 3 | 2 |
| 1.3-A1–A7 | 7 | 3 | 2 | 1 | 1 |
| 1.4-A1–A8 | 8 | 5 | 1 | 1 | 1 |
| P1-A1–A24 | 24 | 12 | 1 | 6 | 5 |
| G1–G9 | 9 | 2 | 0 | 0 | 7 |
| P1-T-01–72 | 72 | 26 | 8 | 29 | 9 |
| Übertragen aus G-1 (K-07, K-08, I-01, I-04, P1-T-22) | 5 | 3 | 1 | 1 | 0 |

**Kernaussage:** Fundament (1.0), Kontexttrennung, Dubletten, Ablage mit Nachweis, Volltext und Sicherung/Wiederherstellung sind nachgewiesen. Offen sind die **Pilotkennzahlen** (Ablage-, Feld-, Fristquote, Prüfquote) und die **Dokumentation** (DECISION_LOG-Nachtrag vorbereitet). Klasse-C-Freigabe, Belegprüfung je Feld, Klärungs-Wiederanlauf und Tagesbericht sind nach Phase 2 verschoben (G-2 A).

### Datenbankbefund DB-31.10 (Kontext `privat`)

| Messung | Wert |
|---|---|
| Dokumente Weboberfläche (`web_desk_s1`) | 47 (erstes 27.09.2026), davon 7 seit Pilotstart 31.10. |
| Status | 39 `filed`, 6 `understood` (wartend), 16 `discarded` (inkl. Smoke-Test) |
| Abgelegt ohne Readback-Nachweis | **0 / 39** (Methode `readback`, alle mit Web-Link und Protokolleintrag `document_filed`) |
| Ablagepfad ausserhalb `90_Archiv/` | 0 / 39 · längster Pfad 183 Zeichen (Grenze 200) |
| Endung passt nicht zum MIME-Typ | 0 / 39 (nur PDF und PNG abgelegt) |
| Dubletten `content_hash` | 0 |
| Nicht verworfene Dokumente ohne Volltext | 0 (45 Volltexte; 25 Dokumente hatten Fehlversuche, alle im Nachlauf nachgeholt) |
| Dokumente mit `review_required` | 2 / 47 |
| Dateiname = letzter KI-Vorschlag | 34 / 39 (87 %; 5 Abweichungen ungeklärt) |
| Aufgaben | 36, davon 13 Smoke-Test, 23 echte · 0 ohne Erfolgskriterium, Akteur, Priorität · 0 doppelte Idempotenzschlüssel · 12 der 23 echten mit Frist |
| Beträge in Analysen seit 01.10. | ausschliesslich Zeichenfolge, mit `betrag_roh` und `beleg` |
| Werkzeuge `approved` | 4 Versionen, alle mit Nachweisverweis in `tool_release_log` |
| Technikprotokoll `jarvis_ops.tech_event` | keine jsonb-/Volltextspalte, nur `message_safe` (varchar) |

## 2. Phase 1.0 (Spec §7.3)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| 1.0-A1 | ✅ | GATE-1.0 §2 (DB 30.08., Gate-Test 20220/21854) |
| 1.0-A2 | ✅ | GATE-1.0 §2 (`log_context_chk`, `action_context_chk`) |
| 1.0-A3 | ✅ | GATE-1.0 §2 (A3a–A3e) |
| 1.0-A4 | ✅ | GATE-1.0 §2 (A4, Lauf 22265) |
| 1.0-A5 | ✅ | GATE-1.0 §2 (Smoke 22087, 22265) |
| 1.0-A6 | ✅ | GATE-1.0 §2 (A6, Gate-Test A-4) |
| 1.0-A7 | ✅ | GATE-1.0 §2, mit dokumentierter Grenze (Unique-Index + `ON CONFLICT`) |
| 1.0-A8 | ✅ | GATE-1.0 §2; erneut TS-33b (31.10.: 22 Workflows, `check_restore` bestanden) |

Übertragene Restfälle aus Entscheidung G-1 (10.09.2026):

| Fall | Status | Begründung / Nachweis |
|---|---|---|
| K-07 Ereignis ohne Kontext | 🔁 CR-02 §4 | Kontext über die Seitenadresse (`source_binding`), nie über die KI; ein Eingang ohne Kontext ist im Ist-Umfang nicht möglich |
| K-08 kontextübergreifende Analyse | ⏭ | Arbeitgeberkontext nur technisch eingerichtet; kein Analysepfad Visolva |
| I-01 `already_processed` | ✅ | S1: gleiche Datei erneut → Dublette, kein zweiter Datensatz |
| I-04 Wiederholung nach Fehler | ✅ | S1: beschädigtes PDF → `failed`, erneuter Upload nutzt denselben Datensatz |
| P1-T-22 Ablagepfad ausserhalb Wurzel | ✅ | Lesepfad: 1.1b SG-03/SVG-03 `outside_context_root`. Ablage: GEGEN-31.10 8/8 – `../` und `/` im Dateinamen, Pfad in Kategorie, Anführungszeichen in Sparte abgewiesen; Archiv ausserhalb der Wurzel, im Papierkorb oder mit fremder ID abgebrochen; Positivfall läuft. Ordner-IDs kommen nie vom Aufrufer |

## 3. Phase 1.1 (Spec §8.6)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| 1.1-A1 | ✅ | CR-02 §4; S1; DB-31.10: alle 47 Dokumente `privat`, Kanal `manual_upload/web_desk_s1` |
| 1.1-A2 | ✅ | S1 (Dublette erkannt); DB-31.10: 0 Dubletten `content_hash` |
| 1.1-A3 | ⏭ | `duplicate_suspected` (zwei Scans desselben Briefes) nicht gebaut. Risiko gering: Ablage nur per Klick (CR-02 E2 A), Ordnerkarte zeigt gleichartige Dokumente (CR-17). Mit Volltext (CR-12) in Phase 2 einfach nachrüstbar |
| 1.1-A4 | 🔁 CR-02 Krit. 5 | Unlesbar → «Prüfung nötig», bleibt im Eingang (S1-Test). Keine eigene Aufgabe, Rolf sieht es direkt in der Oberfläche |
| 1.1-A5 | 🔁 CR-02 Krit. 6 | Falscher Typ wird beim Upload mit Begründung abgewiesen statt zurückgestellt (S1: TXT, verschlüsseltes PDF, falsche Endung) |
| 1.1-A6 | ✅ | CR-12 Tests; DB-31.10: 0 nicht verworfene Dokumente ohne Volltext; `document_text` mit Seitenzahl und `mean_confidence` |
| 1.1-A7 | 🔁 CR-12 E1 A | Rolf hat Document AI (EU) am 31.10. entschieden; Vergleich mit Azure und Bewertungsraster entfallen. P1-O3 damit geschlossen |

## 4. Phase 1.2 (Spec §9.8)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| 1.2-A1 | ⬜ | Kein Referenzkorpus mit Sollwerten in Repo oder Projekt. Messung per Stichprobe im Pilotbericht |
| 1.2-A2 | ⬜ | wie 1.2-A1, Fristen |
| 1.2-A3 | ⏭ | DM-TD4: Das Modell liefert `beleg` je Betrag/Frist, der Beleg wird aber nicht gegen den Volltext geprüft. Mit CR-12 ist die Grundlage jetzt vorhanden |
| 1.2-A4 | ⏭ | wie 1.2-A3 |
| 1.2-A5 | ✅ | WID-31.10 (Upload Rolf 31.10., `SYNTH_Widerspruch_Rechnung.pdf`): Unsicherheit «Differenz CHF 1'250.00 / 1'520.00 nicht erkennbar», genau eine Empfehlung «Rechnungsdifferenz beim Absender reklamieren» (Priorität hoch, Frist, Erfolgskriterium), Option «Reklamieren» empfohlen statt «Bezahlen»; Aufgabe entsteht per Klick (CR-03) |
| 1.2-A6 | 🔁 CR-06 / CR-17 | Vorgangsnummer ersetzt durch Ablageregister und Kennungsabgleich; Abweichung → Rückfrage vor Ablage. CR-17 Logik 19/19, Oberfläche 18/18 |
| 1.2-A7 | ⏭ | Modellbenchmark nicht durchgeführt. Achtung: am 10.09. als «Auflage für Phase 1» vorgemerkt – Verschiebung braucht Rolfs Entscheid |

## 5. Phase 1.3 (Spec §10.6)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| 1.3-A1 | ✅ | DB-31.10: 23/23 echte Aufgaben mit Titel im Verbformat (Sichtprüfung), Erfolgskriterium, Akteur, Priorität |
| 1.3-A2 | ⬜ | Keine deterministische Prüfung gegen eine Verbotsliste nachgewiesen; Sichtprüfung: 2 Grenzfälle mit «prüfen» |
| 1.3-A3 | 🔁 CR-02 E2 A / CR-05 | Keine automatische Aktion: Ablage und Entwürfe nur per Klick, Versand immer durch Rolf. Eine zu niedrige Klasse kann nicht entstehen |
| 1.3-A4 | 🔁 CR-07 2B | Fehlende Empfängeradresse → Eingabefeld statt geratenem Wert |
| 1.3-A5 | ⏭ | Freigabeweg Klasse C (§10.5) nicht gebaut; gestützt auf CR-01 M-3 (Klick-Freigabe in Phase 2) und offenes P1-O2. Testwerkzeug `test.record_approved_action` steht auf `draft` |
| 1.3-A6 | ✅ | WID-31.10: genau eine Klärungsempfehlung |
| 1.3-A7 | ✅ | DB-31.10: 0 doppelte Idempotenzschlüssel bei 36 Aufgaben; CR-16-Neuanalyse ohne zweite Aufgabe |

## 6. Phase 1.4 (Spec §11.7)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| 1.4-A1 | ⬜ | Pilotkennzahl. Stand 34/39 (87 %) Dateiname = letzter KI-Vorschlag; Messmethode im Pilotbericht festlegen |
| 1.4-A2 | ✅ | DB-31.10: 39/39 unter `90_Archiv/` im Kontext `privat`; Wurzelprüfung im Workflow (S1) |
| 1.4-A3 | ✅ | 1.0-A1/A2 (Rechte und Prüfbedingungen); Gegenprobe Sicherung «privat liest Visolva nicht» (TS-13) |
| 1.4-A4 | ✅ | Ablage 39/39 mit Readback; E-Mail-Entwürfe `done` alle mit `nachweis`; Brief per CR-16-Test |
| 1.4-A5 | ✅ | DB-31.10: 0 Dokumente `filed` ohne Nachweis |
| 1.4-A6 | ✅ | S1: Namenskollision → `__2`, keine Überschreibung |
| 1.4-A7 | 🔁 CR-14 E3 / 0041 | Wartende Dokumente erscheinen unter «Wartet auf dich» statt im Tagesbericht |
| 1.4-A8 | ⏭ | Tagesbericht (§11.6) nicht gebaut; `report_internal.write_daily_report` `draft`. Morgen-Briefing ausserhalb von JARVIS als Übergang |

## 7. Abnahmekriterien P1-A (Spec §16)

| Nr. | Status | Begründung / Nachweis |
|---|---|---|
| P1-A1 | ⬜ | = 1.4-A1, Pilot |
| P1-A2 | ⬜ | = 1.2-A1, Pilot-Stichprobe |
| P1-A3 | ⬜ | = 1.2-A2, Pilot-Stichprobe |
| P1-A4 | ⬜ | Konkret und zugeordnet ✅ (1.3-A1). «Terminiert»: 11 echte Aufgaben ohne Frist – im Pilotbericht prüfen, ob das Dokument eine Frist enthielt (§10.1 erlaubt Aufgaben ohne Frist) |
| P1-A5 | 🔁 CR-02 E2 A | Zielwert «≥ 70 % automatisch abgeschlossen» widerspricht der Klickpflicht; im Ist-Umfang gibt es keine Klasse-A-Automatik |
| P1-A6 | ✅ | 1.4-A2 und 1.4-A3 |
| P1-A7 | ✅ | 1.4-A4 (Nachweis im Fachprotokoll und `document.body`, nicht in `evidence` – DM-TD6) |
| P1-A8 | ✅ | 1.1-A2, 1.3-A7; CR-12 Nachlauf-Wiederholung ohne Dubletten |
| P1-A9 | ⏭ | = 1.2-A3 |
| P1-A10 | ✅ | = 1.4-A5 |
| P1-A11 | ⏭ | = 1.3-A5 |
| P1-A12 | ✅ | WID-31.10 (T-15); T-16 setzt den Dokumentvergleich voraus und ist mit G-2 verschoben |
| P1-A13 | ⬜ | Pilotkennzahl; Stand 2/47 (4 %) |
| P1-A14 | ✅ | `jarvis_ops.tech_event` ohne Inhaltsspalte (K-04, DB-31.10). G-3 A umgesetzt 31.10.: `saveDataErrorExecution: none` in allen 6 Workflows (document_desk, auftrag_desk, dokument_suche, text_erfassen, volltext_nachlauf, db_sicherung), nachgelesen; 0 gespeicherte Fehlerausführungen. DM-TD8 erledigt |
| P1-A15 | ⏭ | = 1.4-A8 |
| P1-A16 | ✅ | DB-31.10: 0 Verstösse; S1: falsche Endung abgewiesen |
| P1-A17 | ⏭ | `betrag_roh`/`datum_roh` werden gespeichert, die Ableitbarkeit wird nicht geprüft (DM-TD4) |
| P1-A18 | ⏭ | Positionsbelegprüfung nicht gebaut (DM-TD4) |
| P1-A19 | ⏭ | Klärungs-Wiederanlauf nach Registry (§15.2.1) nicht gebaut; Wiederholung über erneuten Upload |
| P1-A20 | ✅ | `tool_release_log`: 4 freigegebene Versionen mit Nachweis; Gegenprobe R-2e `release_evidence_missing`. Hinweis: Die Ablage nutzt `move_file` ohne Freigabe (DM-TD2) – Kriterium wörtlich erfüllt, Abweichung bekannt |
| P1-A21 | ✅ | CODE-31.10: Kalenderprüfung 5/5 (29.02.2024 gültig; 31.02.2026, 29.02.2023, Fremdformat abgewiesen); ungültige Frist → leer + «Frist bitte prüfen» |
| P1-A22 | ✅ | CODE-31.10: Geldprüfung 4/4 (Zahl, Exponent, eine Nachkommastelle abgewiesen); DB-31.10 nur Zeichenfolgen; kein `parseFloat`/`toFixed` im Workflow |
| P1-A23 | ✅ | Befund B-1 behoben (Freigabe «B-1 A» 31.10.): `discarded`/`misrouted` werden im Knoten «Dublette bewerten» wie eine Dublette behandelt; aktiv `0a96392a-2057-440c-b8f5-3810d26bde89`, Versionsvergleich: nur dieser Knoten geändert. GEGEN-31.10 13/13 (verworfen mit/ohne Analyse, fehlgeleitet, abgelegt → keine Verarbeitung; `failed` → Wiederholung wie bisher) |
| P1-A24 | ✅ | Kein Schreibpfad in einen anderen Kontext vorhanden (nur Kontext `privat` produktiv, getrennte Zugänge, 1.0-A1) |

## 8. Phase-Gate (Spec §18.4) und Testfälle (Spec §17)

### 8.1 Gate G1–G9

| Nr. | Status | Begründung |
|---|---|---|
| G1 | ⬜ | P1-A1–A4, A13 offen (Pilotkennzahlen) |
| G2 | ⬜ | 9 Testfälle offen (Pilot); 29 nach Phase 2 verschoben (G-2 A) |
| G3 | ✅ | GATE-1.0 (Freigabe 10.09.2026) |
| G4 | ⬜ | Viele Fehlerwege getestet (S1, CR-12, Sicherung). Offen: TS-37 (Brieffehler nicht live provoziert), TS-12 (keine aktive Fehlermeldung) |
| G5 | ⬜ | DECISION_LOG im Repo enthält CR-12 und CR-17 bis CR-19, aber nicht CR-01 bis CR-16, DT-1 und die DM-TD-Schulden. Nachtrag ist vorbereitet (`claude/DECISION_LOG_NACHTRAG_CR-19_2026-10-31.md`), wartet auf PR. OFFEN-1 mit G-5 A geschlossen (DT-1 gilt) |
| G6 | ✅ | TS-33b (31.10.): 22 Workflows wiederhergestellt, `check_restore` und `check_ts10` bestanden |
| G7 | ⬜ | Schulden sind dokumentiert, aber über 12 Dokumente verteilt; konsolidierte Liste fehlt |
| G8 | ⬜ | nach Pilotende |
| G9 | ⬜ | nach Pilotende (14.11.2026) |

### 8.2 Testfälle P1-T-01 bis P1-T-72

**17.1 Normalablauf**

| ID | Status | Begründung / Nachweis |
|---|---|---|
| T-01 | 🔁 CR-06/17 | Versicherungsschreiben → Ordner über Register statt Vorgang; Live-Ablagen, CR-17 19/19 |
| T-02 | ✅ | S1 Beitragsanpassung: Frist erkannt; DB-31.10: 12 Aufgaben mit Frist und Erfolgskriterium |
| T-03 | ⬜ | Rechnung mit Positionen: kein Nachweis (Pilot) |
| T-04 | ⬜ | Smartphone-Foto JPG: noch kein abgelegtes JPG (Pilot) |
| T-05 | 🔁 CR-17 | Zweites Dokument → bestehender Ordner über Kennung |
| T-06 | ⏭ | Dokumentvergleich `changes_vs_previous` (§9.7) nicht gebaut |
| T-07 | ⬜ | Mehrseitiger Vertrag: im Pilot prüfen |

**17.2 Ausnahmen**

| ID | Status | Begründung / Nachweis |
|---|---|---|
| T-08 | ✅ | S1 Dublette |
| T-09 | ⏭ | = 1.1-A3 |
| T-10 | 🔁 CR-02 Krit. 5 | S1 unlesbares PDF → `needs_review` |
| T-11 | 🔁 CR-02 Krit. 6 | S1 verschlüsseltes PDF abgewiesen |
| T-12 | ⬜ | Grössengrenze 15 MB (DM-TD9) ohne dokumentierten Test |
| T-13 | 🔁 CR-02 Krit. 5 / CR-06 | Unbekannte Art → Prüfung nötig bzw. Unterkategorie-Vorschlag per Klick |
| T-14 | 🔁 CR-17 | Abweichende Kennung → Rückfrage vor Ablage (19/19) |
| T-15 | ✅ | WID-31.10 |
| T-16 | ⏭ | Setzt den Dokumentvergleich (§9.7) voraus, der mit G-2 A nach Phase 2 verschoben ist |
| T-17 | ⬜ | Im Code vorhanden (Frist ausserhalb Fenster → `plausibel: false` + Unsicherheit), Testnachweis fehlt |
| T-18 | ✅ | DB-31.10: abgelegte Dokumente ohne Aufgabe; CR-08 «Nur ablegen» |

**17.3 Kontext und Trennung**

| ID | Status | Begründung / Nachweis |
|---|---|---|
| T-19 | ⏭ | Kein Verarbeitungsablauf Arbeitgeber; Trennung auf DB- und Adapterebene nachgewiesen (1.1b Teil 2) |
| T-20 | ⏭ | wie T-19 |
| T-21 G | ✅ | GATE-1.0 |
| T-22 G | ✅ | GEGEN-31.10 8/8 (siehe G-1-Tabelle) |
| T-23 G | ✅ | GATE-1.0 |

**17.4 Freigabe** – T-24 bis T-31: alle ⏭ = 1.3-A5 (Klasse-C-Freigabeweg nicht gebaut).

**17.5 Nachweis und Idempotenz**

| ID | Status | Begründung / Nachweis |
|---|---|---|
| T-32 | ✅ | S1 Readback; DB-31.10 39/39 |
| T-33 G | ✅ | Kernbaustein `evidence_verify`: 26 `not_confirmed` aus Smoke-Läufen. Weboberfläche nutzt eigenen Readback (DM-TD6) |
| T-34 | ⬜ | `inconclusive` → Wiederanlauf nur im Code, kein Testnachweis |
| T-35 | ⏭ | Wiederanlauf je Stufe nicht gebaut |
| T-36 | ⬜ | Netzwerkfehler beim Verschieben: kein Testnachweis |
| T-37 | ✅ | = 1.3-A7 |
| T-38 G | ⏭ | DM-TD4 |
| T-39 G | ⬜ | Schemaverletzung der Modellantwort: Bereinigung vorhanden, Retry/Ausnahme nicht nachgewiesen |
| T-45 | ✅ | CODE-31.10 |
| T-46 | ✅ | CODE-31.10 (`1234.50`, Währung getrennt); DB-31.10 |
| T-47 | 🔁 CR-17 | Kennungsnormalisierung, Zuordnung zum Ordner statt Vorgang (19/19) |
| T-48–T-50 G | ⏭ | DM-TD4 (3 Fälle) |
| T-51 | ⬜ | = T-04 |
| T-52 G | ✅ | S1 falsche Endung abgewiesen; DB-31.10 0 Verstösse |
| T-53 G | 🔁 CR-02 Krit. 6 | abgewiesen statt `quarantined` (S1 TXT) |
| T-54–T-57 | ⏭ | Klärungs-Wiederanlauf nicht gebaut (4 Fälle) |
| T-58 G | ✅ | R-2e `release_evidence_missing` (`PHASE_1_0_TOOL_REGISTRY_2026-09-10.md`) |
| T-59 | ✅ | CODE-31.10 |
| T-60 G | ✅ | CODE-31.10 |
| T-61 G | ✅ | CODE-31.10 |
| T-62 G | ⏭ | Keine Uhrzeitfelder im Ist-Umfang |
| T-63 | ✅ | CODE-31.10 |
| T-64 | ⏭ | Keine Summenbildung im Ist-Umfang |
| T-65 G | ✅ | CODE-31.10 |
| T-66 G | ✅ | CODE-31.10 |
| T-67 | ✅ | S1 Dublette, kein zweiter Datensatz |
| T-68 | ✅ | 0041; DB-31.10: 16 `discarded` mit Protokoll |
| T-69 | ⏭ | `misrouted` im Ist-Umfang nicht erreichbar (ein Kontext) |
| T-70–T-72 G | ⏭ | Klärungsmodell nicht gebaut (3 Fälle) |

**17.6 Betrieb**

| ID | Status | Begründung / Nachweis |
|---|---|---|
| T-40 | ⏭ | = 1.4-A8 |
| T-41 | ✅ | K-04 (GATE-1.0) |
| T-42 G | ✅ | K-04; DB-31.10 Spalten `tech_event` |
| T-43 | ✅ | TS-33b |
| T-44 | ✅ | Kategorien/Ablage als Tabelle (`filing_rule` 0027, Register 0035), 43 `config_changed` ohne Workflow-Eingriff |

## 9. Offene Punkte – priorisiert

### A. Vor dem Gate zwingend

| # | Punkt | Kriterien | Stand |
|---|---|---|---|
| A1 | Pilotkennzahlen messen (Basis G-4 A: alle echten Dokumente seit 27.09., Pilotzeitraum gesondert) | P1-A1–A4, A13, 1.2-A1/A2, 1.4-A1 | ab 14.11.; Feld-/Fristqualität als Stichprobe von 20 Dokumenten, Rolf bestätigt per Klick |
| A2 | Widerspruchstest | P1-A12, 1.2-A5, 1.3-A6, T-15 | **erledigt** (WID-31.10) |
| A3 | Gegenprobe Ablagepfad | T-22 | **erledigt** (GEGEN-31.10 8/8) |
| A4 | Fehlerausführungen | P1-A14 | **erledigt** (G-3 A umgesetzt) |
| A5 | DECISION_LOG nachtragen | G5 | Nachtrag vorbereitet, PR offen |
| A6 | Schuldenliste konsolidieren | G7 | mit der Gate-Vorlage |
| A7 | Terminaler Status | P1-A23 | **erledigt** (B-1 A umgesetzt, 13/13) |
| A8 | Sicherheitsprüfung Datenbank-API | Hinweis HANDOVER CR-16 | **erledigt** 31.10.: Die API-Rollen `anon`, `authenticated`, `authenticator`, `service_role` haben weder Schemarecht (USAGE) noch Tabellenrechte auf `jarvis_privat`, `jarvis_visolva`, `jarvis_ops`; trotz ausgeschaltetem RLS über die Supabase-API nicht erreichbar |
| A9 | Pilotbericht, Übergabe Phase 2 | G8, G9 | nach 14.11. |
| A10 | Befund B-2: Kontextwerte im Phase-1-Code | Grundprinzip «keine fest eingebauten Werte», 1.1-A18 | **entschieden B-2 A**: Schuld TS-41, TS-33b präzisiert |

### B. Nach Phase 2 verschoben (G-2 A, 31.10.2026)

Klasse-C-Freigabeweg (1.3-A5, P1-A11, T-24–T-31) · Belegprüfung je Feld (1.2-A3/A4, P1-A9, A17, A18, T-38, T-48–T-50) · Klärungs-Wiederanlauf (P1-A19, T-35, T-54–T-57, T-69–T-72) · Tagesbericht (1.4-A8, P1-A15, T-40) · `duplicate_suspected` (1.1-A3, T-09) · Dokumentvergleich (T-06, T-16) · Arbeitgeberablauf (K-08, T-19, T-20) · Modellbenchmark (1.2-A7) · T-62, T-64 (im Ist-Umfang ohne Gegenstand).

### C. Im Pilot mitprüfen (nicht blockierend)

T-03, T-04/T-51, T-07, T-12, T-17, T-34, T-36, T-39, 1.3-A2 (Verbotsliste).

## 10. Entscheidungen

| Nr. | Entscheidung (Rolf, 31.10.2026) | Umsetzung |
|---|---|---|
| G-2 A | Punkte aus 9 B nach Phase 2, als Paket, inkl. Modellbenchmark | in dieser Matrix; DECISION_LOG-Nachtrag |
| G-3 A | Fehlerausführungen in n8n nicht speichern | umgesetzt in 6 Workflows, nachgelesen |
| G-4 A | Messbasis Pilotbericht: alle echten Dokumente seit 27.09.2026, Pilotzeitraum gesondert | im Pilotbericht |
| G-5 A | DT-1 gilt, OFFEN-1 geschlossen (Repo bleibt öffentlich, Daten getrennt) | DECISION_LOG-Nachtrag |
| B-1 A | Verworfene und fehlgeleitete Dokumente sind terminal (P1-A23) | umgesetzt, aktiv `0a96392a`, Gegenprobe 13/13 |

**B-2 A (Rolf, 31.10.2026):** 16 fest eingebaute Kontextwerte (`privat`, `jarvis_privat`) in den fünf Phase-1-Workflows (`check_ts10.py --src n8n/phase-1`) werden als Schuld **TS-41** geführt und bereinigt, sobald ein zweiter Kontext die Weboberfläche nutzt (frühestens Phase 2). Ursache CR-02 E1 A (Weboberfläche nur `privat`). TS-33b gilt für `check_ts10` nur für `n8n/core`.

## 11. Beobachtung für den Pilotbericht

- **P-4:** Mehrere Vertragsordner (vor CR-17 angelegt) tragen die Vertragsnummer im Ordnernamen, obwohl CR-06 E2 A «Nummer ins Register statt in den Ordnernamen» vorsieht. Nur Hinweis, keine Änderung ohne Freigabe.
- **P-5:** Beim Widerspruchsfall ist der Zahlungsblock mit dem geforderten Betrag (CHF 1'520.00) vorbelegt. Wählt Rolf trotzdem «Bezahlen», entsteht die Zahlungsaufgabe ohne Warnhinweis zur Differenz. Für Phase 2 prüfen.
- 13 Smoke-Test-Aufgaben (offen) und 13 Visolva-Testdokumente (`received`) verfälschen Zählungen; im Pilotbericht herausfiltern, nicht löschen.

## 12. Nächster Schritt

1. Rolf: Testdokument `SYNTH_Widerspruch_Rechnung.pdf` in der Weboberfläche verwerfen.
2. Claude: PR (DECISION_LOG-Nachtrag, Neuexport document_desk mit B-1 und G-3-Einstellungen).
3. Ab 14.11.2026: Pilotbericht (A1), Gate-Vorlage, Übergabe Phase 2.

Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.
