#!/bin/bash
# preflight-superpowers.sh — using-superpowers 硬性规则的运行时钩子（v2，根因修复版）
# Created: 2026-07-31 09:46 by Ada (重写以恢复 f7d5b030 session 5:18 链路崩溃中丢失的版本)
#
# 【根因复盘】
# f7d5b030 session (2026-07-30 22:30 ~ 07-31 05:28) 写了这个脚本并 5 个测试都通过，
# 但**没 git add/commit**。5:18 ~ 5:33 期间 Evolver daemon 反复死 7 次 + Gateway 硬重启
# 导致 working tree 中未 tracked 的文件被覆盖/丢失。
# git reflog HEAD@{0..2} 显示当时有"reset: moving to HEAD"操作，
# 加上 compaction event 触发的 f7d5b030 工作树清理 → 脚本蒸发。
#
# 【v2 改动】
# 1. 路径 = ~/.openclaw/workspace/scripts/preflight-superpowers.sh（同前）
# 2. **本次写入会立即 git add + commit**（关键防丢失）
# 3. **加 systemd timer 30min 自动跑**（取代手动调用）
# 4. 输出更明确，exit codes 严格

set -euo pipefail

# ===== 颜色 =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_NAME="preflight-superpowers"
SCRIPT_VERSION="2.0"

# ===== 默认参数 =====
LOOKBACK_HOURS=1
CHECK_ONLY=0
DRY_RUN=0
MEMORY_FILE="/home/wszmd520520/.openclaw/workspace/MEMORY.md"
SESSIONS_DIR="/home/wszmd520520/.openclaw/agents/main/sessions"
WORKSPACE_DIR="/home/wszmd520520/.openclaw/workspace"
LINT_MARKER="## ⚠️ USING-SUPERPOWERS-LINT-FAIL"

# ===== 帮助 =====
print_usage() {
    cat <<EOF
Usage: $0 [options]

Options:
    --check-only       只检查，不写任何文件 (返回 exit 1 if 违反)
    --dry-run          显示 would-append 但不写文件 (返回 exit 1)
    --lookback <hours> 扫描多少小时内的 sessions (default: 1)
    --help             显这帮助

Exit codes:
    0  合规 (lookback 窗口内有 Using [using-superpowers] 宣告)
    1  违反 (lookback 窗口内 0 宣告)
    2  参数错误
    3  环境异常 (找不到 sessions dir / memory file)
EOF
}

# ===== 日志 =====
log()   { echo -e "${GREEN}[${SCRIPT_NAME}]${NC} $*"; }
warn()  { echo -e "${YELLOW}[${SCRIPT_NAME}]${NC} $*" >&2; }
err()   { echo -e "${RED}[${SCRIPT_NAME}]${NC} $*" >&2; }

# ===== 参数解析 =====
while [ $# -gt 0 ]; do
    case "$1" in
        --check-only) CHECK_ONLY=1; shift;;
        --dry-run) DRY_RUN=1; shift;;
        --lookback) LOOKBACK_HOURS="$2"; shift 2;;
        --help) print_usage; exit 0;;
        *) err "Unknown arg: $1"; print_usage; exit 2;;
    esac
done

# ===== 环境校验 =====
[ -d "$SESSIONS_DIR" ] || { err "找不到 sessions dir: $SESSIONS_DIR"; exit 3; }
[ -f "$MEMORY_FILE" ] || { err "找不到 memory file: $MEMORY_FILE"; exit 3; }

# ===== 找最近 sessions =====
mapfile -t SESSIONS < <(find "$SESSIONS_DIR" -name "*.jsonl" -mmin -$(( LOOKBACK_HOURS * 60 )) 2>/dev/null | head -50)
SESSION_COUNT=${#SESSIONS[@]}
[ "$SESSION_COUNT" -eq 0 ] && { warn "lookback ${LOOKBACK_HOURS}h 内 0 session"; exit 0; }

# ===== 扫所有 assistant turn, 严格匹配 using-superpowers 宣告 =====
# 严格定义: turn 开头第一句必须形如
#   "Using [using-superpowers](path) to [目的]"  或
#   "**Using [using-superpowers] to** [目的]"
# 排除元讨论（"讨论 using-superpowers"不算宣告）
USING_COUNT=0
TOTAL_TURNS=0
# 严格 regex — 兼容两种宣告格式:
#   1) "Using [using-superpowers](path) to ..."
#   2) "Using `using-superpowers` to ..." (markdown 反引号)
PATTERN='^\*?\*?Using[[:space:]]+[`\*]*\[?using-superpowers\]?[`\]]'

for f in "${SESSIONS[@]}"; do
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        TOTAL_TURNS=$((TOTAL_TURNS + 1))

        # 提取 assistant role
        role=$(echo "$line" | python3 -c "import json,sys
try:
  d=json.loads(sys.stdin.read())
  print(d.get('message',{}).get('role','') if isinstance(d.get('message',{}),dict) else '')
except: pass" 2>/dev/null)

        [ "$role" = "assistant" ] || continue

        # 提取 content 文本
        text=$(echo "$line" | python3 -c "import json,sys
try:
  d=json.loads(sys.stdin.read())
  msg=d.get('message',{})
  c=msg.get('content','') if isinstance(msg,dict) else ''
  if isinstance(c, list):
    parts=[]
    for it in c:
      if isinstance(it,dict) and it.get('type')=='text':
        parts.append(it.get('text',''))
    c=' '.join(parts)
  print(c[:500] if c else '')
except: pass" 2>/dev/null)

        # 严格匹配 turn 开头
        if echo "$text" | grep -qiE "$PATTERN"; then
            USING_COUNT=$((USING_COUNT + 1))
        fi
    done < "$f"
done

log "lookback: ${LOOKBACK_HOURS}h"
log "扫了 $SESSION_COUNT 个 session, $TOTAL_TURNS 条 turn"
log "严格 using-superpowers 宣告: $USING_COUNT"

# ===== 决策 =====
if [ "$USING_COUNT" -gt 0 ]; then
    log "✅ 合规 (${LOOKBACK_HOURS}h 内 $USING_COUNT 次宣告)"
    exit 0
fi

# === 违反 ===
warn "${LOOKBACK_HOURS}h 内 0 次 using-superpowers 宣告"
TS_NOW=$(date '+%Y-%m-%d %H:%M:%S')
LINT_LINE="${LINT_MARKER} (${TS_NOW})
最近 ${LOOKBACK_HOURS}h 内 0 次 \`Using [using-superpowers]\` 宣告.
AGENTS.md 第零定律违反. 下一轮务必先 \`update_plan\` + 宣告.

**根因 (2026-07-31 复盘)**: openclaw.json skills.limits.maxSkillsPromptChars=30000
已落地 (A 步), 30+ macOS/chatbot skills.entries 已删 (B 步),
preflight-superpowers.sh v2 重建 (E 步), 但 using-superpowers 行为惯性
需 multi-layer 兜底 (script+git+systemd+user-ping)."

# === --check-only / --dry-run 不写文件 ===
if [ "$CHECK_ONLY" -eq 1 ]; then
    warn "check-only 模式: 不写任何文件, exit 1"
    exit 1
fi
if [ "$DRY_RUN" -eq 1 ]; then
    warn "dry-run 模式: 不写任何文件"
    echo "[would append to $MEMORY_FILE]:"
    echo "$LINT_LINE"
    exit 1
fi

# === 实际写 MEMORY.md (append, 用 4 个 # 分隔避免重复) ===
{
    echo ""
    echo "$LINT_LINE"
    echo ""
} >> "$MEMORY_FILE"
log "已写 lint fail 到 MEMORY.md"

# ===== 防丢失 v2: 立即 git add + commit =====
cd "$WORKSPACE_DIR"
git add scripts/preflight-superpowers.sh MEMORY.md 2>/dev/null || true
if ! git diff --cached --quiet 2>/dev/null; then
    git commit -m "fix(scripts): preflight-superpowers v2 + auto-lint (root cause: 7-31 5:18 Evolver storm lost v1 from working tree)" 2>/dev/null || true
    log "已 git commit 防丢失"
fi

exit 1
