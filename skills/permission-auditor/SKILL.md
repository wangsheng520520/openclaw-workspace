---
name: permission-auditor
description: Report-only auditor that reviews tool-usage patterns to flag shell/exec bypass of registered tools, repeated call loops, and high-risk tool use. Use when reviewing agent tool-call logs for security or tool_bypass signals.
---

# Permission Auditor 🛡️

Analyzes a list of tool-call records and surfaces risky patterns. It is
**report-only**: it never executes commands, never edits files, and never
performs network calls. Safe to run on any tool-call transcript.

## When to use

- A `tool_bypass` or `tool_loop` signal appears.
- Reviewing an agent session's tool-call history for security posture.
- Auditing whether shell/exec was used where a registered tool exists.

## Detected patterns

| Kind | Severity | Meaning |
|------|----------|---------|
| `tool_bypass` | warn | exec/shell command that a registered tool should handle (curl→web_fetch, cat→read, echo>file→write) |
| `tool_loop` | warn | identical call repeated 3+ times |
| `high_risk_tool` | info | use of exec/shell/bash/process/git_force_push |

## Usage

```js
const { audit, formatReport } = require('./skills/permission-auditor');

const records = [
  { tool: 'exec', command: 'curl https://x.com' },
  { tool: 'read', args: 'file.md' },
  'exec: git push --force',
];

const result = audit(records);
console.log(formatReport(result));
```

Records may be strings (`"exec: curl x"`) or objects
(`{ tool, args }` / `{ name, command }` / `{ tool, input }`).

## Output

`audit(records)` returns `{ summary, findings }`:

- `summary`: `total_calls`, `distinct_tools`, `tool_counts`, `warn_count`, `info_count`
- `findings`: array of `{ severity, kind, tool, detail, evidence? }`

`formatReport(result)` renders a readable Markdown report.

## Verify

```bash
node -e "const s=require('./skills/permission-auditor'); console.log(Object.keys(s))"
node skills/permission-auditor/scripts/test.js
```
