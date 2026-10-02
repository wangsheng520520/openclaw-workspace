#!/usr/bin/env bash
# Recover the OpenClaw gateway when it wedges on its own state-lifecycle lock.
#
# Symptom: every state write fails with
#   "another OpenClaw process owns state-lifecycle"
# even though no other OpenClaw process exists. The lock file stays free for
# other processes, so the leak lives inside the gateway process and can only be
# cleared by restarting it.
set -uo pipefail

LOG_DIR="${OPENCLAW_LOG_DIR:-/tmp/openclaw}"
STATE_FILE="${OPENCLAW_WATCHDOG_STATE:-$HOME/.openclaw/.state-lifecycle-watchdog.state}"
COOLDOWN_SECONDS="${OPENCLAW_WATCHDOG_COOLDOWN:-3600}"
DRY_RUN="${OPENCLAW_WATCHDOG_DRY_RUN:-0}"
MARKER="owns state-lifecycle"
READY_MARKER="gateway ready"
# A single occurrence can be a normal race (for example a CLI command that
# touches config while the gateway is running maintenance). A real wedge keeps
# failing for minutes and produces many entries, so require both a minimum
# count and a minimum span.
MIN_OCCURRENCES="${OPENCLAW_WATCHDOG_MIN_OCCURRENCES:-3}"
MIN_SPAN_SECONDS="${OPENCLAW_WATCHDOG_MIN_SPAN:-60}"
MAX_AGE_SECONDS="${OPENCLAW_WATCHDOG_MAX_AGE:-1800}"

log() {
  if command -v logger >/dev/null 2>&1; then
    logger -t openclaw-lifecycle-watchdog -- "$*"
  fi
  printf '%s %s\n' "$(date '+%F %T')" "$*"
}

# Never interfere with a restart that is already in flight.
state=$(systemctl --user is-active openclaw-gateway.service 2>/dev/null || echo unknown)
[ "$state" = "active" ] || { log "gateway is '$state'; nothing to do"; exit 0; }

logfile=$(ls -t "$LOG_DIR"/openclaw-*.log 2>/dev/null | head -n 1)
[ -n "$logfile" ] && [ -f "$logfile" ] || { exit 0; }

# A wedge only counts when it happened after the most recent successful boot.
ready_line=$(grep -nF "$READY_MARKER" "$logfile" | tail -n 1 | cut -d: -f1)
ready_line=${ready_line:-0}

# CLI processes can also hit this message when they race the gateway during a
# state operation; those lines are prefixed with "[openclaw]" and are not a
# wedge. Only count gateway-side failures.
mapfile -t hits < <(grep -nF "$MARKER" "$logfile" | grep -vF '[openclaw]' | awk -F: -v r="$ready_line" '$1 > r { print $1 }')
[ "${#hits[@]}" -ge "$MIN_OCCURRENCES" ] || exit 0

first_line=${hits[0]}
last_line=${hits[$((${#hits[@]} - 1))]}

first_ts=$(sed -n "${first_line}p" "$logfile" | grep -oE '"time":"[^"]+"' | head -n 1 | cut -d'"' -f4)
last_ts=$(sed -n "${last_line}p" "$logfile" | grep -oE '"time":"[^"]+"' | head -n 1 | cut -d'"' -f4)
first_epoch=$(date -d "$first_ts" +%s 2>/dev/null) || first_epoch=0
last_epoch=$(date -d "$last_ts" +%s 2>/dev/null) || last_epoch=0
[ "$first_epoch" -gt 0 ] && [ "$last_epoch" -gt 0 ] || exit 0

now=$(date +%s)
span=$(( last_epoch - first_epoch ))
age=$(( now - last_epoch ))

# One-off contention must not trigger a restart; a wedge keeps failing.
[ "$span" -ge "$MIN_SPAN_SECONDS" ] || exit 0
[ "$age" -le "$MAX_AGE_SECONDS" ] || exit 0

last_restart=0
if [ -f "$STATE_FILE" ]; then
  last_restart=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
fi
case "$last_restart" in ''|*[!0-9]*) last_restart=0 ;; esac

if [ $(( now - last_restart )) -lt "$COOLDOWN_SECONDS" ]; then
  log "state-lifecycle wedge active (${#hits[@]} errors over ${span}s, last ${age}s ago) but cooldown is still running (last restart $(( (now - last_restart) / 60 ))m ago)"
  exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
  log "DRY-RUN: would restart openclaw-gateway.service (${#hits[@]} state-lifecycle errors over ${span}s, last ${age}s ago, log $logfile)"
  exit 0
fi

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$now" > "$STATE_FILE"
log "state-lifecycle wedge detected (${#hits[@]} errors over ${span}s, last ${age}s ago); restarting openclaw-gateway.service"
# --no-block: the gateway needs several minutes to drain and come back, so do
# not hold this oneshot service open for the whole restart.
if ! systemctl --user restart --no-block openclaw-gateway.service; then
  log "restart command failed"
  exit 1
fi
log "restart issued; next automatic restart allowed in $(( COOLDOWN_SECONDS / 60 ))m"
