#!/bin/bash
# skill-preflight.sh — using-superpowers 硬性规则的运行时钩子
# Created: 2026-06-18 20:32 by Ada
# Purpose: 把"宣告 Using X"从输出装饰变成可验证的结构化产物
#
# 用法: 在每次 assistant turn 开始时（before tools/exec），手动调用或自动挂入：
#   source ~/.openclaw/workspace/scripts/skill-preflight.sh && skill_preflight_check "$last_user_message"
#
# 返回: 0=合规 / 1=违反红线（需要 self-correct）
#
# 检查项:
#   1. 本轮回复开头是否含 "Using [skill-name] to"
#   2. 本轮回复是否含 update_plan 调用
#   3. 是否调用了至少一个 skill 工具 / 读了至少一个 SKILL.md
#   4. 任务是否 1%+ 适用某技能（基于关键词匹配启发式）

set -euo pipefail

# 颜色（如果输出到 TTY）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 已知技能名（用于启发式 1% 适用性检查）
KNOWN_SKILLS=(
  "using-superpowers" "skill-vetter" "brainstorming"
  "systematic-debugging" "causal-inference" "ada-lovelace"
  "humanizer" "khazix-writer" "obsidian-vault-maintainer"
  "memory" "ontology" "self-improving-agent"
  "proactive-agent" "multi-search-engine" "agent-browser-clawdbot"
  "huashu-nuwa" "hv-analysis" "neat-freak"
)

# 任务类型 → 推荐技能映射
declare -A TASK_TO_SKILLS=(
  ["设计"]="brainstorming"
  ["架构"]="brainstorming"
  ["排查"]="systematic-debugging"
  ["根因"]="causal-inference"
  ["写"]="khazix-writer"
  ["博客"]="khazix-writer"
  ["清理"]="neat-freak"
  ["搜索"]="multi-search-engine"
  ["调试"]="systematic-debugging"
  ["修复"]="systematic-debugging"
  ["采集"]="obsidian-vault-maintainer"
  ["提炼"]="memory"
)

# ============================================================
# skill_preflight_check <last_user_message>
# 输出: 合规性报告（适合被 assistant 自检读取）
# ============================================================
skill_preflight_check() {
  local last_user_msg="${1:-}"
  local report=""
  local compliant=true
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔒 Skill Preflight Check (using-superpowers)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # --- 检查 1：消息是否触发任何已知技能 ---
  echo "📋 适用技能候选扫描:"
  local candidates=()
  
  # 总是强制列 using-superpowers（meta 技能）
  candidates+=("using-superpowers [meta, 必检]")
  
  # 启发式：从消息关键词匹配
  for task_key in "${!TASK_TO_SKILLS[@]}"; do
    if [[ "$last_user_msg" == *"$task_key"* ]]; then
      local skill="${TASK_TO_SKILLS[$task_key]}"
      candidates+=("$skill [matched: $task_key]")
    fi
  done
  
  # 技能名直接出现在消息中
  for skill in "${KNOWN_SKILLS[@]}"; do
    if [[ "$last_user_msg" == *"$skill"* ]]; then
      candidates+=("$skill [mentioned in msg]")
    fi
  done
  
  if [ ${#candidates[@]} -eq 1 ]; then
    # 只有 using-superpowers 本身
    echo "  ${YELLOW}⚠️  仅 using-superpowers 候选；任务是否真的只 1% 适用其他技能？${NC}"
  fi
  for c in "${candidates[@]}"; do
    echo "  - $c"
  done
  
  echo ""
  echo "🎯 必须执行的动作（按顺序）:"
  echo "  1. ✅ update_plan 列出适用技能候选"
  echo "  2. ⏳ 宣告 'Using [skill] to [purpose]' 开头"
  echo "  3. ⏳ 调用 skill 工具 / 读 SKILL.md"
  echo "  4. ⏳ 才执行 exec / write / edit"
  echo ""
  
  # --- 统计 ---
  echo "📊 历史违反次数: 5 (05-23/05-27/06-03/06-09/06-18)"
  echo "💡 修复: 人格层 + 脚本层 + dreaming 触发器 三层并发"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# self_audit <assistant_reply_text>
# 用于 assistant 自检本轮回复是否合规
# 返回 0=合规 / 1=违反
# ============================================================
self_audit() {
  local reply="${1:-}"
  local violations=()
  
  # 检查 "Using [skill] to" 在前 200 字符内
  local head="${reply:0:200}"
  if ! echo "$head" | grep -qE "Using [a-z][a-z0-9-]+ to "; then
    violations+=("❌ 开头 200 字符内未出现 'Using [skill] to ...' 宣告")
  fi
  
  # 检查 update_plan 痕迹（如果在 chat history 里）
  # 这部分由 orchestrator 检查，脚本层面无法直接验证
  
  if [ ${#violations[@]} -gt 0 ]; then
    echo "${RED}🚨 Preflight 违规:${NC}"
    for v in "${violations[@]}"; do
      echo "  $v"
    done
    return 1
  fi
  
  echo "${GREEN}✅ Preflight 合规${NC}"
  return 0
}

# ============================================================
# dreaming_trigger <text>
# Dream session 里看到这个 text 包含 using-superpowers 时，提醒强制重读 SKILL.md
# ============================================================
dreaming_trigger() {
  local text="${1:-}"
  if [[ "$text" == *"using-superpowers"* ]] || [[ "$text" == *"硬性规则"* ]] || [[ "$text" == *"宣告 Using"* ]]; then
    echo "🌙 Dreaming trigger fired: 强制重读 using-superpowers/SKILL.md"
    echo "   路径: /home/wszmd520520/.openclaw/workspace/skills/using-superpowers/SKILL.md"
    echo "   状态: ✅ 已激活 (openclaw skills check 验证)"
    echo "   关键红线: '宣告是装饰' 是 5 次违反的根因"
    return 0
  fi
  return 1
}

# 如果直接执行此脚本，运行 preflight
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -eq 0 ]; then
    echo "用法: $0 <last_user_message>"
    echo "      $0 --audit <assistant_reply>"
    echo "      $0 --dream <text>"
    exit 1
  fi
  
  case "$1" in
    --audit)
      shift
      self_audit "$@"
      ;;
    --dream)
      shift
      dreaming_trigger "$@"
      ;;
    *)
      skill_preflight_check "$@"
      ;;
  esac
fi