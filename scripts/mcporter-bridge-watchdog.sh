#!/bin/bash
# MC Porter Bridge Watchdog
# 监控 mcporter serve --http 3099 进程，保持其运行

BRIDGE_PORT=3099
BRIDGE_LOG=/tmp/mcporter-bridge.log
CHECK_INTERVAL=60

check_bridge() {
    # 检查端口是否监听
    if ss -tlnp 2>/dev/null | grep -q ":${BRIDGE_PORT} "; then
        return 0  # 运行中
    fi
    return 1  # 未运行
}

start_bridge() {
    echo "[$(date)] Starting mcporter serve bridge..." >> $BRIDGE_LOG
    nohup mcporter serve --http $BRIDGE_PORT >> $BRIDGE_LOG 2>&1 &
    sleep 2
    if check_bridge; then
        echo "[$(date)] Bridge started successfully" >> $BRIDGE_LOG
        return 0
    else
        echo "[$(date)] Bridge failed to start" >> $BRIDGE_LOG
        return 1
    fi
}

# 主循环
while true; do
    if ! check_bridge; then
        echo "[$(date)] Bridge not running, restarting..." >> $BRIDGE_LOG
        start_bridge
    fi
    sleep $CHECK_INTERVAL
done
