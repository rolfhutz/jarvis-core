# JARVIS Phase 0 - Offene Entscheidungen

**Version 1.1.0 - 29. August 2026**

Keine dieser Entscheidungen blockiert die Freigabe der Phase-0-Spezifikation.
O-1, O-2 und O-9 müssen vor dem ersten technischen Meilenstein von Phase 1
geklärt sein.

---

## O-1 PostgreSQL-Anbieter und Datenstandort

**Status:** offen. Entscheidung während der Überarbeitung der Phase-1-Spezifikation.

Verbindlich ist bereits:

- verwaltetes PostgreSQL, kein Self-Hosting,
- anbieterunabhängige Architektur ohne Anbietererweiterungen,
- Sicherung, Wiederherstellung und Export müssen möglich sein.

**Empfehlung:** Rechenzentrum in der Schweiz oder der EU, tägliche Sicherung,
Wiederherstellung auf einen Zeitpunkt, einfacher Export als Dump. Wichtiger als
der Anbietername ist der nachgewiesene Wiederherstellungstest.

---

## O-2 HTTPS-Erreichbarkeit des Freigabeendpunkts

**Status:** offen, wird als technische Voraussetzung separat geprüft.

Die Spezifikation sieht beide Wege vor:

- **bevorzugt:** signierter Einmal-Link auf einen per HTTPS erreichbaren
  Bestätigungsendpunkt, umgesetzt als Webhook-Workflow,
- **alternativ:** ein anderer Freigabeadapter, sofern er alle sieben
  Sicherheitsregeln aus Abschnitt 9.2 der Spezifikation erfüllt.

Der Freigabekanal ist ein Adapter in `policy.approval.channel_adapter`. Das
Aktions- und Freigabemodell bleibt beim Wechsel unverändert. Die spätere
Freigabe über die JARVIS-Oberfläche aus Phase 6 ist derselbe Adaptertausch;
keine der jetzigen Festlegungen verhindert sie (AR-10).

**Zu prüfen:** Ist die genutzte n8n-Instanz von aussen per HTTPS erreichbar, und
ist ein Webhook-Pfad zulässig?

---

## O-3 Aufbewahrungsfristen für Fachprotokolle

**Status:** offen bis zum Produktivbetrieb von Phase 1.

**Empfehlung:** privat zehn Jahre, Arbeitgeber nach interner Vorgabe. In der
Vorlage stehen 3650 Tage. Da Fachprotokolle append-only sind, ist ein zu langer
Wert unkritisch, ein zu kurzer nicht rückholbar.

---

## O-4 Umgang mit dem Altbestand an Dokumenten

**Status:** offen bis zur Detailplanung von Phase 1.

**Empfehlung:** kein Import. Der Pilot arbeitet mit 50 bis 100 neuen Dokumenten
nach Masterfahrplan §1.6. Eine spätere Migration erfolgt selektiv und nur für
aktiv bearbeitete Vorgänge.

---

## O-5 Benachrichtigungskanal für Klasse B und Eskalationen

**Status:** offen bis Phase 1.

**Empfehlung:** derselbe E-Mail-Kanal wie die Freigabe, aber mit eigenem
Betreffpräfix für Filterregeln. Sammelbericht einmal täglich für Klasse B,
sofortige Meldung nur ab Stufe L2. Andernfalls entsteht die Meldungsflut, die
Masterfahrplan §5.4 ausschliesst.

---

## O-6 Erste Werkzeuge im Status `approved`

**Status:** offen bis zum Beginn von Phase 1.

**Empfehlung:** mit drei Werkzeugen im Kontext `privat` starten:
`storage_gdrive.move_file`, `tasks_internal.create_task`,
`approval_email.request_decision`. Alle drei sind reversibel oder harmlos und
unterstützen einen unabhängigen Readback. Erst nach nachgewiesener
Zuverlässigkeit folgt ein Werkzeug mit Aussenwirkung.

---

## O-7 Ablageort des Git-Repositorys

**Status:** **freigegeben** am 29.08.2026.

- privates Repository unter einem von Rolf kontrollierten Konto,
- unabhängig vom Arbeitgeberkonto,
- Git-Anbieter bleibt austauschbar,
- keine Zugangsdaten und keine fachlichen Dokumentinhalte im Repository.

---

## O-8 Sprachmodell je Aufgabenart

**Status:** offen, Festlegung in der Phase-1-Spezifikation.

**Empfehlung:** Trennung nach Aufgabenart statt eines einheitlichen Modells.
Extraktion aus Dokumenten und Klassifikation stellen andere Anforderungen als
Zusammenfassung oder Formulierung von Entwürfen. Der LLM-Adapter erlaubt diese
Trennung ohne Änderung der Prozesslogik.

---

## O-9 Technische Phase-1-Umgebung

**Status:** offen, zu klären nach Freigabe der überarbeiteten Phase-1-Spezifikation.

Zu bestimmen sind: PostgreSQL-Instanz nach O-1, n8n-Instanz und Berechtigungen,
Webhook-Erreichbarkeit nach O-2, Git-Repository nach O-7 sowie die Postfächer und
Speicherorte je Kontext.

Erst danach werden Datenbank und Kern-Sub-Workflows aufgebaut und A-3 und A-4
praktisch nachgewiesen.

---

## O-10 Dauerhafte Speicherung kontextübergreifender Erkenntnisse

**Status:** offen, ausdrücklich zurückgestellt bis **Phase 4**.

**Sachlage:** In Version 1.0.0 war als D7 vorgeschlagen, dass kontextübergreifende
Analysen niemals dauerhaft in einem Kontextschema gespeichert werden dürfen.
Diese Entscheidung wurde nicht freigegeben, weil sie das Langzeitgedächtnis aus
Phase 4 unnötig einschränken würde.

**Was in Phase 0 gilt:**

- kontextübergreifende Analyse nur auf ausdrückliche Anweisung von Rolf,
- jede daraus entstehende schreibende Aktion hat genau einen Zielkontext,
- Dokumentablagen und Fachprotokolle bleiben getrennt,
- keine irreversible Festlegung für die spätere Speicherung.

**Was offen bleibt:** ob kontextübergreifende Erkenntnisse dauerhaft gespeichert
werden, in welchem Speicher, mit welcher Kennzeichnung und mit welchen
Leserechten. Das Feld `visibility` in `memory_entry.schema.json` und die
Kennzeichnung solcher Vorgänge halten beide Wege offen.

**Zu entscheiden spätestens:** bei der Ausarbeitung des Langzeitgedächtnisses in
Phase 4.
