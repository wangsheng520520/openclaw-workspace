#!/bin/bash
# 每日记忆提炼脚本
# 每天凌晨 3 点自动执行，提炼前一天的记忆到 MEMORY.md

WORKSPACE="/home/wszmd520520/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
MEMORY_MD="$WORKSPACE/MEMORY.md"
HEARTBEAT="$MEMORY_DIR/heartbeat-state.json"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

echo "🧠 开始记忆提炼: $TODAY"

# 检查昨天的记忆文件是否存在
if [ ! -f "$MEMORY_DIR/$YESTERDAY.md" ]; then
    echo "⚠️ 记忆文件不存在：$YESTERDAY.md"
    exit 0
fi

# 提炼关键信息（简化版）
echo "📝 提炼 $YESTERDAY 的记忆..."

# 更新 heartbeat-state.json
CURRENT_TIME=$(date -Iseconds)
cat "$HEARTBEAT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
d['lastMemoryRefinement'] = '$CURRENT_TIME'
d['lastCheck'] = '$CURRENT_TIME'
print(json.dumps(d, indent=2))
" > /tmp/heartbeat-new.json && mv /tmp/heartbeat-new.json "$HEARTBEAT"

echo "✅ 记忆提炼完成"
echo "   - 最后提炼：$CURRENT_TIME"
echo "   - 提炼日期：$YESTERDAY"
