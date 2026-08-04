#!/usr/bin/env node
/**
 * daily-memory-watchdog — detects gaps in `memory/YYYY-MM-DD.md` and optionally
 * writes stub files for missing days so the daily memory stream never silently
 * breaks for > N days (default 1).
 *
 * Exit codes:
 *   0  no gap, or gap already stubbed
 *   1  gap detected and (a) --check-only is on, or (b) --fill-stubs wrote stubs
 *   2  bad CLI args / file IO error
 *
 * Usage:
 *   node skills/daily-memory-watchdog/index.js                       # default: check only
 *   node skills/daily-memory-watchdog/index.js --check-only          # exit 1 on any gap
 *   node skills/daily-memory-watchdog/index.js --fill-stubs          # write stubs for missing days
 *   node skills/daily-memory-watchdog/index.js --json                # machine-readable JSON output
 *   node skills/daily-memory-watchdog/index.js --since YYYY-MM-DD    # override "today"
 *
 * No external deps. Pure stdlib (fs, path).
 */
'use strict';

const fs = require('fs');
const path = require('path');

const DAY_MS = 24 * 60 * 60 * 1000;
const DAY_FILE_RE = /^(\d{4})-(\d{2})-(\d{2})(?:-[A-Za-z0-9_]+)?\.md$/;

function resolveMemoryDir() {
  if (process.env.WORKSPACE_ROOT) {
    return path.join(process.env.WORKSPACE_ROOT, 'memory');
  }
  // Walk up from this skill's location until we find a directory containing `memory/`.
  // Default to <workspace>/memory relative to cwd if nothing else matches.
  let dir = process.cwd();
  for (let i = 0; i < 6; i++) {
    const candidate = path.join(dir, 'memory');
    if (fs.existsSync(candidate) && fs.statSync(candidate).isDirectory()) return candidate;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.join(process.cwd(), 'memory');
}

function isoDate(d) {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function parseArgs(argv) {
  const opts = { checkOnly: false, fillStubs: false, json: false, since: null };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--check-only') opts.checkOnly = true;
    else if (a === '--fill-stubs') opts.fillStubs = true;
    else if (a === '--json') opts.json = true;
    else if (a === '--since') { opts.since = argv[++i]; }
    else if (a === '--help' || a === '-h') {
      console.log('Usage: node index.js [--check-only] [--fill-stubs] [--json] [--since YYYY-MM-DD]');
      process.exit(0);
    }
    else { throw new Error('unknown arg: ' + a); }
  }
  return opts;
}

function listDailyFiles(memoryDir) {
  if (!fs.existsSync(memoryDir)) return [];
  // Group by YYYY-MM-DD; the "primary" entry is the bare YYYY-MM-DD.md if
  // present, otherwise the lexically first tagged file for that date. Each
  // date appears at most once in the result.
  const byDate = new Map();
  const files = fs.readdirSync(memoryDir)
    .filter(f => DAY_FILE_RE.test(f))
    .sort(); // lexical sort makes bare "2026-08-04.md" come BEFORE "2026-08-04-evening.md"
  for (const f of files) {
    const m = f.match(DAY_FILE_RE);
    const date = `${m[1]}-${m[2]}-${m[3]}`;
    const ts = Date.UTC(+m[1], +m[2] - 1, +m[3]);
    const existing = byDate.get(date);
    // A file is "bare" iff its entire name is exactly `<date>.md` (no suffix
    // after the date). We compute this by checking that the matched group-3
    // (the day) is followed immediately by `.md` in the original filename.
    const isBare = f === `${date}.md`;
    if (!existing || (isBare && !existing.bare)) {
      byDate.set(date, { file: f, date, ts, bare: isBare });
    }
  }
  return [...byDate.values()].sort((a, b) => a.ts - b.ts);
}

function detectGaps(files, sinceIso) {
  if (!files.length) return { latestDate: null, today: sinceIso || isoDate(new Date()), gaps: [] };

  // Sort defensively (callers may pass unsorted arrays)
  const sorted = [...files].sort((a, b) => a.ts - b.ts);
  const latest = sorted[sorted.length - 1].date;
  const today = sinceIso || isoDate(new Date());
  const latestTs = sorted[sorted.length - 1].ts;
  const todayTs = Date.UTC(+today.slice(0, 4), +today.slice(5, 7) - 1, +today.slice(8, 10));

  const gaps = [];

  // 1. HISTORICAL gaps: between two consecutive daily files, if the diff > 1 day.
  //    These are the "断档" pattern (e.g. 2026-06-14 → 2026-08-04 is a 51-day
  //    historical gap that this skill's existence is designed to surface).
  for (let i = 1; i < sorted.length; i++) {
    const prev = sorted[i - 1];
    const curr = sorted[i];
    const diffDays = Math.round((curr.ts - prev.ts) / DAY_MS);
    if (diffDays > 1) {
      // For each missing day between prev and curr (exclusive of both ends).
      for (let ts = prev.ts + DAY_MS; ts < curr.ts; ts += DAY_MS) {
        const d = isoDate(new Date(ts));
        gaps.push({ date: d, daysAfterLatest: 0, kind: 'historical' });
      }
    }
  }

  // 2. FORWARD gaps: from the day after `latest` up to and including `today`.
  //    These are days that haven't been written yet but should have been.
  for (let ts = latestTs + DAY_MS; ts <= todayTs; ts += DAY_MS) {
    const d = isoDate(new Date(ts));
    gaps.push({ date: d, daysAfterLatest: Math.round((ts - latestTs) / DAY_MS), kind: 'forward' });
  }

  return { latestDate: latest, today, gaps };
}

function stubContent(date) {
  return [
    `# Daily Memory - ${date}`,
    '',
    `> 自动生成 stub: 本日未手动归档 daily memory。`,
    `> 生成时间: ${new Date().toISOString()}`,
    `> 生成器: skills/daily-memory-watchdog`,
    '',
    '## ⚠️ 缺失归档',
    '',
    '- 本日没有用户/agent 触发的 daily memory 写入',
    '- 由 daily-memory-watchdog 写入占位文件以维持 daily stream 连续性',
    '- 真实内容应以 `memory/<真实日期>.md` 形式补齐或合并到相邻日期',
    '',
  ].join('\n');
}

function fillStubs(memoryDir, gaps) {
  const written = [];
  for (const g of gaps) {
    const file = path.join(memoryDir, `${g.date}.md`);
    if (fs.existsSync(file)) continue;
    fs.writeFileSync(file, stubContent(g.date), 'utf8');
    written.push(file);
  }
  return written;
}

function main() {
  let opts;
  try { opts = parseArgs(process.argv); }
  catch (e) { console.error('daily-memory-watchdog: ' + e.message); return 2; }

  const memoryDir = resolveMemoryDir();
  const files = listDailyFiles(memoryDir);
  const { latestDate, today, gaps } = detectGaps(files, opts.since);

  const result = {
    memory_dir: memoryDir,
    daily_files_found: files.length,
    latest_daily_file: latestDate,
    today,
    gap_count: gaps.length,
    gaps,
    stubs_written: [],
  };

  if (opts.fillStubs && gaps.length) {
    try { result.stubs_written = fillStubs(memoryDir, gaps); }
    catch (e) { console.error('daily-memory-watchdog: write failed: ' + e.message); return 2; }
  }

  if (opts.json) {
    process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  } else {
    const lines = [
      `memory_dir:           ${result.memory_dir}`,
      `daily_files_found:    ${result.daily_files_found}`,
      `latest_daily_file:    ${result.latest_daily_file || '(none)'}`,
      `today:                ${result.today}`,
      `gap_count:            ${result.gap_count}`,
    ];
    if (result.gaps.length) {
      lines.push('gaps:');
      for (const g of result.gaps) {
        lines.push(`  - ${g.date}  (+${g.daysAfterLatest}d after latest)`);
      }
    } else {
      lines.push('gaps:                 (none)');
    }
    if (result.stubs_written.length) {
      lines.push(`stubs_written:        ${result.stubs_written.length}`);
      for (const f of result.stubs_written) lines.push(`  - ${f}`);
    }
    console.log(lines.join('\n'));
  }

  // Exit semantics:
  //   gap found and --check-only         -> 1
  //   gap found and --fill-stubs wrote   -> 1 (so cron / supervisor can alert)
  //   no gap                             -> 0
  if (result.gap_count > 0 && (opts.checkOnly || result.stubs_written.length)) return 1;
  return 0;
}

module.exports = { main, parseArgs, listDailyFiles, detectGaps, fillStubs, resolveMemoryDir, isoDate };

// When invoked as a CLI (`node index.js ...`), run main() and propagate its
// exit code. When required as a module (e.g. from test_watchdog.js), do not
// auto-run — callers invoke main() / parseArgs() / etc. explicitly.
if (require.main === module) {
  process.exit(main());
}
