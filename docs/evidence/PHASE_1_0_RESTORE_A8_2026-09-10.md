# Nachweis 1.0-A8 — Export und Wiederherstellung der Workflows

**Datum:** 10. September 2026
**Kriterium:** 1.0-A8 „Export und Wiederherstellung der Workflows in eine leere Instanz gelingt"
**Zielinstanz:** frische lokale n8n-Instanz 2.35.7 (Node v22.22.2), eigenes Benutzerverzeichnis, leere SQLite-Datenbank
**Quelle:** 11 Exporte aus n8n Cloud per „Export JSON", normalisiert mit `tools/normalize_n8n_export.py`

## Ergebnis: bestanden

| Pruefung | Umfang | Ergebnis |
|---|---|---|
| Import | 11 Workflows, 2 Credential-Huellen | `Successfully imported 11 workflows.` |
| Workflow-IDs unveraendert | 11 | bestanden |
| Knoten, Parameter, Verbindungen identisch | 90 Knoten | bestanden |
| Credential-Zuordnung je Knoten (ID und Name) | 19 | bestanden |
| Kontext-Credential passend zum Knotennamen | alle Postgres-Knoten | bestanden |
| Subworkflow-Verweise aufloesbar | 9 | bestanden |
| Credential-Rueckexport ohne Klartext | 2 | verschluesselt |

Reproduzierbar mit `tests/n8n/check_restore.py`; Ablauf in `n8n/core/README.md`.

## Befund im ersten Durchlauf

Die erste Fassung des Normalisierungsskripts entfernte die Credential-IDs und
behielt nur die Namen. Ergebnis: **9 von 19 Zuordnungen falsch.** n8n ordnet
ohne ID nicht ueber den Namen zu, sondern gibt allen Postgres-Knoten das erste
vorhandene Credential. Alle visolva-Knoten liefen mit `jv_privat_postgres`.

Die Datenbank haette die Zugriffe abgewiesen (Kontexttrennung B2 greift auf
Rollenebene), die Workflows waeren aber unbrauchbar gewesen. Behebung:
Credential-IDs bleiben im Export; die Wiederherstellung legt die Credentials
mit denselben IDs an. IDs sind keine Geheimnisse.

## Grenzen

- Geprueft ist die vollstaendige Wiederherstellung von Struktur und
  Zuordnung. Die Verbindung zur Datenbank braucht die Kennwoerter aus dem
  Passwortmanager und wurde in der Testinstanz bewusst nicht hergestellt.
- Die Lauffaehigkeit gegen die echte Datenbank ist durch den Smoke-Test in der
  Produktivinstanz belegt (48/48).
- Der Export des Smoke-Tests entspricht dem Download von Rolf zuzueglich der
  zwei danach eingespielten, dokumentierten Code-Aenderungen (Testwert
  `SMOKE_FAKE_123`); Lauf 21949 mit diesem Stand: 48/48.
