"""
JARVIS Phase 1 - Referenzimplementierung fuer Belegpruefung und Wertnormalisierung.

Version 1.0.0

Diese Datei ist der verbindliche Normalisierungsvertrag der Extraktion. Jede
Implementierung (n8n Code-Node, Adapter, Skript) muss exakt dieses Ergebnis
liefern.

Zwei getrennte Verfahren, die nicht vermischt werden duerfen:

1. TECHNISCHE TEXTNORMALISIERUNG (text_normalize)
   Ausschliesslich fuer die Belegsuche. Sie veraendert keine Bedeutung,
   sondern gleicht nur Darstellungsunterschiede aus: Unicode-Form,
   Bindestrich- und Anfuehrungszeichenvarianten, geschuetzte Leerzeichen,
   Zeilenumbrueche, Gross- und Kleinschreibung.
   Geprueft wird: kommt raw_value so im Beleg vor?

2. TYPISIERTE NORMALISIERUNG (apply_rule)
   Leitet aus raw_value den kanonischen normalized_value ab, z. B.
   "1. Januar 2027" -> "2027-01-01". Jede Regel ist registriert und
   traegt eine ID.
   Geprueft wird: laesst sich normalized_value aus raw_value ableiten?

Zwei Festlegungen mit Auswirkung auf die gesamte Verarbeitung:

  KALENDER. Datums- und Zeitregeln pruefen das konkrete gregorianische
  Kalenderdatum ueber datetime.date beziehungsweise datetime.datetime.
  Eine reine Bereichspruefung von Tag und Monat wuerde den 31.02. und den
  29.02. eines Nicht-Schaltjahrs durchlassen.

  GELDWERTE. Dezimalregeln liefern eine Zeichenfolge mit Dezimalpunkt und
  exakt zwei Nachkommastellen, niemals eine Binaer-Gleitkommazahl. Ein
  float kann 0.10 + 0.20 nicht exakt darstellen; bei Beitraegen, Rechnungen
  und Fristen mit Geldwirkung ist das unzulaessig. Gerechnet wird
  ausschliesslich mit Decimal, in PostgreSQL mit NUMERIC.

Ein Sprachmodell liefert raw_value, normalized_value und die Regel-ID als
Vorschlag. Den validation_status setzt ausschliesslich dieses Verfahren.
"""

from __future__ import annotations

import datetime
import re
import unicodedata
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation

# ---------------------------------------------------------------------------
# 1. Technische Textnormalisierung fuer die Belegsuche
# ---------------------------------------------------------------------------

_DASHES = dict.fromkeys(map(ord, "\u2010\u2011\u2012\u2013\u2014\u2015\u2212"), "-")
_QUOTES = dict.fromkeys(map(ord, "\u2018\u2019\u201a\u201b\u2032"), "'")
_DQUOTES = dict.fromkeys(map(ord, "\u201c\u201d\u201e\u201f\u2033\u00ab\u00bb"), '"')
_SPACES = dict.fromkeys(map(ord, "\u00a0\u2007\u202f\u2009\u200a\u2002\u2003"), " ")


def text_normalize(text: str) -> str:
    """
    Rein technische Normalisierung. Verlustfrei in Bezug auf die Bedeutung.
    Wird auf Beleg und raw_value gleichermassen angewendet.
    """
    if text is None:
        return ""
    s = unicodedata.normalize("NFKC", str(text))
    s = s.translate(_DASHES).translate(_QUOTES).translate(_DQUOTES).translate(_SPACES)
    s = s.replace("\r", " ").replace("\n", " ").replace("\t", " ")
    s = re.sub(r"\s+", " ", s)
    return s.strip().casefold()


def _no_space(text: str) -> str:
    return re.sub(r"\s+", "", text)


def evidence_contains(snippet: str, raw_value: str) -> bool:
    """
    Stufe 1 der Belegpruefung.

    Der Rohwert muss im Beleg auffindbar sein. Zusaetzlich wird eine
    Variante ohne Leerzeichen geprueft, damit ein Zeilenumbruch mitten in
    einer Zahl oder Kennung nicht zu einem falschen Negativ fuehrt.
    """
    if raw_value is None or str(raw_value) == "":
        return False
    n_snip = text_normalize(snippet)
    n_raw = text_normalize(raw_value)
    if n_raw in n_snip:
        return True
    return _no_space(n_raw) in _no_space(n_snip)


# ---------------------------------------------------------------------------
# 2. Typisierte Normalisierungsregeln
# ---------------------------------------------------------------------------

_MONTHS_DE = {
    "januar": 1, "jan": 1, "februar": 2, "feb": 2, "maerz": 3, "marz": 3, "mrz": 3, "mar": 3,
    "april": 4, "apr": 4, "mai": 5, "juni": 6, "jun": 6, "juli": 7, "jul": 7,
    "august": 8, "aug": 8, "september": 9, "sep": 9, "sept": 9,
    "oktober": 10, "okt": 10, "november": 11, "nov": 11, "dezember": 12, "dez": 12,
}

_CURRENCY_SYMBOLS = {
    "chf": "CHF", "fr.": "CHF", "fr": "CHF", "sfr": "CHF", "sfr.": "CHF",
    "eur": "EUR", "\u20ac": "EUR", "euro": "EUR",
    "usd": "USD", "$": "USD",
    "gbp": "GBP", "\u00a3": "GBP",
}

_TRUE_DE = {"ja", "wahr", "true", "erforderlich", "vorhanden", "x"}
_FALSE_DE = {"nein", "falsch", "false", "nicht erforderlich", "keine", "-"}


class NormalizationError(ValueError):
    pass


def _umlaut_fold(text: str) -> str:
    return (text.replace("ä", "ae").replace("ö", "oe").replace("ü", "ue")
                .replace("ß", "ss"))


def expand_two_digit_year(year: int) -> int:
    """
    Zweistellige Jahresangabe. Verbindliche Regel, bewusst beibehalten:
      00 bis 69 -> 2000 bis 2069
      70 bis 99 -> 1970 bis 1999
    Vierstellige Angaben bleiben unveraendert.
    """
    if year >= 100:
        return year
    return year + 2000 if year < 70 else year + 1900


def _iso_date(year: int, month: int, day: int) -> str:
    """
    Erzeugt ein ISO-Datum und prueft dabei das konkrete Kalenderdatum.
    datetime.date weist den 31.02., den 31.04. und den 29.02. eines
    Nicht-Schaltjahrs zurueck; eine Bereichspruefung wuerde das nicht.
    """
    year = expand_two_digit_year(year)
    try:
        d = datetime.date(year, month, day)
    except ValueError as exc:
        raise NormalizationError(
            f"Kein gueltiges Kalenderdatum: {day:02d}.{month:02d}.{year:04d} ({exc})") from exc
    return d.isoformat()


def _iso_datetime(year: int, month: int, day: int, hh: int, mm: int, ss: int) -> str:
    """Wie _iso_date, zusaetzlich mit Pruefung der Uhrzeit."""
    year = expand_two_digit_year(year)
    try:
        dt = datetime.datetime(year, month, day, hh, mm, ss)
    except ValueError as exc:
        raise NormalizationError(
            f"Kein gueltiger Zeitpunkt: {day:02d}.{month:02d}.{year:04d} "
            f"{hh:02d}:{mm:02d}:{ss:02d} ({exc})") from exc
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def _rule_date_de_numeric(raw: str) -> str:
    m = re.fullmatch(r"\s*(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{2,4})\s*", raw)
    if not m:
        raise NormalizationError("Kein Datum im Format TT.MM.JJJJ")
    return _iso_date(int(m.group(3)), int(m.group(2)), int(m.group(1)))


def _rule_date_de_long(raw: str) -> str:
    s = _umlaut_fold(text_normalize(raw))
    m = re.fullmatch(r"(\d{1,2})\.?\s+([a-z]+)\.?\s+(\d{4})", s)
    if not m:
        raise NormalizationError("Kein Datum im Format '1. Januar 2027'")
    month = _MONTHS_DE.get(m.group(2))
    if month is None:
        raise NormalizationError(f"Unbekannter Monatsname: {m.group(2)}")
    return _iso_date(int(m.group(3)), month, int(m.group(1)))


def _rule_date_iso(raw: str) -> str:
    m = re.fullmatch(r"\s*(\d{4})-(\d{2})-(\d{2})\s*", raw)
    if not m:
        raise NormalizationError("Kein Datum im Format JJJJ-MM-TT")
    return _iso_date(int(m.group(1)), int(m.group(2)), int(m.group(3)))


def _rule_datetime_de(raw: str) -> str:
    """
    Ergebnis ist eine ortszeitbezogene Angabe ohne Zeitzone. Die Umrechnung
    nach UTC erfolgt spaeter mit der Zeitzone des Kontexts, nicht hier.
    """
    m = re.fullmatch(r"\s*(\d{1,2})\.(\d{1,2})\.(\d{2,4})[,\s]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(?:uhr)?\s*",
                     raw, flags=re.IGNORECASE)
    if not m:
        raise NormalizationError("Kein Zeitpunkt im Format TT.MM.JJJJ HH:MM")
    return _iso_datetime(int(m.group(3)), int(m.group(2)), int(m.group(1)),
                         int(m.group(4)), int(m.group(5)), int(m.group(6) or 0))


MONEY_SCALE = Decimal("0.01")


def _to_money(text: str) -> str:
    """
    Kanonische Geldzeichenfolge: Dezimalpunkt, exakt zwei Nachkommastellen,
    keine Exponentialschreibweise, kein float. Kaufmaennische Rundung.
    """
    try:
        value = Decimal(text)
    except (InvalidOperation, ValueError) as exc:
        raise NormalizationError(f"Kein Dezimalwert: {text}") from exc
    if not value.is_finite():
        raise NormalizationError(f"Kein endlicher Dezimalwert: {text}")
    return format(value.quantize(MONEY_SCALE, rounding=ROUND_HALF_UP), "f")


def to_decimal(value: str) -> Decimal:
    """
    Zugang zur Berechnung. Jede Rechnung mit Geldwerten laeuft ueber Decimal,
    niemals ueber float. In PostgreSQL entspricht das NUMERIC.
    """
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError) as exc:
        raise NormalizationError(f"Kein Dezimalwert: {value}") from exc


def is_canonical_money(value) -> bool:
    """Prueft die kanonische Darstellung eines Geldwerts."""
    return isinstance(value, str) and re.fullmatch(r"-?\d+\.\d{2}", value) is not None


def _strip_currency(raw: str) -> str:
    s = text_normalize(raw)
    for token in sorted(_CURRENCY_SYMBOLS, key=len, reverse=True):
        s = s.replace(token, " ")
    return re.sub(r"[^0-9.,'\u2019+-]", "", s)


def _rule_decimal_de(raw: str) -> str:
    """Tausenderpunkt, Dezimalkomma: 1.234,50 -> "1234.50" """
    s = _strip_currency(raw)
    if not re.fullmatch(r"[+-]?\d{1,3}(\.\d{3})*(,\d+)?|[+-]?\d+(,\d+)?", s):
        raise NormalizationError(f"Kein deutsches Zahlformat: {raw}")
    return _to_money(s.replace(".", "").replace(",", "."))


def _rule_decimal_ch(raw: str) -> str:
    """Hochkomma als Tausendertrenner, Dezimalpunkt: 1'234.50 -> "1234.50" """
    s = _strip_currency(raw).replace("\u2019", "'")
    # In der Schweiz uebliche Schreibweise fuer volle Betraege: 12'000.-
    s = re.sub(r"\.-$", ".00", s)
    if not re.fullmatch(r"[+-]?\d{1,3}('\d{3})*(\.\d+)?|[+-]?\d+(\.\d+)?", s):
        raise NormalizationError(f"Kein schweizerisches Zahlformat: {raw}")
    return _to_money(s.replace("'", ""))


def _rule_decimal_en(raw: str) -> str:
    """Tausenderkomma, Dezimalpunkt: 1,234.50 -> "1234.50" """
    s = _strip_currency(raw)
    if not re.fullmatch(r"[+-]?\d{1,3}(,\d{3})*(\.\d+)?|[+-]?\d+(\.\d+)?", s):
        raise NormalizationError(f"Kein englisches Zahlformat: {raw}")
    return _to_money(s.replace(",", ""))


def _rule_currency_iso(raw: str) -> str:
    s = text_normalize(raw)
    if s in _CURRENCY_SYMBOLS:
        return _CURRENCY_SYMBOLS[s]
    for token, code in _CURRENCY_SYMBOLS.items():
        if re.search(rf"(?<![a-z0-9]){re.escape(token)}(?![a-z0-9])", s):
            return code
    if re.fullmatch(r"[a-z]{3}", s):
        return s.upper()
    raise NormalizationError(f"Kein erkennbarer Waehrungscode: {raw}")


def _rule_integer_plain(raw: str) -> int:
    s = re.sub(r"[\s.'\u2019]", "", text_normalize(raw))
    if not re.fullmatch(r"[+-]?\d+", s):
        raise NormalizationError(f"Keine Ganzzahl: {raw}")
    return int(s)


def _rule_identifier_strip(raw: str) -> str:
    """Kennungen werden vergleichbar gemacht: nur Buchstaben und Ziffern, klein."""
    s = text_normalize(raw)
    s = re.sub(r"[^a-z0-9]", "", s)
    if not s:
        raise NormalizationError(f"Kennung ohne verwertbaren Inhalt: {raw}")
    return s


def _rule_string_trim(raw: str) -> str:
    s = unicodedata.normalize("NFKC", str(raw))
    s = re.sub(r"\s+", " ", s).strip()
    if not s:
        raise NormalizationError("Leere Zeichenfolge")
    return s


def _rule_boolean_de(raw: str) -> bool:
    s = text_normalize(raw)
    if s in _TRUE_DE:
        return True
    if s in _FALSE_DE:
        return False
    raise NormalizationError(f"Kein boolescher Wert: {raw}")


RULES = {
    "date.de_numeric": ("date", _rule_date_de_numeric),
    "date.de_long": ("date", _rule_date_de_long),
    "date.iso": ("date", _rule_date_iso),
    "datetime.de_numeric": ("datetime", _rule_datetime_de),
    "decimal.de": ("money", _rule_decimal_de),
    "decimal.ch": ("money", _rule_decimal_ch),
    "decimal.en": ("money", _rule_decimal_en),
    "currency.iso4217": ("currency_code", _rule_currency_iso),
    "integer.plain": ("integer", _rule_integer_plain),
    "identifier.strip_separators": ("identifier", _rule_identifier_strip),
    "string.trim": ("string", _rule_string_trim),
    "boolean.de": ("boolean", _rule_boolean_de),
}


def apply_rule(rule_id: str, raw_value: str):
    """Stufe 2 der Belegpruefung: kanonischen Wert aus dem Rohwert ableiten."""
    if rule_id not in RULES:
        raise NormalizationError(f"Unbekannte Normalisierungsregel: {rule_id}")
    return RULES[rule_id][1](str(raw_value))


def rule_data_type(rule_id: str) -> str:
    if rule_id not in RULES:
        raise NormalizationError(f"Unbekannte Normalisierungsregel: {rule_id}")
    return RULES[rule_id][0]


def values_match(expected, actual) -> bool:
    """
    Vergleich kanonischer Werte.

    Geldwerte sind Zeichenfolgen und werden exakt ueber Decimal verglichen.
    Eine Gleitkommazahl auf einer der beiden Seiten gilt als Abweichung: ein
    Geldwert darf nicht als float gefuehrt werden.
    """
    if isinstance(expected, bool) or isinstance(actual, bool):
        return expected is actual
    if isinstance(expected, float) or isinstance(actual, float):
        return False
    if is_canonical_money(expected) and is_canonical_money(actual):
        return Decimal(expected) == Decimal(actual)
    if isinstance(expected, int) and isinstance(actual, int):
        return expected == actual
    return expected == actual


# ---------------------------------------------------------------------------
# 3. Dateiendung aus dem geprueften MIME-Typ
# ---------------------------------------------------------------------------

MIME_EXTENSION_MAP = {
    "application/pdf": "pdf",
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/tiff": "tif",
}


def extension_for_mime(mime_type: str) -> str:
    """
    Die Dateiendung wird ausschliesslich aus dem geprueften MIME-Typ
    abgeleitet, niemals aus dem urspruenglichen Dateinamen. Ein Original
    wird nicht konvertiert; es behaelt sein Format.
    """
    key = (mime_type or "").strip().lower()
    if key not in MIME_EXTENSION_MAP:
        raise NormalizationError(f"Kein zulaessiger MIME-Typ fuer die Ablage: {mime_type}")
    return MIME_EXTENSION_MAP[key]


def filename_matches_mime(filename: str, mime_type: str) -> bool:
    """Prueft, ob die Endung des Zieldateinamens zum MIME-Typ passt."""
    expected = extension_for_mime(mime_type)
    return filename.lower().endswith("." + expected)
