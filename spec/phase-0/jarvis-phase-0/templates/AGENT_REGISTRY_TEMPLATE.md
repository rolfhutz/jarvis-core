# JARVIS - Verantwortungstrennung und Sprachmodellrollen

**Version 1.1.0 - Phase 0**
**Ersetzt** das Agentenregister aus Version 1.0.0 mit acht Basisagenten.

---

## 1. Warum diese Fassung anders ist

Version 1.0.0 hatte acht Agenten definiert, darunter `executor`, `verifier` und
`approval_broker`. Das war zu viel Agentenkomplexität für Arbeit, die keine
Interpretation erfordert. Ein Werkzeugaufruf, eine Freigabeprüfung und ein
Readback sind deterministische Vorgänge; sie brauchen kein Sprachmodell.

Entscheidung D9 verlangt getrennte **Verantwortlichkeiten**, nicht getrennte
Agenten. Diese Fassung setzt die Trennung über Sub-Workflows und Berechtigungen
um und beschränkt Sprachmodelle auf die drei Stellen, an denen tatsächlich
interpretiert wird.

## 2. Trennung der vier Verantwortlichkeiten

| Verantwortlichkeit | Umsetzung | Sprachmodell | Darf ausführen |
|---|---|---|---|
| **Planung** | `JV-CORE-SUB-action_plan-v1`, `JV-CORE-SUB-action_classify-v1` | nur für Ziel und Inhaltsvorschlag | nein |
| **Freigabe** | `JV-CORE-SUB-approval_request-v1`, `JV-CORE-SUB-approval_callback-v1` | nein | nein |
| **Ausführung** | `JV-CORE-SUB-tool_invoke-v1` | nein | ja, nur registrierte Werkzeuge |
| **Prüfung** | `JV-CORE-SUB-evidence_verify-v1` | nein | nein, nur lesen |

Kein Sub-Workflow vereint zwei dieser Verantwortlichkeiten. Nach der Freigabe
steht kein Sprachmodell mehr im Pfad (D4): Was freigegeben wurde, wird
unverändert ausgeführt.

**Trennung über Berechtigungen.** Die Trennung ist nicht nur organisatorisch.
`tool_invoke` ist der einzige Ort mit Zugriff auf Werkzeug-Credentials.
`approval_callback` ist der einzige Ort, der eine Freigabe von `pending` auf
`approved` setzen darf. Die Planung hat keinen Zugriff auf beides.

## 3. Sprachmodellrollen

Nur drei Rollen nutzen ein Sprachmodell.

### 3.1 `event_interpreter`

| | |
|---|---|
| Aufgabe | Quellsignal verstehen, Felder mit Textbeleg und Konfidenz extrahieren, Kontext vorschlagen |
| Erzeugt | Inhalt von `event.payload` und `event.field_evidence` |
| Erzeugt nicht | Aufgaben, Aktionen, Risikoklassen |
| Guardrails | keine erfundenen Werte; jedes Feld mit Konfidenz und Beleg; ein Kontextvorschlag ist `model_suggestion` und reicht für schreibende Aktionen nicht aus |
| Eskalation | bei Konfidenz unter Schwellwert in die Ausnahmeliste |

### 3.2 `task_deriver`

| | |
|---|---|
| Aufgabe | Aufgaben mit Akteur, Frist, Priorität und Erfolgskriterium ableiten |
| Erzeugt | Objekte nach `task.schema.json` |
| Erzeugt nicht | Aktionen, Freigaben, Werkzeugaufrufe |
| Guardrails | `success_criterion` ist Pflicht; bei menschlichem Akteur ist `assignee` Pflicht; keine erfundenen Fristen, nur belegte oder ausdrücklich als Annahme gekennzeichnete |
| Eskalation | fehlende Pflichtangaben führen zur Ausnahme, nicht zur Schätzung |

### 3.3 `draft_composer` (ab Phase 1)

| | |
|---|---|
| Aufgabe | Entwürfe, Zusammenfassungen und Entscheidungsvorlagen formulieren |
| Erzeugt | Entwurfsinhalte und `approval.decision_summary` |
| Erzeugt nicht | Versand, Freigabe, Ausführung |
| Guardrails | keine verbindlichen Zusagen ohne geprüfte Grundlage; jeder Entwurf mit Quellenangabe; ein Entwurf ist niemals selbst eine Aktion |

Alle drei Rollen verweisen auf `context.adapters.llm` und eine versionierte
`prompt_id@version`. Kein Modellname wird in Phase 0 festgelegt (Annahme A8).

## 4. Übergreifende Guardrails

- Kein Sprachmodell setzt eine Risikoklasse fest oder senkt sie.
- Kein Sprachmodell erteilt eine Freigabe.
- Kein Sprachmodell ruft ein Werkzeug direkt auf.
- Kein Sprachmodell ändert Berechtigungen, Registereinträge oder Freigaberegeln.
- Kein Sprachmodell schreibt in ein Fachprotokoll; das tut ausschliesslich `fach_log_write`.
- Jede Modellrolle arbeitet in genau einem Kontext.

## 5. Feldvertrag für spätere Rollen

Wird eine weitere Sprachmodellrolle nötig, wird sie mit diesen Feldern
beschrieben. Ein maschinenlesbares Agentenregister entsteht in Phase 1, sobald
die erste Rolle tatsächlich implementiert wird.

```json
{
  "agent_id": "",
  "version": "1.0.0",
  "display_name": "",
  "role": "",
  "responsibilities": [],
  "non_goals": [],
  "allowed_contexts": [],
  "produces": [],
  "may_trigger_actions": false,
  "may_request_approval": false,
  "llm_binding": {
    "adapter_ref": "context.adapters.llm",
    "prompt_id": "",
    "prompt_version": "1.0.0"
  },
  "guardrails": [],
  "escalation_target": "exception_list",
  "quality_metrics": [],
  "status": "draft"
}
```

**Prüffrage vor jeder neuen Rolle:** Erfordert diese Aufgabe wirklich
Interpretation, oder lässt sie sich als Regel beschreiben? Im zweiten Fall
gehört sie in einen Sub-Workflow, nicht in ein Sprachmodell.
