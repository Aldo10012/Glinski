#!/usr/bin/env bash
# Runs GlinskiKit tests with coverage and enforces per-target line-coverage floors.
set -euo pipefail
cd "$(dirname "$0")/../GlinskiKit"
swift test --enable-code-coverage
python3 - "$(swift test --show-codecov-path)" <<'PY'
import json, sys
floors = {"GlinskiEngine": 100.0, "GlinskiFeature": 100.0, "BoardUI": 90.0}
files = json.load(open(sys.argv[1]))["data"][0]["files"]
failed = False
for target, floor in floors.items():
    mine = [f for f in files if f"/Sources/{target}/" in f["filename"]]
    covered = sum(f["summary"]["lines"]["covered"] for f in mine)
    total = sum(f["summary"]["lines"]["count"] for f in mine)
    pct = 100.0 * covered / total if total else 0.0
    print(f"{target}: {pct:.2f}% ({covered}/{total} lines), floor {floor}%")
    for f in mine:
        if f["summary"]["lines"]["percent"] < 100:
            print(f'    {f["filename"].split("/Sources/")[1]}: {f["summary"]["lines"]["percent"]:.1f}%')
    failed |= pct < floor
sys.exit(1 if failed else 0)
PY
