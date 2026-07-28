#!/bin/bash
# evolver-watchdog-supervisor.sh — Evolver 常驻双保险监督进程
#
# 职责: 每 30s 检查 daemon (node index.js --loop) 存活, 真死时才通过
#       标准入口 scripts/evolver-watchdog.sh 拉起 (用户决策 2026-07-06:
#       "统一使用 watchdog 脚本启动", 不直接 exec node)。
#
# 历史教训 (2026-07-27 spawn 风暴事故):
#   旧 [WD] 监督进程无条件 spawn → 新 daemon 撞 Singleton 锁秒退 → 30s 后再
#   spawn → 无限风暴。本脚本三条防御:
#     1. spawn 前进程+端口双探测, 双失败才判定死亡
#     2. 5s 二次确认, 容忍 suicide-respawn 轮换间隙 (index.js spawnReplacementProcess)
#     3. spawn 后 60s 退避, 让 daemon 完成端口绑定
#
# 与旧版的行为差异: SIGTERM 只杀监督进程自身, 不转发给 daemon
#   (daemon 是独立生命周期, 杀监督不应连杀健康 daemon)。
#
# 启动: setsid nohup bash scripts/evolver-watchdog-supervisor.sh \
#         >> logs/evolver-watchdog-supervisor.log 2>&1 < /dev/null &
# 防重: flock /tmp/evolver-watchdog-supervisor.lock (第二个实例自动退出)

WORKSPACE="$HOME/.openclaw/workspace"
WATCHDOG="$WORKSPACE/scripts/evolver-watchdog.sh"
WD_LOG="$WORKSPACE/logs/evolver-watchdog.log"
LOCK=/tmp/evolver-watchdog-supervisor.lock
CHECK_INTERVAL=30
CONFIRM_DELAY=5
POST_SPAWN_BACKOFF=60
PORT=19820

exec 9>"$LOCK"
if ! flock -n 9; then
  echo "[WD] $(date '+%F %T') 已有监督进程持锁 ($LOCK), 本实例退出"
  exit 0
fi

log() { echo "[WD] $(date '+%F %T') $*"; }

daemon_alive() {
  pgrep -f 'index\.js --loop' >/dev/null 2>&1 && return 0
  timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$PORT" 2>/dev/null && return 0
  return 1
}

trap 'log "收到终止信号, 监督进程退出 (daemon 不受影响)"; exit 0' TERM INT

log "监督进程启动 (PID=$$, 每 ${CHECK_INTERVAL}s 巡检, 拉起入口: $(basename "$WATCHDOG"))"

while true; do
  if daemon_alive; then
    : # 健康则静默, 不刷日志
  else
    sleep "$CONFIRM_DELAY"
    if daemon_alive; then
      log "检测到瞬时空窗 (suicide-respawn 轮换间隙), 无需干预"
    else
      log "ALERT: daemon 真死 (进程+端口 $PORT 双失败), 拉起 watchdog"
      if [ -x "$WATCHDOG" ] || [ -f "$WATCHDOG" ]; then
        nohup bash "$WATCHDOG" >> "$WD_LOG" 2>&1 &
        log "watchdog 已拉起 PID=$!, 退避 ${POST_SPAWN_BACKOFF}s 等待端口绑定"
        sleep "$POST_SPAWN_BACKOFF"
        if daemon_alive; then
          log "恢复确认: daemon 已回归 ✅"
        else
          log "WARNING: 退避后仍未检测到 daemon, 下一轮继续尝试"
        fi
      else
        log "ERROR: watchdog 脚本缺失: $WATCHDOG (60s 后重试)"
        sleep 60
      fi
    fi
  fi
  # 后台 sleep + wait: 保证 trap 能立即打断等待
  # 9>&-: 后台子进程不得继承 flock fd, 否则本进程退出后
  # 孤儿 sleep 会继续持锁最多 30s, 阻塞监督进程接管 (2026-07-29 实测)
  sleep "$CHECK_INTERVAL" 9>&- &
  wait $!
done
