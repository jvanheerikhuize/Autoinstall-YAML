#!/usr/bin/env bash
# Validate feature specs locally the same way .github/workflows/validate-specs.yml does,
# using only python3 + PyYAML + jsonschema (all present on the reference machine).
# Usage: scripts/validate-specs.sh [spec.yaml ...]   (default: all specs/features/FEAT-*.yaml)
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$#" -gt 0 ]; then specs=("$@"); else mapfile -t specs < <(ls specs/features/FEAT-*.yaml); fi
python3 -I - "${specs[@]}" <<'PY'
import json, sys, yaml, jsonschema
schema = json.load(open("specs/schemas/feature-spec.schema.json"))
validator = jsonschema.Draft7Validator(schema)
failed = 0
for path in sys.argv[1:]:
    data = yaml.safe_load(open(path))
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    if errors:
        failed += 1
        print(f"FAIL {path}")
        for e in errors:
            print(f"  {'/'.join(map(str, e.path)) or '<root>'}: {e.message}")
    else:
        md = data["metadata"]
        print(f"ok   {path}  [{md['id']} {md['status']}, {len(data['acceptance_criteria'])} AC]")
sys.exit(1 if failed else 0)
PY
if yamllint --version >/dev/null 2>&1; then yamllint -d relaxed Autoinstall.yaml "${specs[@]}"; fi
