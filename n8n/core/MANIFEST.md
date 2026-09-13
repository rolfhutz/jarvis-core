# Manifest der JARVIS-Kernworkflows

**Stand:** 13. September 2026, nach Schritt 1.1b Teil 2 (Speicheradapter Visolva, 1.1b-E3, 1.1b-E4, REL-1.1b-2, TS-33a)
**Instanz:** persoenliches n8n-Projekt `Rolf Hutz` (n8n Cloud)
**Grundlage:** SPEC_PHASE_0 1.1.0, SPEC_PHASE_1 4.0.2, ADR-002, ADR-003, E-1, E-2, TS10-E1 bis TS10-E3

| Workflow | ID | Status in n8n | Datenbank | Aenderung in 1.1a (TS-10) |
|---|---|---|---|---|
| `JV-CORE-SUB-context_resolve-v1` | `5IyWf1dH3huijkKG` | **veroeffentlicht** | ja (lesend, `jv_privat_postgres`, TS10-E2) | Aufloesung aus `jarvis_ops.source_binding` und `context_registry`; Grundcodes `input_invalid`, `binding_unknown`, `binding_disabled`, `context_not_active`, `binding_halted`, `hint_conflict`; `credential_ref` entfaellt |
| `JV-CORE-SUB-id_generate-v1` | `ZtUV95YyMA5IlgoE` | **veroeffentlicht** | nein | Kontextliste durch Formatpruefung ersetzt |
| `JV-CORE-SUB-idempotency_guard-v1` | `bpC5dlK2Ez0sVhUj` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang „Kontext ohne Weiche“ |
| `JV-CORE-SUB-action_classify-v1` | `tWVy6kRzwFMw4lmJ` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang |
| `JV-CORE-SUB-tool_invoke-v1` | `ELs6LnRIWKCv04yc` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang |
| `JV-CORE-SUB-evidence_verify-v1` | `UKcnRE0eJzyl8T1V` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang an Kontext- und Ablageweiche |
| `JV-CORE-SUB-fach_log_write-v1` | `8ur7Lc15KEF0Y8M1` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang |
| `JV-CORE-SUB-tech_log_write-v1` | `Bp7m62faVmLZ6VdB` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang |
| `JV-CORE-SUB-error_handler-v1` | `HOTikshdbkz6dk9q` | **veroeffentlicht** | ja | Kontextliste entfernt, Ausweichausgang |
| `JV-CORE-ADP-tasks_internal-v1` | `GFTIzQsak9UJVhAj` | **veroeffentlicht**, Aufrufer beschraenkt | ja | Kontexttabelle entfernt, Ausweichausgang auf „Ergebnis ungueltige Eingabe“ |
| `JV-CORE-ADP-docstore_internal-v1` | `2QdRVAniHgkWjqh2` | **veroeffentlicht**, Aufrufer beschraenkt | ja | wie `tasks_internal` |
| `JV-CORE-ADP-casestore_internal-v1` | `V1fuepKIR20OwgZp` | **veroeffentlicht**, Aufrufer beschraenkt | ja | wie `tasks_internal` |
| `JV-CORE-ADP-storage_gdrive-v1` | `qZpVoKoKuPRyOGg7` | **veroeffentlicht**, Aufrufer beschraenkt, Ausfuehrungsdaten nicht gespeichert | ja (lesend, `jv_privat_postgres`) + Drive (`jv_privat_gdrive`) | Kontext `privat`. Wurzelpruefung vor jedem Download, eigener sha256 mit Abgleich der Anbieterpruefsumme; in `tool_invoke` noch nicht verdrahtet (1.1b-E2). Werkzeug seit 1.1b Teil 2: `storage_gdrive.get_file@1.2.0` (`approved`, beide Kontexte), 1.1.0 `deprecated` |
| `JV-CORE-ADP-storage_gdrive_visolva-v1` | `IHdbJYSAs2HtMzK6` | **veroeffentlicht**, Aufrufer beschraenkt, Ausfuehrungsdaten nicht gespeichert | ja (lesend, `jv_visolva_postgres`) + Drive (`jv_visolva_gdrive`) | **neu in 1.1b Teil 2 (1.1b-E3/E4 A):** Kontext `arbeitgeber_visolva`. Geprueft gleiche Kopie des privaten Adapters; Unterschiede nur in Kontextweiche, drei Google-Knoten und der Einstellungsabfrage. Logik doppelt gepflegt (TS-32) |
| `JV-CORE-OPS-db_keepalive-v1` | `DTRoxZvPQ5BPhM4o` | **veroeffentlicht** | ja | unveraendert |
| `JV-CORE-OPS-smoke_test-v1` | `P5IlT5RlGBK1aqiO` | Entwurf, manuell | ja (beide Kontexte) + Drive (`jv_privat_gdrive`, `jv_visolva_gdrive`) | 1.1b Teil 2: Einrichtungspruefung beider Kontexte (9 private und 8 Visolva-Ordner, TS-27 A), Faelle `storage_gdrive.get_file` je Kontext, Freigabenachweis; 69 Knoten, 168 Pruefungen |

"Entwurf" heisst in n8n: nicht veroeffentlicht. Seit TS-23 (10.09.2026) sind alle Kern-Subworkflows
und Adapter veroeffentlicht; nur der Smoke-Test bleibt Entwurf (manueller Ausloeser).

**Adapter:** Aufruferbeschraenkung `callerPolicy: workflowsFromAList`,
`callerIds: ELs6LnRIWKCv04yc,P5IlT5RlGBK1aqiO` (nur `tool_invoke` und Smoke-Test, A-6). Gilt auch fuer `storage_gdrive`.
**Regel TS-23:** In n8n 2.x sind unveroeffentlichte Entwuerfe fuer Elternworkflows nicht
sichtbar (Befund 1.0.8, Lauf 22175). Deshalb sind alle `SUB` und `ADP` veroeffentlicht.
**Eine Aenderung wirkt erst nach erneutem Veroeffentlichen.** Ablauf je Aenderung:
aendern → veroeffentlichen → pruefen, dass veroeffentlichte Version = aktueller Stand
(`versionId` = `activeVersionId`) → Smoke-Test → Export ins Repo.
**Export ins Repo (TS-33a, 13.09.2026):** Die Dateien in `n8n/core/` stammen aus dem
`Download` der n8n-Oberflaeche und sind mit `tools/normalize_n8n_export.py` normalisiert.
Handgepflegte Dateien sind nicht zulaessig: sie fuehren zu erfundenen Knoten-IDs und
unvollstaendiger Credential-Liste und machen die Wiederherstellung nachweisuntauglich.

## Credentials

| Credential | ID | Login | erbt Rechte von |
|---|---|---|---|
| `jv_privat_postgres` | `oCkj27EiMe96vXvU` | `jv_privat_login` | `jv_privat_user` |
| `jv_visolva_postgres` | `7BblU6FbDds3EZBb` | `jv_visolva_login` | `jv_visolva_user` |
| `jv_privat_gdrive` | `T9eXpovYsz2Ipp6B` | — (privates Google-Konto, V-1) | nur Kontext `privat`, Adapter `storage_gdrive` |
| `jv_visolva_gdrive` | `r79T8YvgoloadnXV` | — (Arbeitskonto `rolf@visolva.pro`, 1.1b-E3) | nur Kontext `arbeitgeber_visolva`, Adapter `storage_gdrive_visolva`; weiter Zugriffsumfang, Schuld TS-31 |

Kennwoerter nur im Passwortmanager und im Credential-Speicher von n8n.

`jv_privat_postgres` dient zusaetzlich als Betriebs-Lesezugang fuer Lesezugriffe vor bekanntem
Kontext (`context_resolve`, spaeter Bindungsliste und K-07-Eintrag des Hauptablaufs; TS10-E2).
Schuld TS-26: vor dem Arbeitgeber-Pilot eigenen Betriebszugang pruefen.

## Einheitliche Regeln in allen Kern-Subworkflows

- Genau ein Objekt je Aufruf (n8n-Konvention Abschnitt 3); die registerlesenden
  Workflows und die Adapter pruefen das ausdruecklich.
- Jeder Datenbankzugriff laeuft ueber das Credential des eigenen Kontexts; einzige Ausnahme
  ist das Lesen der Konfiguration vor bekanntem Kontext (TS10-E2).
- Kontextnamen stehen nur in den Kontextweichen (Switch) und ihren Postgres-Zweigen (TS-10b).
  Jede Kontextweiche hat einen verbundenen Ausweichausgang; ein unbekannter Kontext bricht ab
  (TS10-E1). Pruefung: `tests/n8n/check_ts10.py`.
- Kein Modell entscheidet ueber Kontext, Risikoklasse, Idempotenz oder Freigabe.
- Freitext wird nur als base64-JSON-Block an PostgreSQL uebergeben (ADR-003).
- Adapter schreiben mit genau einem SQL-Statement und lesen danach mit einer eigenen
  Abfrage zurueck (Readback, A-1). Nachweis ueber `evidence_verify` (D8, E-2).
- Neuer Adapter = versionierte Aenderung an `tool_invoke` (E-1).

## Nachweise

| Nachweis | Dokument |
|---|---|
| Smoke-Test 48/48 (Ausfuehrungen 21907, 21949) | `docs/evidence/PHASE_1_0_SMOKE_TEST_2026-09-10.md` |
| Register R-1 bis R-5 | `docs/evidence/PHASE_1_0_TOOL_REGISTRY_2026-09-10.md` |
| 1.0-A8 Wiederherstellung, 11 Workflows | `docs/evidence/PHASE_1_0_RESTORE_A8_2026-09-10.md` |
| Werkzeugfreigabe 1.0.8, Smoke-Test 104/104 (22087, 22265) | `docs/evidence/PHASE_1_0_8_TOOL_RELEASE_2026-09-10.md` |
| 1.0-A8 / 1.0.8-A10 Wiederherstellung, 14 Workflows | `docs/evidence/PHASE_1_0_8_RESTORE_2026-09-10.md` |
| Phase-1.0-Gate | `docs/evidence/PHASE_1_0_GATE_2026-09-10.md` |
| TS-23: Smoke-Test nach Veroeffentlichung aller SUB, 104/104 (22371) | `docs/decisions/DECISION_LOG.md` |
| 1.1a TS-10: Smoke-Test 105/105 (22616), 116/116 (22715); statische Pruefung; Wiederherstellung 14 Workflows | `docs/evidence/PHASE_1_1A_TS10_2026-09-11.md` |
| 1.1b Teil 2: Speicheradapter Visolva, Smoke-Test 168/168 (23802), Exportabgleich TS-33a | `docs/evidence/PHASE_1_1B_TEIL2_VISOLVA_2026-09-13.md` |

## Bekannte Grenzen

- Neuer Kontext braucht in jeder Kontextweiche einen Zweig mit eigenem Credential (TS-10b).
- `id_generate` prueft den Kontext nur auf das Format; der Probelauf der Adapter prueft ihn
  nicht selbst (Absicherung durch `tool_invoke`). Bewusste Abschwaechungen nach TS10-E1.
- `jv_privat_postgres` als Betriebs-Lesezugang (TS-26).
- Der Keep-Alive meldet Fehlschlaege nicht aktiv; Meldekanal ab Phase 2 (TS-12).
- Adapter klassifizieren Fehler nur; die Wiederholung folgt mit 1.1 (TS-19).
- Jeder Smoke-Lauf verbraucht echte Vorgangsnummern (TS-18).
- Adapterlogik liegt doppelt vor (privat und Visolva); Aenderungen immer in beiden
  Workflows nachziehen (TS-32).
- Die Wiederherstellung aus `n8n/core/` ist seit 1.1a nicht erneut geprueft; `check_restore.py`
  braucht eine leere Instanz mit n8n-CLI, die es auf n8n Cloud nicht gibt (TS-33b).
- `jv_visolva_gdrive` hat vollen Drive-Zugriff auf `rolf@visolva.pro`; Grenze ist allein die
  Wurzelpruefung (TS-31).
