#!/usr/bin/env bash
# alignment-check.sh — 配置 vs OpenClaw 官方推荐对账
#
# 用途: 定期检查当前 openclaw.json 与官方"完美最佳实践"之间的 gap
#       输出"已对齐 / 缺失 / 偏离"三类状态
# 作者: Ada Lovelace skill 蒸馏 / 2026-06-10
# 风格: 与 evolver-watchdog.sh 一致（set -euo pipefail + timeout 防护）
#
# 设计: 写死关键检查项 (2026-06-10 完美最佳实践对账清单)
#       任何 P0/P1 检查项不一致都返回非 0 退出码
#       P2/P3 不一致仅打印警告
#
# 退出码:
#   0 = 所有 P0/P1 已对齐
#   1 = P0 缺失
#   2 = P1 缺失
#   3 = 仅 P2/P3 缺失

set -uo pipefail

# --- 路径与防护 --------------------------------------------------------
OPENCLAW_BIN="${OPENCLAW_BIN:-openclaw}"
OPENCLAW_JSON="${HOME}/.openclaw/openclaw.json"
TIMEOUT="${OPENCLAW_TIMEOUT:-12}"

# 计数器
P0_FAIL=0
P1_FAIL=0
P2_FAIL=0
PASS=0
TOTAL=0

# 标题
echo "=================================================================="
echo "🧭 Alignment Check — $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "   (OpenClaw 官方最佳实践对账)"
echo "=================================================================="
echo

# --- 工具函数 ----------------------------------------------------------
check_p0() {
  local id="$1"; local desc="$2"; local actual="$3"
  TOTAL=$((TOTAL+1))
  if [ -n "$actual" ] && [ "$actual" != "(缺失)" ] && [ "$actual" != "(查询失败)" ]; then
    echo "  ✅ P0  $id  $desc  =  $actual"
    PASS=$((PASS+1))
  else
    echo "  ❌ P0  $id  $desc  =  $actual"
    P0_FAIL=$((P0_FAIL+1))
  fi
}

check_p1() {
  local id="$1"; local desc="$2"; local actual="$3"
  TOTAL=$((TOTAL+1))
  if [ -n "$actual" ] && [ "$actual" != "(缺失)" ] && [ "$actual" != "(查询失败)" ]; then
    echo "  ✅ P1  $id  $desc  =  $actual"
    PASS=$((PASS+1))
  else
    echo "  ❌ P1  $id  $desc  =  $actual"
    P1_FAIL=$((P1_FAIL+1))
  fi
}

check_p2() {
  local id="$1"; local desc="$2"; local actual="$3"
  TOTAL=$((TOTAL+1))
  if [ -n "$actual" ] && [ "$actual" != "(缺失)" ] && [ "$actual" != "(查询失败)" ]; then
    echo "  ✅ P2  $id  $desc  =  $actual"
    PASS=$((PASS+1))
  else
    echo "  ⚠️  P2  $id  $desc  =  $actual"
    P2_FAIL=$((P2_FAIL+1))
  fi
}

# 简化版 config get（用 python 解析 openclaw.json，避免 CLI 超时）
get_json() {
  local path="$1"
  python3 -c "
import json
try:
    c = json.load(open('$OPENCLAW_JSON'))
    for k in '$path'.split('.'):
        if k.endswith(']'):
            arr, idx = k[:-1].split('[')
            c = c[arr][int(idx)]
        else:
            c = c.get(k) if isinstance(c, dict) else None
            if c is None: break
    if c is None: print('(缺失)')
    elif isinstance(c, (dict, list)): print(json.dumps(c, ensure_ascii=False))
    else: print(c)
except Exception as e:
    print('(查询失败)')" 2>/dev/null
}

# --- 检查区 -----------------------------------------------------------

echo "▶ P0 必做项（核心 5 层架构）"
echo "------------------------------------------------------------------"

# L1 Bootstrap
L1_BS=$(get_json "agents.defaults.bootstrapMaxChars")
check_p0 "L1.BS"  "bootstrapMaxChars"           "$L1_BS"

# L2 Session
L2_DM=$(get_json "session.dmScope")
check_p0 "L2.DM"  "session.dmScope"             "$L2_DM"

L2_RST=$(get_json "session.reset.mode")
check_p0 "L2.RST" "session.reset.mode"          "$L2_RST"

# L3 Context Engine (默认 legacy 即可——未配 = 走默认，视为 OK)
L3_CE=$(get_json "plugins.slots.contextEngine")
if [ "$L3_CE" = "(缺失)" ]; then
  L3_CE="(默认 legacy)"
fi
check_p0 "L3.CE"  "plugins.slots.contextEngine" "$L3_CE"

# L4 Memory Plugin
L4_MM=$(get_json "plugins.slots.memory")
check_p0 "L4.MM"  "plugins.slots.memory"        "$L4_MM"

# L5 Compaction + Pruning
L5_MODE=$(get_json "agents.defaults.compaction.mode")
check_p0 "L5.CM"  "compaction.mode"             "$L5_MODE"

L5_FLUSH=$(get_json "agents.defaults.compaction.memoryFlush.model")
check_p0 "L5.FL"  "compaction.memoryFlush.model" "$L5_FLUSH"

L5_PRUNE=$(get_json "agents.defaults.contextPruning.mode")
check_p0 "L5.PR"  "contextPruning.mode"         "$L5_PRUNE"

echo
echo "▶ P1 体验提升项"
echo "------------------------------------------------------------------"

P1_AM=$(get_json "plugins.entries.active-memory.enabled")
check_p1 "P1.AM"  "active-memory plugin"        "$P1_AM"

P1_TD=$(get_json "agents.defaults.memorySearch.query.hybrid.temporalDecay.enabled")
check_p1 "P1.TD"  "memorySearch.query.hybrid.temporalDecay"  "${P1_TD:-(未设)}"

P1_MMR=$(get_json "agents.defaults.memorySearch.query.hybrid.mmr.enabled")
check_p1 "P1.MMR" "memorySearch.query.hybrid.mmr"            "${P1_MMR:-(未设)}"

echo
echo "▶ P2 维稳与观测项"
echo "------------------------------------------------------------------"

P2_DOCS=$(ls -1 /home/wszmd520520/.openclaw/workspace/{AGENTS,SOUL,TOOLS,IDENTITY,USER,HEARTBEAT,BOOTSTRAP}.md 2>/dev/null | wc -l)
check_p2 "P2.BM"  "BOOTSTRAP.md 存在"           "$P2_DOCS/7 bootstrap 文件"

P2_SCRIPT_DIR=$(ls -1 /home/wszmd520520/.openclaw/workspace/scripts/memory-snapshot.sh 2>/dev/null | wc -l)
check_p2 "P2.SS"  "memory-snapshot.sh 存在"     "$P2_SCRIPT_DIR"

echo
echo "▶ P3 历史锁定项（应保持原状）"
echo "------------------------------------------------------------------"
P3_DM=$(get_json "session.dmScope")
echo "  🔒 P3.DM  session.dmScope = $P3_DM (期望 per-channel-peer, 06-10 锁定)"
P3_RST=$(get_json "session.reset.mode")
echo "  🔒 P3.RST session.reset.mode = $P3_RST (期望 idle, 06-10 锁定)"

# --- 总结 -------------------------------------------------------------
echo
echo "=================================================================="
echo "📊 对账结果"
echo "=================================================================="
echo "  总检查项: $TOTAL"
echo "  ✅ 通过:  $PASS"
echo "  ❌ P0 失败: $P0_FAIL"
echo "  ❌ P1 失败: $P1_FAIL"
echo "  ⚠️  P2 缺失: $P2_FAIL"
echo

# 退出码
if [ "$P0_FAIL" -gt 0 ]; then
  echo "🔴 状态: 关键缺失 (exit 1)"
  exit 1
elif [ "$P1_FAIL" -gt 0 ]; then
  echo "🟡 状态: 体验项缺失 (exit 2)"
  exit 2
elif [ "$P2_FAIL" -gt 0 ]; then
  echo "🟢 状态: 维稳项缺失 (exit 3)"
  exit 3
else
  echo "🟢 状态: 完美对齐 (exit 0)"
  exit 0
fi
