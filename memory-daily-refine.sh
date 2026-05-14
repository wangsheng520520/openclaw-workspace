#!/bin/bash
# 每日记忆提炼脚本
# 每天凌晨 3 点自动执行

WORKSPACE="/home/wszmd520520/.openclaw/workspace"
MEMORY_DIR="$WORKSPACE/memory"
HEARTBEAT="$MEMORY_DIR/heartbeat-state.json"

echo "🧠 开始记忆提炼: $(date)"

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
