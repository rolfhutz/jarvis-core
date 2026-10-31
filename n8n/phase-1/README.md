# Phase-1-Workflows

Exportierte n8n-Workflows des KI-Dokumentenassistenten (Kontext privat).

| Datei | Inhalt | Stand |
|---|---|---|
| `JV-P1-MAIN-document_desk-v1.json` | Weboberfläche Dokumente: Upload, KI-Analyse, Ablage, Aufgaben, Regeln, Suchen, Ablageort zuerst, Ablagepfad als Baum (CR-02 bis CR-18) | 31.10.2026 |
| `JV-P1-MAIN-auftrag_desk-v1.json` | Aufträge zu Dokumenten: Entwürfe (E-Mail/Brief), Zahlungsaufgaben, Empfänger, Versand bestätigen (CR-05 bis CR-16) | 23.10.2026 |
| `JV-P1-MAIN-dokument_suche-v1.json` | Such-Schnittstelle der Weboberfläche, nur lesend (CR-12) | 31.10.2026 |
| `JV-P1-SUB-text_erfassen-v1.json` | Unterworkflow Texterkennung (Google Document AI, EU) und Speichern in `document_text` (CR-12) | 31.10.2026 |
| `JV-P1-OPS-volltext_nachlauf-v1.json` | Nachlauf fehlender Volltexte, alle 2 Stunden, max. 3 Fehlversuche je Dokument (CR-12) | 31.10.2026 |

Erzeugt mit `tools/normalize_n8n_export.py --phase cr-16|cr-18 --secrets-out <privat>` aus dem n8n-Export
(Schnittstelle, kein Handpflegen). Webhook-Pfade sind durch `JV_GEHEIM_WEBHOOK_PFAD` ersetzt (DT-1);
bei einer Wiederherstellung die echten Pfade aus `claude/privat_daten/webhook_pfade.json` (Claude-Projekt) eintragen.

CR-12 braucht zusätzlich das Credential `jv_privat_docai` (Google-Dienstkonto, Document AI) und die n8n-Variablen
`JV_DOCAI_PROJECT` und `JV_DOCAI_OCR_PROCESSOR` (Werte stehen nicht im Repository).
