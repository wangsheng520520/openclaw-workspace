---
name: daily-memory-watchdog
description: Detects gaps in the `memory/YYYY-MM-DD.md` daily-memory stream and optionally writes stub files for missing days. Use when daily memory files have been silently missing for > 1 day (e.g. cron payload path drift, session-lane failure, write-permission regression) or when a watchdog/alarm system needs a deterministic "is the daily stream healthy?" check. Triggers on signals like "daily memory 断档", "memory_gap_detected", "memory/<date>.md missing", "consecutive days without daily archive".
---

# daily-memory-watchdog

A read-mostly watchdog for the OpenClaw daily memory stream. The OpenClaw bootstrap
injects curated notes (MEMORY.md, TOOLS.md, AGENTS.md, etc.) but the per-day
`memory/YYYY-MM-DD.md` files are written by session/cron activity. When that
activity silently stops (cron drift, session-lane failure, write-permission
regression, lancedb/embedding timeout), the daily stream can be silent for
weeks before anyone notices.

This watchdog gives the system a deterministic, dependency-free check + a safe
self-heal (write a stub file so the stream is provably continuous).

## When to Use

- `memory/2026-XX-XX.md` is missing for more than 1 day
- Heartbeat or narrative says "daily memory 断档"
- After a cron payload path change, lancedb timeout, or session-lane rewrite
- As a cron pre-flight before `memory-daily-refine.sh`
- As a 5-minute watchdog alarm alongside `evolver-healthcheck.sh`

## What It Does

1. Scans `memory/` for `YYYY-MM-DD.md` files (treats `YYYY-MM-DD-tag.md` as
   the same date — the bare file wins, but either counts as "this date is
   covered")
2. Detects TWO kinds of gaps:
   - **Historical gaps** between two consecutive daily files where the diff
     is > 1 day (e.g. 2026-06-14 → 2026-08-04 = 51-day 断档)
   - **Forward gaps** from the day after the latest daily file up to and
     including today (catches "we forgot to write today's file" early)
3. Optionally writes a stub file for each gap so the stream is provably
   continuous (stubs are clearly marked `> 自动生成 stub`)
4. Exits 0 (no gap) / 1 (gap detected or stubs written) / 2 (IO error) for
   cron / supervisor integration

## Usage

```bash
# Default: check only, human-readable output, exit 1 if any gap
node skills/daily-memory-watchdog/index.js

# CI / cron: machine-readable
node skills/daily-memory-watchdog/index.js --json

# Self-heal: write stub files for missing days
node skills/daily-memory-watchdog/index.js --fill-stubs

# Override "today" for tests / historical runs
node skills/daily-memory-watchdog/index.js --since 2026-08-01 --check-only
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No gap (or gap already stubbed) |
| 1 | Gap detected (and --check-only or --fill-stubs actually wrote) |
| 2 | Bad CLI args / file IO error |

## Configuration

- `WORKSPACE_ROOT` env var (optional) — points at the OpenClaw workspace;
  otherwise the skill walks up from cwd to find a `memory/` subdirectory
- `--since YYYY-MM-DD` — override the "today" anchor for tests

## Limits

- Pure stdlib (no npm deps)
- No file modifications unless `--fill-stubs` is explicit
- Stubs are clearly marked `> 自动生成 stub` so they can be filtered/merged later
- Does NOT touch `MEMORY.md`, `heartbeat-state.json`, or any GEP-metadata under `.evolver/`
  (those are managed by other tools; this watchdog stays narrow to the daily stream)
