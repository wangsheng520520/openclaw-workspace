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
#
# 2026-10-02 追加 check 5「cron 连续失败看门狗」：
#   起因是 SESSION-STATE 新鲜度检查这个 job 自己连续失败，而它自带的
#   「连续 3 次 error 就发飞书」兜底永远触发不了 —— 因为发消息本身要靠
#   同一条失败的 agent run。所以看门狗必须在 agent run 之外、用纯 CLI 发。
#   本检查直接读 cron 状态库的 consecutiveErrors，超阈值就调 lark-cli 发飞书。
set -u

WORKSPACE=/home/wszmd520520/.openclaw/workspace
OPENCLAW_BIN=/home/wszmd520520/.nvm/versions/node/v24.21.0/bin/openclaw
LARK_CLI=/home/wszmd520520/.nvm/versions/node/v24.21.0/bin/lark-cli
RESULT_JSON="$WORKSPACE/memory/boot-health-last.json"
LOG_FILE="$WORKSPACE/scripts/logs/boot-health.log"
ALIGN_LOG=/tmp/boot-health-alignment.log
DOCTOR_LOG=/tmp/boot-health-doctor.log
DOCTOR_WARN_BASELINE=2

# check 5 配置
STATE_DB=/home/wszmd520520/.openclaw/state/openclaw.sqlite
FEISHU_CHAT_ID=oc_e8a582e5e3d7f43455144e0e07e011ad
CRON_ERR_THRESHOLD=${CRON_ERR_THRESHOLD:-3}      # 连续失败几次算故障
CRON_ALERT_REPEAT_HOURS=${CRON_ALERT_REPEAT_HOURS:-12}  # 同一批故障最多多久提醒一次
CRON_ALERT_STATE="$WORKSPACE/memory/cron-watchdog-last-alert.json"
# 看门狗自己一报警就会 exit 1，从而把自己的 consecutiveErrors 也推上去。
# 不排除自己的话会形成自指：它把自己也列进失败清单 → 指纹每次都变 → 反复告警。
CRON_SELF_JOB_NAME=${CRON_SELF_JOB_NAME:-boot-health-check}

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

# --- check 5: cron jobs with too many consecutive errors --------------------
c5=ok; d5=""
CRON_FAILS=""
if [ -f "$STATE_DB" ]; then
  CRON_FAILS=$(python3 - "$STATE_DB" "$CRON_ERR_THRESHOLD" "$CRON_SELF_JOB_NAME" <<'PY' 2>/dev/null
import json, sqlite3, sys

db, thr, self_name = sys.argv[1], int(sys.argv[2]), sys.argv[3]
try:
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=5)
    con.execute("pragma busy_timeout=5000")
    rows = con.execute("select name, enabled, state_json from cron_jobs").fetchall()
except sqlite3.Error:
    sys.exit(0)
finally:
    try:
        con.close()
    except Exception:
        pass

bad = []
for name, enabled, state_json in rows:
    if not enabled:
        continue
    if name == self_name:
        continue
    try:
        st = json.loads(state_json or "{}")
    except ValueError:
        continue
    errs = st.get("consecutiveErrors") or 0
    if isinstance(errs, int) and errs >= thr:
        detail = " ".join(str(st.get("lastError") or "").split())[:110]
        bad.append(f"{name} (连续 {errs} 次)" + (f" — {detail}" if detail else ""))
print(" || ".join(bad))
PY
)
  if [ -n "$CRON_FAILS" ]; then
    c5=warn; d5="$CRON_FAILS"
  else
    d5="no enabled job over ${CRON_ERR_THRESHOLD} consecutive errors"
  fi
else
  c5=skip; d5="cron state db not found"
fi

# --- summarise --------------------------------------------------------------
ATTENTION=0
[ "$c1" = fail ] && ATTENTION=$((ATTENTION + 1))
[ "$c2" = fail ] && ATTENTION=$((ATTENTION + 1))
[ "$c3" = warn ] && ATTENTION=$((ATTENTION + 1))
[ "$c4" = fail ] && ATTENTION=$((ATTENTION + 1))
[ "$c5" = warn ] && ATTENTION=$((ATTENTION + 1))

TS=$(date -Iseconds)
python3 - "$RESULT_JSON" "$TS" "$c1" "$d1" "$c2" "$d2" "$c3" "$d3" "$c4" "$d4" "$c5" "$d5" "$ATTENTION" <<'PY'
import json, sys
out, ts = sys.argv[1], sys.argv[2]
names = ("heartbeat", "alignment", "doctor", "feishuWs", "cronJobs")
vals = sys.argv[3:13]
checks = {n: {"status": vals[i * 2], "detail": vals[i * 2 + 1]} for i, n in enumerate(names)}
doc = {"ts": ts, "checks": checks, "attention": int(sys.argv[13])}
with open(out, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

SUMMARY="heartbeat=$c1($d1) | alignment=$c2($d2) | doctor=$c3($d3) | feishuWs=$c4($d4) | cronJobs=$c5($d5)"
printf '%s %s\n' "$TS" "$SUMMARY" >> "$LOG_FILE"
printf '%s\n' "$SUMMARY"

# --- direct CLI watchdog alert (never goes through an agent run) ------------
if [ "$c5" = warn ]; then
  FP=$(printf '%s' "$CRON_FAILS" | sha256sum | cut -c1-16)
  NOW_EPOCH=$(date +%s)
  SHOULD_SEND=$(python3 - "$CRON_ALERT_STATE" "$FP" "$NOW_EPOCH" "$CRON_ALERT_REPEAT_HOURS" <<'PY'
import json, sys
path, fp, now, hours = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
try:
    doc = json.load(open(path, encoding="utf-8"))
except Exception:
    doc = {}
last = int(doc.get("sentAtEpoch") or 0)
same = doc.get("fingerprint") == fp
print("no" if (same and now - last < hours * 3600) else "yes")
PY
)
  if [ "$SHOULD_SEND" = yes ]; then
    ALERT_MSG="🛠️ OpenClaw cron 看门狗：有定时任务连续失败

${CRON_FAILS}

（来源：boot-health-check.sh，直接命令行告警，未经过 agent run）
时间：${TS}"
    if timeout 60 "$LARK_CLI" im +messages-send --chat-id "$FEISHU_CHAT_ID" \
         --idempotency-key "cron-watchdog-${FP}" --text "$ALERT_MSG" >/dev/null 2>&1; then
      printf '%s alert-sent fingerprint=%s\n' "$TS" "$FP" >> "$LOG_FILE"
      python3 - "$CRON_ALERT_STATE" "$FP" "$NOW_EPOCH" "$CRON_FAILS" <<'PY'
import json, sys
path, fp, now, fails = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
with open(path, "w", encoding="utf-8") as fh:
    json.dump({"fingerprint": fp, "sentAtEpoch": now, "sentAt": now, "failing": fails}, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
    else
      printf '%s alert-send-failed fingerprint=%s\n' "$TS" "$FP" >> "$LOG_FILE"
    fi
  else
    printf '%s alert-suppressed (same fingerprint within %sh)\n' "$TS" "$CRON_ALERT_REPEAT_HOURS" >> "$LOG_FILE"
  fi
fi

if [ "$ATTENTION" -gt 0 ]; then
  exit 1
fi
exit 0
