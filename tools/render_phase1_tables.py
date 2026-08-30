"""
JARVIS Phase 1.0 - Sicheres Rendern der Erweiterungstabellen im Kontextschema.

Gleicher Grundsatz wie tools/render_context_schema.py aus Phase 0: Es gibt
keine freie Textersetzung. Schemaname, Kontextkennung und Datenbankbenutzer
werden ausschliesslich aus der Kontextkonfiguration uebernommen und
zusaetzlich gegen ein enges Muster geprueft. Ein Wert, der nicht in der
Konfiguration steht oder das Muster verletzt, fuehrt zum Abbruch.

Aufrufe:
    python3 tools/render_phase1_tables.py --list
    python3 tools/render_phase1_tables.py --context privat --out build/
    python3 tools/render_phase1_tables.py --self-test

Das Skript erzeugt ausschliesslich SQL-Dateien. Es stellt keine Verbindung
zu einer Datenbank her und fuehrt nichts aus.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "spec" / "phase-0" / "jarvis-phase-0" / "templates" / "context_config.example.json"
TEMPLATE = ROOT / "db" / "templates" / "004_phase1_context_tables.template.sql"

# Identisch zu tools/render_context_schema.py aus Phase 0.
SCHEMA_PATTERN = re.compile(r"^jarvis_[a-z0-9_]{2,40}$")
CONTEXT_PATTERN = re.compile(r"^[a-z][a-z0-9_]{2,31}$")
USER_PATTERN = re.compile(r"^jv_[a-z0-9_]{2,40}$")

RESERVED = {"public", "information_schema", "pg_catalog", "jarvis_ops"}


class RenderError(Exception):
    pass


def load_contexts(config_path: pathlib.Path = CONFIG) -> dict:
    cfg = json.loads(config_path.read_text(encoding="utf-8"))
    return {c["context_id"]: c for c in cfg["contexts"]}


def derive_db_user(context: dict) -> str:
    cred = context["persistence"]["credential_ref"]
    if not cred.endswith("_postgres"):
        raise RenderError(
            f"credential_ref '{cred}' folgt nicht der Konvention jv_<kontext>_postgres"
        )
    return cred[: -len("_postgres")] + "_user"


def validate_identifiers(context_id: str, schema: str, db_user: str) -> None:
    if not CONTEXT_PATTERN.match(context_id):
        raise RenderError(f"Unzulaessige Kontextkennung: {context_id!r}")
    if not SCHEMA_PATTERN.match(schema):
        raise RenderError(f"Unzulaessiger Schemaname: {schema!r}")
    if not USER_PATTERN.match(db_user):
        raise RenderError(f"Unzulaessiger Datenbankbenutzer: {db_user!r}")
    if schema in RESERVED:
        raise RenderError(f"Reserviertes Schema darf nicht verwendet werden: {schema!r}")


def render_context(context_id: str, contexts: dict) -> str:
    if context_id not in contexts:
        raise RenderError(
            f"Kontext {context_id!r} steht nicht in der Konfiguration. "
            f"Bekannt: {sorted(contexts)}"
        )
    ctx = contexts[context_id]
    schema = ctx["persistence"]["db_schema"]
    db_user = derive_db_user(ctx)
    validate_identifiers(context_id, schema, db_user)

    text = TEMPLATE.read_text(encoding="utf-8")
    text = text.replace("{{SCHEMA}}", schema)
    text = text.replace("{{CONTEXT_ID}}", context_id)
    text = text.replace("{{DB_USER}}", db_user)

    if "{{" in text:
        rest = sorted(set(re.findall(r"\{\{[A-Z_]+\}\}", text)))
        raise RenderError(f"Nicht ersetzte Platzhalter verblieben: {rest}")
    return text


def self_test() -> int:
    """Gegenproben: unzulaessige Werte muessen abgewiesen werden."""
    checks = []

    def expect_error(label, fn):
        try:
            fn()
        except RenderError:
            checks.append((label, True))
        else:
            checks.append((label, False))

    def expect_ok(label, fn):
        try:
            fn()
        except RenderError as exc:
            checks.append((f"{label} ({exc})", False))
        else:
            checks.append((label, True))

    contexts = load_contexts()

    for context_id in contexts:
        expect_ok(f"Kontext {context_id} rendert", lambda c=context_id: render_context(c, contexts))

    expect_error(
        "Unbekannter Kontext wird abgewiesen",
        lambda: render_context("nicht_registriert", contexts),
    )
    expect_error(
        "Reserviertes Schema wird abgewiesen",
        lambda: validate_identifiers("privat", "jarvis_ops", "jv_privat_user"),
    )
    expect_error(
        "Schema ohne Praefix wird abgewiesen",
        lambda: validate_identifiers("privat", "fremdschema", "jv_privat_user"),
    )
    expect_error(
        "Benutzer ohne Praefix wird abgewiesen",
        lambda: validate_identifiers("privat", "jarvis_privat", "postgres"),
    )
    expect_error(
        "Kontextkennung mit Sonderzeichen wird abgewiesen",
        lambda: validate_identifiers("pri'vat", "jarvis_privat", "jv_privat_user"),
    )
    expect_error(
        "credential_ref ohne Konvention wird abgewiesen",
        lambda: derive_db_user({"persistence": {"credential_ref": "irgendwas"}}),
    )

    failed = 0
    for label, ok in checks:
        print(f"  {'ok ' if ok else 'FEHLER'} {label}")
        if not ok:
            failed += 1
    print(f"\n{len(checks)} Pruefungen, davon fehlgeschlagen: {failed}")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="bekannte Kontexte anzeigen")
    parser.add_argument("--context", help="Kontextkennung, z. B. privat")
    parser.add_argument("--out", help="Zielordner fuer die SQL-Datei")
    parser.add_argument("--self-test", action="store_true", help="Gegenproben ausfuehren")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    contexts = load_contexts()

    if args.list:
        for context_id, ctx in contexts.items():
            schema = ctx["persistence"]["db_schema"]
            print(f"{context_id:24} schema={schema:22} user={derive_db_user(ctx)}")
        return 0

    if not args.context:
        parser.error("--context, --list oder --self-test angeben")

    try:
        sql = render_context(args.context, contexts)
    except RenderError as exc:
        print(f"Abbruch: {exc}", file=sys.stderr)
        return 1

    if not args.out:
        print(sql)
        return 0

    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / f"004_phase1_context_tables.{args.context}.sql"
    target.write_text(sql, encoding="utf-8")
    print(f"geschrieben: {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
