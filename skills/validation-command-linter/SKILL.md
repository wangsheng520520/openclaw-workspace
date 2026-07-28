---
name: validation-command-linter
description: Lints proposed GEP/Hub validation commands before submission to catch safety-gate rejections (bad prefix, shell operators, env leaks, trivial commands). Use when authoring a Gene's validation array or any evolver validation step so cycles are not wasted on BLOCKED commands.
---

# validation-command-linter

A read-only, dependency-free linter that predicts whether a validation
command will pass the evolver / EvoMap Hub safety gate — **before** you
submit it. This prevents wasted evolution cycles where a command is
rejected with `BLOCKED: validation command rejected by safety check`.

## Why this exists

The safety gate rejects validation commands that:

- do **not** start with an allowed prefix (`node`, `npm`, `npx`);
- contain **shell operators** (`>`, `<`, `|`, `;`, `&`, `` ` ``, `$(`, `&&`, `||`) — even inside JS string literals;
- **leak** the local environment (`process.env.*`, `/home/<user>/`, `HOME`, etc.);
- run an **unsandboxable** local `.js` file the Hub does not have;
- are **trivial** (only `console.log`, never exit non-zero on failure);
- are **malformed/truncated** (unbalanced quotes, parentheses, or brackets — the common retry-loop cause where a `node -e` command is cut off mid-string).

## Usage

```js
const { lint, lintCommand } = require('./skills/validation-command-linter');

const report = lint([
  "node -e \"require('assert').strictEqual(1+1,2)\"", // ok
  "node scripts/foo.js | tee out.log",                 // bad: unsandboxable + shell op
]);

console.log(report.ok);       // false
console.log(report.passed);   // 1
console.log(report.results);  // per-command issues + suggestion
```

### Single command

```js
lintCommand('console.log("hi")');
// { ok:false, issues:['trivial: ...'], suggestion:"node -e \"...\"" }
```

## Return shape

`lint(commands)` → `{ ok, total, passed, results[] }`
`lintCommand(cmd)` → `{ command, ok, issues[], suggestion }`

When `ok` is false, `suggestion` gives a known-safe fallback:
`node -e "require('assert').strictEqual(1+1,2)"`.

## Smoke test

```
node -e "const l=require('./skills/validation-command-linter'); if(l.lintCommand('console.log(1)').ok) process.exit(1)"
```
