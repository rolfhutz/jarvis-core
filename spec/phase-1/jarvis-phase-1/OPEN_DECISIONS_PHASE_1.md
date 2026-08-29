# JARVIS Phase 1 — Offene Entscheidungen

**Version 1.2 - 29. August 2026**

Keine dieser Entscheidungen blockiert die Freigabe der Spezifikation. Die Spalte „Spätestens" nennt den Zeitpunkt, ab dem die Umsetzung ohne die Entscheidung stehenbleibt.

| Nr. | Gegenstand | Spätestens |
|---|---|---|
| P1-O1 | PostgreSQL-Anbieter | vor Schritt 1.0 |
| P1-O2 | Freigabeadapter und HTTPS-Erreichbarkeit | vor Schritt 1.3 |
| P1-O3 | OCR-Dienst | Ende Schritt 1.1 |
| P1-O4 | Modellauswahl je Rolle | Ende Schritt 1.2 |
| P1-O5 | Eingangskanäle für Scan und Smartphone | vor Schritt 1.1 |
| P1-O6 | Kategorienliste und Ordner-Mapping | vor Schritt 1.2 |
| P1-O7 | Git-Repository | vor Schritt 1.0 |
| P1-O8 | Aufbewahrungsfristen | vor Pilotbeginn |
| P1-O9 | Umgang mit dem Altbestand | nach dem Phase-1-Gate |
| P1-O10 | Umgang mit Dokumenten ohne Handlungsbedarf | vor Schritt 1.3 |
| P1-O11 | Weitere Normalisierungsregeln für andere Sprachräume und für nicht monetäre Dezimalwerte | bei Bedarf, nicht blockierend |

---

## P1-O1 — PostgreSQL-Anbieter

**Verbindlich bereits entschieden:** verwaltetes PostgreSQL, anbieterunabhängige Architektur, Sicherung, Wiederherstellung und Export müssen möglich sein.

**Offen:** der konkrete Anbieter.

**Empfehlung:** Ein verwalteter Anbieter mit Rechenzentrum in der Schweiz oder der EU, täglicher Sicherung und Wiederherstellung auf einen Zeitpunkt. Entscheidend ist nicht der Name, sondern ein einmal tatsächlich durchgeführter Wiederherstellungstest vor Pilotbeginn. Keine Anbietererweiterungen verwenden, damit ein Wechsel ein Dump-und-Restore bleibt.

**Spätestens:** vor Schritt 1.0. Ohne Instanz beginnt nichts.

---

## P1-O2 — Freigabeadapter und HTTPS-Erreichbarkeit

**Sachlage:** Der bevorzugte Weg ist ein signierter Einmal-Link auf einen per HTTPS erreichbaren Bestätigungsendpunkt, umgesetzt als Webhook in n8n. Das setzt voraus, dass die genutzte n8n-Instanz von aussen erreichbar ist und ein Webhook-Pfad zulässig ist.

**Empfehlung:** Erreichbarkeit vor Schritt 1.3 klären. Falls nicht gegeben, empfehle ich als Ersatzadapter eine im eigenen Netz erreichbare Bestätigungsseite, nicht eine Freigabe per Antwortstichwort in einer E-Mail. Grund: Eine Antwort-E-Mail lässt sich nicht zuverlässig an genau eine Aktion und einen Inhaltsstand binden und erfüllt die Anforderungen an Einmalverwendung und Zweistufigkeit nur schwach.

Alle sieben Sicherheitsregeln aus Phase 0 gelten unabhängig vom Adapter. Das Aktions- und Freigabemodell ändert sich nicht; der spätere Wechsel auf die JARVIS-Oberfläche aus Phase 6 ist derselbe Adaptertausch.

**Spätestens:** vor Schritt 1.3.

---

## P1-O3 — OCR-Dienst

**Verfahren bereits entschieden:** Auswahl in Schritt 1.1 anhand von rund 20 repräsentativen Dokumenten nach dem Bewertungsraster in Spezifikation 8.5.

**Empfehlung:** Google Document AI als ersten Kandidaten testen, weil die private Ablage bereits auf Google Drive liegt, der Dienst Konfidenz und Positionsbezug je Feld liefert und Formular- sowie Tabellenerkennung mitbringt. Mindestens einen zweiten Kandidaten gegentesten, damit die Auswahl belastbar ist und der Adaptervertrag praktisch erprobt wird.

**Ausschlussbedingung:** Ein Dienst, der den Ausgabevertrag `schemas/tools/ocr_default.analyze_document.output.json` nicht erfüllt — insbesondere Konfidenz und Positionsbezug je erkanntem Block — scheidet unabhängig von der Textqualität aus. Ohne diese Werte ist die Belegpflicht aus Abschnitt 9.4.1 nicht umsetzbar. Der Vertrag liegt seit Version 4.0.1 vor und ist damit vor der Auswahl prüfbar.

**Spätestens:** Ende Schritt 1.1.

---

## P1-O4 — Modellauswahl je Rolle

**Verfahren bereits entschieden:** drei austauschbare Leistungsprofile, Modell-IDs nur in der Konfiguration, Benchmark vor Pilotbeginn.

**Empfehlung:** Mit einem Anbieter für alle drei Rollen starten und erst nach dem Benchmark differenzieren. Für `extraction_model` ein kleineres Modell mit erzwungener Schemaausgabe, für `reasoning_model` das stärkere. Bewertet werden Feldqualität, Fristerkennung, Schemaeinhaltung, Halluzinationsrate über die Belegprüfung, Laufzeit und Kosten.

**Kosten sind eine Messgrösse, kein Ausschlusskriterium.** Pflichtfeldqualität und Fristerkennung haben Vorrang. Erst wenn zwei Modelle bei diesen beiden Kennzahlen gleichauf liegen, entscheiden Kosten.

**Spätestens:** Ende Schritt 1.2.

---

## P1-O5 — Eingangskanäle für Scan und Smartphone

**Sachlage:** Die Spezifikation verlangt je Kontext einen eigenen Eingangsordner, damit die Kontextauflösung immer `source_binding` ist. Wie Scanner und Smartphone dort hineinschreiben, ist offen.

**Empfehlung:** Für das Smartphone die Ablage-App mit einem Verknüpfungsziel auf den privaten Eingangsordner. Für den Scanner ein Scan-Profil, das direkt in denselben Ordner schreibt. Keine Zwischenstation über eine App mit eigener Logik.

Falls ein Gerät nur an einen einzigen Zielordner schreiben kann und beide Kontexte bedienen soll: den privaten Eingang wählen und Arbeitgeberdokumente manuell in den anderen Eingang legen. Eine automatische Aufteilung eines gemeinsamen Eingangs auf zwei Kontexte wird nicht gebaut — sie wäre eine Kontextauflösung per Modellvorschlag und damit für schreibende Aktionen unzulässig.

**Spätestens:** vor Schritt 1.1.

---

## P1-O6 — Kategorienliste und Ordner-Mapping

**Sachlage:** Die Startliste stammt aus Version 3 und ist plausibel, aber nicht am realen Bestand geprüft.

**Empfehlung:** Liste unverändert übernehmen und nach Woche 1 des Pilots anhand der tatsächlich aufgetretenen Dokumentarten anpassen. Das Mapping liegt in `config/category_map_privat.json`; eine Anpassung ist eine Konfigurationsänderung ohne Workflow-Eingriff. Für `arbeitgeber_visolva` in Phase 1 nur die drei Testordner.

**Spätestens:** vor Schritt 1.2, in erster Fassung.

---

## P1-O7 — Git-Repository

**Aus Phase 0 bereits freigegeben:** privates Repository unter einem von Rolf kontrollierten Konto, unabhängig vom Arbeitgeberkonto, Anbieter austauschbar, keine Zugangsdaten und keine fachlichen Dokumentinhalte im Repository.

**Offen für Phase 1:** die konkrete Einrichtung.

**Empfehlung:** Ein Repository für alle Phasen mit Ordnern `spec/`, `schemas/`, `registry/`, `config/`, `n8n/`, `prompts/`, `tools/`. Prompts werden versioniert wie Code, weil eine Prompt-Änderung dieselbe Wirkung hat wie eine Codeänderung.

**Spätestens:** vor Schritt 1.0, damit ab dem ersten Workflow exportiert wird.

---

## P1-O8 — Aufbewahrungsfristen

**Empfehlung:** Fachprotokolle zehn Jahre, technische Protokolle 90 Tage, Sitzungsdaten 30 Tage. In der Kontextkonfiguration stehen bereits 3650 Tage. Da Fachprotokolle append-only sind, ist ein zu langer Wert unkritisch, ein zu kurzer nicht rückholbar.

**Spätestens:** vor Pilotbeginn.

---

## P1-O9 — Umgang mit dem Altbestand

**Empfehlung:** Kein Import in Phase 1. Nach dem Phase-1-Gate selektiv nachziehen, und zwar nur Dokumente zu Vorgängen, die aktiv bearbeitet werden. Ein vollständiger Massenimport würde die Prüfquote unbrauchbar machen und den Bestand mit unsicheren Daten füllen.

**Spätestens:** nach dem Phase-1-Gate.

---

## P1-O10 — Dokumente ohne Handlungsbedarf

**Sachlage:** Ein Teil des Posteingangs erfordert keine Handlung, etwa eine Zahlungsbestätigung oder eine Werbebeilage. Die Spezifikation legt fest, dass solche Dokumente abgelegt werden und keine erfundene Aufgabe entsteht (Test P1-T-18). Offen ist, ob sie überhaupt vollständig analysiert werden sollen.

**Empfehlung:** In Phase 1 alle Dokumente vollständig analysieren, auch die ohne Handlungsbedarf. Grund: Der Bestand wird damit vollständig für Phase 4 aufgebaut, und die Klassifikation „kein Handlungsbedarf" ist selbst eine Aussage, die belegt sein muss. Eine Abkürzung für erkannte Werbung kann nach dem Pilot ergänzt werden, wenn die Kosten es rechtfertigen.

**Spätestens:** vor Schritt 1.3.

---

## P1-O11 — Weitere Normalisierungsregeln

**Status:** offen, nicht blockierend.

**Sachlage:** Die zwölf registrierten Regeln decken deutsche, schweizerische und
englische Schreibweisen für Datum, Betrag, Währung, Ganzzahl, Kennung,
Zeichenfolge und Wahrheitswert ab. Französische Datumsangaben fehlen. Ebenso
fehlt eine Regel für nicht monetäre Dezimalwerte, etwa Mengen mit
Nachkommastellen oder Prozentsätze; `quantity` ist derzeit ganzzahlig.

**Empfehlung:** Erst ergänzen, wenn im Pilot ein Dokument auftritt, das eine
Regel braucht. Eine Ergänzung besteht aus einem Registryeintrag, einer Funktion
in `tools/normalization_reference.py`, Beispielen und Ablehnungsfällen; sie
berührt weder die Prozesslogik noch die Phase-0-Verträge. Vorsorglich Regeln zu
bauen, die nie gebraucht werden, erhöht nur die Prüffläche.

**Verbindlich dabei:** Ein nicht monetärer Dezimalwert bekommt einen eigenen
Datentyp und eine eigene Regel. Er wird nicht über `decimal.de`, `decimal.ch`
oder `decimal.en` abgebildet, denn diese runden auf zwei Nachkommastellen.

**Spätestens:** bei Bedarf im Pilotbetrieb.

---

## Aus Phase 0 übernommene, weiterhin offene Punkte

| Nr. | Gegenstand | Zuständige Phase |
|---|---|---|
| O-5 | Benachrichtigungskanal für Klasse B und Eskalationen | Phase 2, da Klasse B in Phase 1 kein produktives Werkzeug hat |
| O-10 | Dauerhafte Speicherung kontextübergreifender Erkenntnisse | Phase 4, unverändert zurückgestellt |
