#!/bin/bash
# evolver-spawn.sh — 手动触发 Evolver 单次进化的两段式工作流 (2026-07-25 v3 重建)
#
# 来源: TOOLS.md 第 569-588 行 + 2026-07-23 首次重建 + ERR-20260725-001 教训
#
# 设计意图:
#   - 单次运行 evolver (不带 --loop),生成 GEP 提示词文件
#   - 输出 GEP_FILE=<绝对路径> 让 Agent (这里是我) 读取并 spawn subagent
#   - sessions_spawn 必须在 Gateway 主运行时才能真正调用 evolver 推理
#
# 三点防御 (织入):
#   ① run_id 数值排序 (sort -n),不用 mtime (避免 undefined 文件 mtime 乱序)
#   ② 超时码 124 不判失败 (GEP 可能已落盘,继续判定文件)
#   ③ run_id 未变化给 WARN (防 daemon 抢先生成的静默误导)
#
# 边界 (TOOLS.md 588):
#   - 手动触发的单次工具,不进 cron (持续进化由 --loop daemon + watchdog 负责)
#
# ERR-20260725-001 教训 (织入):
#   - 单次运行不会替换 daemon,只是创建新进程与之竞争 lifecycle 管理权
#   - 操作完成后必须检查并清理孤立进程
#   - 运行前 ps aux 确认只有一个 --loop daemon 进程

set -e

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
EVOLVER_DIR="$WORKSPACE_ROOT/skills/evolver"
EVOLUTION_DIR="$WORKSPACE_ROOT/memory/evolution"
LOG_DIR="$WORKSPACE_ROOT/logs"

# ============================================================
# Pre-flight: 确保 watchdog + daemon 已在跑 (本脚本是手动触发器,不是替代)
# ============================================================
WD_PID_FILE="/tmp/evolver-watchdog.pid"
DAEMON_PID_FILE="/tmp/evolver-daemon.pid"

if [ -f "$WD_PID_FILE" ] && [ -f "$DAEMON_PID_FILE" ]; then
  WD_PID=$(awk -F, '{print $1}' "$WD_PID_FILE" 2>/dev/null || echo "")
  DAEMON_PID=$(awk -F, '{print $1}' "$DAEMON_PID_FILE" 2>/dev/null || echo "")
  if [ -n "$WD_PID" ] && kill -0 "$WD_PID" 2>/dev/null; then
    echo "[evolver-spawn] watchdog PID=$WD_PID 健康 (daemon=$DAEMON_PID)"
    echo "[evolver-spawn] 本脚本不会影响 daemon 持续进化,仅生成单次 GEP 文件"
  else
    echo "[evolver-spawn] WARN: PID 文件存在但 watchdog PID=$WD_PID 不存活,可能需要重启 watchdog"
  fi
else
  echo "[evolver-spawn] NOTE: watchdog 未运行,本脚本生成的 GEP 仍有效,但持续进化暂停"
fi

# ============================================================
# Pre-flight ②: 确认没有其他手动进程在跑 (避免并存竞争 lifecycle)
# ============================================================
EXISTING_MANUAL=$(ps -eo pid,etime,args | grep "node index.js" | grep -v " --loop" | grep -v grep | grep -v gateway || true)
if [ -n "$EXISTING_MANUAL" ]; then
  echo "[evolver-spawn] WARN: 检测到其他手动 node index.js 进程:"
  echo "$EXISTING_MANUAL" | sed 's/^/    /'
  echo "[evolver-spawn] WARN: 多个手动进程会竞争 lifecycle,建议先 kill:"
  echo "$EXISTING_MANUAL" | awk '{print "    kill "$1}' | head -3
fi

# ============================================================
# 1. 记录运行前的 cycleCount (用于输出"本次生成在 cycle X 之后")
# ============================================================
if [ -f "$EVOLUTION_DIR/evolution_state.json" ]; then
  BEFORE_CYCLE=$(python3 -c "import json; print(json.load(open('$EVOLUTION_DIR/evolution_state.json'))['cycleCount'])" 2>/dev/null || echo "?")
  echo "[evolver-spawn] before-cycleCount=$BEFORE_CYCLE"
else
  BEFORE_CYCLE="?"
  echo "[evolver-spawn] NOTE: evolution_state.json 不存在,首次运行"
fi

# ============================================================
# 2. 单次运行 evolver (90s 超时,带超时码 124 不判失败)
# ============================================================
cd "$EVOLVER_DIR"
echo "[evolver-spawn] 运行: timeout 90 node index.js (cwd=$EVOLVER_DIR)"
# 注意: 不捕获 stdout 给变量 (避免大输出卡住),写文件供后续分析
LOG_FILE="$LOG_DIR/evolver-spawn-stdout.log"
mkdir -p "$LOG_DIR"

# 用 timeout 包裹,即使超时也继续 (GEP 文件可能已落盘)
timeout 90 node index.js > "$LOG_FILE" 2>&1 || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

# 超时码 124 不判失败 — GEP 可能已落盘,继续判定文件
if [ "$EXIT_CODE" -eq 124 ]; then
  echo "[evolver-spawn] WARN: timeout 90s 触发 (exit 124),但 GEP 可能已落盘,继续判定"
elif [ "$EXIT_CODE" -ne 0 ]; then
  echo "[evolver-spawn] ERROR: node index.js 退出码 $EXIT_CODE,详见 $LOG_FILE"
  echo "[evolver-spawn] 末尾 10 行日志:"
  tail -10 "$LOG_FILE" | sed 's/^/    /'
  exit "$EXIT_CODE"
fi

# ============================================================
# 3. 找到最新生成的 GEP 文件 (按 run_id 数值排序,不用 mtime)
# ============================================================
echo "[evolver-spawn] 扫描新生成的 GEP 文件..."

# 防御 ①: run_id 数值排序 (避免 undefined 文件 mtime 乱序)
# 防御 ②: 超时码不阻断
# 防御 ③: run_id 未变化给 WARN
NEW_GEP_FILES=$(find "$EVOLUTION_DIR" -maxdepth 1 -name "gep_prompt_*run_*.txt" -type f 2>/dev/null \
  | sed -E 's/.*run_([0-9]+)\.txt$/\1 &/' \
  | sort -n -r \
  | head -3 \
  | awk '{for (i=2; i<=NF; i++) printf "%s ", $i; print ""}')

if [ -z "$NEW_GEP_FILES" ]; then
  echo "[evolver-spawn] ERROR: 未找到 gep_prompt_*run_*.txt 文件"
  echo "[evolver-spawn] 可能 evolver 没有触发 GEP 生成 (需要 cycle 推进 + GEP 协议生效)"
  echo "[evolver-spawn] 详见 $LOG_FILE"
  exit 1
fi

# 防御 ③: run_id 未变化检测 (从最新文件提取 run_id,与上次记录比对)
LATEST_GEP_FILE=$(echo "$NEW_GEP_FILES" | head -1)
LATEST_RUN_ID=$(echo "$LATEST_GEP_FILE" | sed -E 's/.*run_([0-9]+)\.txt$/\1/')

CACHE_RUN_ID="/tmp/evolver-spawn-last-run-id"
if [ -f "$CACHE_RUN_ID" ]; then
  PREV_RUN_ID=$(cat "$CACHE_RUN_ID")
  if [ "$LATEST_RUN_ID" = "$PREV_RUN_ID" ]; then
    echo "[evolver-spawn] WARN: 本次 run_id=$LATEST_RUN_ID 与上次相同 ($PREV_RUN_ID)"
    echo "[evolver-spawn] 可能 watchdog daemon 抢先生成了 GEP,本次运行未触发新周期"
    echo "[evolver-spawn] 仍输出 GEP_FILE 让 Agent 决定是否使用"
  else
    echo "[evolver-spawn] run_id 变化: $PREV_RUN_ID → $LATEST_RUN_ID ✓"
  fi
fi
echo "$LATEST_RUN_ID" > "$CACHE_RUN_ID"

# ============================================================
# 4. 输出 GEP_FILE=<绝对路径> (Agent 会读取并 spawn subagent)
# ============================================================
ABS_GEP_FILE=$(realpath "$LATEST_GEP_FILE" 2>/dev/null || echo "$LATEST_GEP_FILE")
echo "[evolver-spawn] ============================================"
echo "[evolver-spawn] GEP_FILE=$ABS_GEP_FILE"
echo "[evolver-spawn] ============================================"
echo "[evolver-spawn] 下一步: Agent 读取此文件作为 task 调用 sessions_spawn"
echo "[evolver-spawn] sessions_spawn 必须在 Gateway 主运行时,本脚本不直接调用"
echo ""
echo "[evolver-spawn] 完整脚本输出日志: $LOG_FILE"
echo "[evolver-spawn] 脚本执行完成"

exit 0