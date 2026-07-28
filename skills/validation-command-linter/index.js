'use strict';

/**
 * validation-command-linter
 *
 * Checks whether a proposed GEP/Hub validation command will pass the
 * evolver safety gate BEFORE it is submitted. The gate rejects commands
 * that (a) do not start with an allowed prefix (node/npm/npx),
 * (b) contain shell operators, (c) leak local environment/paths, or
 * (d) are trivial (console.log-only / no failure exit).
 *
 * Pure, dependency-free, read-only. Never executes the command.
 */

// Shell metacharacters that the Hub sandbox rejects (even inside JS strings).
const SHELL_OPERATORS = ['>', '<', '|', ';', '&', '`', '$(', '&&', '||'];

// Prefixes the safety check allows.
const ALLOWED_PREFIXES = ['node', 'npm', 'npx'];

// Patterns that indicate a local-environment leak.
const LEAK_PATTERNS = [
  /process\.env\.[A-Z_]+/,
  /\/home\/[^/\s]+/,
  /\/Users\/[^/\s]+/,
  /[A-Za-z]:\\Users\\/,
  /\bHOME\b/,
];

/**
 * Lint a single validation command string.
 * @param {string} cmd
 * @returns {{ command: string, ok: boolean, issues: string[], suggestion: string|null }}
 */
function lintCommand(cmd) {
  const issues = [];
  const command = typeof cmd === 'string' ? cmd.trim() : '';

  if (!command) {
    return {
      command: '',
      ok: false,
      issues: ['empty_command'],
      suggestion: "node -e \"require('assert').strictEqual(1+1,2)\"",
    };
  }

  const firstToken = command.split(/\s+/)[0];
  if (!ALLOWED_PREFIXES.includes(firstToken)) {
    issues.push(
      'bad_prefix: command must start with one of ' + ALLOWED_PREFIXES.join('/')
    );
  }

  for (const op of SHELL_OPERATORS) {
    if (command.includes(op)) {
      issues.push('shell_operator: contains "' + op + '" (prohibited)');
    }
  }

  for (const re of LEAK_PATTERNS) {
    if (re.test(command)) {
      issues.push('env_leak: matches ' + re.toString());
      break;
    }
  }

  // References a local script the Hub sandbox will not have.
  if (/\bnode\s+[^\s-][^\s]*\.js\b/.test(command)) {
    issues.push(
      'unsandboxable: runs a local .js file; prefer node -e "<self-contained assertion>"'
    );
  }

  // Trivial: only prints, never asserts / exits non-zero on failure.
  const hasExitOnFail =
    /process\.exit|assert|throw|strictEqual|\.exit\(/.test(command);
  const isConsoleOnly = /console\.(log|error|info)/.test(command) && !hasExitOnFail;
  if (isConsoleOnly) {
    issues.push('trivial: only logs, never exits non-zero on failure');
  }

  // Malformed / truncated: unbalanced quotes, parens, or brackets. This
  // catches the common retry-loop failure where a `node -e` command is cut
  // off mid-string (e.g. "...split('-').lengt) and gets repeatedly BLOCKED.
  if (!isBalanced(command)) {
    issues.push(
      'malformed: unbalanced quotes/parentheses/brackets (likely truncated command)'
    );
  }

  const ok = issues.length === 0;
  return {
    command,
    ok,
    issues,
    suggestion: ok ? null : "node -e \"require('assert').strictEqual(1+1,2)\"",
  };
}

/**
 * Check that quotes, parentheses, and brackets in a command are balanced.
 * Quote-aware: parens/brackets inside a quoted string are ignored, and a
 * closing quote must match its opening quote. Backslash escapes are honored.
 * @param {string} s
 * @returns {boolean}
 */
function isBalanced(s) {
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let quote = null;
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (quote) {
      if (ch === '\\') {
        i++; // skip escaped char
        continue;
      }
      if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'" || ch === '`') {
      quote = ch;
      continue;
    }
    if (ch === '(' || ch === '[' || ch === '{') {
      stack.push(ch);
    } else if (pairs[ch]) {
      if (stack.pop() !== pairs[ch]) return false;
    }
  }
  return quote === null && stack.length === 0;
}

/**
 * Lint an array (or single) of validation commands.
 * @param {string[]|string} commands
 * @returns {{ ok: boolean, total: number, passed: number, results: object[] }}
 */
function lint(commands) {
  const list = Array.isArray(commands) ? commands : [commands];
  const results = list.map(lintCommand);
  const passed = results.filter((r) => r.ok).length;
  return {
    ok: passed === results.length && results.length > 0,
    total: results.length,
    passed,
    results,
  };
}

/**
 * CLI / smoke entry. Prints a small self-check when run directly.
 */
function main() {
  const sample = lint([
    "node -e \"require('assert').strictEqual(1+1,2)\"",
    'node scripts/foo.js && echo done',
    'console.log("hi")',
  ]);
  console.log(JSON.stringify(sample, null, 2));
  return sample;
}

if (require.main === module) {
  main();
}

module.exports = { lint, lintCommand, isBalanced, main, ALLOWED_PREFIXES, SHELL_OPERATORS };
