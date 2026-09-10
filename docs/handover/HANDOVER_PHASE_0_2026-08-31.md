# HANDOVER_PHASE_0_2026-08-31

**Modul:** Phase 0 — JARVIS-Fundament und Architekturverträge
**Stand:** 31. August 2026
**Gate-Status:** geschlossen. Freigabe durch Rolf am 31.08.2026 in diesem Chat erteilt.
**Vorheriger Chat:** „JARVIS Phase 0 Spezifikation und Verträge" (29.08.2026), „Supabase Alternativen und Kostenvergleich" (29.08.2026)

---

## 1. Ziel des Moduls

Festlegung der gemeinsamen Regeln und Datenverträge vor der technischen Umsetzung, damit Phase 1 nicht nachträglich umgebaut werden muss. Phase 0 baut keinen Assistenten, sondern das Fundament: Kontextmodell, Objekt-IDs, Ereignis- und Aktionsformat, Ergebnisnachweis, Werkzeug- und Agentenregister, Gedächtnismodell, n8n-Konventionen, Fehlerlogik, Idempotenz und Testfälle.

Der Gate-Abschluss dieses Chats betrifft ausschließlich den zuletzt offenen Teil: den praktischen Nachweis der Abnahmekriterien **A-3 (Kontexttrennung)** und **A-4 (Dublettenfreiheit)** gegen eine laufende Datenbank und aus n8n heraus.

---

## 2. Verbindliche Entscheidungen

Unverändert gültig aus dem Phase-0-Artefaktpaket v1.1.0:

- **B1** PostgreSQL ist die einzige Quelle der Wahrheit.
- **B2** Kontexttrennung über getrennte Schemas und getrennte Datenbank-Zugangsdaten.
- **B3** Technische Bezeichner in englischem snake_case; Arbeitssprache der Kommunikation ist Deutsch.
- **B4** Freigabe per E-Mail mit signiertem Einmal-Link.
- **B5** Zwei Startkontexte: `privat` und `arbeitgeber_visolva`.
- **D1–D6, D8, D9** wie im Artefaktpaket dokumentiert. Kern: Trennung von Aufgabe und Aktion, Unveränderlichkeit der Risikoklasse, vertragsgebundene Nachweisstrategie, kein LLM zwischen Freigabe und Ausführung, zweistufige Freigabebestätigung, bereinigte technische Protokolle, ausschließlich anfügende Fachprotokolle, logische Trennung von Planung, Freigabe, Ausführung und Prüfung.
- **D7** ist ausdrücklich zurückgezogen und als offene Entscheidung **O-10** nach Phase 4 verschoben.

In diesem Chat neu getroffen und von Rolf freigegeben:

- **E1** Je Kontext ein eigener anmeldefähiger Datenbankbenutzer, der die Rechte ausschließlich über eine Gruppenrolle erbt. Rechte hängen an der Gruppenrolle, nicht am Login. Damit ist der Login rotierbar, ohne Berechtigungen anzufassen. *(Freigabe: „B" am 31.08.2026)*
- **E2** Das Phase-0-Gate gilt als geschlossen. *(Freigabe: „Ich gebe das Phase-0-Gate frei." am 31.08.2026)*

Faktisch umgesetzt, formal noch **nicht** von Rolf als Entscheidung protokolliert: Supabase als PostgreSQL-Anbieter (siehe Abschnitt 9, P1-O1).

---

## 3. Umgesetzte Komponenten

### Datenbank

| Schema | Zweck | Tabellen |
|---|---|---|
| `jarvis_ops` | gemeinsame technische Ebene | 5: `context_registry`, `contract_version`, `tech_event`, `tool_circuit_state`, `workflow_run` |
| `jarvis_privat` | Fachkontext privat | 17 |
| `jarvis_visolva` | Fachkontext arbeitgeber_visolva | 17, strukturgleich |

Tabellen je Fachkontext: `action`, `action_lock`, `action_log`, `approval`, `case`, `case_identifier`, `case_number_seq`, `document`, `document_analysis`, `document_extraction`, `document_text`, `error_event`, `event`, `evidence`, `memory_entry`, `task`, `test_approval_record`.

### Migrationen

| Version | Name | Herkunft |
|---|---|---|
| 20260830101645 | `0001_create_context_roles` | Setup 30.08. |
| 20260830101714 | `0002_ops_schema` | Setup 30.08. |
| 20260830101812 | `0003_context_schema_privat` | Setup 30.08. |
| 20260830101906 | `0004_context_schema_visolva` | Setup 30.08. |
| 20260830101953 | `0005_phase1_tables_privat` | Setup 30.08. |
| 20260830102037 | `0006_phase1_tables_visolva` | Setup 30.08. |
| 20260830102056 | `0007_grants_and_isolation_privat` | Setup 30.08. |
| 20260830102108 | `0008_grants_and_isolation_visolva` | Setup 30.08. |
| 20260830102117 | `0009_context_registry_seed` | Setup 30.08. |
| 20260830102256 | `0010_admin_role_membership` | Setup 30.08. |
| — | `0011_context_login_users` | **dieser Chat, 31.08.** |
| — | `0012_context_login_search_path` | **dieser Chat, 31.08.** |

`0011` legt `jv_privat_login` und `jv_visolva_login` an: `LOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS`, Mitglied der jeweiligen Gruppenrolle, mit `CONNECT` auf die Datenbank. Passwörter werden bewusst **nicht** in der Migration gesetzt, damit kein Geheimnis in der Versionshistorie landet.

`0012` setzt je Login-Benutzer einen festen `search_path`, damit eine Abfrage ohne Schema-Präfix nicht in einem fremden Kontext landen kann.

### Rollenmodell

| Rolle | Art | Rechte |
|---|---|---|
| `jv_privat_user` | Gruppenrolle, NOLOGIN | `USAGE` auf `jarvis_privat` und `jarvis_ops` |
| `jv_visolva_user` | Gruppenrolle, NOLOGIN | `USAGE` auf `jarvis_visolva` und `jarvis_ops` |
| `jv_privat_login` | Login, erbt von `jv_privat_user` | `search_path = jarvis_privat, jarvis_ops, public` |
| `jv_visolva_login` | Login, erbt von `jv_visolva_user` | `search_path = jarvis_visolva, jarvis_ops, public` |

---

## 4. Dateien und Workflow-Namen

| Artefakt | Ort | Verantwortung |
|---|---|---|
| `jarvis_gate_test_context_isolation` | n8n, persönliches Projekt, ID `OX9nWrdOFxDAGviv` | Nachweis A-3 und A-4. Manuell ausgelöst, **nicht** veröffentlicht. |
| Credential `jarvis_db_privat` | n8n, Typ `postgres` | Datenbankzugang Kontext privat |
| Credential `jarvis_db_visolva` | n8n, Typ `postgres` | Datenbankzugang Kontext arbeitgeber_visolva |
| Phase-0-Artefaktpaket v1.1.0 | aus vorherigem Chat | Verträge, Schemata, Register |
| Phase-1-Spezifikation v4.0.2 | aus vorherigem Chat, 39 Dateien | wartet auf Freigabe |

Aufbau des Gate-Workflows, acht Knoten in Reihe:

`start` → `t1_privat_eigener_kontext` → `t2_privat_fremder_kontext` → `t3_visolva_eigener_kontext` → `t4_visolva_fremder_kontext` → `t5_rechtematrix_privat` → `t6_rechtematrix_visolva` → `gate_protokoll`

Die negativ erwarteten Knoten `t2` und `t4` laufen mit `onError: continueRegularOutput`, damit die Kette nicht abbricht und der Fehler auswertbar bleibt.

---

## 5. Datenmodelle und Schnittstellen

Für den Nachweis relevant:

- `action` — Primärschlüssel `action_id`; eindeutiger Index `action_idempotency_uq` auf `idempotency_key`; Prüfbedingungen: `context_id` fest je Schema, `actor = 'jarvis'`, `risk_class` in A/B/C, Klasse C nur mit erteilter Freigabe ausführbar, Status `succeeded` nur mit `executed_at` und `verified_at`.
- `action_lock` — Primärschlüssel `idempotency_key`, Fremdschlüssel auf `action`. Trägt den Ausführungsanspruch.
- `action_log` — anfügendes Fachprotokoll, `context_id` per Prüfbedingung an das Schema gebunden.
- `jarvis_ops.context_registry` — Zuordnung Kontext zu Schema und Datenbankbenutzer. Befüllt mit `privat` → `jarvis_privat` / `jv_privat_user` und `arbeitgeber_visolva` → `jarvis_visolva` / `jv_visolva_user`, beide `status = active`, `config_version = 1.0.0`.

Verbindungsweg n8n zur Datenbank: Supabase Session-Pooler, Port 5432, Benutzername im Format `<rolle>.<projekt_referenz>`, TLS erzwungen. Die Direktverbindung ist nur über IPv6 erreichbar und für n8n Cloud nicht nutzbar.

---

## 6. Zugangsvoraussetzungen

Ohne Angabe von Geheimnissen:

- Supabase-Projekt mit den drei Schemas; Pooler-Host und Projekt-Referenz aus dem Dashboard unter **Connect → Session pooler**.
- Zwei Datenbankpasswörter für `jv_privat_login` und `jv_visolva_login`, gesetzt per `ALTER ROLE`, verwahrt in Rolfs Passwortmanager. Sie stehen in keiner Migration, keinem Workflow und keiner Dokumentation.
- n8n-Instanz mit den beiden Postgres-Credentials.
- Schreibzugriff auf das Git-Repository ist weiterhin **nicht** vorhanden (siehe P1-O7).

---

## 7. Ausgeführte Tests und Ergebnisse

### Vorlauf: Nachweis auf Datenbankebene (31.08., über Adminverbindung mit `SET ROLE`)

| Prüfung | Erwartung | Ergebnis |
|---|---|---|
| `jv_privat_user` schreibt nach `jarvis_privat.action` | gelingt | bestanden, `act_gate_a3_privat_001` |
| `jv_privat_user` schreibt nach `jarvis_visolva.action` | scheitert | bestanden, `42501 permission denied for schema jarvis_visolva` |
| `jv_visolva_user` liest aus `jarvis_privat.action` | scheitert | bestanden, `42501 permission denied for schema jarvis_privat` |
| zweite Aktion mit gleichem `idempotency_key` | scheitert | bestanden, `23505` auf `action_idempotency_uq` |
| zweiter Lock-Claim über `ON CONFLICT` | keine Dublette | bestanden, ein Lock, gehalten von Lauf 1 |
| Rechtematrix über alle 39 Tabellen | vollständige Trennung | bestanden |

### Hauptnachweis: aus n8n, mit zwei getrennt authentifizierten Verbindungen

**Ausführung 20219 (31.08., 18:22):** Gesamtergebnis `NICHT BESTANDEN` für A-3.2 und A-3.4. Ursache war ein Fehler in der Auswertung, nicht in der Trennung. Die Bewertung suchte in der Fehlermeldung nach der Zeichenkette „permission denied"; n8n reicht die Postgres-Meldung in dieser Form nicht durch. Die Datenbank hatte beide Zugriffe korrekt abgewiesen.

**Korrektur:** Die negativen Prüfungen werden nicht mehr über einen Textabgleich bewertet, sondern über zwei unabhängige Belege — das Ausbleiben eines Ergebnisses **und** eine explizite Rechteabfrage per `has_schema_privilege` je Datenbankbenutzer. Dafür kamen die Knoten `t5_rechtematrix_privat` und `t6_rechtematrix_visolva` hinzu.

**Ausführung 20220 (31.08., 18:23): Gesamtergebnis BESTANDEN.**

| Prüfung | Beschreibung | Beleg |
|---|---|---|
| A-3.1 | privat schreibt in eigenen Kontext | gelungen als `jv_privat_login` |
| A-3.2 | privat greift auf fremden Kontext zu | abgewiesen, `schema_usage_fremd=false` |
| A-3.3 | visolva schreibt in eigenen Kontext | gelungen als `jv_visolva_login` |
| A-3.4 | visolva greift auf fremden Kontext zu | abgewiesen, `schema_usage_fremd=false` |
| A-3.5 | jeder erreicht seinen eigenen Kontext | beide `true` |
| A-4.1 | privat, keine Dublette | `neu=0 vorher=1` |
| A-4.2 | visolva, keine Dublette | `neu=0 vorher=1` |

Der Idempotenznachweis entstand über zwei zeitlich getrennte Läufe: Lauf 1 meldete `neu=1 vorher=0`, Lauf 2 meldete `neu=0 vorher=1`. Über beide Läufe existiert genau ein Datensatz je Kontext.

### Nicht getestet

- Trennung der Dokumentablagen (Google Drive) — gehört nach Masterfahrplan in Phase 1.
- Freigabeweg per E-Mail mit signiertem Einmal-Link — Phase 1, Schritt 1.3.
- Export und Wiederherstellung der Workflows.
- Verhalten bei Ausfall oder Pausierung der Datenbank.

---

## 8. Bekannte Fehler und technische Schulden

**P1-TD1 — Zertifikatskette der Datenbankverbindung wird nicht validiert.** Der n8n-Postgres-Knoten bietet kein Feld zur Hinterlegung des CA-Zertifikats. Beide Credentials laufen deshalb mit `SSL = Require` und aktiviertem „Ignore SSL Issues". Die Verbindung bleibt vollständig verschlüsselt, die Echtheitsprüfung des Gegenübers entfällt. Restrisiko: ein Angreifer zwischen n8n Cloud und Supabase fiele nicht am Zertifikat auf. Erneut prüfen, sobald n8n ein CA-Feld anbietet oder die Datenbank hinter einem eigenen Endpunkt liegt. *Vorgeschlagen am 31.08., von Rolf noch nicht ausdrücklich übernommen.*

**Testdaten im Fachbestand.** In beiden Fachschemas liegen Nachweisdatensätze: `act_gate_a3_privat_001` samt Lock, `act_gate_wf_privat`, `act_gate_wf_visolva` sowie ein älterer Eintrag `act_01JQ8ZKPT4N7VXWA2E5GHM3BCD` aus dem Setup vom 30.08. Offen ist, ob sie als Gate-Beleg bestehen bleiben oder vor Pilotstart entfernt werden.

**Betriebsauflagen aus der Anbieterentscheidung, noch nicht umgesetzt:** täglicher Keep-Alive-Ping gegen die Pausierung nach sieben Tagen Inaktivität, wöchentliche `pg_dump`-Sicherung, Datenbankadapter so gekapselt, dass ein Anbieterwechsel nur die Verbindungskonfiguration berührt.

---

## 9. Offene Entscheidungen

| Nr. | Gegenstand | Status |
|---|---|---|
| **P1-O1** | PostgreSQL-Anbieter | Supabase ist faktisch aufgesetzt und im Betrieb nachgewiesen, aber von Rolf noch nicht förmlich als Entscheidung protokolliert. Nachzuholen. |
| **P1-O2** | Freigabeadapter und HTTPS-Erreichbarkeit | offen, benötigt vor Schritt 1.3 |
| **P1-O5** | Eingangskanäle Scanner und Smartphone | offen, benötigt vor Schritt 1.0 |
| **P1-O7** | Schreibzugriff auf das Git-Repository | offen. Lesezugriff auf `rolfhutz/jarvis-core` bestätigt, Branch `main` mit Platzhalter-README. Das vorbereitete Startarchiv kann ohne Connector oder Token mit Schreibrecht nicht abgelegt werden. |
| **O-10** | zurückgezogene Entscheidung D7 | verschoben nach Phase 4 |
| — | Übernahme von P1-TD1 als technische Schuld | Vorschlag liegt vor |
| — | Umgang mit den Testdaten im Fachbestand | offen |

---

## 10. Exakter nächster Bauschritt

**Freigabe der Phase-1-Spezifikation v4.0.2 durch Rolf.**

Das Paket umfasst 39 Dateien und 108 Prüfungen und benötigt für den Validierungslauf das Phase-0-Paket unter `../jarvis-phase-0`. Bis zur Freigabe beginnt keine Umsetzung.

Danach in dieser Reihenfolge:

1. P1-O1 förmlich bestätigen.
2. P1-O7 klären, damit die Artefakte versioniert abgelegt werden können.
3. P1-O5 entscheiden.
4. Erst dann Phase 1, Schritt 1.0 beginnen.

---

## 11. Hinweis

**Bestehende Entscheidungen nicht neu erfinden. Änderungen nur ausdrücklich begründet und nach Freigabe.**
