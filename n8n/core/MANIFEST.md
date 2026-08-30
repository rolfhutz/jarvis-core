# Manifest der JARVIS-Kern-Subworkflows

**Stand:** 30. August 2026
**Instanz:** persönliches n8n-Projekt `Rolf Hutz`
**Grundlage:** SPEC_PHASE_0 1.1.0, SPEC_PHASE_1 4.0.2, Abschnitt 7.1 Punkt 7

Alle neun Workflows sind **nicht veröffentlicht** und tragen das Präfix `JV-CORE-SUB-`. Bestehende Workflows der Instanz sind unberührt.

| # | Workflow | ID | Version | Status | Nodes | Credential-Bedarf |
|---|---|---|---|---|---|---|
| 1 | `JV-CORE-SUB-context_resolve-v1` | `5IyWf1dH3huijkKG` | v1 | inaktiv, Entwurf | 5 | keiner |
| 2 | `JV-CORE-SUB-id_generate-v1` | `ZtUV95YyMA5IlgoE` | v1 | inaktiv, Entwurf | 5 | keiner |
| 3 | `JV-CORE-SUB-idempotency_guard-v1` | `bpC5dlK2Ez0sVhUj` | v1 | inaktiv, Entwurf | 7 | `jv_privat_postgres`, `jv_visolva_postgres` |
| 4 | `JV-CORE-SUB-action_classify-v1` | `tWVy6kRzwFMw4lmJ` | v1 | inaktiv, Entwurf | 3 | keiner |
| 5 | `JV-CORE-SUB-tool_invoke-v1` | `ELs6LnRIWKCv04yc` | v1 | inaktiv, Entwurf | 5 | keiner |
| 6 | `JV-CORE-SUB-evidence_verify-v1` | `UKcnRE0eJzyl8T1V` | v1 | inaktiv, Entwurf | 5 | keiner |
| 7 | `JV-CORE-SUB-fach_log_write-v1` | `8ur7Lc15KEF0Y8M1` | v1 | inaktiv, Entwurf | 7 | `jv_privat_postgres`, `jv_visolva_postgres` |
| 8 | `JV-CORE-SUB-tech_log_write-v1` | `Bp7m62faVmLZ6VdB` | v1 | inaktiv, Entwurf | 7 | `jv_privat_postgres`, `jv_visolva_postgres` |
| 9 | `JV-CORE-SUB-error_handler-v1` | `HOTikshdbkz6dk9q` | v1 | inaktiv, Entwurf | 7 | `jv_privat_postgres`, `jv_visolva_postgres` |

51 Nodes insgesamt.

---

## Was jeder Workflow tut

Alle neun sind Subworkflows mit `executeWorkflowTrigger` als Einstieg. Sie werden von Elternworkflows aufgerufen und haben keinen eigenen Zeitplan und keinen Webhook.

| Workflow | Aufgabe | Entscheidungsweg |
|---|---|---|
| `context_resolve` | Kontext aus `source_binding` auflösen | feste Zuordnungstabelle, unbekannte Bindung bricht ab |
| `id_generate` | `praefix_ULID` und Idempotenzschlüssel | ULID aus Zeit und Zufall, Schlüssel als SHA-256 über die kanonische Feldfolge |
| `idempotency_guard` | Ausführungssperre beanspruchen | `INSERT … ON CONFLICT DO NOTHING RETURNING`; keine Zeile bedeutet Dublette |
| `action_classify` | Risikoklasse A, B oder C | Werkzeugregister plus Kontext-Overrides, höhere Klasse gewinnt |
| `tool_invoke` | Vertragstor vor jedem Werkzeugaufruf | Registrierung, Version, Freigabestatus, Klasse-C-Freigabe |
| `evidence_verify` | Nachweis nach Entscheidung D3 | Readback ist Pflicht, wenn er möglich ist |
| `fach_log_write` | Fachprotokoll append-only schreiben | nur `INSERT`, Korrekturen über `corrects_log_id` |
| `tech_log_write` | Technikereignis schreiben | Positivliste von Spalten, `message_safe` wird bereinigt |
| `error_handler` | Fehler klassifizieren und protokollieren | `transient`, `permanent`, `contract`, `security` aus Fehlercode und Meldungstext |

**Kein Modell entscheidet über Kontext, Risikoklasse, Idempotenz oder Freigabe.** Diese vier Wege sind vollständig deterministisch und in Code-Nodes ohne LLM-Aufruf umgesetzt.

---

## Credential-Bedarf und der offene Blocker

**Blocker:** In n8n existiert kein einziges Postgres-Credential. Weder `jv_privat_postgres` noch `jv_visolva_postgres` sind angelegt; eine Suche nach Credentials vom Typ `postgres` liefert null Treffer.

Die acht Postgres-Nodes in den vier Datenbank-Workflows tragen deshalb **kein** Credential. Ein Credential-Verweis in n8n braucht zwingend eine Credential-ID, und eine ID lässt sich nicht erfinden. Der Bedarf ist stattdessen an zwei Stellen eindeutig hinterlegt:

1. **Im Node-Namen selbst** — jeder Postgres-Node nennt sein Zielschema oder seine Rolle, etwa `Fachprotokoll jarvis_privat` oder `tech_event schreiben als jv_visolva_user`.
2. **Als Haftnotiz im Workflow** — jeder der vier Datenbank-Workflows enthält eine Notiz `Benoetigte Credentials` mit der Zuordnung Node → Credential → Datenbankrolle.

| Credential | Datenbankrolle | Zielschema | Benötigt von |
|---|---|---|---|
| `jv_privat_postgres` | `jv_privat_user` | `jarvis_privat`, lesend/schreibend auf erlaubte `jarvis_ops`-Tabellen | idempotency_guard, fach_log_write, tech_log_write, error_handler |
| `jv_visolva_postgres` | `jv_visolva_user` | `jarvis_visolva`, lesend/schreibend auf erlaubte `jarvis_ops`-Tabellen | dieselben vier |

### Warum die Credentials noch nicht angelegt werden können

Beide Datenbankrollen existieren im Supabase-Projekt, sind aber `NOLOGIN` und ohne Kennwort — so vorgesehen in Migration `0001_create_context_roles.sql`. Ein Credential ohne Anmelderecht wäre wertlos.

Reihenfolge für die Aktivierung:

1. Anmelderecht und Kennwort je Rolle setzen, **ausserhalb** dieses Repositoriums:
   `ALTER ROLE jv_privat_user WITH LOGIN PASSWORD '<im Tresor erzeugt>';`
2. In n8n je ein Credential vom Typ **Postgres** unter genau dem Namen `jv_privat_postgres` bzw. `jv_visolva_postgres` anlegen; Verbindungsdaten aus dem Supabase-Projekt.
3. Credential am jeweiligen Postgres-Node zuordnen (je Workflow zwei Nodes).
4. Synthetische Smoke-Tests fahren, dann veröffentlichen.

Kein Kennwort und keine Verbindungszeichenfolge gehört in dieses Repository.

---

## Export und Wiederherstellung

Die neun JSON-Dateien in diesem Ordner sind die Exporte aus der laufenden Instanz. Geprüft am 30. August 2026:

- Import in eine **frische, leere n8n-Instanz** (Fassung 2.35.7, eigenes Benutzerverzeichnis, leere SQLite-Datenbank): `Successfully imported 9 workflows.`
- Rückexport aus dieser Instanz und Abgleich gegen dieses Verzeichnis: **neun von neun identisch** in Nodenamen, Nodetypen, sämtlichen Parametern und allen Verbindungen. Keine Abweichung.

```bash
n8n import:workflow --separate --input=n8n/core
n8n export:workflow --all --separate --output=<zielordner>
```

Dieser Nachweis deckt **nicht** das Abnahmekriterium 1.0-A8 ab. Dort geht es um Export und Wiederherstellung der vollständigen, lauffähigen Workflows samt Credential-Zuordnung in eine leere Instanz. Solange die Credentials fehlen, ist nur die Struktur wiederherstellbar, nicht die Lauffähigkeit.

---

## Was noch fehlt, bevor die Workflows aktiviert werden können

1. **Anmelderecht und Kennwort** für `jv_privat_user` und `jv_visolva_user`.
2. **Zwei Postgres-Credentials** in n8n unter den oben genannten Namen.
3. **Zuordnung** der Credentials an die acht Postgres-Nodes.
4. **Synthetische Smoke-Tests** je Workflow gegen das Supabase-Projekt.
5. **Elternworkflow**, der die Subworkflows aufruft — die Subworkflows haben bewusst keinen eigenen Auslöser.
6. **Werkzeugfreigabe** von `draft` auf `approved`. Bis dahin weist `tool_invoke` jeden Aufruf mit `tool_not_released` ab; das ist beabsichtigt und kein Fehler.
