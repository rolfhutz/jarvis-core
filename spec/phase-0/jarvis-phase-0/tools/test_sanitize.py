"""
Tests fuer die Bereinigung von message_safe (TS-5).

Positivtests: zulaessige Meldungen bleiben unveraendert.
Negativtests: jede Meldung mit einem Geheimnis oder Fachinhalt wird bereinigt,
und das Geheimnis darf danach nicht mehr im Ergebnis vorkommen.

Aufruf:  python3 tools/test_sanitize.py
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from sanitize_message import MAX_LENGTH, is_safe, sanitize_message  # noqa: E402

POSITIV = [
    "Zielsystem antwortete nicht innerhalb des Zeitlimits.",
    "HTTP 429 rate limited, Wiederholung geplant.",
    "Validierungsfehler in Feld due_at.",
    "Verbindung abgebrochen (Code 502).",
    "Berechtigung fehlt fuer Operation move_file.",
]

# (Beschreibung, Rohmeldung, Zeichenkette, die danach nicht mehr auftauchen darf)
NEGATIV = [
    ("Zugangsschluessel in der Meldung",
     "Auth failed: api_key=sk-live-9f2b7c1d4e6a8b3c5d7e9f0a",
     "sk-live-9f2b7c1d4e6a8b3c5d7e9f0a"),
    ("Bearer-Token",
     "401 Unauthorized, Authorization: Bearer abcdef1234567890abcdef1234567890",
     "abcdef1234567890abcdef1234567890"),
    ("JWT",
     "Token abgelehnt: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1r",
     "eyJhbGciOiJIUzI1NiJ9"),
    ("E-Mail-Adresse des Empfaengers",
     "Zustellung an kunde.mustermann@example.com fehlgeschlagen",
     "kunde.mustermann@example.com"),
    ("URL mit Query-Parametern",
     "Aufruf https://api.example.com/v1/send?token=geheim123456 schlug fehl",
     "token=geheim123456"),
    ("Dateipfad mit Klarnamen",
     "Datei /home/rolf/Dokumente/Kuendigung_Krankenkasse.pdf nicht gefunden",
     "Kuendigung_Krankenkasse.pdf"),
    ("Fachinhalt in Anfuehrungszeichen",
     'Betreff "Rueckmeldung zur Lieferzeit Angebot 2026-0815" konnte nicht gesetzt werden',
     "Rueckmeldung zur Lieferzeit"),
    ("IBAN",
     "Zahlung an CH9300762011623852957 abgelehnt",
     "CH9300762011623852957"),
    ("Belegnummer",
     "Rechnungsnummer 4711000815 nicht gefunden",
     "4711000815"),
    ("IP-Adresse",
     "Verbindung zu 192.168.10.42 abgelehnt",
     "192.168.10.42"),
    ("Zeilenumbrueche und Steuerzeichen",
     "Fehler\nZeile2\tTabulator",
     "\n"),
]


def main():
    print("JARVIS Phase 0 - Tests der Bereinigung von message_safe (TS-5)\n")
    failures = []

    print("Positivtests: zulaessige Meldungen bleiben unveraendert")
    for text in POSITIV:
        result = sanitize_message(text)
        if result != text or not is_safe(text):
            failures.append(f"[POS] '{text}' wurde veraendert zu '{result}'")
            print(f"  FEHLER {text}")
        else:
            print(f"  ok  {text}")

    print("\nNegativtests: Geheimnisse und Fachinhalte werden entfernt")
    for label, raw, forbidden in NEGATIV:
        result = sanitize_message(raw)
        if forbidden in result:
            failures.append(f"[NEG] {label}: '{forbidden}' ist noch enthalten")
            print(f"  FEHLER {label:38s} -> {result}")
        else:
            print(f"  ok  {label:38s} -> {result}")

    print("\nWeitere Zusicherungen")
    long_text = "A" * 5000
    if len(sanitize_message(long_text)) > MAX_LENGTH:
        failures.append("[LEN] Laengenbegrenzung nicht eingehalten")
        print("  FEHLER Laengenbegrenzung")
    else:
        print(f"  ok  Laengenbegrenzung auf {MAX_LENGTH} Zeichen eingehalten")

    if sanitize_message(None) != "":
        failures.append("[NULL] None wird nicht abgefangen")
        print("  FEHLER Umgang mit None")
    else:
        print("  ok  Umgang mit None")

    if not is_safe(sanitize_message(NEGATIV[0][1])):
        failures.append("[IDEM] Bereinigung ist nicht stabil")
        print("  FEHLER Bereinigung ist nicht stabil")
    else:
        print("  ok  Zweifache Bereinigung liefert dasselbe Ergebnis")

    print()
    if failures:
        print(f"FEHLGESCHLAGEN: {len(failures)} Befund(e)")
        for f in failures:
            print("  -", f)
        return 1
    print("ERGEBNIS: alle Pruefungen bestanden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
