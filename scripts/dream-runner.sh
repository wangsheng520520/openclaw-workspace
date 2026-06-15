#!/usr/bin/env bash
# dream-runner.sh — v6.5 workaround for the missing memory-core dreaming hook.
#
# Root cause: dist/extensions/memory-core/index.js (the only file that calls
# registerShortTermPromotionDreaming) has no importer in the gateway process,
# so the before_agent_reply hook is never registered. The managed-cron job
# "Memory Dreaming Promotion" still fires the agentTurn payload, but no
# dreaming logic ever runs. This script reproduces as much of the dreaming
# pipeline as the v6.5 CLI surface exposes:
#   * memory status --fix     → repair stale recall locks (idempotent)
#   * memory promote --apply  → write promoted candidates to MEMORY.md
#   * memory rem-harness --grounded → render grounded REM preview
#   * memory rem-backfill --stage-short-term → seed durable grounded
#     candidates into the live promotion store
#
# Anything that still depends on the gateway-side hook (writeDeepDreamingReport
# into memory/dreaming/deep/<date>.md, runDreamingSweepPhases for light/rem
# reports) remains broken until the upstream v6.5 bundle is repaired.
set -euo pipefail

WS="${OPENCLAW_WORKSPACE:-/home/wszmd520520/.openclaw/workspace}"

log() { printf '[dream-runner %s] %s\n' "$(date -Iseconds)" "$*" >&2; }

if ! command -v openclaw >/dev/null 2>&1; then
  log "openclaw not on PATH; aborting"
  exit 127
fi

cd "$WS"

# Per-step timeout so a single slow step never blocks the nightly budget.
STEP_TIMEOUT=180

log "memory status --fix (repairs stale recall locks, idempotent)"
timeout "$STEP_TIMEOUT" openclaw memory status --fix 2>&1 | sed 's/^/  status: /' | tail -10 >&2 || log "  status --fix failed (continuing)"

log "memory promote --apply --json"
if promote_json="$(timeout "$STEP_TIMEOUT" openclaw memory promote --apply --json 2>&1)"; then
  printf '%s\n' "$promote_json" > /tmp/dream-runner-promote.json
  log "  promote JSON: $(echo "$promote_json" | head -c 400)..."
else
  log "  promote failed: $promote_json"
fi

log "memory rem-harness --grounded (preview, no writes)"
timeout "$STEP_TIMEOUT" openclaw memory rem-harness --grounded --include-promoted 2>&1 \
  | sed 's/^/  rem-harness: /' | tail -25 >&2 || log "  rem-harness failed (continuing)"

log "memory rem-backfill --stage-short-term"
timeout "$STEP_TIMEOUT" openclaw memory rem-backfill --path "$WS/memory" --stage-short-term 2>&1 \
  | sed 's/^/  rem-backfill: /' | tail -20 >&2 || log "  rem-backfill failed (continuing)"

log "done"
exit 0
