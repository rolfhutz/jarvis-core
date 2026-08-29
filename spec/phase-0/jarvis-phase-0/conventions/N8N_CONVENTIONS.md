# JARVIS - n8n-Namens-, Modul- und Fehlerkonventionen

**Version 1.1.0 - Phase 0**
**Status:** verbindlich für alle Phasen. In Phase 0 werden keine produktiven Workflows gebaut.

---

## 1. Grundsätze

1. Ein Workflow hat genau eine Verantwortung. Kein Sammelworkflow.
2. Jeder Workflow ist einzeln exportierbar und ohne die restliche Instanz verständlich.
3. Kein Workflow enthält Arbeitgebernamen, Ordner-IDs, Konten, Adressen, API-Schlüssel oder Zugangsdaten. Ausschliesslich Adapter-IDs, Credential-Namen und `config_ref`-Verweise.
4. Kein Workflow entscheidet selbst über eine Risikoklasse. Die Klasse kommt aus dem Werkzeugregister und den Kontextregeln.
5. Jeder Workflow gibt denselben Umschlag zurück, den er entgegennimmt.

## 2. Namensschema

```
JV-<PHASE>-<TYP>-<name>-v<MAJOR>
```

| Bestandteil | Werte |
|---|---|
| `JV` | fester Präfix für JARVIS |
| `<PHASE>` | `P0`, `P1`, ... oder `CORE` für phasenübergreifende Bausteine |
| `<TYP>` | `MAIN` (Auslöser), `SUB` (aufgerufener Baustein), `ADP` (Systemadapter), `OPS` (Betrieb) |
| `<name>` | `snake_case`, englisch, ohne Umlaute |
| `v<MAJOR>` | Hauptversion; eine inkompatible Änderung erzeugt einen neuen Workflow, der alte bleibt bis zur Ausserbetriebnahme bestehen |

Beispiele:

```
JV-CORE-SUB-context_resolve-v1
JV-CORE-SUB-idempotency_guard-v1
JV-CORE-SUB-action_dispatch-v1
JV-CORE-ADP-storage_gdrive-v1
JV-CORE-OPS-error_handler-v1
JV-P1-MAIN-document_intake-v1
```

**Weitere Namensregeln**

| Gegenstand | Schema | Beispiel |
|---|---|---|
| Credential | `jv_<kontext>_<system>` | `jv_privat_gdrive` |
| Umgebungsvariable | `JV_<KONTEXT>_<ZWECK>` | `JV_VISOLVA_APPROVAL_RECIPIENT` |
| Prompt | `<agent_id>_<zweck>@<version>` | `action_planner_base@1.0.0` |
| Node | `<Verb> <Objekt>` in deutscher Klartextsprache | `Kontext auflösen` |
| Tag | `context:privat`, `phase:0`, `type:sub` | |

## 3. Einheitlicher Umschlag

Jeder Haupt- und Sub-Workflow nimmt genau ein Objekt entgegen und gibt genau ein Objekt zurück:

```json
{
  "envelope_version": "1.0.0",
  "trace": {
    "trace_id": "",
    "correlation_id": "",
    "causation_id": "",
    "workflow_name": "",
    "workflow_version": ""
  },
  "context_id": "",
  "payload": {},
  "result": {
    "status": "ok",
    "error": null
  }
}
```

Regeln:

- `trace_id` wird beim ersten Auslöser erzeugt und unverändert weitergereicht.
- `causation_id` verweist auf den auslösenden Schritt und macht Ketten nachvollziehbar.
- `context_id` darf ab dem Auflösungsschritt nicht mehr verändert werden.
- `result.status` ist `ok`, `blocked`, `awaiting_approval` oder `error`.
- Fehler werden als strukturierter Fehlerdatensatz nach `error_escalation.schema.json` zurückgegeben, nicht als Freitext.

## 4. Pflicht-Sub-Workflows des Fundaments

Diese Bausteine werden in Phase 1 implementiert. Ihre Verträge sind ab jetzt verbindlich.

| Workflow | Aufgabe | Sprachmodell | Wesentliche Ausgabe |
|---|---|---|---|
| `JV-CORE-SUB-context_resolve-v1` | Kontext bestimmen und absichern | nein | `context_id`, `context_resolution` |
| `JV-CORE-SUB-id_generate-v1` | ULID mit Präfix erzeugen | nein | Objekt-ID |
| `JV-CORE-SUB-event_normalize-v1` | Quellsignal in das Ereignisformat überführen | ja, `event_interpreter` | Ereignis |
| `JV-CORE-SUB-idempotency_guard-v1` | Schlüssel bilden, Sperre setzen, Dubletten abweisen | nein | `proceed` oder `already_processed` |
| `JV-CORE-SUB-action_plan-v1` | Aktionsobjekt befüllen, Werkzeug wählen | nur für Inhaltsvorschlag | Aktion |
| `JV-CORE-SUB-action_classify-v1` | Risikoklasse aus Werkzeugregister und Kontextregeln bestimmen | nein | `risk_class`, `risk_class_source` |
| `JV-CORE-SUB-approval_request-v1` | Freigabeanforderung erzeugen und versenden | nein | Freigabedatensatz |
| `JV-CORE-SUB-approval_callback-v1` | Entscheidung entgegennehmen und prüfen | nein | Status der Freigabe |
| `JV-CORE-SUB-tool_invoke-v1` | Registriertes Werkzeug aufrufen | nein | Rohergebnis |
| `JV-CORE-SUB-evidence_verify-v1` | Nachweis nach Werkzeugvertrag erbringen und bewerten | nein | Nachweisdatensatz |
| `JV-CORE-SUB-fach_log_write-v1` | Fachprotokoll im Kontextschema schreiben | nein | Protokoll-ID |
| `JV-CORE-SUB-tech_log_write-v1` | Technisches Protokoll schreiben, `message_safe` bereinigen | nein | ohne Fachdaten |
| `JV-CORE-OPS-error_handler-v1` | Fehler klassifizieren, Retry oder Eskalation entscheiden | nein | Fehlerdatensatz |

Nur ein einziger dieser Bausteine nutzt zwingend ein Sprachmodell. Klassifizierung, Freigabe, Ausführung und Nachweis sind vollständig deterministisch (Entscheidung D9).

**Aufrufreihenfolge einer Aktion**

```
context_resolve -> idempotency_guard -> action_plan -> action_classify
   -> (bei Klasse C) approval_request -> approval_callback
   -> tool_invoke -> evidence_verify -> fach_log_write
```

`tool_invoke` darf nur aufgerufen werden, wenn `idempotency_guard` die Sperre erteilt hat und, bei Klasse C, eine gültige Freigabe vorliegt. Diese Reihenfolge ist nicht optional.

`evidence_verify` liest die Nachweisstrategie aus `registry/tool_registry.json`. Ist `readback_supported` wahr, führt der Baustein einen unabhängigen Lesevorgang aus; andernfalls erhebt er die im Vertrag zugelassene Ersatzmethode und trägt deren Grenzen in `verification.limitation` ein. Eine Methode ausserhalb von `accepted_methods` führt nicht zum Status `succeeded`.

## 5. Einstellungen je Workflow

| Einstellung | Wert | Grund |
|---|---|---|
| Error Workflow | `JV-CORE-OPS-error_handler-v1` | einheitliche Fehlerbehandlung |
| Save successful executions | **aus** für fachliche Workflows | verhindert fachliche Inhalte im gemeinsamen Execution-Log |
| Save failed executions | **aus** für fachliche Workflows | Diagnose läuft über `jarvis_ops.tech_event` |
| Save manual executions | aus | |
| Timezone | UTC intern, Anzeige `Europe/Zurich` | |
| Timeout | je Werkzeugvertrag, Standard 60 Sekunden | |
| Caller policy | Sub-Workflows nur aus derselben Instanz aufrufbar | |

**Freigabekanal.** `approval_request` und `approval_callback` sprechen den in `policy.approval.channel_adapter` konfigurierten Adapter an. Bevorzugt ist ein per HTTPS erreichbarer Bestätigungsendpunkt als Webhook-Workflow. Ist dieser nicht verfügbar, wird ein anderer Adapter eingesetzt, ohne dass sich das Aktions- oder Freigabemodell ändert. Die spätere Freigabe über die JARVIS-Oberfläche aus Phase 6 ist derselbe Adaptertausch.

**Folge:** Diagnose ohne Execution-Daten funktioniert nur, wenn `tech_log_write` konsequent aufgerufen wird. Das ist Pflicht in jedem Zweig, auch im Fehlerfall.

## 6. Fehlerkonvention

1. Jeder Fehler wird klassifiziert nach `error_escalation.schema.json`. Freitextfehler sind unzulässig.
2. `message_safe` wird vor dem Schreiben mit dem Verfahren aus `tools/sanitize_message.py` bereinigt: keine Token, keine Zugangsdaten, keine Adressen, keine Pfade, keine fachlichen Inhalte, maximal 500 Zeichen. Die Bereinigung ist Pflicht, nicht Empfehlung; ungeprüfter Text darf `jarvis_ops.tech_event` nicht erreichen.
3. Vor jedem Wiederholungsversuch erfolgt ein Statusabgleich. Ergebnis wird im Feld `reconciliation` dokumentiert.
4. Bei `unknown_state` erfolgt kein automatischer Wiederholungsversuch.
5. Nach drei erfolglosen Versuchen: Eskalationsstufe `L1_exception_list`, bei Klasse C oder Fristbezug direkt `L2_notify`.
6. Fünf Fehler desselben Werkzeugs in 15 Minuten öffnen den Schutzschalter; das Werkzeug pausiert und ein Ereignis `system.error` wird erzeugt.

## 7. Versionierung und Export

- Alle Workflows werden als JSON in Git abgelegt, Pfad `n8n/<workflow_name>.json`.
- Export erfolgt mindestens bei jeder Änderung und zusätzlich wöchentlich automatisiert.
- Vor jedem Phase-Gate wird ein Export in eine leere Testinstanz importiert und der Import geprüft. Ein nicht wiederherstellbarer Workflow gilt als nicht abgenommen.
- Änderungen an Schemata, Prompts, Werkzeug- und Agentenverträgen werden in `jarvis_ops.contract_version` registriert.
- Kompatibilitätsregel: Minor-Versionen dürfen nur optionale Felder ergänzen. Jede Pflichtfeldänderung oder Enum-Erweiterung mit Verhaltensfolge ist eine Major-Version.
- Datenbankvorlagen werden nie von Hand angepasst, sondern über `tools/render_context_schema.py` erzeugt. Nur so bleiben Schemaname, Kontextkennung und Benutzer geprüft.

## 8. Verbote

- Kein direkter Datenbankzugriff ausserhalb der dafür vorgesehenen Sub-Workflows.
- Keine Werkzeugaufrufe ausserhalb von `tool_invoke`.
- Keine Klasse-C-Ausführung ohne `approval_callback`.
- Keine Speicherung von Zugangsdaten oder Token in Workflow-Parametern, Prompts oder Notizfeldern.
- Kein Sprachmodell im Ausführungspfad zwischen Freigabe und Werkzeugaufruf. Nach der Freigabe wird ausgeführt, was freigegeben wurde, unverändert.
- Keine Risikoklasse aus einem Sprachmodell. Die Klasse kommt aus `registry/tool_registry.json` und den Kontextregeln.
- Kein Status `succeeded` ohne einen Nachweis, den der Werkzeugvertrag als ausreichend definiert.
