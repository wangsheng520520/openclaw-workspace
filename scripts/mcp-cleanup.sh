#!/bin/bash
# MCP Process Leak Cleanup Script v2
# 杀掉所有 MCP 相关进程（Gateway 会按需重建）
# 用法: ./mcp-cleanup.sh [--dry-run]

set +e

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

BEFORE_AVAIL=$(free -m | awk 'NR==2{print $7}')
log "=== MCP Cleanup Start === (Available: ${BEFORE_AVAIL}MB)"

# 只在可用内存低于 3GB 或有重复进程时清理
TOTAL_MCP=$(ps aux | grep -E "mcp|chrome-devtools|bazi|ziwei|markmap|playwright|context7|exa-mcp|Sequential|think-tool" | grep -v grep | grep -v "openclaw-gateway" | grep -v "evolver" | wc -l)

if [ "$TOTAL_MCP" -le 30 ] && [ "$BEFORE_AVAIL" -gt 3000 ]; then
    log "✅ OK: $TOTAL_MCP MCP processes, ${BEFORE_AVAIL}MB available — no cleanup needed"
    exit 0
fi

log "Found $TOTAL_MCP MCP processes, ${BEFORE_AVAIL}MB available — cleaning up"

KILLED=0
for pattern in "mcp-deepwiki" "mcp-server-chart" "mcp-server-memory" "mcp-server-sequential" "context7" "chrome-devtools-mcp" "mcp-instruct" "bazi-mcp" "claude-mcp-think" "markmap" "ziwei" "playwright-mcp" "exa-mcp" "amap"; do
    pids=$(ps aux | grep "$pattern" | grep -v grep | awk '{print $2}')
    count=$(echo "$pids" | grep -c . 2>/dev/null || echo 0)
    if [ "$count" -gt 1 ]; then
        kept=0
        for pid in $pids; do
            if [ $kept -lt 1 ]; then
                kept=$((kept + 1))
            else
                if $DRY_RUN; then
                    log "  [DRY-RUN] Would kill $pattern PID $pid"
                else
                    kill "$pid" 2>/dev/null && KILLED=$((KILLED + 1))
                fi
            fi
        done
        log "  $pattern: kept 1, killed $((count - 1))"
    fi
done

# 也清理 npm exec 包装进程
NPM_PIDS=$(ps aux | grep "npm exec.*mcp\|npm exec.*chrome\|npm exec.*bazi\|npm exec.*think\|npm exec.*markmap\|npm exec.*ziwei\|npm exec.*playwright\|npm exec.*context7\|npm exec.*deepwiki\|npm exec.*exa" | grep -v grep | awk '{print $2}')
NPM_COUNT=$(echo "$NPM_PIDS" | grep -c . 2>/dev/null || echo 0)
if [ "$NPM_COUNT" -gt 15 ]; then
    # 保留前 15 个（正常数量），杀掉多余的
    EXTRA=$(echo "$NPM_PIDS" | tail -n +16)
    EXTRA_COUNT=$(echo "$EXTRA" | grep -c . 2>/dev/null || echo 0)
    if [ "$EXTRA_COUNT" -gt 0 ] && ! $DRY_RUN; then
        echo "$EXTRA" | xargs kill 2>/dev/null
        KILLED=$((KILLED + EXTRA_COUNT))
        log "  npm-exec wrappers: killed $EXTRA_COUNT extras"
    fi
fi

sleep 2
AFTER_AVAIL=$(free -m | awk 'NR==2{print $7}')
FREED=$((AFTER_AVAIL - BEFORE_AVAIL))
log "Killed $KILLED processes, freed ${FREED}MB (Available: ${AFTER_AVAIL}MB)"
log "=== MCP Cleanup Complete ==="
