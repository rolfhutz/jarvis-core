"""
JARVIS Phase 0 - Syntaxpruefung der gerenderten SQL-Dateien.

Geprueft wird die Grammatik des PostgreSQL-Parsers, ohne dass eine Datenbank
eingerichtet oder verbunden wird. Damit laesst sich vor jeder Freigabe
feststellen, ob die Vorlagen ueberhaupt einspielbar sind.

Zusaetzlich wird geprueft:
  Q1  Alle Platzhalter sind ersetzt.
  Q2  Es gibt kein 'CREATE RULE ... DO INSTEAD NOTHING' mehr, das
      Aenderungsversuche stillschweigend verwerfen wuerde.
  Q3  Fuer jedes fremde Kontextschema existiert ein ausdruecklicher Entzug.
  Q4  Das gemeinsame technische Schema enthaelt keine jsonb-Spalte.

Aufruf:  python3 tools/validate_sql.py
Voraussetzung: pglast (siehe requirements.txt)
"""

import pathlib
import re
import sys

try:
    from pglast import parse_sql
    from pglast.parser import ParseError
except ImportError:  # pragma: no cover
    print("pglast ist nicht installiert. Bitte 'pip install -r requirements.txt' ausfuehren.")
    sys.exit(2)

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from render_context_schema import load_contexts, render_context, render_ops  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent


def check_statements(name, text, failures):
    try:
        stmts = parse_sql(text)
        print(f"  ok  {name:44s} {len(stmts):3d} Anweisungen geparst")
    except ParseError as exc:
        failures.append(f"[SQL] {name}: {exc}")
        print(f"  FEHLER {name}: {exc}")


def main():
    print("JARVIS Phase 0 - Syntaxpruefung der SQL-Vorlagen\n")
    failures = []
    contexts = load_contexts()

    rendered = {}
    rendered.update(render_ops())
    for cid in contexts:
        rendered.update(render_context(cid, contexts))

    print("Teil 1 - PostgreSQL-Grammatik")
    for name in sorted(rendered):
        check_statements(name, rendered[name], failures)

    print("\nTeil 2 - strukturelle Zusicherungen")

    # Q1
    leftovers = {n: re.findall(r"\{\{[A-Z_]+\}\}", t) for n, t in rendered.items()}
    if any(v for v in leftovers.values()):
        failures.append(f"[Q1] Nicht ersetzte Platzhalter: {leftovers}")
        print("  FEHLER Q1 Platzhalter verblieben")
    else:
        print("  ok  Q1 Alle Platzhalter sind ersetzt")

    # Q2
    raw_templates = "\n".join(
        re.sub(r"--.*", "", p.read_text(encoding="utf-8"))
        for p in (ROOT / "db").glob("*.sql")
    )
    if re.search(r"(?i)create\s+rule[^;]*do\s+instead\s+nothing", raw_templates):
        failures.append("[Q2] Stillschweigend verwerfende Regel gefunden")
        print("  FEHLER Q2 CREATE RULE ... DO INSTEAD NOTHING vorhanden")
    else:
        print("  ok  Q2 Kein stillschweigendes Verwerfen von Aenderungen")

    # Q3
    q3 = []
    for cid, ctx in contexts.items():
        grants = rendered[f"003_grants_and_isolation.{cid}.sql"]
        for other_id, other in contexts.items():
            if other_id == cid:
                continue
            schema = other["persistence"]["db_schema"]
            if f"REVOKE ALL ON SCHEMA {schema} FROM" not in grants:
                q3.append(f"[Q3] {cid}: kein Entzug fuer {schema}")
    failures.extend(q3)
    if not q3:
        print("  ok  Q3 Fuer jedes fremde Kontextschema existiert ein Entzug")

    # Q4
    ops = rendered["002_ops_schema.sql"]
    body = re.sub(r"--.*", "", ops)
    if re.search(r"(?i)\bjsonb\b", body):
        failures.append("[Q4] jarvis_ops enthaelt eine jsonb-Spalte")
        print("  FEHLER Q4 jsonb im gemeinsamen technischen Schema")
    else:
        print("  ok  Q4 Gemeinsames technisches Schema ohne jsonb-Spalte")

    # Q5 Append-only wird mit einem Fehler durchgesetzt
    ctx_sql = rendered[f"001_context_schema.{next(iter(contexts))}.sql"]
    if "append_only_violation" not in ctx_sql or "RAISE EXCEPTION" not in ctx_sql:
        failures.append("[Q5] Kein fehlerwerfender Schutz des Fachprotokolls")
        print("  FEHLER Q5 Append-only wird nicht mit einem Fehler durchgesetzt")
    else:
        print("  ok  Q5 Append-only wird mit einem Fehler durchgesetzt")

    # Q6 Sequenzrechte vorhanden
    if "ON ALL SEQUENCES IN SCHEMA" not in ctx_sql:
        failures.append("[Q6] Keine Sequenzrechte fuer bigserial vergeben")
        print("  FEHLER Q6 Sequenzrechte fehlen")
    else:
        print("  ok  Q6 Sequenzrechte fuer bigserial sind vergeben")

    # Q7 Abschluss eines Laufs ist moeglich
    grants_any = rendered[f"003_grants_and_isolation.{next(iter(contexts))}.sql"]
    if "GRANT UPDATE (finished_at" not in grants_any:
        failures.append("[Q7] Workflow-Laeufe koennen nicht abgeschlossen werden")
        print("  FEHLER Q7 Kein spaltenweises UPDATE auf workflow_run")
    else:
        print("  ok  Q7 Laeufe koennen spaltenweise abgeschlossen werden")

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
