# Manifest der JARVIS-Kernworkflows

**Stand:** 10. September 2026, nach Schritt 1.0.8
**Instanz:** persoenliches n8n-Projekt `Rolf Hutz` (n8n Cloud)
**Grundlage:** SPEC_PHASE_0 1.1.0, SPEC_PHASE_1 4.0.2, ADR-002, ADR-003, E-1, E-2

| Workflow | ID | Status in n8n | Datenbank | Aenderung in 1.0.8 |
|---|---|---|---|---|
| `JV-CORE-SUB-context_resolve-v1` | `5IyWf1dH3huijkKG` | Entwurf, getestet | nein | unveraendert |
| `JV-CORE-SUB-id_generate-v1` | `ZtUV95YyMA5IlgoE` | Entwurf, getestet | nein | unveraendert |
| `JV-CORE-SUB-idempotency_guard-v1` | `bpC5dlK2Ez0sVhUj` | Entwurf, getestet | ja | unveraendert |
| `JV-CORE-SUB-action_classify-v1` | `tWVy6kRzwFMw4lmJ` | Entwurf, getestet | ja | unveraendert |
| `JV-CORE-SUB-tool_invoke-v1` | `ELs6LnRIWKCv04yc` | Entwurf, getestet | ja | Verteiler auf Adapter (E-1), `action_id`, `dry_run`, `adapter_error` |
| `JV-CORE-SUB-evidence_verify-v1` | `UKcnRE0eJzyl8T1V` | Entwurf, getestet | ja | Nachweis wird gespeichert, Rueckgabe `evidence_id` (E-2) |
| `JV-CORE-SUB-fach_log_write-v1` | `8ur7Lc15KEF0Y8M1` | Entwurf, getestet | ja | unveraendert |
| `JV-CORE-SUB-tech_log_write-v1` | `Bp7m62faVmLZ6VdB` | Entwurf, getestet | ja | unveraendert |
| `JV-CORE-SUB-error_handler-v1` | `HOTikshdbkz6dk9q` | Entwurf, getestet | ja | unveraendert |
| `JV-CORE-ADP-tasks_internal-v1` | `GFTIzQsak9UJVhAj` | **veroeffentlicht**, Aufrufer beschraenkt | ja | neu |
| `JV-CORE-ADP-docstore_internal-v1` | `2QdRVAniHgkWjqh2` | **veroeffentlicht**, Aufrufer beschraenkt | ja | neu |
| `JV-CORE-ADP-casestore_internal-v1` | `V1fuepKIR20OwgZp` | **veroeffentlicht**, Aufrufer beschraenkt | ja | neu |
| `JV-CORE-OPS-db_keepalive-v1` | `DTRoxZvPQ5BPhM4o` | **veroeffentlicht** | ja | unveraendert |
| `JV-CORE-OPS-smoke_test-v1` | `P5IlT5RlGBK1aqiO` | Entwurf, manuell | ja | 47 Knoten, 104 Pruefungen |

"Entwurf" heisst in n8n: nicht veroeffentlicht. Subworkflows werden nur von
Elternworkflows aufgerufen und brauchen keinen eigenen Ausloeser.

**Adapter:** Aufruferbeschraenkung `callerPolicy: workflowsFromAList`,
`callerIds: ELs6LnRIWKCv04yc,P5IlT5RlGBK1aqiO` (nur `tool_invoke` und Smoke-Test, A-6).
Die Adapter muessen veroeffentlicht sein, sonst scheitert der verschachtelte Aufruf aus
`tool_invoke` (Befund 1.0.8, Lauf 22175; Ursache ungeklaert, TS-23). **Aenderungen an
einem Adapter wirken erst nach erneutem Veroeffentlichen.**

## Credentials

| Credential | ID | Login | erbt Rechte von |
|---|---|---|---|
| `jv_privat_postgres` | `oCkj27EiMe96vXvU` | `jv_privat_login` | `jv_privat_user` |
| `jv_visolva_postgres` | `7BblU6FbDds3EZBb` | `jv_visolva_login` | `jv_visolva_user` |

Kennwoerter nur im Passwortmanager und im Credential-Speicher von n8n.

## Einheitliche Regeln in allen Kern-Subworkflows

- Genau ein Objekt je Aufruf (n8n-Konvention Abschnitt 3); die registerlesenden
  Workflows und die Adapter pruefen das ausdruecklich.
- Jeder Datenbankzugriff laeuft ueber das Credential des eigenen Kontexts.
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

## Bekannte Grenzen

- Kontextliste und Quellbindungen stehen in den Code-Knoten fest und werden in
  Schritt 1.1 aus `jarvis_ops.context_registry` gelesen (TS-10).
- Der Keep-Alive meldet Fehlschlaege nicht aktiv; Meldekanal ab Phase 2 (TS-12).
- Adapter klassifizieren Fehler nur; die Wiederholung folgt mit 1.1 (TS-19).
- Jeder Smoke-Lauf verbraucht echte Vorgangsnummern (TS-18).
