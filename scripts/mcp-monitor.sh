#!/bin/bash
# MCP Monitor & Auto-heal Script v10
# Phase 1: 清理重复进程（kill多的，保留PPID=1的最旧实例）
# Phase 2: 等待Gateway respawn
# Phase 3: 直接用npx启动仍缺失的服务（不重启Gateway）
# 仅 Phase 3 [FAIL] 才考虑 Gateway 重启作为最终 fallback

DELAY=10
RECHECK_SLEEP=15
log() { echo "[MCP MONITOR $(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ps -ef 完整命令行中的 npm exec 包名模式
declare -A MCP_PATTERNS=(
    ["amap"]="@amap/amap-maps-mcp-server"
    ["playwright"]="@playwright/mcp@latest"
    ["chrome-devtools"]="chrome-devtools-mcp@latest"
    ["mcp-deepwiki"]="mcp-deepwiki@latest"
    ["Memory"]="@modelcontextprotocol/server-memory"
    ["sequential-thinking"]="@modelcontextprotocol/server-sequential-thinking"
    ["context7"]="@upstash/context7-mcp@latest"
    ["github"]="@modelcontextprotocol/server-github"
    ["mcp-server-chart"]="@antv/mcp-server-chart"
    ["think-tool"]="@cgize/mcp-think-tool"
    ["thinking-models"]="@thinking-models/mcp-server"
    ["markmap"]="@jinzcdev/markmap-mcp-server"
)

# exa 已排除：Smithery CLI 依赖 Gateway stdio 管道，脚本无法管理
# exa 由 Gateway 直接启动/停止，监控脚本不介入

# 扫描单个服务：返回 npm exec 进程 PID 列表
scan_one() {
    local pat="$1"
    ps -ef | grep "$pat" | grep -v grep | grep -v watchdog \
        | awk '{print $2}' | sort -n | tr '\n' ',' | sed 's/,$//'
}

log "=== MCP Monitor Start ==="

DUP_LOG=""
MISSING=""

for config_name in "${!MCP_PATTERNS[@]}"; do
    pat="${MCP_PATTERNS[$config_name]}"
    pids=$(scan_one "$pat")

    [ -z "$pids" ] && count=0 || count=$(echo "$pids" | tr ',' '\n' | awk 'END {print NR}')

    if [ "$count" -eq 0 ]; then
        log "[MISSING] $config_name"
        MISSING="${MISSING}${config_name} "
    elif [ "$count" -gt 1 ]; then
        first=$(echo "$pids" | cut -d',' -f1)
        rest=$(echo "$pids" | cut -d',' -f2- | tr ',' ' ')
        k=0
        for pid in $rest; do
            [ -z "$pid" ] && continue
            kill "$pid" 2>/dev/null && k=$((k+1))
        done
        log "[DUPLICATE] $config_name: kept $first, killed $k"
        DUP_LOG="${DUP_LOG}${config_name} "
    fi
done

if [ -n "$DUP_LOG" ]; then
    log "已清理(${DUP_LOG}%)，等待 ${DELAY}s..."
    sleep "$DELAY"
fi

for config_name in "${!MCP_PATTERNS[@]}"; do
    pat="${MCP_PATTERNS[$config_name]}"
    pids=$(scan_one "$pat")
    [ -z "$pids" ] && MISSING="${MISSING}${config_name} "
done

if [ -n "$MISSING" ]; then
    MISSING=$(echo "$MISSING" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')
    log "[MANUAL-START] 启动: ${MISSING%, }"
    for svc in $MISSING; do
        [ -z "$svc" ] && continue
        case "$svc" in
            amap)              npx -y @amap/amap-maps-mcp-server >/dev/null 2>&1 & ;;
            playwright)        npx @playwright/mcp@latest --headless >/dev/null 2>&1 & ;;
            chrome-devtools)   npx chrome-devtools-mcp@latest >/dev/null 2>&1 & ;;
            mcp-deepwiki)     npx -y mcp-deepwiki@latest >/dev/null 2>&1 & ;;
            Memory)            npx -y @modelcontextprotocol/server-memory >/dev/null 2>&1 & ;;
            sequential-thinking) npx -y @modelcontextprotocol/server-sequential-thinking >/dev/null 2>&1 & ;;
            context7)          npx -y @upstash/context7-mcp@latest >/dev/null 2>&1 & ;;
            github)            npx -y @modelcontextprotocol/server-github >/dev/null 2>&1 & ;;
            mcp-server-chart)  npx -y @antv/mcp-server-chart >/dev/null 2>&1 & ;;
            think-tool)        npx -y @cgize/mcp-think-tool >/dev/null 2>&1 & ;;
            thinking-models)   npx --no-cache @thinking-models/mcp-server >/dev/null 2>&1 & ;;
            markmap)           npx -y @jinzcdev/markmap-mcp-server >/dev/null 2>&1 & ;;
            *)                 log "[SKIP] 未知: $svc" ;;
        esac
        log "[STARTED] $svc"
    done
    log "等待 ${RECHECK_SLEEP}s..."
    sleep "$RECHECK_SLEEP"

    STILL=""
    for svc in $MISSING; do
        [ -z "$svc" ] && continue
        pat="${MCP_PATTERNS[$svc]}"
        pids=$(scan_one "$pat")
        [ -z "$pids" ] && STILL="${STILL}${svc} "
    done

    if [ -n "$STILL" ]; then
        log "[FAIL] 失败: ${STILL%, }"
    else
        log "[OK] 缺失服务已恢复"
    fi
else
    log "[OK] 所有 MCP 服务运行正常"
fi

log "=== MCP Monitor End ==="