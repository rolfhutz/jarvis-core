# JARVIS Werkzeugregister - Feldvertrag und Erläuterung

**Version 1.1.0 - Phase 0**

> **Diese Datei ist Erläuterung, keine Datenquelle.**
> Verbindlich ist ausschliesslich `registry/tool_registry.json`, validiert gegen
> `schemas/tool_registry.schema.json`. Risikoklassen, Nachweisstrategien,
> Idempotenz und erlaubte Kontexte werden nur dort gepflegt. Prüfskripte und die
> spätere Klassifizierung lesen dieselbe Datei. Eine parallele Pflege in Markdown
> oder in Skriptcode ist unzulässig.

---

## 1. Zweck

Das Werkzeugregister ist die einzige zulässige Quelle für die Frage, was JARVIS
technisch tun darf. Ein Werkzeug ohne Eintrag existiert für JARVIS nicht.

Das Register bestimmt:

- die **Mindest-Risikoklasse** einer Aktion,
- die **zulässige Nachweisstrategie** (Entscheidung D3),
- die **Idempotenzstrategie**,
- die **erlaubten Kontexte**.

## 2. Verbindliche Regeln

1. Der Orchestrator ruft nur Werkzeuge mit Status `approved` auf.
2. Die Risikoklasse darf gegenüber `risk_class_default` nur erhöht werden. Eine Herabstufung ist unzulässig, auch nicht durch ein Sprachmodell (D2).
3. Jedes schreibende Werkzeug muss eine Nachweisstrategie definieren. Ohne sie darf es nicht den Status `approved` erhalten.
4. Ist ein unabhängiger Readback möglich, ist er die einzige zulässige Methode. Andernfalls muss der Vertrag benennen, was der Ersatznachweis nicht belegt.
5. Jedes schreibende Werkzeug gibt an, aus welchen Feldern der Idempotenzschlüssel gebildet wird.
6. `allowed_contexts` ist eine Positivliste. Leer bedeutet: nicht erlaubt.
7. Keine Arbeitgebernamen, Konten, Ordner-IDs oder Zugangsdaten. Nur Adapter-IDs und `config_ref`-Verweise.
8. Änderungen an `risk_class_default`, `allowed_contexts` oder `evidence` erfordern eine neue Hauptversion des Werkzeugs.

## 3. Vom Schema erzwungene Regeln

Diese Regeln müssen nicht eingehalten werden, sie können nicht verletzt werden:

| Regel | Wirkung |
|---|---|
| `external_effect` in `external_recipient`, `financial`, `legal` | `risk_class_default` muss B oder C sein |
| `external_effect` in `financial`, `legal` | `risk_class_default` muss C sein |
| `operation = write` und `reversibility = irreversible` | `risk_class_default` muss B oder C sein |
| `evidence.readback_supported = true` | `accepted_methods` darf ausschliesslich `["readback"]` sein |
| `evidence.readback_supported = false` | `evidence.limitation` ist Pflicht und muss aussagekräftig sein |

## 4. Feldvertrag

| Feld | Pflicht | Bedeutung |
|---|---|---|
| `tool_id` | ja | `^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$`, z. B. `storage_gdrive.move_file` |
| `version` | ja | semantische Version des Werkzeugvertrags |
| `display_name` | ja | deutsches Anzeigelabel |
| `purpose` | ja | was das Werkzeug fachlich bewirkt |
| `adapter_id` | ja | austauschbarer Systemadapter |
| `operation` | ja | `read` oder `write` |
| `allowed_contexts` | ja | Positivliste von Kontext-IDs |
| `input_schema_ref` / `output_schema_ref` | nein | Verweise auf die Ein- und Ausgabeschemata |
| `required_permissions` | nein | benötigte Rechte im Zielsystem, fachlich beschrieben |
| `side_effects` | ja | was in der Welt verändert wird |
| `external_effect` | ja | `none`, `internal`, `external_recipient`, `financial`, `legal` |
| `risk_class_default` | ja | A, B oder C |
| `reversibility` | ja | `reversible`, `compensable`, `irreversible` |
| `undo_tool_id` | nein | Werkzeug zur Rückgängigmachung |
| `idempotency.key_fields` | ja | Bestandteile des Schlüssels, ausschliesslich stabile Werte |
| `idempotency.strategy` | ja | `db_unique_constraint`, `provider_native`, `db_plus_provider` |
| `idempotency.native_support` | ja | ob das Zielsystem selbst Idempotenz anbietet |
| `idempotency.extra_dedup` | nein | zusätzlicher Mechanismus, z. B. `content_hash` |
| `evidence.readback_supported` | ja | ob ein unabhängiger Lesevorgang möglich ist |
| `evidence.accepted_methods` | ja | abschliessende Liste ausreichender Nachweismethoden |
| `evidence.required_types` | ja | zu erhebende Nachweisarten |
| `evidence.verify_delay_seconds` | ja | Wartezeit vor der Prüfung |
| `evidence.limitation` | bedingt | was der Ersatznachweis nicht belegt |
| `evidence.deferred_check_after_hours` | nein | Zeitpunkt eines nachgelagerten Abgleichs |
| `retry_policy` | ja | wiederholbare Fehlerklassen, höchstens drei Versuche, Backoff |
| `timeout_seconds` | ja | harte Obergrenze |
| `rate_limit` | nein | Aufrufe je Zeitfenster |
| `dry_run_supported` | ja | ob eine Simulation möglich ist |
| `status` | ja | `draft`, `approved`, `deprecated` |
| `owner` | ja | Verantwortlicher für den Vertrag |

## 5. Ausgelieferte Einträge

Alle fünf Einträge in `registry/tool_registry.json` stehen im Status `draft` und
sind nicht implementiert.

| Werkzeug | Kontexte | Klasse | Readback | Nachweis |
|---|---|---|---|---|
| `storage_gdrive.move_file` | privat | A | ja | `readback` auf Datei-ID, Pfad und Name |
| `tasks_internal.create_task` | beide | A | ja | `readback` auf die Aufgaben-ID |
| `mail_default.send_message` | beide | C | ja | `readback` im Ordner der gesendeten Nachrichten |
| `messaging_superchat.send_template_message` | Arbeitgeber | B | **nein** | Anbieter-ID und Zustellquittung, mit Grenzangabe und Nachprüfung nach 24 Stunden |
| `approval_email.request_decision` | beide | A | ja | `readback` auf die Anforderungsnachricht |

Der vierte Eintrag ist bewusst enthalten: Er zeigt, wie ein Werkzeug ohne
Lesezugriff behandelt wird, und ist die Grundlage der Beispiele
`examples/action_class_b_message_send.json` und
`examples/evidence_provider_no_readback.json`.

## 6. Neues Werkzeug aufnehmen

1. Eintrag in `registry/tool_registry.json` ergänzen, Status `draft`.
2. `python3 tools/validate_schemas.py` ausführen; das Schema weist unzulässige Kombinationen ab.
3. `python3 tools/validate_policy.py` ausführen; prüft Kontextbezüge und Herabstufungen.
4. Erst nach nachgewiesener Zuverlässigkeit im Pilotbetrieb den Status auf `approved` setzen.
