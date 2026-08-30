# Nachweis Phase 1.0 — Ausführung im Supabase-Zielprojekt

**Datum:** 30. August 2026
**Zielprojekt:** Supabase, Projektkennung `slatmyyxwruxvihcaklk` (Konnektor `Supabase JARVIS`, Zugriff über MCP)
**Serverfassung:** PostgreSQL **17.6**
**Zugangsrolle:** `postgres` — auf Supabase **kein** Superuser, sondern eine Rolle mit `CREATEROLE`
**Ausgangszustand:** keine Migrationen, keine `jarvis*`-Schemata, keine `jv_`-Rollen — vor Beginn per MCP geprüft

Dieses Protokoll hält den Lauf gegen die echte Zielinstanz fest. Der vorangegangene lokale Lauf gegen PostgreSQL 16.13 steht in [`NACHWEIS_PHASE_1_0_DATENBANK.md`](NACHWEIS_PHASE_1_0_DATENBANK.md).

---

## 1. Ausgeführte Migrationen

Alle über `apply_migration`, in dieser Reihenfolge, jede einzeln mit einer Zustandsabfrage nachgeprüft. **Zehn von zehn erfolgreich, kein Fehlschlag, keine Wiederholung.**

| Reihenfolge | Migration | Registrierte Fassung | Nachprüfung |
|---|---|---|---|
| 1 | `0001_create_context_roles` | 20260830101645 | beide Rollen vorhanden, `rolcanlogin = false` |
| 2 | `0002_ops_schema` | 20260830101714 | 5 Tabellen, 4 Trigger |
| 3 | `0003_context_schema_privat` | 20260830101812 | Schema mit 10 Tabellen |
| 4 | `0004_context_schema_visolva` | 20260830101906 | Schema mit 10 Tabellen |
| 5 | `0005_phase1_tables_privat` | 20260830101953 | 17 Tabellen, `document_index` abgelöst |
| 6 | `0006_phase1_tables_visolva` | 20260830102037 | 17 Tabellen, `document_index` abgelöst |
| 7 | `0007_grants_and_isolation_privat` | 20260830102056 | — |
| 8 | `0008_grants_and_isolation_visolva` | 20260830102108 | — |
| 9 | `0009_context_registry_seed` | 20260830102117 | 2 Kontexte, 2 Vertragsversionen |
| 10 | `0010_admin_role_membership` | nach Befund ergänzt | `SET ROLE` auf beide Kontextrollen möglich |

---

## 2. Befund, der Migration 0010 nötig gemacht hat

Nach `0001` schlug der erste Prüfversuch mit einer unerwarteten Meldung fehl:

```
SET ROLE jv_privat_user;
ERROR 42501: permission denied to set role "jv_privat_user"
```

**Ursache.** Auf Supabase ist `postgres` kein Superuser. Seit PostgreSQL 16 zerfällt eine Rollenmitgliedschaft in drei getrennte Rechte. Beim Anlegen einer Rolle durch eine `CREATEROLE`-Rolle entsteht sie als:

```
admin_option = true, inherit_option = false, set_option = false
```

Der Administrator darf die Rolle also verwalten, aber nicht annehmen. Lokal war das nicht aufgefallen, weil dort ein echter Superuser lief, der jede Rolle annehmen kann.

**Folge ohne Behebung.** Die Kriterien 1.0-A1 bis 1.0-A4 wären überhaupt nicht prüfbar gewesen. Gefährlicher noch: Dieser Fehler trägt denselben SQLSTATE `42501` wie die erwartete Zugriffsverweigerung. Eine Prüfung, die nur auf den Fehlercode schaut, hätte ihn als **bestandene Kontexttrennung** gewertet, obwohl nichts geprüft wurde. Die Prüfblöcke vergleichen deshalb den Meldungstext, nicht nur den Code.

**Behebung.** Migration `0010_admin_role_membership.sql` vergibt `SET TRUE` bei ausdrücklich `INHERIT FALSE`. Die Rechte des Kontextbenutzers wirken damit ausschliesslich nach einem bewussten `SET ROLE`, nie beiläufig. Kein Anmelderecht, kein Kennwort, keine neue Befugnis für `postgres` — es ist ohnehin Eigentümer aller drei Schemata. Die Kontexttrennung bleibt unberührt: Sie trennt `jv_privat_user` von `jv_visolva_user`, nicht den Eigentümer von seinen eigenen Schemata.

An fachlichen Schemas und Vertragsregeln wurde nichts geändert.

---

## 3. Abnahme gegen Supabase — 23 von 23 bestanden

Ausgeführt als `tests/db/phase_1_0_acceptance.sql` über MCP. Ausschliesslich synthetische Testdaten.

| Nr. | Kriterium | Ergebnis auf Supabase |
|---|---|---|
| 1.0-A1 | Schreiben in fremdes Kontextschema | `42501 permission denied for schema jarvis_visolva` |
| 1.0-A1b | Lesen aus fremdem Fachprotokoll | `42501 permission denied for schema jarvis_visolva` |
| 1.0-A2 | Protokolleintrag mit fremder `context_id` | `23514 log_context_chk` |
| 1.0-A2b | Aktion mit fremder `context_id` | `23514 action_context_chk` |
| 1.0-A3a | `UPDATE` auf `action_log` als Kontextbenutzer | `42501 permission denied for table action_log` |
| 1.0-A3b | `UPDATE` als Eigentümer | `42501 append_only_violation` |
| 1.0-A3c | `DELETE` als Kontextbenutzer | `42501 permission denied for table action_log` |
| 1.0-A3d | `DELETE` als Eigentümer | `42501 append_only_violation` |
| 1.0-A3e | `TRUNCATE` | `42501 append_only_violation` |
| 1.0-A4 | `INSERT` in `action_log` mit Sequenz | gelungen, `log_id = 4` |
| 1.0-A5 | Workflow-Lauf starten und abschliessen | `status = succeeded` |
| 1.0-A5b | Abgeschlossenen Lauf erneut ändern | `run_already_final` |
| 1.0-A6 | Gleicher Idempotenzschlüssel zweimal | `23505 action_idempotency_uq` |
| 1.0-A6b | Anzahl Aktionen danach | genau 1 |
| 1.0-A7 | Sperre beanspruchen | Schlüssel zurückgegeben |
| 1.0-A7b | Zweiter Anspruch | keine Zeile, kein Fehler |
| 1.0-P1a | Vorgangsnummer je Kontext und Jahr | `V-2026-0001`, `V-2026-0002` |
| 1.0-P1b | Dokument und Vorgang anlegen | gelungen |
| 1.0-P1c | Gleicher `content_hash` | `23505 document_content_hash_uq` |
| 1.0-P1d | Dublette ohne Original | `23514 document_duplicate_requires_original` |
| 1.0-P1e | Doppelte Vorgangskennung | `23505 case_identifier_value_uq` |
| 1.0-P1f | Vorgang schliessen ohne Zeitpunkt | `23514 case_closed_requires_timestamp` |
| 1.0-P1g | `DELETE` auf dem Dokumentregister | `42501 permission denied for table document` |

**1.0-A8 ist nicht geprüft und bleibt offen.** Export und Wiederherstellung der Workflows setzen die n8n-Subworkflows voraus, die noch nicht existieren.

### Befund im Prüfaufbau: eine Transaktion statt vieler

Der erste Durchlauf über MCP meldete 20 von 23. Die drei Fehlschläge — A6b, A7, A7b — hatten dieselbe Ursache und lagen **nicht** am Schema.

Die Python-Fassung ruft `psql` je Prüfung einmal auf; jede Anweisung wird sofort wirksam. Über MCP läuft dagegen alles in **einer** Transaktion. Der erwartete Unique-Fehler des zweiten `INSERT` rollte den umschliessenden Unterblock zurück — samt der ersten, geglückten Aktion. Danach fehlte die Aktion, auf die die Sperre per Fremdschlüssel verweist, und A7 scheiterte mit `23503`.

Behoben, indem jede Vorbedingung in einem eigenen Unterblock steht. Der Wiederholungslauf ergab 23 von 23. Die korrigierte Fassung liegt als `tests/db/phase_1_0_acceptance.sql` im Repository und wurde zusätzlich gegen eine frische lokale PostgreSQL-16-Instanz vollständig durchlaufen: ebenfalls 23 von 23.

---

## 4. Readback gegen Supabase — 39 von 39 bestanden

Ausgeführt als `tests/db/readback_phase_1_0.sql` über MCP, gelesen aus dem Systemkatalog.

| Abschnitt | Prüfungen | Ergebnis |
|---|---|---|
| 1. Schemata | 3 | `jarvis_ops`, `jarvis_privat`, `jarvis_visolva` vorhanden |
| 2. Tabellen | 5 | 5 in `jarvis_ops`, je 17 je Kontextschema; `document_index` in beiden abgelöst |
| 3. Rollen | 4 | beide vorhanden, beide `NOLOGIN` |
| 4. Kontextbedingungen | 2 | je 16 Bedingungen `context_id = '<kontext>'` |
| 5. Trigger | 10 | drei Append-only-Trigger je Kontextschema, vier in `jarvis_ops` |
| 6. Eindeutigkeitsindizes | 12 | je sechs pro Kontextschema |
| 7. Kontextregister | 3 | 2 Kontexte, Einträge deckungsgleich mit der Kontextkonfiguration, 2 Vertragsversionen |

**Korrektur einer früheren Angabe.** Ein vorheriger Bericht und die erste Fassung von `NACHWEIS_PHASE_1_0_DATENBANK.md` nannten 44 Readback-Prüfungen. Richtig sind **39**; die Zahl stammt aus der Auszählung des Protokolls `PHASE_1_0_READBACK_2026-08-30.log` und der Prüfpunkte im Skript. Der Umfang der Prüfung hat sich nicht geändert, nur die genannte Zahl war falsch.

---

## 5. Was für Phase 1.0 weiterhin fehlt

Das Phase-1.0-Gate bleibt **offen**. Erfüllt sind sieben der acht Kriterien aus Abschnitt 7.3, und zwar nur ihr Datenbankanteil. Es fehlen:

1. **Die neun Kern-Subworkflows** aus Abschnitt 7.1 Punkt 7: `context_resolve`, `id_generate`, `idempotency_guard`, `action_classify`, `tool_invoke`, `evidence_verify`, `fach_log_write`, `tech_log_write`, `error_handler`.
2. **Kriterium 1.0-A8**: Export und Wiederherstellung der Workflows in eine leere Instanz.
3. **Anmelderecht und Zugangsdaten** für `jv_privat_user` und `jv_visolva_user`, einzurichten bei der n8n-Anbindung und ausschliesslich im Anmeldeinformationsspeicher von n8n zu halten.
4. **Freigabe der Werkzeuge** von `draft` auf `approved` — bewusst noch nicht erfolgt, solange die zugehörigen Subworkflows nicht praktisch existieren.
5. **Wiederherstellungstest** der Datenbank, offener Rest aus P1-O1.

Erst wenn alle acht Kriterien erfüllt und dokumentiert sind, schliesst mit dem Phase-1.0-Gate zugleich das Phase-0-Gate.
