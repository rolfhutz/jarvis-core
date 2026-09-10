# Nachweis Phase 1.0 — Smoke-Test der Kern-Subworkflows

**Datum:** 10. September 2026
**Workflow:** `JV-CORE-OPS-smoke_test-v1` (n8n-ID `P5IlT5RlGBK1aqiO`), manuell ausgelöst, nicht veröffentlicht
**Datenbank:** Supabase `slatmyyxwruxvihcaklk`, Zugriff ausschliesslich über `jv_privat_postgres` und `jv_visolva_postgres`
**Testdaten:** synthetisch, gekennzeichnet mit `trc_smoke_<zeitstempel>` beziehungsweise `smk_<zeitstempel>`. Das Fachprotokoll ist append-only; die Einträge bleiben mit Freigabe von Rolf (10.09.2026) dauerhaft bestehen.

---

## 1. Ergebnis

| Lauf | Ausführung | Ergebnis |
|---|---|---|
| 1 | 21865 | 38 von 48, **nicht bestanden** — drei echte Fehler, siehe Abschnitt 3 |
| 2 | 21907 | **48 von 48, bestanden** |

## 2. Prüfumfang von Lauf 2

| Bereich | Fälle | Inhalt |
|---|---|---|
| `context_resolve` | C01–C04 | beide Kontexte; unbekannte Bindung und widersprechender Hinweis abgewiesen |
| `id_generate` | I01–I03 | Präfix-ULID, SHA-256-Schlüssel, Determinismus; unbekannte Objektart abgewiesen |
| `action_classify` (R-3) | K01–K07 | Klasse aus Register je Werkzeug und Version; C für unbekanntes Werkzeug; manuelle Hochstufung; Kontextzulassung |
| `tool_invoke` (R-4) | T01–T07 | nicht freigegeben, nicht registriert, falsche Version, Kontext nicht zugelassen, Herabstufung, Klasse C ohne Freigabe, Klasse C mit Freigabe aber nicht freigegeben |
| `evidence_verify` (R-5) | E01–E07 | Readback verifiziert; Readback erzwungen; Ersatznachweis mit Grenze; Methode nicht zugelassen; unbekannter Vertrag; Abweichung; leerer Soll-Zustand |
| `idempotency_guard` | G01–G04, G12 | Sperre je Kontext; zweiter Anspruch abgewiesen; genau einer von zwei Läufen erhält die Sperre (1.0-A7); ungültiger Schlüssel abgewiesen |
| `fach_log_write` | F01–F03 | beide Kontexte, Text mit Kommas und Umlauten; unzulässiger Akteur abgewiesen |
| `tech_log_write` | L01–L02 | beide Kontexte; Bereinigung von Kennwort und E-Mail-Adresse |
| `error_handler` | H01–H02 | transient mit Wiederholung; security mit Halt und Meldung |
| Readback | 8 | Fachprotokoll unverändert (Kommas, Umlaute), Technikprotokoll bereinigt, Fehlerereignis vorhanden, genau eine Sperre je Aktion |

## 3. Befunde aus Lauf 1 und Behebung

| Nr. | Befund | Folge ohne Behebung | Behebung |
|---|---|---|---|
| B1 | Text mit Komma wird von der Parameterliste des Postgres-Knotens zerlegt | Werte verrutschen unbemerkt in falsche Spalten | ADR-003: Freitext als base64-JSON-Block, Entpacken per `jsonb_to_record` |
| B2 | Leerer Wert kommt als Text `"null"` an | Schreibfehler in Zahlenspalten, falsche Texte in Textspalten | wie B1 |
| B3 | `error_handler` gab nur die Datenbankantwort zurück | Aufrufer erfährt nicht, ob wiederholt oder eskaliert werden muss | Rückgabe der vollständigen Eskalationsentscheidung; bereinigter Text zusätzlich in `error_event.body` |

## 4. Nicht Gegenstand dieses Nachweises

- Ein zugelassener Werkzeugaufruf (`invocation_allowed = true`): In 1.0 steht noch kein Werkzeug auf `approved`. Folgt mit Schritt 1.0.8.
- Freigabeweg und Tagesbericht (Schritte 1.3 und 1.4).
- Wiederherstellung in eine leere Instanz (1.0-A8): eigener Nachweis.
