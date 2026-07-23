#!/usr/bin/env python3
"""Self-test for dep_scan.py — deterministic, no network, no external deps."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCAN = HERE / "dep_scan.py"


def run(root: Path, *args: str) -> tuple[int, str]:
    p = subprocess.run(
        [sys.executable, str(SCAN), str(root), *args],
        capture_output=True, text=True,
    )
    return p.returncode, p.stdout


def main() -> int:
    failures = 0
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)

        # vulnerable npm project
        (root / "package.json").write_text(json.dumps({
            "name": "t", "dependencies": {"lodash": "4.17.11", "axios": "0.21.0"}
        }))
        code, out = run(root, "--json")
        data = json.loads(out)
        if code != 1:
            print(f"FAIL: expected exit 1 on vuln project, got {code}"); failures += 1
        if data["vulnerabilities"][0]["severity"] != "high":
            print("FAIL: expected high severity first (sorted)"); failures += 1
        if not any(v["package"] == "axios" for v in data["vulnerabilities"]):
            print("FAIL: axios vuln not detected"); failures += 1

        # report-only: manifest unchanged
        before = (root / "package.json").read_text()
        run(root)
        if (root / "package.json").read_text() != before:
            print("FAIL: manifest was modified (must be report-only)"); failures += 1

        # clean project
        clean = root / "clean"
        clean.mkdir()
        (clean / "package.json").write_text('{"name":"c","dependencies":{"lodash":"4.17.21"}}')
        code, _ = run(clean)
        if code != 0:
            print(f"FAIL: expected exit 0 on clean project, got {code}"); failures += 1

        # threshold filtering
        code, out = run(root, "--threshold", "high", "--json")
        data = json.loads(out)
        if any(v["severity"] == "moderate" for v in data["vulnerabilities"]):
            print("FAIL: threshold=high leaked moderate results"); failures += 1

    if failures:
        print(f"\n{failures} test(s) FAILED")
        return 1
    print("all tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
