# Phase-1-Workflows

Exportierte n8n-Workflows des KI-Dokumentenassistenten (Kontext privat).

| Datei | Inhalt | Stand |
|---|---|---|
| `JV-P1-MAIN-document_desk-v1.json` | Weboberfläche Dokumente: Upload, KI-Analyse, Ablage, Aufgaben, Regeln (CR-02 bis CR-16) | 23.10.2026 |
| `JV-P1-MAIN-auftrag_desk-v1.json` | Aufträge zu Dokumenten: Entwürfe (E-Mail/Brief), Zahlungsaufgaben, Empfänger, Versand bestätigen (CR-05 bis CR-16) | 23.10.2026 |

Erzeugt mit `tools/normalize_n8n_export.py --phase cr-16 --secrets-out <privat>` aus dem n8n-Export
(Schnittstelle, kein Handpflegen). Webhook-Pfade sind durch `JV_GEHEIM_WEBHOOK_PFAD` ersetzt (DT-1);
bei einer Wiederherstellung die echten Pfade aus `claude/privat_daten/webhook_pfade.json` (Claude-Projekt) eintragen.
