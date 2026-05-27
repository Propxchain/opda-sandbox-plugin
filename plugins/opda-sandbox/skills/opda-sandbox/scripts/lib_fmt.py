"""Formatters for opda-sandbox output. Usage: ... | python3 lib_fmt.py <mode>
modes: orgs | endpoints | provenance | claims | raw"""
import json, sys
from collections import Counter

mode = sys.argv[1] if len(sys.argv) > 1 else "raw"
d = json.load(sys.stdin)

if mode == "orgs":
    rows = d.get("content", d if isinstance(d, list) else [])
    print("count:", len(rows))
    for o in rows:
        print("- %-38s | %-9s | %s | %s" % (
            (o.get("OrganisationName") or "")[:38], o.get("Status") or "",
            (o.get("CreatedOn") or "")[:10], o.get("OrganisationId") or ""))

elif mode == "endpoints":
    servers = d if isinstance(d, list) else d.get("content", [])
    if not servers:
        print("  (no published endpoints)")
    for s in servers:
        for r in (s.get("ApiResources") or []):
            for e in (r.get("ApiDiscoveryEndpoints") or []):
                print("  %s | %s" % (r.get("ApiFamilyType") or "?", e.get("ApiEndpoint") or ""))

elif mode == "provenance":
    pm = d.get("provenanceMap", {})
    ev = Counter(v.get("evidenceType") for v in pm.values())
    src = Counter(v.get("source") for v in pm.values())
    conf = [v.get("confidence") for v in pm.values() if isinstance(v.get("confidence"), (int, float))]
    print("UPRN:", d.get("uprn"), "| schema:", d.get("schemaVersion"), "| fields:", len(pm))
    print("evidence:", dict(ev))
    print("sources:", dict(src))
    if conf:
        print("confidence: min=%.2f max=%.2f avg=%.2f" % (min(conf), max(conf), sum(conf) / len(conf)))

elif mode == "claims":
    vc = d.get("verifiedClaims") or d.get("claims") or (d if isinstance(d, list) else [])
    print("verifiedClaims:", len(vc) if isinstance(vc, list) else "n/a")
    if isinstance(vc, list) and vc:
        v = vc[0]; ver = v.get("verification", {})
        print("  trust_framework:", ver.get("trust_framework"))
        print("  evidence:", [e.get("type") for e in (ver.get("evidence") or [])])
        print("  claim fields:", list((v.get("claims") or {}).keys())[:8])

else:
    print(json.dumps(d, indent=2)[:4000])
