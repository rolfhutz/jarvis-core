# Manifest der JARVIS-Kernworkflows

**Stand:** 10. September 2026
**Instanz:** persoenliches n8n-Projekt `Rolf Hutz` (n8n Cloud)
**Grundlage:** SPEC_PHASE_0 1.1.0, SPEC_PHASE_1 4.0.2, ADR-002, ADR-003

| Workflow | ID | Status | Datenbank | Aenderung seit 30.08. |
|---|---|---|---|---|
| `JV-CORE-SUB-context_resolve-v1` | `5IyWf1dH3huijkKG` | Entwurf, getestet | nein | unveraendert |
| `JV-CORE-SUB-id_generate-v1` | `ZtUV95YyMA5IlgoE` | Entwurf, getestet | nein | unveraendert |
| `JV-CORE-SUB-idempotency_guard-v1` | `bpC5dlK2Ez0sVhUj` | Entwurf, getestet | ja | Credentials zugeordnet |
| `JV-CORE-SUB-action_classify-v1` | `tWVy6kRzwFMw4lmJ` | Entwurf, getestet | ja | liest Register (ADR-002) |
| `JV-CORE-SUB-tool_invoke-v1` | `ELs6LnRIWKCv04yc` | Entwurf, getestet | ja | liest Register (ADR-002) |
| `JV-CORE-SUB-evidence_verify-v1` | `UKcnRE0eJzyl8T1V` | Entwurf, getestet | ja | liest Register (ADR-002) |
| `JV-CORE-SUB-fach_log_write-v1` | `8ur7Lc15KEF0Y8M1` | Entwurf, getestet | ja | base64-Uebergabe (ADR-003) |
| `JV-CORE-SUB-tech_log_write-v1` | `Bp7m62faVmLZ6VdB` | Entwurf, getestet | ja | base64-Uebergabe (ADR-003) |
| `JV-CORE-SUB-error_handler-v1` | `HOTikshdbkz6dk9q` | Entwurf, getestet | ja | Rueckgabe der Eskalation, base64-Uebergabe |
| `JV-CORE-OPS-db_keepalive-v1` | `DTRoxZvPQ5BPhM4o` | **veroeffentlicht** | ja | neu |
| `JV-CORE-OPS-smoke_test-v1` | `P5IlT5RlGBK1aqiO` | Entwurf, manuell | ja | neu |

"Entwurf" heisst in n8n: nicht veroeffentlicht. Subworkflows werden nur von
Elternworkflows aufgerufen und brauchen keinen eigenen Ausloeser.

## Credentials

| Credential | ID | Login | erbt Rechte von |
|---|---|---|---|
| `jv_privat_postgres` | `oCkj27EiMe96vXvU` | `jv_privat_login` | `jv_privat_user` |
| `jv_visolva_postgres` | `7BblU6FbDds3EZBb` | `jv_visolva_login` | `jv_visolva_user` |

Kennwoerter nur im Passwortmanager und im Credential-Speicher von n8n.

## Einheitliche Regeln in allen Kern-Subworkflows

- Genau ein Objekt je Aufruf (n8n-Konvention Abschnitt 3); die registerlesenden
  Workflows pruefen das ausdruecklich.
- Jeder Datenbankzugriff laeuft ueber das Credential des eigenen Kontexts.
- Kein Modell entscheidet ueber Kontext, Risikoklasse, Idempotenz oder Freigabe.
- Freitext wird nur als base64-JSON-Block an PostgreSQL uebergeben (ADR-003).

## Nachweise

| Nachweis | Dokument |
|---|---|
| Smoke-Test 48/48 (Ausfuehrungen 21907, 21949) | `docs/evidence/PHASE_1_0_SMOKE_TEST_2026-09-10.md` |
| Register R-1 bis R-5 | `docs/evidence/PHASE_1_0_TOOL_REGISTRY_2026-09-10.md` |
| 1.0-A8 Wiederherstellung | `docs/evidence/PHASE_1_0_RESTORE_A8_2026-09-10.md` |

## Bekannte Grenzen

- `tool_invoke` enthaelt noch einen Platzhalter fuer den Adapteraufruf. Kein
  Werkzeug steht auf `approved`; Schritt 1.0.8 folgt.
- Kontextliste und Quellbindungen stehen in den Code-Knoten fest und werden in
  Schritt 1.1 aus `jarvis_ops.context_registry` gelesen (technische Schuld).
- Der Keep-Alive meldet Fehlschlaege nicht aktiv; Meldekanal ab Phase 2.
