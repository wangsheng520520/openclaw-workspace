'use strict';
/**
 * dependency-scanner — Node entry wrapper.
 *
 * Thin, importable interface over the safe, offline-first Python scanner in
 * scripts/dep_scan.py. Report-only: never mutates manifests, never executes
 * untrusted dependency code (pure static lockfile analysis).
 *
 * Exports:
 *   scan(projectRoot, opts)  -> Promise<{ manifests_scanned, vulnerabilities }>
 *   scanText(projectRoot, opts) -> Promise<string>   (human-readable report)
 *   main()                   -> CLI entrypoint
 */
const path = require('path');
const { spawn } = require('child_process');

const SCANNER = path.join(__dirname, 'scripts', 'dep_scan.py');
const VALID_THRESHOLDS = ['low', 'moderate', 'high', 'critical'];

function _python() {
  return process.env.PYTHON || 'python3';
}

function _runScanner(args) {
  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';
    const child = spawn(_python(), [SCANNER, ...args], {
      cwd: process.cwd(),
      env: process.env,
    });
    child.stdout.on('data', (d) => { stdout += d.toString(); });
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('error', (err) => resolve({ code: 2, stdout, stderr: String(err && err.message || err) }));
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

/**
 * Scan a project root and return parsed JSON results.
 * @param {string} projectRoot directory to scan (default: cwd)
 * @param {{threshold?: string}} opts
 * @returns {Promise<{manifests_scanned:number, vulnerabilities:Array, exitCode:number}>}
 */
async function scan(projectRoot, opts = {}) {
  const root = projectRoot || '.';
  const threshold = VALID_THRESHOLDS.includes(String(opts.threshold))
    ? String(opts.threshold)
    : 'low';
  const { code, stdout, stderr } = await _runScanner([root, '--threshold', threshold, '--json']);
  let parsed = { manifests_scanned: 0, vulnerabilities: [] };
  try {
    if (stdout.trim()) parsed = JSON.parse(stdout);
  } catch (_e) {
    parsed = { manifests_scanned: 0, vulnerabilities: [], parse_error: (stderr || 'invalid scanner output').trim() };
  }
  parsed.exitCode = code;
  return parsed;
}

/**
 * Scan and return the human-readable report text.
 */
async function scanText(projectRoot, opts = {}) {
  const root = projectRoot || '.';
  const threshold = VALID_THRESHOLDS.includes(String(opts.threshold))
    ? String(opts.threshold)
    : 'low';
  const { stdout } = await _runScanner([root, '--threshold', threshold]);
  return stdout;
}

async function main() {
  const argv = process.argv.slice(2);
  const root = argv.find((a) => !a.startsWith('-')) || '.';
  const tIdx = argv.indexOf('--threshold');
  const threshold = tIdx >= 0 ? argv[tIdx + 1] : 'low';
  const asJson = argv.includes('--json');
  if (asJson) {
    const res = await scan(root, { threshold });
    process.stdout.write(JSON.stringify(res, null, 2) + '\n');
    process.exitCode = res.exitCode === 2 ? 2 : (res.vulnerabilities.length ? 1 : 0);
  } else {
    const text = await scanText(root, { threshold });
    process.stdout.write(text);
  }
}

module.exports = { scan, scanText, main };

if (require.main === module) {
  main().catch((err) => {
    process.stderr.write('dependency-scanner error: ' + (err && err.message || err) + '\n');
    process.exitCode = 2;
  });
}
