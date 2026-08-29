"""
JARVIS Phase 0 - Referenzimplementierung fuer Idempotenz und Fingerprints.

Version 1.0.0

Diese Datei ist der verbindliche Normalisierungsvertrag. Jede Implementierung
(n8n Code-Node, Adapter, Skript) muss exakt dieses Ergebnis liefern.

Grundsatz: Der Idempotenzschluessel wird ausschliesslich aus stabilen Werten
gebildet. Veraenderliche natuerliche Objektschluessel (Betreff, Dateiname,
Betrag, Zusammenfassung) sind unzulaessig.
"""

from __future__ import annotations

import hashlib
import unicodedata

FIELD_SEPARATOR = "\u001f"  # ASCII Unit Separator, kann in Feldwerten nicht auftreten

IDEMPOTENCY_FIELDS = (
    "context_id",
    "source_ref",
    "action_type",
    "target_system",
    "target_object_ref",
)


def normalize_value(value: str) -> str:
    """Normalisiert einen Einzelwert deterministisch."""
    if value is None:
        raise ValueError("Idempotenzbasis darf keine leeren Felder enthalten")
    text = unicodedata.normalize("NFKC", str(value))
    text = text.strip().lower()
    text = " ".join(text.split())
    if text == "":
        raise ValueError("Idempotenzbasis darf keine leeren Felder enthalten")
    if FIELD_SEPARATOR in text:
        raise ValueError("Feldwert enthaelt das reservierte Trennzeichen")
    return text


def build_idempotency_key(basis: dict) -> str:
    """
    Erzeugt den Idempotenzschluessel als SHA-256 Hexdigest.

    basis muss genau die Felder aus IDEMPOTENCY_FIELDS enthalten:
      context_id        Kontextkennung
      source_ref        Quellereignis-ID oder stabile Quellsystem-ID
      action_type       Aktionstyp in Punktnotation
      target_system     Adapter-ID des Zielsystems
      target_object_ref Stabile Referenz des Zielobjekts
    """
    missing = [f for f in IDEMPOTENCY_FIELDS if f not in basis]
    if missing:
        raise ValueError(f"Fehlende Felder in der Idempotenzbasis: {missing}")
    joined = FIELD_SEPARATOR.join(normalize_value(basis[f]) for f in IDEMPOTENCY_FIELDS)
    return hashlib.sha256(joined.encode("utf-8")).hexdigest()


def content_fingerprint(fields: dict) -> str:
    """
    Erzeugt den Inhalts-Fingerprint ueber die entscheidungsrelevanten Felder
    einer Aktion. Aendert sich der Fingerprint nach einer Freigabe, verliert
    die Freigabe ihre Gueltigkeit.

    Rueckgabe im Format 'sha256:<hex>'.
    """
    parts = []
    for key in sorted(fields):
        parts.append(normalize_value(key))
        parts.append(normalize_value(fields[key]))
    joined = FIELD_SEPARATOR.join(parts)
    return "sha256:" + hashlib.sha256(joined.encode("utf-8")).hexdigest()


def file_content_hash(data: bytes) -> str:
    """
    Dublettenerkennung fuer Dateien. Bewusst getrennt vom Idempotenzschluessel:
    zwei fachlich verschiedene Vorgaenge koennen dieselbe Datei enthalten und
    umgekehrt.
    """
    return "sha256:" + hashlib.sha256(data).hexdigest()


if __name__ == "__main__":
    demo = {
        "context_id": "privat",
        "source_ref": "evt_01JBQ8Z4K7M3N9P2R5T6V8W0XY",
        "action_type": "task.create",
        "target_system": "tasks_internal",
        "target_object_ref": "case:privat/versicherung/police-4711",
    }
    print(build_idempotency_key(demo))
