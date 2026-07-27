'use strict';

/* Self-check for permission-auditor. Exits non-zero on failure. */
const assert = require('assert');
const { audit, formatReport, normalize } = require('..');

// 1. normalize string form
let n = normalize('exec: curl https://x.com');
assert.strictEqual(n.tool, 'exec');
assert.ok(n.args.includes('curl'));

// 2. normalize object forms
assert.strictEqual(normalize({ name: 'read', input: 'f.md' }).tool, 'read');
assert.strictEqual(normalize({ tool: 'exec', command: 'ls' }).args, 'ls');

// 3. bypass detection (curl)
let r = audit([{ tool: 'exec', command: 'curl https://x.com' }]);
assert.ok(r.findings.some((f) => f.kind === 'tool_bypass'), 'curl should flag bypass');

// 4. loop detection (3x identical)
r = audit([
  { tool: 'exec', args: 'ls' },
  { tool: 'exec', args: 'ls' },
  { tool: 'exec', args: 'ls' },
]);
assert.ok(r.findings.some((f) => f.kind === 'tool_loop'), '3x identical should flag loop');

// 5. high-risk info
r = audit([{ tool: 'process', args: '' }]);
assert.ok(r.findings.some((f) => f.kind === 'high_risk_tool'), 'process is high-risk');

// 6. clean input yields no warnings
r = audit([{ tool: 'read', args: 'a' }, { tool: 'write', args: 'b' }]);
assert.strictEqual(r.summary.warn_count, 0, 'clean input has no warnings');

// 7. report is a string
assert.strictEqual(typeof formatReport(audit([])), 'string');

// 8. empty / non-array input safe
assert.strictEqual(audit(null).summary.total_calls, 0);

console.log('permission-auditor: 8/8 self-checks PASSED');
