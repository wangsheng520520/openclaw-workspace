---
name: todo-manager
description: Scan codebase files for TODO/FIXME/HACK/XXX comments to surface hidden technical debt. Use when checking code health, preparing for refactors, or auditing project completeness.
---
# Todo Manager

Scans source files for TODO, FIXME, HACK, and XXX comments.

## Usage
- `node index.js <dir>` — scans directory, outputs JSON
- `node index.js <dir> --format markdown` — outputs Markdown report
- `node index.js <dir> --max-files 50` — limit scan scope
