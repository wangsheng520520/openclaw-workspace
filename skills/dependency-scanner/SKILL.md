---
name: dependency-scanner
description: "Safe offline-first dependency vulnerability scanner (report-only, npm + PyPI)"
metadata:
  version: "1.0.0"
  origin: "evolver Cycle #0746 gene_dependency_vulnerability_scan"
allowed-tools: ["exec", "read"]
user-invocable: true
---

# Dependency Vulnerability Scanner

Safe, report-only dependency vulnerability scanner. Parses lockfiles/manifests
WITHOUT executing any untrusted code, then cross-references pinned versions
against a vulnerability database and prints a severity-ranked report.

**Always report-only** — never mutates manifests.

## Supported manifests

- `package.json` / `package-lock.json` (npm)
- `requirements.txt` (pip, `==` pins)
- `pyproject.toml` (basic `[project]` dependencies / poetry)

## Workflow

1. **Run scanner** against a project root:
   ```bash
   python3 skills/dependency-scanner/scripts/dep_scan.py <project_root>
   ```
2. **Filter by severity**:
   ```bash
   python3 skills/dependency-scanner/scripts/dep_scan.py <project_root> --threshold high
   ```
3. **Machine-readable output**:
   ```bash
   python3 skills/dependency-scanner/scripts/dep_scan.py <project_root> --json
   ```
4. **Self-test** (deterministic, no network):
   ```bash
   python3 skills/dependency-scanner/scripts/test_dep_scan.py
   ```

## Exit codes

- `0` — no vulnerabilities at/above threshold
- `1` — vulnerabilities found at/above threshold
- `2` — usage / parse error

## Offline DB

Built-in curated vulnerability DB at `scripts/vuln_db.json`. Extend from
OSV.dev exports for production.

## Safety

- **Never executes untrusted code** — pure static analysis of lockfiles
- **Never mutates manifests** — report-only
- **Offline-first** — no network required
