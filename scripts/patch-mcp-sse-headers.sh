#!/bin/bash
# MCPhub SSE Header 重复补丁
# 修复 buildSseEventSourceFetch header 重复 → 401
# 运行: bash ~/.openclaw/workspace/scripts/patch-mcp-sse-headers.sh
set -euo pipefail

OC_DIR="/home/wszmd520520/.nvm/versions/node/v24.14.0/lib/node_modules/openclaw/dist"
TARGET=$(find "$OC_DIR" -maxdepth 1 -name "pi-bundle-mcp-runtime-*.js" 2>/dev/null | head -1)

if [ -z "$TARGET" ]; then
    echo "❌ 找不到 pi-bundle-mcp-runtime-*.js"
    exit 1
fi

if grep -q "existingKey" "$TARGET" 2>/dev/null; then
    echo "✅ 已有补丁 ($(basename $TARGET))"
    exit 0
fi

echo "🔧 打补丁: $(basename $TARGET)"

python3 "$OC_DIR/../scripts/patch_build_sse.py" "$TARGET" 2>/dev/null || \
python3 -c "
import sys
f = sys.argv[1]
with open(f, 'r') as fh: c = fh.read()

old = '\t\treturn fetchWithUndici(url, {\n\t\t\t...init,\n\t\t\theaders: {\n\t\t\t\t...sdkHeaders,\n\t\t\t\t...headers\n\t\t\t}\n\t\t});'

new = '''\t\tconst merged = { ...sdkHeaders };
\t\tfor (const [key, val] of Object.entries(headers)) {
\t\t\tconst ek = Object.keys(merged).find(k => k.toLowerCase() === key.toLowerCase());
\t\t\tif (ek) merged[ek] = val;
\t\t\telse merged[key] = val;
\t\t}
\t\treturn fetchWithUndici(url, {
\t\t\t...init,
\t\t\theaders: merged
\t\t});'''

if old in c:
    c = c.replace(old, new)
    with open(f, 'w') as fh: fh.write(c)
    print(f'✅ Patched {f}')
else:
    print('⚠️ 原始代码已变更，需手动检查')
    sys.exit(1)
" "$TARGET"

systemctl --user restart openclaw-gateway
echo "✅ Gateway 已重启"
