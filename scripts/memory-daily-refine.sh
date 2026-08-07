#!/bin/bash
# 每日记忆提炼脚本 v3 (2026-08-07)
# 每天凌晨 3 点自动执行
# 
# v3 行为:
#   - 处理"1 天"数据（昨天，每天 03:00 跑→提炼前一天）
#   - 读 memory/YYYY-MM-DD.md + memory/YYYY-MM-DD-HHMM.md（昨日所有）
#   - 不调 LLM (按 relevant-memories 教训: 绕 MiniMax-M3 失败风险)
#   - 用 python3 提取要点（心跳记录 + 任何带 - HH:MM — 的行）
#   - 追加到 MEMORY-promoted.md "## 最后记忆提炼日志" 章节末尾
#   - 更新 heartbeat-state.json (lastMemoryRefinement + lastCheck)
# 
# 边界:
#   - 不修改 MEMORY.md (受 06-10 决策保护)
#   - 不修改其他 MEMORY-*.md 子文件（只追加到 promoted）
#   - 1 天范围: 按文件名日期前缀取昨天 YYYY-MM-DD*.md（用户 11:17 指示）
#   - 跨日文件（如 2026-08-06-2222.md）只要 mtime 在范围内都包含

set -uo pipefail

WORKSPACE="/home/wszmd520520/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
HEARTBEAT="$MEMORY_DIR/heartbeat-state.json"
PROMOTED="$WORKSPACE/MEMORY-promoted.md"

# 0. 准备：检查前置
[ -f "$HEARTBEAT" ] || { echo "❌ $HEARTBEAT 不存在"; exit 1; }
[ -f "$PROMOTED" ] || { echo "❌ $PROMOTED 不存在"; exit 1; }
[ -d "$MEMORY_DIR" ] || { echo "❌ $MEMORY_DIR 不存在"; exit 1; }

# 1. 收集"昨天 1 天"的 memory 文件（每天 03:00 跑 → 提炼前一天）
#    按**文件名日期** YYYY-MM-DD 前缀（不用 mtime：避免 8-07 00:25 evolver 批量触碰的假新鲜）
#    跨日文件（如 2026-08-06-2222.md）按 YYYY-MM-DD 部分匹配
#    只含昨天，不含今天："每天只提炼 1 天"（用户 11:17 指示）
TMP_FILE_LIST=$(mktemp)
# 昨天：每天 03:00 跑，目标是提炼前一天 03:00 → 今日 03:00 之间的所有文件
# 定义：YESTERDAY 日期的所有 .md（YYYY-MM-DD.md + YYYY-MM-DD-HHMM.md）
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

for prefix in "$YESTERDAY"; do
    find "$MEMORY_DIR" -maxdepth 1 -type f -name "${prefix}*.md" \
        ! -name "heartbeat-state.json" \
        ! -name "security-audit-*.md" \
        ! -name "*.migrated" \
        2>/dev/null
done | sort -u > "$TMP_FILE_LIST"

FILE_COUNT=$(wc -l < "$TMP_FILE_LIST" | tr -d ' ')
echo "🧠 记忆提炼 v3 开始: $(date -Iseconds)"
echo "   昨天日期范围内找到 $FILE_COUNT 个文件"

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "   无新文件可提炼（仅更新时间戳）"
    rm -f "$TMP_FILE_LIST"
    # 仍更新时间戳（保留 v2 行为）
    CURRENT_TIME=$(date -Iseconds)
    python3 -c "
import json
fp = '$HEARTBEAT'
d = json.load(open(fp))
d['lastMemoryRefinement'] = '$CURRENT_TIME'
d['lastCheck'] = '$CURRENT_TIME'
open(fp, 'w').write(json.dumps(d, indent=2, ensure_ascii=False))
"
    echo "✅ 仅时间戳已更新"
    exit 0
fi

# 2. 提取要点 (python3, 不调 LLM)
#    策略: 提取每文件 - HH:MM — 开头的"事件行" + 文件头标题
TMP_EXTRACT=$(mktemp)
python3 - "$TMP_FILE_LIST" > "$TMP_EXTRACT" <<'PYEOF'
import sys, re, os
from pathlib import Path
from datetime import datetime, timezone, timedelta

CST = timezone(timedelta(hours=8))
now = datetime.now(CST)

files = [l.strip() for l in open(sys.argv[1]) if l.strip()]
print(f"**自动提炼**: ({now.strftime('%Y-%m-%d %H:%M CST')}, {len(files)} 文件)")
print("")

for fp in files:
    p = Path(fp)
    name = p.name
    # 跳过 archive / .migrated / 历史文件
    if 'archive' in str(p.parent) or name.endswith('.migrated'):
        continue
    try:
        content = p.read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        print(f"- [{name}] ⚠️ 读失败: {e}")
        continue
    # 提取心跳记录 (pattern: "- HH:MM CST — ...")
    lines = [l.strip() for l in content.split('\n') if l.strip()]
    event_lines = [l for l in lines if re.match(r'^-\s+\d{1,2}:\d{2}\s*(CST)?\s*[—–-]', l)]
    # 也提取任何 - XXX: 模式的行 (避免漏掉非 CST 格式)
    if not event_lines:
        event_lines = [l for l in lines if l.startswith('- ') and len(l) > 15]
    if not event_lines:
        continue
    print(f"- [{name}]")
    # 最多 8 条（避免 MEMORY-promoted.md 膨胀）
    for el in event_lines[:8]:
        print(f"  {el[:200]}")
    if len(event_lines) > 8:
        print(f"  ... ({len(event_lines) - 8} more)")
    print("")
PYEOF

EXTRACT_CONTENT=$(cat "$TMP_EXTRACT")
rm -f "$TMP_FILE_LIST" "$TMP_EXTRACT"

# 3. 追加到 MEMORY-promoted.md "## 最后记忆提炼日志" 章节末尾
#    找章节起点（"## 最后记忆提炼日志" 那一行），在文件末尾追加（章节本身就是时间倒序）
TIMESTAMP_HEADER=$(date "+**最后记忆提炼**: %Y-%m-%d %H:%M")

# 用 python3 追加（避免 awk 边界问题）
python3 - "$PROMOTED" "$TIMESTAMP_HEADER" "$EXTRACT_CONTENT" <<'PYEOF'
import sys
from pathlib import Path
fp = Path(sys.argv[1])
header = sys.argv[2]
extract = sys.argv[3]
existing = fp.read_text(encoding='utf-8')
# 追加: 章节头 + 提炼内容 + 间隔
new_block = f"\n---\n\n{header}\n{extract}"
fp.write_text(existing + new_block, encoding='utf-8')
print(f"   已追加到 {fp} ({len(new_block)} chars)")
PYEOF

# 4. 更新 heartbeat-state.json
CURRENT_TIME=$(date -Iseconds)
python3 - <<PYEOF
import json
fp = "$HEARTBEAT"
d = json.load(open(fp))
d['lastMemoryRefinement'] = '$CURRENT_TIME'
d['lastCheck'] = '$CURRENT_TIME'
open(fp, 'w').write(json.dumps(d, indent=2, ensure_ascii=False))
PYEOF

echo "✅ 记忆提炼 v3 完成"
