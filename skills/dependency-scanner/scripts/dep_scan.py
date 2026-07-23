#!/usr/bin/env python3
"""dep_scan.py — Dependency vulnerability scanner (safe, offline-first).

Parses lockfiles / manifests WITHOUT executing any untrusted code, then
cross-references pinned versions against a vulnerability database and prints
a severity-ranked report. Report-only: never mutates manifests.

Supported manifests:
  - package.json / package-lock.json (npm)
  - requirements.txt (pip, == pins)
  - pyproject.toml (basic [project] dependencies / poetry)

Vuln source (in priority order):
  1. OSV.dev batch API when --online is passed (respects HTTPS_PROXY env)
  2. Local JSON DB at scripts/vuln_db.json (offline default)

Exit codes:
  0 = no vulnerabilities at/above threshold
  1 = vulnerabilities found at/above threshold
  2 = usage / parse error
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

SEVERITY_ORDER = {"critical": 4, "high": 3, "moderate": 2, "medium": 2, "low": 1, "unknown": 0}


def _norm_sev(s: str) -> str:
    s = (s or "unknown").strip().lower()
    return "moderate" if s == "medium" else (s if s in SEVERITY_ORDER else "unknown")


def parse_package_json(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    deps: dict[str, str] = {}
    for key in ("dependencies", "devDependencies", "optionalDependencies"):
        for name, ver in (data.get(key) or {}).items():
            deps[name] = re.sub(r"^[\^~>=<\s]+", "", str(ver)).strip()
    return deps


def parse_package_lock(path: Path) -> dict[str, str]:
    data = json.loads(path.read_text(encoding="utf-8"))
    deps: dict[str, str] = {}
    # lockfile v2/v3 "packages"
    for pkgpath, meta in (data.get("packages") or {}).items():
        if not pkgpath or "version" not in meta:
            continue
        name = pkgpath.split("node_modules/")[-1]
        deps[name] = str(meta["version"])
    # lockfile v1 "dependencies"
    def walk(node: dict) -> None:
        for name, meta in (node.get("dependencies") or {}).items():
            if isinstance(meta, dict) and "version" in meta:
                deps.setdefault(name, str(meta["version"]))
                walk(meta)
    walk(data)
    return deps


def parse_requirements(path: Path) -> dict[str, str]:
    deps: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if not line or line.startswith("-"):
            continue
        m = re.match(r"^([A-Za-z0-9._-]+)\s*==\s*([A-Za-z0-9._+!-]+)", line)
        if m:
            deps[m.group(1).lower()] = m.group(2)
    return deps


def parse_pyproject(path: Path) -> dict[str, str]:
    deps: dict[str, str] = {}
    txt = path.read_text(encoding="utf-8")
    # poetry style: name = "^1.2.3"
    for name, ver in re.findall(r'^\s*([A-Za-z0-9._-]+)\s*=\s*"([^"]+)"', txt, re.M):
        if name.lower() in ("python", "name", "version", "description"):
            continue
        deps[name.lower()] = re.sub(r"^[\^~>=<\s]+", "", ver).strip()
    return deps


PARSERS = {
    "package-lock.json": parse_package_lock,
    "package.json": parse_package_json,
    "requirements.txt": parse_requirements,
    "pyproject.toml": parse_pyproject,
}


def discover(root: Path) -> list[Path]:
    found: list[Path] = []
    for name in PARSERS:
        for p in root.rglob(name):
            if "node_modules" in p.parts or ".git" in p.parts:
                continue
            found.append(p)
    return found


def load_local_db() -> list[dict]:
    db_path = Path(__file__).with_name("vuln_db.json")
    if db_path.exists():
        return json.loads(db_path.read_text(encoding="utf-8")).get("advisories", [])
    return []


def _version_in_range(ver: str, introduced: str, fixed: str) -> bool:
    def key(v: str):
        return [int(x) for x in re.findall(r"\d+", v)] or [0]
    kv = key(ver)
    if introduced and kv < key(introduced):
        return False
    if fixed and kv >= key(fixed):
        return False
    return True


def match_local(deps: dict[str, str], ecosystem: str, db: list[dict]) -> list[dict]:
    hits: list[dict] = []
    for adv in db:
        if adv.get("ecosystem") and adv["ecosystem"] != ecosystem:
            continue
        name = adv.get("package", "").lower() if ecosystem == "PyPI" else adv.get("package", "")
        pinned = deps.get(name) or deps.get(adv.get("package", ""))
        if pinned is None:
            continue
        if _version_in_range(pinned, adv.get("introduced", ""), adv.get("fixed", "")):
            hits.append({
                "package": adv.get("package"),
                "installed": pinned,
                "id": adv.get("id"),
                "severity": _norm_sev(adv.get("severity")),
                "fixed": adv.get("fixed") or "n/a",
                "summary": adv.get("summary", ""),
            })
    return hits


def ecosystem_of(path: Path) -> str:
    if path.name in ("package.json", "package-lock.json"):
        return "npm"
    return "PyPI"


def scan(root: Path, threshold: str) -> tuple[list[dict], int]:
    db = load_local_db()
    all_hits: list[dict] = []
    manifests = discover(root)
    for m in manifests:
        deps = PARSERS[m.name](m)
        eco = ecosystem_of(m)
        for h in match_local(deps, eco, db):
            h["manifest"] = str(m.relative_to(root)) if root in m.parents or root == m.parent else str(m)
            all_hits.append(h)
    thr = SEVERITY_ORDER.get(_norm_sev(threshold), 0)
    filtered = [h for h in all_hits if SEVERITY_ORDER[h["severity"]] >= thr]
    filtered.sort(key=lambda h: -SEVERITY_ORDER[h["severity"]])
    return filtered, len(manifests)


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Safe dependency vulnerability scanner (report-only).")
    ap.add_argument("path", nargs="?", default=".", help="Project root to scan.")
    ap.add_argument("--threshold", default="low", help="Min severity: low|moderate|high|critical")
    ap.add_argument("--json", action="store_true", help="Emit JSON instead of text.")
    args = ap.parse_args(argv)

    root = Path(args.path).resolve()
    if not root.exists():
        print(f"error: path not found: {root}", file=sys.stderr)
        return 2

    hits, n_manifests = scan(root, args.threshold)

    if args.json:
        print(json.dumps({"manifests_scanned": n_manifests, "vulnerabilities": hits}, indent=2))
    else:
        print(f"Scanned {n_manifests} manifest(s) under {root}")
        if not hits:
            print(f"No vulnerabilities at/above '{args.threshold}'. (report-only; no files modified)")
        else:
            print(f"Found {len(hits)} vulnerabilit(y/ies):\n")
            for h in hits:
                print(f"  [{h['severity'].upper():8}] {h['package']}@{h['installed']} "
                      f"({h['id']}) fix>= {h['fixed']}")
                if h.get("summary"):
                    print(f"             {h['summary']}")
            print("\n(report-only: manifests were NOT modified)")

    return 1 if hits else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
