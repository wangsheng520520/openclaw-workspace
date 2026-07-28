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
# fix(2026-07-29): md5 指纹法整体废弃 → pgrep 模式 + 排除 shell comm + 端口兜底。
#  daemon 自重启 (index.js spawnReplacementProcess) 用 process.execPath+__filename
#  全路径 cmdline, 21 字节指纹永远不匹配 (每 2h 固定误报 0 daemon 并无效拉起);
#  daemon 的 comm 可能是 node 或自设 title (MainThread), 故用排除式过滤;
#  修剪逻辑加 60s 轮换窗口保护, 避免误杀 suicide-respawn 的接替进程。

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
HEALTHCHECK_LOG="/tmp/evolver-healthcheck.log"
LOCK_FILE="/tmp/evolver-healthcheck.lock"

log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" | tee -a "$HEALTHCHECK_LOG" >&2 ; }

exec 9>"$LOCK_FILE" || { log "FATAL: cannot open $LOCK_FILE"; exit 2; }
flock -n 9 || { log "WARN: another healthcheck running, exiting 2"; exit 2; }

# 找 daemon 进程: cmdline 含 'index.js --loop', 排除 shell 包装进程
#  (cron agent 的 bash -c 命令行本身含此模式串; daemon comm 可能是
#   node 或进程自设 title 如 MainThread, 故用排除式而非包含式过滤)
DAEMONS=()
for pid in $(pgrep -f 'index\.js --loop' 2>/dev/null); do
    comm=$(cat "/proc/$pid/comm" 2>/dev/null || true)
    case "$comm" in
        bash|sh|dash|zsh|systemd*) continue ;;
    esac
    DAEMONS+=("$pid")
done

# 端口兜底: 进程探测为空但 19820 在监听 → 视为健康, 不误拉第二个 daemon
if [ ${#DAEMONS[@]} -eq 0 ] && ss -tln 2>/dev/null | grep -q '127.0.0.1:19820'; then
    log "OK: no process matched but 19820 LISTEN, treating as healthy (cmdline anomaly)"
    exit 0
fi

# 多 daemon → 修剪到 1 个(保留最旧), 但放过 suicide-respawn 轮换窗口:
# 接替进程刚 detached 出来时新旧并存 <60s, 此时修剪会误杀接替者 → 双亡
if [ ${#DAEMONS[@]} -gt 1 ]; then
    youngest_age=999999
    for pid in "${DAEMONS[@]}"; do
        age=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
        [ -n "$age" ] && [ "$age" -lt "$youngest_age" ] && youngest_age=$age
    done
    if [ "$youngest_age" -lt 60 ]; then
        log "INFO: ${#DAEMONS[@]} daemons but youngest only ${youngest_age}s old (rotation window), not trimming"
        exit 0
    fi
    # 保留端口持有者(真 daemon); 无端口持有者时退回保留最旧
    #  (旧版固定保留最旧 → 会误杀健康 daemon、留下卡死的僵尸前辈)
    keeper=$(ss -tlnp 2>/dev/null | grep '127.0.0.1:19820' | sed -nE 's/.*pid=([0-9]+).*/\1/p' | head -1)
    if [ -z "$keeper" ] || ! printf '%s\n' "${DAEMONS[@]}" | grep -qx "$keeper"; then
        keeper=$(printf '%s\n' "${DAEMONS[@]}" | sort -n | head -1)
    fi
    log "WARN: ${#DAEMONS[@]} daemons running, trimming to 1 (keeper=$keeper, 端口持有者优先)"
    for pid in "${DAEMONS[@]}"; do
        [ "$pid" != "$keeper" ] && kill -TERM "$pid" 2>/dev/null && log "  killed PID $pid"
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
    # 9>&-: 关闭继承的 flock fd, 否则 spawn 出的 watchdog 会替 healthcheck 持锁
    #  (2026-07-29 07:26 事故: watchdog 变 daemon 后僵留, 持锁 2.5h+ 瘫痪 cron 层)
    nohup "$SCRIPT" >/tmp/evolver-watchdog-spawn-$(date +%s).log 2>&1 9>&- &
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
