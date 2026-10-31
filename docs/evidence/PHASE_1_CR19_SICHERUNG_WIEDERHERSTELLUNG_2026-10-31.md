# Nachweis CR-19: Sicherung und Wiederherstellung (31.10.2026)

## Datenbanksicherung (TS-13)
| Prüfung | Ergebnis |
|---|---|
| 0046 `f_sicherung` als `jv_privat_user`: `jarvis_privat` (34 Tabellen), `jarvis_ops` (11) | lesbar |
| Gegenprobe: `jv_privat_user` liest `jarvis_visolva` | abgewiesen (insufficient_privilege) |
| Gegenprobe: Schema `public` | abgewiesen (22023) |
| Lauf 1 (manuell, Planauslöser) | privat 2026-W44: 45 Tabellen, 1561 Zeilen, 1,81 MB roh / 0,32 MB gepackt, nachgelesen+entpackt+gezählt; Visolva: 17 Tabellen, 251 Zeilen |
| Lauf 2 (Wiederholung) | beide Kontexte `backup_skipped` – keine Doppelablage |
| Lauf 3 nach Umbenennung der Knoten (Zweig A/B) | privat neu abgelegt und nachgewiesen (1571 Zeilen), Visolva übersprungen |
| Rückspieltest | Sicherung privat W44 aus Drive geladen, in leere PostgreSQL 16 nach allen Migrationen (inkl. 0047) zurückgespielt: alle 45 Tabellen zeilengleich, `document_search('gekündigt')` = 8 Treffer wie live, Werkzeugregister-Stände übernommen. Gegenprobe ohne `--ersetzen` bricht ab. Lokale Kopie danach gelöscht |
| Schemavergleich live ↔ Repo-Migrationen | 2 Abweichungen gefunden (→ 0047, TS-40); Trigramm-Indizes unterscheiden sich nur in der Schema-Schreibweise des Operators |

## Workflow-Wiederherstellung (TS-33b)
Lokale n8n 2.45.7 auf Node 24, Credential-Hüllen mit Original-IDs (9), Import `n8n/core` (17) und `n8n/phase-1` (5), Rückexport.

```
core:    {"workflows": 17, "knoten": 269, "credential_zuordnungen": 79, "subworkflow_verweise": 24, "aufruferregeln": 11, "binaermodus": 15}  BESTANDEN
phase-1: {"workflows": 5, "knoten": 245, "credential_zuordnungen": 90, "subworkflow_verweise": 2, "aufruferregeln": 1}  BESTANDEN
check_ts10 core: 16 Workflows, 89 Knoten, 13 Kontextweichen  BESTANDEN
```

Grenzen: Datenbankverbindungen der Testinstanz nicht hergestellt (Kennwörter nur im Passwortmanager); Veröffentlichungsstatus nicht Teil des Exports.
