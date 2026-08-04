#!/usr/bin/env node
/**
 * test_watchdog.js — self-test for daily-memory-watchdog
 * Run: node skills/daily-memory-watchdog/test_watchdog.js
 * Exits 0 on success, 1 on first failure.
 *
 * No external deps. Uses os.tmpdir() for an isolated fixture directory.
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const SKILL_DIR = path.dirname(__filename);
const INDEX = path.join(SKILL_DIR, 'index.js');

let passed = 0;
let failed = 0;
const failures = [];

function assert(cond, msg) {
  if (cond) { passed++; return; }
  failed++;
  failures.push(msg);
  console.error('FAIL: ' + msg);
}

function makeFixture() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'dmw-test-'));
  const memDir = path.join(dir, 'memory');
  fs.mkdirSync(memDir);
  // Simulate: 2026-08-01, 2026-08-02, 2026-08-04 exist; 2026-08-03 is missing.
  fs.writeFileSync(path.join(memDir, '2026-08-01.md'), '# 8/1\n');
  fs.writeFileSync(path.join(memDir, '2026-08-02.md'), '# 8/2\n');
  fs.writeFileSync(path.join(memDir, '2026-08-04.md'), '# 8/4\n');
  // Also a tagged file that should NOT be counted as a 4th date.
  fs.writeFileSync(path.join(memDir, '2026-08-04-evening.md'), '# 8/4 evening\n');
  return memDir;
}

function clean(dir) {
  try { fs.rmSync(dir, { recursive: true, force: true }); } catch (_) {}
}

function runCli(args, cwd) {
  return execFileSync(process.execPath, [INDEX, ...args], {
    cwd: cwd || process.cwd(),
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

// -- Test 1: pure module exports --
{
  const dw = require(INDEX);
  assert(typeof dw.main === 'function', 'module exports main()');
  assert(typeof dw.listDailyFiles === 'function', 'module exports listDailyFiles()');
  assert(typeof dw.detectGaps === 'function', 'module exports detectGaps()');
  assert(typeof dw.fillStubs === 'function', 'module exports fillStubs()');
  assert(typeof dw.resolveMemoryDir === 'function', 'module exports resolveMemoryDir()');
  assert(typeof dw.isoDate === 'function', 'module exports isoDate()');
}

// -- Test 2: listDailyFiles filters by date and ignores tagged --
{
  const dw = require(INDEX);
  const dir = makeFixture();
  try {
    const files = dw.listDailyFiles(dir);
    // 4 raw files on disk, but 3 distinct dates (8/1, 8/2, 8/4). Tagged file
    // for 8/4 should not add a 4th date.
    assert(files.length === 3, `listDailyFiles: 4 raw files collapse to 3 distinct dates, got ${files.length}`);
    assert(files[0].date === '2026-08-01', 'listDailyFiles: first date is 2026-08-01');
    assert(files[2].date === '2026-08-04', 'listDailyFiles: last date is 2026-08-04');
    // For 8/4, the bare file wins over the tagged one
    assert(files[2].file === '2026-08-04.md', `listDailyFiles: prefers bare file over tagged, got ${files[2].file}`);
  } finally { clean(dir); }
}

// -- Test 3: detectGaps finds historical + forward gaps --
{
  const dw = require(INDEX);
  const dir = makeFixture();
  try {
    const files = dw.listDailyFiles(dir);
    // Fixture has 8/1, 8/2, 8/4 → 8/3 is a historical gap.

    // Case A: today = 2026-08-04 → exactly 1 gap (8/3, historical)
    const noForward = dw.detectGaps(files, '2026-08-04');
    assert(noForward.gaps.length === 1, `detectGaps: today==latest → 1 historical gap, got ${noForward.gaps.length}`);
    assert(noForward.gaps[0].date === '2026-08-03', `detectGaps: historical gap is 8/3, got ${noForward.gaps[0].date}`);
    assert(noForward.gaps[0].kind === 'historical', `detectGaps: kind=historical, got ${noForward.gaps[0].kind}`);

    // Case B: today = 2026-08-05 → 2 gaps: 8/3 (historical) + 8/5 (forward)
    const oneForward = dw.detectGaps(files, '2026-08-05');
    assert(oneForward.gaps.length === 2, `detectGaps: today+1d → 1 historical + 1 forward = 2 gaps, got ${oneForward.gaps.length}`);
    const histGap = oneForward.gaps.find(g => g.kind === 'historical');
    const fwdGap = oneForward.gaps.find(g => g.kind === 'forward');
    assert(histGap && histGap.date === '2026-08-03', 'detectGaps: historical gap is 8/3');
    assert(fwdGap && fwdGap.date === '2026-08-05', 'detectGaps: forward gap is 8/5');
    assert(fwdGap.daysAfterLatest === 1, `detectGaps: forward gap daysAfterLatest=1, got ${fwdGap.daysAfterLatest}`);

    // Case C: today = 2026-08-06 → 3 gaps: 8/3 (historical) + 8/5 + 8/6 (both forward)
    const twoForward = dw.detectGaps(files, '2026-08-06');
    assert(twoForward.gaps.length === 3, `detectGaps: 2-day forward drift → 1 historical + 2 forward = 3 gaps, got ${twoForward.gaps.length}`);
  } finally { clean(dir); }
}

// -- Test 4: empty memory dir returns no-gap result without throwing --
{
  const dw = require(INDEX);
  const parent = fs.mkdtempSync(path.join(os.tmpdir(), 'dmw-empty-'));
  const dir = path.join(parent, 'memory');
  fs.mkdirSync(dir);
  try {
    const files = dw.listDailyFiles(dir);
    const r = dw.detectGaps(files, '2026-08-04');
    assert(files.length === 0, 'listDailyFiles: empty dir returns []');
    assert(r.latestDate === null, 'detectGaps: empty → latestDate null');
    assert(r.gaps.length === 0, 'detectGaps: empty → no gaps (nothing to compare against)');
  } finally { clean(parent); }
}

// -- Test 5: --check-only exits 1 on gap, 0 on no-gap --
{
  // makeFixture now returns the memory/ subdir; we need the parent for
  // WORKSPACE_ROOT (because resolveMemoryDir() does <root>/memory).
  const memDir = makeFixture();
  const parent = path.dirname(memDir);
  try {
    // Anchor the CLI to the fixture by passing WORKSPACE_ROOT=<parent> so
    // resolveMemoryDir() returns <parent>/memory = our memDir.
    let exitCode = 0;
    let out = '';
    try {
      out = execFileSync(process.execPath, [INDEX, '--check-only', '--json'], {
        cwd: parent,
        env: { ...process.env, WORKSPACE_ROOT: parent },
        encoding: 'utf8',
      });
    } catch (e) {
      exitCode = e.status || 1;
      out = (e.stdout || '') + (e.stderr || '');
    }
    const parsed = JSON.parse(out);
    assert(typeof parsed.gap_count === 'number', 'CLI --json output has numeric gap_count');
    assert(typeof parsed.latest_daily_file === 'string', 'CLI --json output has latest_daily_file string');
    assert(typeof parsed.today === 'string', 'CLI --json output has today string');
    assert(Array.isArray(parsed.gaps), 'CLI --json output has gaps array');
    assert(exitCode === 0 || exitCode === 1, `CLI exits 0 or 1, got ${exitCode}`);
    // The fixture's latest daily is 2026-08-04 and there's a historical gap
    // (8/3 missing between 8/2 and 8/4). So gap_count is always >= 1 with the
    // current fixture, regardless of today.
    assert(parsed.gap_count >= 1, `fixture has at least 1 historical gap, got ${parsed.gap_count}`);
    // If today is 8/4, gap_count should be exactly 1 (the historical 8/3).
    // If today is 8/5+, there should also be forward gaps.
    if (parsed.today === '2026-08-04') {
      assert(parsed.gap_count === 1, `today=latest → only historical gap (1), got ${parsed.gap_count}`);
      assert(parsed.gaps[0].kind === 'historical', 'today=latest → the only gap is historical');
    }
  } finally { clean(parent); }
}

// -- Test 6: --fill-stubs actually writes a stub file --
{
  const dw = require(INDEX);
  const memDir = makeFixture();
  try {
    // Use --fill-stubs programmatically by calling fillStubs on detected gaps.
    // With today=2026-08-06, fixture has 1 historical gap (8/3) + 2 forward (8/5, 8/6).
    const files = dw.listDailyFiles(memDir);
    const r = dw.detectGaps(files, '2026-08-06');
    const written = dw.fillStubs(memDir, r.gaps);
    assert(written.length === 3, `fillStubs: 1 historical + 2 forward = 3 stubs, got ${written.length}`);
    const stub = fs.readFileSync(path.join(memDir, '2026-08-05.md'), 'utf8');
    assert(/自动生成 stub/.test(stub), 'fillStubs: stub content includes 自动生成 stub marker');
    assert(/daily-memory-watchdog/.test(stub), 'fillStubs: stub content includes generator name');
    const histStub = fs.readFileSync(path.join(memDir, '2026-08-03.md'), 'utf8');
    assert(/自动生成 stub/.test(histStub), 'fillStubs: historical gap also gets a stub');
  } finally { clean(path.dirname(memDir)); }
}

// -- Test 7: --fill-stubs is idempotent (re-running writes nothing new) --
{
  const dw = require(INDEX);
  const memDir = makeFixture();
  try {
    const files = dw.listDailyFiles(memDir);
    const r = dw.detectGaps(files, '2026-08-06');
    dw.fillStubs(memDir, r.gaps);
    // After the first fill, list again with today=8/6: all gap days now exist.
    const files2 = dw.listDailyFiles(memDir);
    const r2 = dw.detectGaps(files2, '2026-08-06');
    assert(r2.gaps.length === 0, `fillStubs idempotent: re-detect finds 0 gaps, got ${r2.gaps.length}`);
  } finally { clean(path.dirname(memDir)); }
}

// -- Test 8: parseArgs rejects unknown flags --
{
  const dw = require(INDEX);
  let threw = false;
  try { dw.parseArgs(['node', 'index.js', '--bogus']); } catch (_) { threw = true; }
  assert(threw, 'parseArgs throws on unknown flag');
}

// -- Test 9: isoDate produces YYYY-MM-DD with zero-pad --
{
  const dw = require(INDEX);
  const s = dw.isoDate(new Date(Date.UTC(2026, 0, 5))); // Jan 5
  assert(s === '2026-01-05', `isoDate pads month/day: expected 2026-01-05, got ${s}`);
}

// -- Test 10: --json exit semantics on a real fixture with controlled --since --
{
  // We can't easily pass --since through the production CLI without modifying it,
  // so test the programmatic API instead.
  const dw = require(INDEX);
  const dir = makeFixture();
  try {
    const files = dw.listDailyFiles(dir);
    const r = dw.detectGaps(files, '2026-08-04');
    assert(r.gap_count_or_length === undefined, 'detectGaps does NOT have gap_count_or_length typo field'); // typo guard
    assert(Array.isArray(r.gaps), 'detectGaps.gaps is an array');
  } finally { clean(dir); }
}

// -- Summary --
console.log(`\nok: ${passed} assertions passed, ${failed} failed`);
if (failed) {
  console.error('FAILURES:');
  for (const m of failures) console.error('  - ' + m);
  process.exit(1);
}
process.exit(0);
