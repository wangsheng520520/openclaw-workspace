#!/usr/bin/env bash
# alignment-monitor.sh — 每日 4:30 自动监控 OpenClaw 完美最佳实践对账
#
# 调度：openclaw cron add session:alignment cron "30 4 * * *" Asia/Shanghai
# 退出码语义：0=完美, 1=P0 缺, 2=P1 缺, 3=P2 缺
# 报告策略：仅非0时飞书私聊 + 落盘 logs/alignment-check.log
#
# 设计原则（来自 MEMORY.md + LEARNINGS.md 反复验证）：
#   - 独立 session 不抢主会话 lane
#   - 不指定 model 字段，让 default 继承（避开 M2.7 历史教训）
#   - 4:30 错峰（避 3:00 梦境 / 4:00 KG+记忆提炼 / 4:00 dreaming promotion）
#   - timeout 防护（WSL2 网络抖动）
#
# 用法：直接执行或被 cron agentTurn 调用

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"
ALIGN_SCRIPT="$SCRIPT_DIR/alignment-check.sh"
LOG_DIR="$WORKSPACE/logs"
LOG_FILE="$LOG_DIR/alignment-check.log"
FEISHU_TARGET="${FEISHU_USER:-ou_e5f06d7a314911f40b2a0bb1a454b2ca}"
TS="$(date '+%Y-%m-%d %H:%M:%S %Z')"
TS_ISO="$(date -Iseconds 2>/dev/null || date)"

# --- 准备 ---
mkdir -p "$LOG_DIR"

if [[ ! -x "$ALIGN_SCRIPT" ]]; then
  echo "[$TS] [FATAL] alignment-check.sh not found or not executable: $ALIGN_SCRIPT" | tee -a "$LOG_FILE"
  exit 99
fi

# --- 执行对账 (带 timeout 防护) ---
RAW_OUTPUT=$(timeout 60 "$ALIGN_SCRIPT" 2>&1) || ALIGN_RC=$?
ALIGN_RC=${ALIGN_RC:-0}

# --- 落盘（无论成功失败都记） ---
{
  echo "==============================================="
  echo "Alignment Check — $TS"
  echo "==============================================="
  echo "$RAW_OUTPUT"
  echo ""
  echo "[exit_code=$ALIGN_RC]"
  echo ""
} >> "$LOG_FILE"

# --- 日志轮转（>5MB 截断保留最后 1000 行） ---
LOG_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
if [[ $LOG_SIZE -gt 5242880 ]]; then
  tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  echo "[$TS] [INFO] log rotated to last 1000 lines" >> "$LOG_FILE"
fi

# --- 退出码翻译 ---
case $ALIGN_RC in
  0) STATUS_LABEL="🟢 完美对齐" ;;
  1) STATUS_LABEL="🔴 P0 缺失" ;;
  2) STATUS_LABEL="🟡 P1 缺失" ;;
  3) STATUS_LABEL="⚠️ P2 缺失" ;;
  *) STATUS_LABEL="❓ 未知退出码 $ALIGN_RC" ;;
esac

# --- 飞书通知（仅非0时） ---
if [[ $ALIGN_RC -ne 0 ]]; then
  # 提取失败/缺失段（最多 30 行）
  RELEVANT=$(echo "$RAW_OUTPUT" | grep -E "❌|⚠️" | head -30 || echo "(无匹配行)")

  MSG="🔔 **Alignment Check 异常** — $TS

状态：**$STATUS_LABEL**
退出码：\`$ALIGN_RC\`

**关键问题：**
\`\`\`
$RELEVANT
\`\`\`

完整日志：\`$LOG_FILE\`
跑：\`./scripts/alignment-check.sh\` 看详情"

  # 用 lark-cli 发飞书（参考每周安全审计范本 announce -> feishu:USER）
  if command -v lark-cli >/dev/null 2>&1; then
    export PATH="$HOME/.nvm/versions/node/v24.14.0/bin:$PATH"
    echo "$MSG" | timeout 30 lark-cli im +messages-send \
      --chat-id "$FEISHU_TARGET" \
      --content "$MSG" 2>&1 | tail -3 >> "$LOG_FILE" || \
      echo "[$TS] [WARN] feishu send failed (non-fatal)" >> "$LOG_FILE"
  else
    echo "[$TS] [WARN] lark-cli not found, skip feishu notify" >> "$LOG_FILE"
  fi
fi

# --- 退出（保留原始退出码，供 cron 决定是否触发失败告警） ---
exit $ALIGN_RC
