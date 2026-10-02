#!/usr/bin/env bash
# boot-health-check.sh -- deterministic replacement for the retired boot-md hook.
#
# Why this exists:
#   The boot-md hook ran BOOT.md as a full agent turn on every gateway start.
#   That turn held the main thread for ~5 minutes, and its ephemeral session
#   cleanup raced the run's own post-tool finalization, so it failed 100% of
#   the time with "Cannot mutate session while competing work is in flight".
#   This script runs the same four checks with no agent turn and no session,
#   so it can neither block nor fail the gateway startup path.
#
# Exit: 0 = healthy, 1 = at least one check needs attention.
set -u

WORKSPACE=/home/wszmd520520/.openclaw/workspace
OPENCLAW_BIN=/home/wszmd520520/.nvm/versions/node/v24.21.0/bin/openclaw
RESULT_JSON="$WORKSPACE/memory/boot-health-last.json"
LOG_FILE="$WORKSPACE/scripts/logs/boot-health.log"
ALIGN_LOG=/tmp/boot-health-alignment.log
DOCTOR_LOG=/tmp/boot-health-doctor.log
DOCTOR_WARN_BASELINE=2

mkdir -p "$(dirname "$RESULT_JSON")" "$(dirname "$LOG_FILE")"

# --- check 1: heartbeat freshness (<60 min) ---------------------------------
c1=ok; d1=""
HB_FILE="$WORKSPACE/memory/heartbeat-state.json"
if [ ! -f "$HB_FILE" ]; then
  c1=fail; d1="missing heartbeat-state.json"
else
  HB_TS=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("lastCheck",""))' "$HB_FILE" 2>/dev/null)
  HB_EPOCH=$(date -d "$HB_TS" +%s 2>/dev/null || echo 0)
  NOW_EPOCH=$(date +%s)
  if [ -z "$HB_TS" ] || [ "$HB_EPOCH" -le 0 ]; then
    c1=fail; d1="unreadable lastCheck in heartbeat-state.json"
  else
    AGE_MIN=$(( (NOW_EPOCH - HB_EPOCH) / 60 ))
    if [ "$AGE_MIN" -lt 60 ]; then
      d1="heartbeat fresh (${AGE_MIN} min ago)"
    else
      c1=fail; d1="heartbeat stale (${AGE_MIN} min)"
    fi
  fi
fi

# --- check 2: alignment-check.sh exit code ----------------------------------
c2=ok; d2=""
if [ -f "$WORKSPACE/scripts/alignment-check.sh" ]; then
  ( cd "$WORKSPACE" && timeout 180 bash scripts/alignment-check.sh ) > "$ALIGN_LOG" 2>&1
  ALIGN_EXIT=$?
  if [ "$ALIGN_EXIT" -eq 0 ]; then
    d2="alignment-check exit=0"
  else
    c2=fail; d2="alignment-check exit=$ALIGN_EXIT (see $ALIGN_LOG)"
  fi
else
  c2=skip; d2="alignment-check.sh not found"
fi

# --- check 3: openclaw doctor warning blocks (baseline <= 2) ----------------
c3=ok; d3=""
timeout 180 "$OPENCLAW_BIN" doctor > "$DOCTOR_LOG" 2>&1
WARN_BLOCKS=0
if [ -f "$DOCTOR_LOG" ]; then
  WARN_BLOCKS=$(grep -c "Doctor warnings" "$DOCTOR_LOG" 2>/dev/null || true)
  WARN_BLOCKS=${WARN_BLOCKS:-0}
fi
case "$WARN_BLOCKS" in ''|*[!0-9]*) WARN_BLOCKS=0;; esac
if [ "$WARN_BLOCKS" -le "$DOCTOR_WARN_BASELINE" ]; then
  d3="doctor warning blocks=$WARN_BLOCKS (baseline $DOCTOR_WARN_BASELINE)"
else
  c3=warn; d3="doctor warning blocks=$WARN_BLOCKS exceeds baseline $DOCTOR_WARN_BASELINE"
fi

# --- check 4: feishu websocket started within the last 24h ------------------
c4=ok; d4=""
XDG_RUNTIME_DIR="/run/user/$(id -u)"; export XDG_RUNTIME_DIR
WS_HITS=0
if command -v journalctl >/dev/null 2>&1; then
  WS_HITS=$(journalctl --user -u openclaw-gateway --since "24 hours ago" --no-pager 2>/dev/null | grep -c "WebSocket client started" || true)
  WS_HITS=${WS_HITS:-0}
fi
case "$WS_HITS" in ''|*[!0-9]*) WS_HITS=0;; esac
if [ "$WS_HITS" -gt 0 ]; then
  d4="feishu WebSocket started within 24h"
else
  c4=fail; d4="feishu WebSocket not started in 24h"
fi

# --- summarise --------------------------------------------------------------
ATTENTION=0
[ "$c1" = fail ] && ATTENTION=$((ATTENTION + 1))
[ "$c2" = fail ] && ATTENTION=$((ATTENTION + 1))
[ "$c3" = warn ] && ATTENTION=$((ATTENTION + 1))
[ "$c4" = fail ] && ATTENTION=$((ATTENTION + 1))

TS=$(date -Iseconds)
python3 - "$RESULT_JSON" "$TS" "$c1" "$d1" "$c2" "$d2" "$c3" "$d3" "$c4" "$d4" "$ATTENTION" <<'PY'
import json, sys
out, ts = sys.argv[1], sys.argv[2]
names = ("heartbeat", "alignment", "doctor", "feishuWs")
vals = sys.argv[3:11]
checks = {n: {"status": vals[i * 2], "detail": vals[i * 2 + 1]} for i, n in enumerate(names)}
doc = {"ts": ts, "checks": checks, "attention": int(sys.argv[11])}
with open(out, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

SUMMARY="heartbeat=$c1($d1) | alignment=$c2($d2) | doctor=$c3($d3) | feishuWs=$c4($d4)"
printf '%s %s\n' "$TS" "$SUMMARY" >> "$LOG_FILE"
printf '%s\n' "$SUMMARY"

if [ "$ATTENTION" -gt 0 ]; then
  exit 1
fi
exit 0
