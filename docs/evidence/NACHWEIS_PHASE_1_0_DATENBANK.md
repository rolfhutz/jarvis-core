# Nachweis Phase 1.0 — Datenbankteil

**Datum:** 30. August 2026
**Umfang:** Schritt 1.0 aus `SPEC_PHASE_1_DOKUMENTENASSISTENT_v4.0.2.md`, Abschnitt 7, soweit er die Datenbank betrifft.
**Grundlage:** `db/migrations/0001` bis `0009` (`0010` kam beim Supabase-Lauf hinzu, siehe Abschnitt 1)

---

## 1. Wo dieser Nachweis erbracht wurde

Die Migrationen und alle praktischen Prüfungen dieses Nachweises liefen gegen **PostgreSQL 16.13**, eine leere lokale Instanz, die eigens für diesen Lauf aufgesetzt und danach verworfen wurde.

**Nachgetragen am 30. August 2026:** Der Lauf gegen die Supabase-Instanz ist inzwischen erfolgt und in [`PHASE_1_0_SUPABASE_2026-08-30.md`](PHASE_1_0_SUPABASE_2026-08-30.md) protokolliert — zehn Migrationen, 23 Abnahme- und 39 Readback-Prüfungen, alle bestanden. Zum Zeitpunkt dieses Dokuments war der Konnektor `Supabase JARVIS` nicht verbunden und `apply_migration` nicht verfügbar; das Folgeprotokoll ist deshalb massgeblich für alles, was die Zielinstanz betrifft.

Dort steht auch der einzige Befund, der lokal nicht auftreten konnte: Auf Supabase ist die Rolle `postgres` kein Superuser und darf die Kontextrollen ohne ausdrückliches `SET`-Recht nicht annehmen. Das machte Migration `0010_admin_role_membership.sql` nötig.

Die Aussagekraft des lokalen Laufs ist hoch, aber nicht vollständig: Die Migrationen verwenden ausschliesslich Standard-PostgreSQL 16 ohne Anbietererweiterung, weshalb ein abweichendes Verhalten nur dort zu erwarten wäre, wo Supabase Rechte einschränkt — beim Anlegen der Rollen in `0001` und bei den `REVOKE`-Anweisungen in `0007` und `0008`.

---

## 2. Ausgeführte Migrationen

| Datei | Inhalt | lokal |
|---|---|---|
| `0001_create_context_roles.sql` | Rollen `jv_privat_user`, `jv_visolva_user`, beide `NOLOGIN` ohne Kennwort | bestanden |
| `0002_ops_schema.sql` | Schema `jarvis_ops` mit fünf Tabellen und vier Triggern | bestanden |
| `0003_context_schema_privat.sql` | Schema `jarvis_privat`, Phase-0-Tabellen | bestanden |
| `0004_context_schema_visolva.sql` | Schema `jarvis_visolva`, Phase-0-Tabellen | bestanden |
| `0005_phase1_tables_privat.sql` | Phase-1-Tabellen nach Abschnitt 7.2 | bestanden |
| `0006_phase1_tables_visolva.sql` | Phase-1-Tabellen nach Abschnitt 7.2 | bestanden |
| `0007_grants_and_isolation_privat.sql` | Rechte und gegenseitige Entzüge | bestanden |
| `0008_grants_and_isolation_visolva.sql` | Rechte und gegenseitige Entzüge | bestanden |
| `0009_context_registry_seed.sql` | `context_registry` und `contract_version` befüllt | bestanden |

Die Reihenfolge ist bindend: Rollen vor Rechtevergabe, beide Kontextschemata vor den gegenseitigen Entzügen, Phase-1-Tabellen vor `0007`/`0008`, damit `REVOKE ALL ON ALL TABLES` auch die neuen Tabellen erfasst.

Die Dateien `0002` bis `0008` sind gerendert, nicht von Hand geschrieben. Quelle und Werkzeug stehen im Kopf jeder Datei.

---

## 3. Angelegte Struktur

**Schemata:** `jarvis_ops`, `jarvis_privat`, `jarvis_visolva`

**Rollen:** `jv_privat_user`, `jv_visolva_user` — beide `NOLOGIN`, `NOINHERIT`, ohne Sonderrechte und ohne Kennwort. Im Repository steht kein Geheimnis. Das Anmelderecht wird erst bei der n8n-Anbindung vergeben.

**Tabellen in `jarvis_ops` (5):** `workflow_run`, `tech_event`, `tool_circuit_state`, `contract_version`, `context_registry`

**Tabellen je Kontextschema (17):**

- Aus Phase 0 (9): `event`, `task`, `action`, `action_lock`, `approval`, `evidence`, `error_event`, `action_log`, `memory_entry`
- Aus Phase 1, Abschnitt 7.2 (8): `document`, `case`, `case_identifier`, `document_text`, `document_extraction`, `document_analysis`, `case_number_seq`, `test_approval_record`

`document_index` aus Phase 0 ist abgelöst und geht in `document` auf, wie Abschnitt 7.2 es vorschreibt. Der Unique-Index auf `content_hash` besteht fort.

**Registereinträge:** zwei Kontexte in `context_registry`, zwei Vertragsversionen in `contract_version` (Phase 0 = 1.1.0, Phase 1 = 4.0.2).

---

## 4. Abnahmekriterien

Protokoll: [`PHASE_1_0_ABNAHME_2026-08-30.log`](PHASE_1_0_ABNAHME_2026-08-30.log), erzeugt von `tests/db/phase_1_0_acceptance.py`. **23 Prüfungen, alle bestanden.**

| Kriterium | Prüfung | Ergebnis |
|---|---|---|
| 1.0-A1 | Schreiben in `jarvis_visolva.action_log` als `jv_privat_user` | abgewiesen, `42501 permission denied for schema jarvis_visolva` |
| 1.0-A1b | Lesen aus fremdem Fachprotokoll | abgewiesen, `42501 permission denied` |
| 1.0-A2 | Protokolleintrag mit fremder `context_id` | abgewiesen, `23514 log_context_chk` |
| 1.0-A2b | Aktion mit fremder `context_id` | abgewiesen, `23514 action_context_chk` |
| 1.0-A3a | `UPDATE` auf `action_log` als Kontextbenutzer | abgewiesen, `42501 permission denied for table action_log` |
| 1.0-A3b | `UPDATE` als Eigentümer | abgewiesen, `42501 append_only_violation` |
| 1.0-A3c | `DELETE` als Kontextbenutzer | abgewiesen, `42501 permission denied` |
| 1.0-A3d | `DELETE` als Eigentümer | abgewiesen, `42501 append_only_violation` |
| 1.0-A3e | `TRUNCATE` | abgewiesen, `42501 append_only_violation` |
| 1.0-A4 | `INSERT` in `action_log` mit Sequenz | gelungen, `log_id` vergeben |
| 1.0-A5 | Workflow-Lauf starten und abschliessen | gelungen, Status `succeeded` |
| 1.0-A5b | Abgeschlossenen Lauf erneut ändern | abgewiesen, `run_already_final` |
| 1.0-A6 | Gleicher Idempotenzschlüssel zweimal | abgewiesen, `23505 action_idempotency_uq` |
| 1.0-A6b | Anzahl Aktionen danach | genau 1 |
| 1.0-A7 | Sperre beanspruchen | gelungen, Schlüssel zurückgegeben |
| 1.0-A7b | Zweiter Anspruch auf dieselbe Sperre | keine Zeile zurück, kein Fehler |

Ergänzend zu den Phase-1-Tabellen: fortlaufende Vorgangsnummer (`V-2026-0001`, `V-2026-0002`), Anlegen von Dokument und Vorgang, harter Dublettenstopp über `content_hash`, Ablehnung einer Dublette ohne Original, Ablehnung einer doppelten Vorgangskennung, Ablehnung eines abgeschlossenen Vorgangs ohne Abschlusszeitpunkt, kein `DELETE` auf dem Dokumentregister. Alle sieben bestanden.

**1.0-A8 (Export und Wiederherstellung der Workflows) ist nicht geprüft.** Es setzt die n8n-Subworkflows voraus, die noch nicht existieren.

### Zwei Befunde aus dem Testaufbau

Beide betrafen die Tests, nicht das Schema, und sind behoben:

1. **Zeilenbasierte Trigger greifen auf einer leeren Tabelle nicht.** Der erste Lauf meldete `UPDATE`/`DELETE` auf `action_log` fälschlich als erfolgreich. Ursache: Es gab keine Zeile, die geändert worden wäre, also feuerte der `FOR EACH ROW`-Trigger nie. Die Tests legen sich jetzt zuerst eine eigene Zeile an. Fachlich bedeutet das: Der Trigger schützt vorhandene Zeilen, der Rechteentzug schützt zusätzlich davor, dass der Kontextbenutzer es überhaupt versucht. Beide Wege sind nötig, genau wie in der Phase-0-Vorlage beschrieben.
2. **`boolean::text` liefert in PostgreSQL `false`, nicht `f`.** Der Readback meldete deshalb fälschlich, die Rollen hätten Anmelderecht. Die Rollen sind und waren `NOLOGIN`.

---

## 5. Readback

Protokoll: [`PHASE_1_0_READBACK_2026-08-30.log`](PHASE_1_0_READBACK_2026-08-30.log), erzeugt von `tests/db/readback_phase_1_0.py`. **39 Prüfungen, alle bestanden.**

Zurückgelesen und gegen die Spezifikation abgeglichen wurden: drei Schemata, alle erwarteten Tabellen, zwei Rollen samt Anmelderecht, 32 Kontextbedingungen (16 je Kontextschema), zehn Trigger, zwölf Eindeutigkeitsindizes sowie die Einträge in `context_registry` und `contract_version`.

Der Readback fragt den Systemkatalog ab und verlässt sich nicht auf die Rückmeldung der Migration — Entscheidung D3 sinngemäss auf die Datenbank angewandt.

---

## 6. Bestehende Testläufe

Unverändert bestanden, nach allen Änderungen dieses Schritts erneut ausgeführt:

- **Phase 0** — `tools/run_all_tests.py`: 7 Schritte, **94 Einzelprüfungen** bestanden
- **Phase 1** — `tools/validate_phase1.py --phase0 …`: 8 Teile, **108 Einzelprüfungen** bestanden

An fachlichen Schemas und Vertragsregeln wurde nichts geändert. Ein Supabase-Kompatibilitätsfehler, der eine Anpassung erzwungen hätte, ist nicht aufgetreten — er konnte mangels Verbindung allerdings auch nicht auftreten.

---

## 7. Was für den Abschluss von Phase 1.0 noch fehlt

Das Gate bleibt **offen**. Es fehlen:

1. ~~Ausführung der Migrationen im Supabase-Projekt~~ — am 30. August 2026 erledigt, siehe [`PHASE_1_0_SUPABASE_2026-08-30.md`](PHASE_1_0_SUPABASE_2026-08-30.md).
2. **Die neun Kern-Subworkflows** aus Abschnitt 7.1 Punkt 7: `context_resolve`, `id_generate`, `idempotency_guard`, `action_classify`, `tool_invoke`, `evidence_verify`, `fach_log_write`, `tech_log_write`, `error_handler`.
3. **Kriterium 1.0-A8**, Export und Wiederherstellung der Workflows in eine leere Instanz.
4. **Freigabe der Werkzeuge** von `draft` auf `approved`. Bewusst noch nicht erfolgt: Ein Werkzeug wird erst freigegeben, wenn der zugehörige Subworkflow praktisch existiert.
5. **Wiederherstellungstest** der Datenbank, offener Rest aus P1-O1.

Erst wenn alle acht Kriterien aus Abschnitt 7.3 erfüllt und dokumentiert sind, schliesst mit dem Phase-1.0-Gate zugleich das Phase-0-Gate.
