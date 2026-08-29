"""
JARVIS Phase 0 - Gesamtlauf aller Pruefungen.

Fuehrt alle Pruefskripte in fester Reihenfolge aus, zaehlt die Einzelergebnisse
und schreibt auf Wunsch ein Protokoll nach tests/.

Aufrufe:
    python3 tools/run_all_tests.py
    python3 tools/run_all_tests.py --write-log

Rueckgabe: Exit-Code 0, wenn alle Schritte bestanden wurden.
"""

import argparse
import datetime
import pathlib
import platform
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"

STEPS = [
    ("Beispiele erzeugen", "build_examples.py", []),
    ("Schema- und Vertragsvalidierung", "validate_schemas.py", []),
    ("Gegenprobe Negativfaelle", "validate_negative.py", []),
    ("Kontextkonfiguration (TS-6)", "validate_policy.py", []),
    ("Bereinigung message_safe (TS-5)", "test_sanitize.py", []),
    ("Rendering der SQL-Vorlagen (TS-4)", "render_context_schema.py", ["--self-test"]),
    ("SQL-Syntax und Struktur", "validate_sql.py", []),
]


def run_step(script, args):
    proc = subprocess.run(
        [sys.executable, str(TOOLS / script), *args],
        capture_output=True, text=True, cwd=str(ROOT)
    )
    return proc.returncode, proc.stdout + proc.stderr


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-log", action="store_true",
                        help="Protokoll nach tests/TESTLAUF_<Datum>.md schreiben")
    args = parser.parse_args()

    started = datetime.datetime.now(datetime.timezone.utc)
    lines = []
    failed = []
    total_ok = 0

    header = (
        "JARVIS Phase 0 - Gesamtlauf aller Pruefungen\n"
        f"Zeitpunkt (UTC): {started.isoformat(timespec='seconds')}\n"
        f"Python:          {platform.python_version()} auf {platform.system()} {platform.machine()}\n"
        f"Arbeitsordner:   {ROOT}\n"
    )
    print(header)
    lines.append(header)

    for label, script, extra in STEPS:
        code, output = run_step(script, extra)
        ok_count = output.count("  ok  ")
        total_ok += ok_count
        status = "BESTANDEN" if code == 0 else "FEHLGESCHLAGEN"
        if code != 0:
            failed.append(label)
        summary = f"[{status}] {label}  ({ok_count} Einzelpruefungen)"
        print(summary)
        lines.append("\n" + "=" * 78)
        lines.append(summary)
        lines.append("=" * 78)
        lines.append(output.rstrip())

    finished = datetime.datetime.now(datetime.timezone.utc)
    duration = (finished - started).total_seconds()
    footer = (
        f"\nSchritte: {len(STEPS)}, davon fehlgeschlagen: {len(failed)}\n"
        f"Einzelpruefungen bestanden: {total_ok}\n"
        f"Dauer: {duration:.1f} Sekunden\n"
        f"Gesamtergebnis: {'ALLE PRUEFUNGEN BESTANDEN' if not failed else 'FEHLGESCHLAGEN: ' + ', '.join(failed)}"
    )
    print(footer)
    lines.append(footer)

    if args.write_log:
        target = ROOT / "tests" / f"TESTLAUF_{started.date().isoformat()}.md"
        body = "# Gespeicherter Testlauf Phase 0\n\n```\n" + "\n".join(lines) + "\n```\n"
        target.write_text(body, encoding="utf-8")
        print(f"\nProtokoll geschrieben: {target}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
