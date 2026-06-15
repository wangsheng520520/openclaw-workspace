#!/bin/bash
# Evolver 看门狗启动脚本
# 连续环路模式 + 变色龙代理智能检测
# - 变色龙 SOCKS 代理可用时：Evolver Hub 请求走代理
# - 代理不可用时：自动回落直连

set -e

cd ~/.openclaw/workspace/skills/evolver

WORKSPACE_ROOT="$HOME/.openclaw/workspace"
SCRIPTS_DIR="$WORKSPACE_ROOT/scripts"
CHAMELEON_PROXY_HOST="${CHAMELEON_PROXY_HOST:-127.0.0.1}"
CHAMELEON_PROXY_PORT="${CHAMELEON_PROXY_PORT:-1234}"
EVOLVER_PROXY_BRIDGE_HOST="${EVOLVER_PROXY_BRIDGE_HOST:-127.0.0.1}"
EVOLVER_PROXY_BRIDGE_PORT="${EVOLVER_PROXY_BRIDGE_PORT:-18080}"
EVOLVER_PROXY_BRIDGE_PID_FILE="${EVOLVER_PROXY_BRIDGE_PID_FILE:-/tmp/evolver-http-connect-to-socks5.pid}"
EVOLVER_PROXY_BRIDGE_LOG="${EVOLVER_PROXY_BRIDGE_LOG:-/tmp/evolver-http-connect-to-socks5.log}"
EVOLVER_PROXY_BRIDGE_SCRIPT="$SCRIPTS_DIR/evolver-http-connect-to-socks5.js"
EVOLVER_PROXY_PRELOAD_SCRIPT="$SCRIPTS_DIR/evolver-hubfetch-env-proxy-preload.js"

_tcp_open() {
  local host="$1"
  local port="$2"
  timeout 2 bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null
}

_bridge_alive() {
  # The bridge may already be running from a previous watchdog invocation while
  # the pid file is stale (for example after a failed restart). The listening
  # port is the source of truth; pid file is only advisory.
  _tcp_open "$EVOLVER_PROXY_BRIDGE_HOST" "$EVOLVER_PROXY_BRIDGE_PORT"
}

_start_proxy_bridge() {
  if _bridge_alive; then
    return 0
  fi
  if [ ! -f "$EVOLVER_PROXY_BRIDGE_SCRIPT" ]; then
    echo "  - 代理桥脚本缺失：$EVOLVER_PROXY_BRIDGE_SCRIPT"
    return 1
  fi
  CHAMELEON_PROXY_HOST="$CHAMELEON_PROXY_HOST" \
  CHAMELEON_PROXY_PORT="$CHAMELEON_PROXY_PORT" \
  EVOLVER_PROXY_BRIDGE_HOST="$EVOLVER_PROXY_BRIDGE_HOST" \
  EVOLVER_PROXY_BRIDGE_PORT="$EVOLVER_PROXY_BRIDGE_PORT" \
    node "$EVOLVER_PROXY_BRIDGE_SCRIPT" > "$EVOLVER_PROXY_BRIDGE_LOG" 2>&1 &
  echo $! > "$EVOLVER_PROXY_BRIDGE_PID_FILE"
  sleep 1
  _bridge_alive
}

# 加载环境变量
export $(grep -v '^#' ~/.openclaw/workspace/.env 2>/dev/null | sed 's/[[:space:]]*#.*$//' | xargs)

# Evolver 配置
export EVOLVE_STRATEGY=balanced
export EVOMAP_PROXY=1

PROXY_MODE="direct"
if _tcp_open "$CHAMELEON_PROXY_HOST" "$CHAMELEON_PROXY_PORT" && _start_proxy_bridge; then
  PROXY_MODE="chameleon"
  export HTTP_PROXY="http://$EVOLVER_PROXY_BRIDGE_HOST:$EVOLVER_PROXY_BRIDGE_PORT"
  export HTTPS_PROXY="http://$EVOLVER_PROXY_BRIDGE_HOST:$EVOLVER_PROXY_BRIDGE_PORT"
  export http_proxy="$HTTP_PROXY"
  export https_proxy="$HTTPS_PROXY"
  export NO_PROXY="localhost,127.0.0.1,::1"
  export no_proxy="$NO_PROXY"
  if [ -f "$EVOLVER_PROXY_PRELOAD_SCRIPT" ]; then
    export NODE_OPTIONS="--use-env-proxy --require=$EVOLVER_PROXY_PRELOAD_SCRIPT ${NODE_OPTIONS:-}"
  else
    export NODE_OPTIONS="--use-env-proxy ${NODE_OPTIONS:-}"
  fi
else
  unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
  # Remove this script's proxy flags when falling back to direct mode. Preserve
  # unrelated caller-provided NODE_OPTIONS as much as possible.
  export NODE_OPTIONS="${NODE_OPTIONS:-}"
  NODE_OPTIONS="${NODE_OPTIONS//--use-env-proxy/}"
  NODE_OPTIONS="${NODE_OPTIONS//--require=$EVOLVER_PROXY_PRELOAD_SCRIPT/}"
  export NODE_OPTIONS
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 启动 Evolver 看门狗..."
echo "  - 模式：EVOMAP_PROXY=1 node index.js --loop"
echo "  - 策略：$EVOLVE_STRATEGY"
echo "  - Hub 网络：$PROXY_MODE"
if [ "$PROXY_MODE" = "chameleon" ]; then
  echo "  - 变色龙：$CHAMELEON_PROXY_HOST:$CHAMELEON_PROXY_PORT"
  echo "  - HTTP 桥：$HTTP_PROXY"
  echo "  - Preload：$EVOLVER_PROXY_PRELOAD_SCRIPT"
else
  echo "  - 代理不可用，使用直连模式"
fi
echo "  - PID: $$"

# 启动连续环路模式
EVOMAP_PROXY=1 node index.js --loop
