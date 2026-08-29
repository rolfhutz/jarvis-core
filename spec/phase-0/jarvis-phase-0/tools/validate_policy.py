"""
JARVIS Phase 0 - Pruefung der Kontextkonfiguration gegen das Werkzeugregister.
Schliesst die technische Schuld TS-6.

Geprueft wird:
  P1  Kein risk_class_override senkt die Klasse unter das Werkzeugminimum.
  P2  Jeder Override verweist auf ein existierendes Werkzeug oder nennt einen
      Aktionstyp und traegt eine Begruendung.
  P3  max_autonomous_risk_class ist niemals C. Klasse C erfordert immer eine
      Freigabe und darf nicht autonom ausgefuehrt werden.
  P4  Jedes Werkzeug wird nur in Kontexten zugelassen, die es tatsaechlich gibt.
  P5  Der in policy.approval genannte Kanaladapter ist im Kontext konfiguriert
      und aktiv.
  P6  Kein Konfigurationswert enthaelt einen Klartext statt eines env-Verweises.

Aufruf:  python3 tools/validate_policy.py
Rueckgabe: Exit-Code 0, wenn die Konfiguration zulaessig ist.
"""

import copy
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = ROOT / "templates" / "context_config.example.json"
REGISTRY = ROOT / "registry" / "tool_registry.json"

RISK_ORDER = {"A": 0, "B": 1, "C": 2}


def load(config_path=CONFIG):
    cfg = json.loads(pathlib.Path(config_path).read_text(encoding="utf-8"))
    reg = json.loads(REGISTRY.read_text(encoding="utf-8"))
    return cfg, {t["tool_id"]: t for t in reg["tools"]}


def check(cfg, tools):
    """Gibt eine Liste von Beanstandungen zurueck. Leere Liste bedeutet zulaessig."""
    findings = []
    known_contexts = {c["context_id"] for c in cfg["contexts"]}

    for ctx in cfg["contexts"]:
        cid = ctx["context_id"]
        policy = ctx["policy"]

        # P1 und P2
        for ov in policy.get("risk_class_overrides", []):
            if not ov.get("reason"):
                findings.append(f"P2 {cid}: Override ohne Begruendung")
            tool_id = ov.get("tool_id")
            if tool_id:
                tool = tools.get(tool_id)
                if tool is None:
                    findings.append(f"P2 {cid}: Override verweist auf unbekanntes Werkzeug {tool_id}")
                elif RISK_ORDER[ov["min_risk_class"]] < RISK_ORDER[tool["risk_class_default"]]:
                    findings.append(
                        f"P1 {cid}: Override senkt {tool_id} von "
                        f"{tool['risk_class_default']} auf {ov['min_risk_class']}"
                    )
            elif not ov.get("action_type"):
                findings.append(f"P2 {cid}: Override nennt weder Werkzeug noch Aktionstyp")

        # P3
        if policy.get("max_autonomous_risk_class") == "C":
            findings.append(f"P3 {cid}: Klasse C darf nicht autonom ausgefuehrt werden")

        # P5
        channel = policy["approval"]["channel_adapter"]
        adapters = ctx.get("adapters", {})
        bound = [a for a in adapters.values() if a.get("adapter_id") == channel]
        if not bound:
            findings.append(f"P5 {cid}: Freigabekanal {channel} ist im Kontext nicht konfiguriert")
        elif not any(a.get("enabled", True) for a in bound):
            findings.append(f"P5 {cid}: Freigabekanal {channel} ist deaktiviert")

        # P6
        for name, adapter in adapters.items():
            ref = adapter.get("config_ref")
            if ref is not None and not ref.startswith("env:"):
                findings.append(f"P6 {cid}: config_ref bei {name} ist kein env-Verweis")
        rec = policy["approval"]["recipient_ref"]
        if not rec.startswith("env:"):
            findings.append(f"P6 {cid}: recipient_ref ist kein env-Verweis")

    # P4
    for tool_id, tool in tools.items():
        unknown = set(tool["allowed_contexts"]) - known_contexts
        if unknown:
            findings.append(f"P4 {tool_id}: unbekannte Kontexte {sorted(unknown)}")

    return findings


def self_test():
    """Gegenprobe: eine absichtlich fehlerhafte Konfiguration muss beanstandet werden."""
    cfg, tools = load()
    cases = []

    bad = copy.deepcopy(cfg)
    bad["contexts"][1]["policy"]["risk_class_overrides"].append(
        {"tool_id": "mail_default.send_message", "min_risk_class": "A", "reason": "Beschleunigung"})
    cases.append(("Herabstufung eines Klasse-C-Werkzeugs", bad, "P1"))

    bad = copy.deepcopy(cfg)
    bad["contexts"][0]["policy"]["max_autonomous_risk_class"] = "C"
    cases.append(("Klasse C als autonom erlaubt", bad, "P3"))

    bad = copy.deepcopy(cfg)
    bad["contexts"][0]["policy"]["approval"]["recipient_ref"] = "rolf@example.com"
    cases.append(("Klartextadresse in der Konfiguration", bad, "P6"))

    bad = copy.deepcopy(cfg)
    bad["contexts"][0]["policy"]["approval"]["channel_adapter"] = "approval_teams"
    cases.append(("Freigabekanal nicht konfiguriert", bad, "P5"))

    bad = copy.deepcopy(cfg)
    bad["contexts"][1]["policy"]["risk_class_overrides"].append(
        {"tool_id": "gibt_es.nicht", "min_risk_class": "C", "reason": "Test"})
    cases.append(("Override auf unbekanntes Werkzeug", bad, "P2"))

    failures = []
    for label, config, expected in cases:
        findings = check(config, tools)
        if any(f.startswith(expected) for f in findings):
            print(f"  ok  {label:44s} wird beanstandet ({expected})")
        else:
            print(f"  FEHLER {label:41s} wird nicht beanstandet")
            failures.append(label)
    return failures


def main():
    print("JARVIS Phase 0 - Pruefung der Kontextkonfiguration (TS-6)\n")
    cfg, tools = load()

    print("Teil 1 - ausgelieferte Konfiguration")
    findings = check(cfg, tools)
    if findings:
        print(f"  FEHLER {len(findings)} Beanstandung(en)")
        for f in findings:
            print("   -", f)
    else:
        print(f"  ok  {len(cfg['contexts'])} Kontexte, {len(tools)} Werkzeuge, keine Beanstandung")

    print("\nTeil 2 - Gegenprobe mit absichtlich fehlerhaften Konfigurationen")
    self_failures = self_test()

    print()
    if findings or self_failures:
        print("FEHLGESCHLAGEN")
        return 1
    print("ERGEBNIS: alle Pruefungen bestanden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
