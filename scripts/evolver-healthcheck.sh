#!/bin/bash
# evolver-healthcheck.sh — 单实例守护检查 + 自动重启
#  restored 2026-07-27 from skill_workshop proposal evolver-watchdog-recovery-20260712-036f67be78
#  (原文件 7/25 起 ENOENT；7/26 晚 solidify rollback 风暴中重建副本亦丢失)
# 行为契约(OpenClaw cron job 658e9e67 引用):
#   exit 0 = daemon 健康
#   exit 1 = 已通过 watchdog 重启并验证 19820 LISTEN
#   exit 2 = flock 锁失败 / watchdog 脚本找不到
#   exit 3 = spawn 后 8s 内 19820 未监听
# fix(2026-07-27): 参照 cmdline hash 用 printf 产生真实 NUL 字节
#  (原稿 echo -n 'node\0...' 输出字面反斜杠，md5 永远不匹配 → 误判 0 daemon)

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
HEALTHCHECK_LOG="/tmp/evolver-healthcheck.log"
LOCK_FILE="/tmp/evolver-healthcheck.lock"

log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" | tee -a "$HEALTHCHECK_LOG" >&2 ; }

exec 9>"$LOCK_FILE" || { log "FATAL: cannot open $LOCK_FILE"; exit 2; }
flock -n 9 || { log "WARN: another healthcheck running, exiting 2"; exit 2; }

# 找 daemon 进程:cmdline 必须恰好 21 字节 'node\0index.js\0--loop\0'
REF_MD5=$(printf 'node\0index.js\0--loop\0' | md5sum | awk '{print $1}')
DAEMONS=()
for pid in $(pgrep -f "node index.js --loop" 2>/dev/null); do
    if [ -r "/proc/$pid/cmdline" ]; then
        md5=$(md5sum "/proc/$pid/cmdline" 2>/dev/null | awk '{print $1}')
        if [ "$md5" = "$REF_MD5" ]; then
            DAEMONS+=("$pid")
        fi
    fi
done

# 多 daemon → 修剪到 1 个(保留最旧)
if [ ${#DAEMONS[@]} -gt 1 ]; then
    log "WARN: ${#DAEMONS[@]} daemons running, trimming to 1 (oldest)"
    oldest=$(printf '%s\n' "${DAEMONS[@]}" | sort -n | head -1)
    for pid in "${DAEMONS[@]}"; do
        [ "$pid" != "$oldest" ] && kill -TERM "$pid" 2>/dev/null && log "  killed PID $pid"
    done
    exit 0
fi

# 0 daemon → 走 watchdog 重启
if [ ${#DAEMONS[@]} -eq 0 ]; then
    log "ALERT: 0 evolver daemons running, invoking watchdog"
    CANDIDATES=(
        "$WORKSPACE/scripts/evolver-watchdog.sh"
    )
    # 也接受 backup 路径(用户在 07-11 弃用变色龙桥时备份了)
    for bak in "$WORKSPACE"/scripts/.bak.*/evolver-watchdog.sh; do
        [ -f "$bak" ] && CANDIDATES+=("$bak")
    done
    SCRIPT=""
    for c in "${CANDIDATES[@]}"; do
        if [ -x "$c" ]; then SCRIPT="$c"; break; fi
    done
    if [ -z "$SCRIPT" ]; then
        log "FATAL: no watchdog script found in candidates: ${CANDIDATES[*]}"
        exit 2
    fi
    log "  spawning: $SCRIPT"
    nohup "$SCRIPT" >/tmp/evolver-watchdog-spawn-$(date +%s).log 2>&1 &
    sleep 8
    if ss -tln 2>/dev/null | grep -q '127.0.0.1:19820'; then
        log "  ✅ 19820 LISTEN after spawn, exit 1"
        exit 1
    else
        log "  ❌ 19820 NOT listening after spawn, exit 3"
        exit 3
    fi
fi

# 1 daemon → 健康
log "OK: daemon PID=${DAEMONS[0]} alive, 19820 status: $(ss -tln 2>/dev/null | grep -c 19820) listener"
exit 0
