"""
JARVIS 1.0-A8 - Abgleich einer wiederhergestellten n8n-Instanz mit dem Repository.

Ablauf (siehe n8n/core/README.md):
  1. leere Instanz, Credential-Huellen mit den IDs aus meta.jarvis_required_credentials
  2. n8n import:workflow --separate --input=n8n/core
  3. n8n export:workflow --all --separate --output=<rueckexport>
  4. n8n export:credentials --all --output=<credentials.json>   (ohne --decrypted)
  5. python3 tests/n8n/check_restore.py --src n8n/core --out <rueckexport> --creds <credentials.json>

Geprueft: Workflow-IDs, Knotenmenge, Parameter, Verbindungen, Credential-Zuordnung
je Knoten, Kontext-Credential passend zum Knotennamen, Subworkflow-Verweise.
"""
import argparse, json, glob, sys
ap = argparse.ArgumentParser()
ap.add_argument("--src", required=True); ap.add_argument("--out", required=True); ap.add_argument("--creds", required=True)
A = ap.parse_args()
src = {}
for f in glob.glob(A.src + '/*.json'):
    d = json.load(open(f, encoding='utf-8')); src[d['name']] = d
out = {}
for f in glob.glob(A.out + '/*.json'):
    d = json.load(open(f, encoding='utf-8')); out[d['name']] = d
creds = {c['id']: c['name'] for c in json.load(open(A.creds))}
ids = {d['id'] for d in out.values()}
fehler = []; zaehler = {'workflows': 0, 'knoten': 0, 'credential_zuordnungen': 0, 'subworkflow_verweise': 0}
def strip(n):
    n = dict(n); c = n.pop('credentials', None); n.pop('id', None); n.pop('webhookId', None); return n, c
for name, s in sorted(src.items()):
    o = out.get(name); zaehler['workflows'] += 1
    if not o: fehler.append(name + ': fehlt nach Import'); continue
    if o['id'] != s['id']: fehler.append(name + ': ID weicht ab')
    so = {n['name']: n for n in s['nodes']}; oo = {n['name']: n for n in o['nodes']}
    if set(so) != set(oo): fehler.append(name + ': Knotenmenge weicht ab')
    for k in so:
        zaehler['knoten'] += 1
        a, ca = strip(so[k]); b, cb = strip(oo.get(k, {}))
        if json.dumps(a, sort_keys=True) != json.dumps(b, sort_keys=True):
            fehler.append(name + '/' + k + ': Parameter weichen ab')
        for t, ref in (ca or {}).items():
            zaehler['credential_zuordnungen'] += 1
            got = (cb or {}).get(t) or {}
            if got.get('id') != ref['id'] or creds.get(got.get('id')) != ref['name']:
                fehler.append(name + '/' + k + ': Credential ' + ref['name'] + ' falsch zugeordnet: ' + str(got))
    if json.dumps(s['connections'], sort_keys=True) != json.dumps(o['connections'], sort_keys=True):
        fehler.append(name + ': Verbindungen weichen ab')
    for n in o['nodes']:
        if n['type'] == 'n8n-nodes-base.executeWorkflow':
            zaehler['subworkflow_verweise'] += 1
            if n['parameters']['workflowId']['value'] not in ids:
                fehler.append(name + '/' + n['name'] + ': Subworkflow fehlt')
    for n in o['nodes']:
        for t, ref in (n.get('credentials') or {}).items():
            schema_ok = ('visolva' in n['name']) == (ref.get('name') == 'jv_visolva_postgres') if n['type'] == 'n8n-nodes-base.postgres' and ('visolva' in n['name'] or 'privat' in n['name']) else True
            if not schema_ok: fehler.append(name + '/' + n['name'] + ': Knotenname und Kontext-Credential passen nicht zusammen')
print(json.dumps(zaehler))
print('ERGEBNIS:', 'BESTANDEN' if not fehler else 'NICHT BESTANDEN')
for x in fehler: print(' -', x)
sys.exit(0 if not fehler else 1)
