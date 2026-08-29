"""
JARVIS Phase 0 - Referenzimplementierung fuer die Bereinigung von message_safe.
Schliesst die technische Schuld TS-5.

Version 1.0.0

Zweck: Nur bereinigte Fehlermeldungen duerfen in das gemeinsame technische
Protokoll gelangen. Das Verfahren arbeitet nach einer Positivliste:
Erlaubt ist ausschliesslich ein eng begrenztes Zeichen- und Wortmuster.
Alles, was wie ein Bezeichner, ein Schluessel, eine Adresse, ein Pfad oder
ein sonstiger Wert aussieht, wird ersetzt.

Eine Verbotsliste waere hier ungeeignet: Sie muesste jede denkbare Form eines
Geheimnisses kennen. Die Positivliste kennt stattdessen die zulaessige Form
einer technischen Fehlermeldung.
"""

from __future__ import annotations

import re
import unicodedata

MAX_LENGTH = 500

# Reihenfolge ist bedeutsam: spezifische Muster zuerst.
_PATTERNS = [
    # Zugangsdaten in Schluessel-Wert-Form
    (re.compile(r"(?i)\b(api[_-]?key|apikey|token|secret|password|passwort|pwd|authorization|bearer|credential|client[_-]?secret)\b\s*[:=]?\s*\S+"), "[entfernt]"),
    # URLs mit eingebetteten Zugangsdaten oder Query-Parametern
    (re.compile(r"(?i)\b[a-z][a-z0-9+.-]*://\S+"), "[url]"),
    # E-Mail-Adressen
    (re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"), "[adresse]"),
    # Dateipfade
    (re.compile(r"(?:[A-Za-z]:\\|/)[^\s,;]{3,}"), "[pfad]"),
    # JWT
    (re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"), "[entfernt]"),
    # Lange undurchsichtige Zeichenketten, typisch fuer Schluessel und Hashes
    (re.compile(r"\b[A-Za-z0-9_\-]{24,}\b"), "[entfernt]"),
    # IBAN
    (re.compile(r"\b[A-Z]{2}[0-9]{2}[A-Z0-9]{10,30}\b"), "[entfernt]"),
    # IP-Adressen
    (re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b"), "[ip]"),
    # Beliebige laengere Zahlenfolgen, z. B. Konto- oder Belegnummern
    (re.compile(r"\b\d{7,}\b"), "[nummer]"),
    # Anfuehrungszeichen mit Inhalt, typisch fuer eingebettete Fachdaten
    (re.compile(r"[\"'\u201e\u201c\u201d\u00ab\u00bb][^\"'\u201e\u201c\u201d\u00ab\u00bb]{3,}[\"'\u201e\u201c\u201d\u00ab\u00bb]"), "[inhalt]"),
]

_ALLOWED_CHARS = re.compile(r"[^A-Za-z0-9 .,:;()\[\]/_\-+=<>%#äöüÄÖÜß]")


def sanitize_message(raw: str) -> str:
    """
    Erzeugt aus einer beliebigen Fehlermeldung einen fuer das gemeinsame
    technische Protokoll zulaessigen Text.

    Garantien:
      - hoechstens MAX_LENGTH Zeichen,
      - keine Zugangsdaten, Token, Adressen, URLs, Pfade oder langen Bezeichner,
      - keine in Anfuehrungszeichen eingebetteten Fachinhalte,
      - keine Steuerzeichen und keine Zeilenumbrueche.
    """
    if raw is None:
        return ""
    text = unicodedata.normalize("NFKC", str(raw))
    text = text.replace("\r", " ").replace("\n", " ").replace("\t", " ")

    for pattern, replacement in _PATTERNS:
        text = pattern.sub(replacement, text)

    text = _ALLOWED_CHARS.sub(" ", text)
    text = " ".join(text.split())

    if len(text) > MAX_LENGTH:
        text = text[: MAX_LENGTH - 3].rstrip() + "..."
    return text


def is_safe(text: str) -> bool:
    """Prueft, ob ein Text die Bedingungen fuer message_safe bereits erfuellt."""
    return text == sanitize_message(text) and len(text) <= MAX_LENGTH
