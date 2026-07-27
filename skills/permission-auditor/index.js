'use strict';

/**
 * permission-auditor
 * Report-only auditor for tool-usage patterns. Scans a list of tool-call
 * records and flags risky patterns: shell/exec bypass of registered tools,
 * repeated identical calls (loops), and use of high-risk tools.
 *
 * Pure, dependency-free, side-effect-free. Never executes anything.
 */

// Tools that can bypass safer registered tools when misused.
const BYPASS_TOOLS = ['exec', 'shell', 'bash', 'process'];

// Patterns inside exec/shell commands that a registered tool usually handles.
const BYPASS_HINTS = [
  { re: /\bcurl\b|\bwget\b/i, suggest: 'web_fetch / web_search' },
  { re: /\bgit\s+push\b/i, suggest: 'reviewed git workflow (avoid force push)' },
  { re: /\bcat\s+.+\.(md|txt|json|js|ts)\b/i, suggest: 'read tool' },
  { re: /\brm\s+-rf\b/i, suggest: 'explicit confirmed delete' },
  { re: /\becho\b.+>\s*\S+/i, suggest: 'write / edit tool' },
];

// High-risk tools worth surfacing regardless of frequency.
const HIGH_RISK = ['exec', 'shell', 'bash', 'process', 'git_force_push'];

/**
 * Normalize a single record into { tool, args }.
 * Accepts strings ("exec: curl x") or objects ({ tool, args }/{ name, command }).
 */
function normalize(record) {
  if (record == null) return { tool: '', args: '' };
  if (typeof record === 'string') {
    const idx = record.indexOf(':');
    if (idx > -1) {
      return { tool: record.slice(0, idx).trim(), args: record.slice(idx + 1).trim() };
    }
    return { tool: record.trim(), args: '' };
  }
  const tool = String(record.tool || record.name || '').trim();
  const args = String(
    record.args != null ? record.args
      : record.command != null ? record.command
      : record.input != null ? record.input
      : ''
  ).trim();
  return { tool, args };
}

/**
 * Audit an array of tool-call records.
 * @param {Array} records
 * @returns {{ summary: object, findings: Array }}
 */
function audit(records) {
  const list = Array.isArray(records) ? records.map(normalize) : [];
  const findings = [];
  const counts = Object.create(null);
  const seen = Object.create(null);

  for (let i = 0; i < list.length; i++) {
    const { tool, args } = list[i];
    if (!tool) continue;
    counts[tool] = (counts[tool] || 0) + 1;

    // High-risk tool usage.
    if (HIGH_RISK.includes(tool)) {
      findings.push({
        severity: 'info',
        kind: 'high_risk_tool',
        tool,
        detail: `high-risk tool "${tool}" used`,
      });
    }

    // Bypass hint scanning inside shell-like commands.
    if (BYPASS_TOOLS.includes(tool) && args) {
      for (const h of BYPASS_HINTS) {
        if (h.re.test(args)) {
          findings.push({
            severity: 'warn',
            kind: 'tool_bypass',
            tool,
            detail: `possible bypass; prefer ${h.suggest}`,
            evidence: args.slice(0, 120),
          });
        }
      }
    }

    // Repeated identical call detection (loop signal).
    const key = tool + '\u0000' + args;
    seen[key] = (seen[key] || 0) + 1;
  }

  for (const key of Object.keys(seen)) {
    if (seen[key] >= 3) {
      const [tool, args] = key.split('\u0000');
      findings.push({
        severity: 'warn',
        kind: 'tool_loop',
        tool,
        detail: `identical call repeated ${seen[key]}x (possible loop)`,
        evidence: (args || '').slice(0, 120),
      });
    }
  }

  const summary = {
    total_calls: list.length,
    distinct_tools: Object.keys(counts).length,
    tool_counts: counts,
    warn_count: findings.filter((f) => f.severity === 'warn').length,
    info_count: findings.filter((f) => f.severity === 'info').length,
  };

  return { summary, findings };
}

/** Format an audit result into a readable text report. */
function formatReport(result) {
  const { summary, findings } = result;
  const lines = [];
  lines.push('# Permission / Tool-Usage Audit');
  lines.push('');
  lines.push(`- Total calls: ${summary.total_calls}`);
  lines.push(`- Distinct tools: ${summary.distinct_tools}`);
  lines.push(`- Warnings: ${summary.warn_count} | Info: ${summary.info_count}`);
  lines.push('');
  if (!findings.length) {
    lines.push('No risky patterns detected.');
    return lines.join('\n');
  }
  lines.push('## Findings');
  for (const f of findings) {
    let row = `- [${f.severity.toUpperCase()}] ${f.kind} (${f.tool}): ${f.detail}`;
    if (f.evidence) row += ` — "${f.evidence}"`;
    lines.push(row);
  }
  return lines.join('\n');
}

function main() {
  // Demo/self-check entry.
  const sample = [
    { tool: 'exec', command: 'curl https://example.com' },
    { tool: 'read', args: 'SKILL.md' },
    'exec: git push --force origin main',
  ];
  const result = audit(sample);
  console.log(formatReport(result));
  return result;
}

module.exports = { audit, formatReport, normalize, main, BYPASS_TOOLS, HIGH_RISK };

if (require.main === module) main();
