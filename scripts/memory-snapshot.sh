#!/usr/bin/env bash
# memory-snapshot.sh — 快照当前 OpenClaw 记忆系统状态
#
# 用途: 快速给"会话当下"的记忆系统拍快照，便于跨会话对账、人工审计
# 作者: Ada Lovelace skill 蒸馏 / 2026-06-10
# 风格: 与 evolver-watchdog.sh 一致（set -euo pipefail + timeout 防护）
#
# 退出码:
#   0 = 全部成功
#   1 = 一个或多个查询失败（不致命，错误已打印）

set -euo pipefail

# --- 路径与防护 --------------------------------------------------------
WORKSPACE="${HOME}/.openclaw/workspace"
OPENCLAW_BIN="${OPENCLAW_BIN:-openclaw}"
TIMEOUT="${OPENCLAW_TIMEOUT:-15}"

# 优雅降级函数（来自 evolver-watchdog.sh 风格）
safe_run() {
  local desc="$1"; shift
  local out
  if out="$(timeout "$TIMEOUT" "$@" 2>&1)"; then
    echo "$out"
  else
    local rc=$?
    echo "[⚠️  $desc: 失败 (exit=$rc, 可能 timeout=$TIMEOUT)]" >&2
    return 1
  fi
}

# --- 标题 --------------------------------------------------------------
echo "=================================================================="
echo "📸 Memory Snapshot — $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=================================================================="
echo

# --- 1. memory-status 顶层 --------------------------------------------
echo "▶ 1. openclaw memory status (顶层 5 行)"
echo "------------------------------------------------------------------"
# memory status 可能慢（laravel-style json 解析），用 30s 防护
MS_OUT=$(timeout 30 "$OPENCLAW_BIN" memory status 2>&1 | head -10) || MS_OUT="[⚠️  memory status 失败/超时]"
echo "$MS_OUT"
echo

# --- 2. MEMORY.md 字节数 / 行数 ---------------------------------------
MEMORY_MD="$WORKSPACE/MEMORY.md"
if [ -f "$MEMORY_MD" ]; then
  MEM_BYTES=$(wc -c < "$MEMORY_MD")
  MEM_LINES=$(wc -l < "$MEMORY_MD")
  echo "▶ 2. MEMORY.md"
  echo "------------------------------------------------------------------"
  echo "  路径:   $MEMORY_MD"
  echo "  字节:   $MEM_BYTES"
  echo "  行数:   $MEM_LINES"
  echo
else
  echo "▶ 2. MEMORY.md ❌ MISSING"
  echo
fi

# --- 3. memory/ 目录 daily 文件统计 -----------------------------------
MEM_DIR="$WORKSPACE/memory"
if [ -d "$MEM_DIR" ]; then
  DAILY_COUNT=$(find "$MEM_DIR" -maxdepth 1 -name "20[0-9][0-9]-*.md" -type f 2>/dev/null | wc -l)
  DAILY_TOTAL=$(find "$MEM_DIR" -maxdepth 1 -name "20[0-9][0-9]-*.md" -type f -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
  DAILY_TOTAL=${DAILY_TOTAL:-0}
  LATEST_DAILY=$(find "$MEM_DIR" -maxdepth 1 -name "20[0-9][0-9]-*.md" -type f -printf '%T@ %f\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
  LATEST_DAILY=${LATEST_DAILY:-"(无)"}
  echo "▶ 3. memory/ daily 文件"
  echo "------------------------------------------------------------------"
  echo "  daily 文件数:   $DAILY_COUNT"
  echo "  总行数:         $DAILY_TOTAL"
  echo "  最新:           $LATEST_DAILY"
  echo
fi

# --- 4. .dreams/ 状态 --------------------------------------------------
DREAMS_DIR="$MEM_DIR/.dreams"
if [ -d "$DREAMS_DIR" ]; then
  DREAMS_SIZE=$(du -sh "$DREAMS_DIR" 2>/dev/null | awk '{print $1}')
  DREAMS_FILES=$(find "$DREAMS_DIR" -type f 2>/dev/null | wc -l)
  echo "▶ 4. .dreams/ 状态"
  echo "------------------------------------------------------------------"
  echo "  路径:   $DREAMS_DIR"
  echo "  磁盘:   $DREAMS_SIZE"
  echo "  文件数: $DREAMS_FILES"
  echo
fi

# --- 5. LanceDB 磁盘使用 ---------------------------------------------
LANCEDB="$HOME/.openclaw/memory/lancedb"
if [ -d "$LANCEDB" ]; then
  LANCEDB_SIZE=$(du -sh "$LANCEDB" 2>/dev/null | awk '{print $1}')
  echo "▶ 5. LanceDB (memory-lancedb)"
  echo "------------------------------------------------------------------"
  echo "  路径:   $LANCEDB"
  echo "  磁盘:   $LANCEDB_SIZE"
  echo
fi

# --- 6. config get 三个关键字段 ---------------------------------------
echo "▶ 6. 关键配置（agents.defaults 子段）"
echo "------------------------------------------------------------------"
for path in \
    "agents.defaults.model.primary" \
    "agents.defaults.compaction.memoryFlush.model" \
    "agents.defaults.contextPruning.mode" \
    "agents.defaults.compaction.mode" \
    "plugins.slots.memory"; do
  val=$(safe_run "config get $path" "$OPENCLAW_BIN" config get "$path" 2>/dev/null | head -1) || val="(查询失败)"
  echo "  $path = $val"
done
echo

# --- 7. active-memory 与 contextPruning 状态 -------------------------
echo "▶ 7. active-memory / contextPruning 启用状态"
echo "------------------------------------------------------------------"
AM_VAL=$(safe_run "config get active-memory" "$OPENCLAW_BIN" config get plugins.entries.active-memory.enabled 2>/dev/null | head -1) || AM_VAL="(查询失败)"
CP_VAL=$(safe_run "config get contextPruning" "$OPENCLAW_BIN" config get agents.defaults.contextPruning.mode 2>/dev/null | head -1) || CP_VAL="(查询失败)"
echo "  active-memory.enabled = $AM_VAL"
echo "  contextPruning.mode  = $CP_VAL"
echo

# --- 8. 主对话模型与硅基流动可达性 -----------------------------------
echo "▶ 8. 主对话模型 / fallback 健康"
echo "------------------------------------------------------------------"
# 简单 fetch: 从 memory 块读 primary（避免硬编码）
safe_run "providers list" "$OPENCLAW_BIN" config get models.providers 2>/dev/null | \
  python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for p, info in d.items():
        m_count = len(info.get('models',[]))
        print(f'  {p}: {m_count} models')
except Exception as e:
    print(f'  ⚠️  解析失败: {e}')" || echo "  (无法获取 provider 列表)"
echo

echo "=================================================================="
echo "✅ Snapshot 完成（$(date '+%H:%M:%S')）"
echo "=================================================================="
