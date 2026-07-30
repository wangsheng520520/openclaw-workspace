#!/bin/bash
# repatch-memory-lancedb.sh — 重打 memory-lancedb 插件白名单 patch
#
# 目的: BAAI/bge-m3 不在插件默认 EMBEDDING_DIMENSIONS 白名单，
#       任何 `npm install` 或 OpenClaw 升级都会覆盖此 patch。
#       本脚本确保白名单里始终有 bge-m3: 1024。
#
# 触发场景:
#   - 任何 `npm install @openclaw/memory-lancedb*` 之后
#   - OpenClaw 主程序升级后
#   - 看到 `disabled until configured (Unsupported embedding model: BAAI/bge-m3)` 错误时
#
# 用法:
#   bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh                # 检查+打 patch（如需要）
#   bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh --restart       # 打完 patch 后硬重启 gateway
#   bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh --verify-only   # 只检查，不动文件
#
# 铁证 (2026-07-30): 07-02 我们打此 patch → 07-14 一直工作 → 07-15 npm 升级覆盖 →
#                    07-17 ~ 07-30 静默 16 天 → 07-30 重打此 patch 立即恢复
#                    (LanceDB 最后写入 mtime = 2026-07-14 08:29，plugin 安装 mtime = 2026-07-15 21:47:26)

set -euo pipefail

# ---------- 配置 ----------
# 插件真实安装位置 (OpenClaw 7.1+ 是独立 project 目录, 而非 global node_modules)
PLUGIN_GLOB="/home/wszmd520520/.openclaw/npm/projects/openclaw-memory-lancedb-*/node_modules/@openclaw/memory-lancedb"

# 待插入的白名单条目
BGE_LINE='	"BAAI/bge-m3": 1024'
# OpenAI 大模型后面那行 (作为锚点)
ANCHOR_LINE='	"text-embedding-3-large": 3072'

# ---------- 颜色（如果终端支持） ----------
if [ -t 1 ]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

log()  { echo "${BLUE}[repatch]${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*"; }
err()  { echo "${RED}[err]${NC} $*" >&2; }

# ---------- 解析参数 ----------
RESTART_AFTER=0
VERIFY_ONLY=0
for arg in "$@"; do
    case "$arg" in
        --restart)       RESTART_AFTER=1 ;;
        --verify-only)   VERIFY_ONLY=1 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            err "未知参数: $arg"
            echo "用法: $0 [--restart] [--verify-only]"
            exit 1 ;;
    esac
done

# ---------- 1. 定位 plugin ----------
log "定位 memory-lancedb 插件..."
shopt -s nullglob
PLUGIN_DIRS=( $PLUGIN_GLOB )
shopt -u nullglob

if [ ${#PLUGIN_DIRS[@]} -eq 0 ]; then
    err "找不到 memory-lancedb 插件安装目录"
    err "  期望路径: $PLUGIN_GLOB"
    err "  解决: 检查 ~/.openclaw/npm/projects/ 下有没有 openclaw-memory-lancedb-* 目录"
    exit 2
fi

if [ ${#PLUGIN_DIRS[@]} -gt 1 ]; then
    warn "找到多个 memory-lancedb 插件安装:"
    for d in "${PLUGIN_DIRS[@]}"; do
        echo "  - $d"
    done
    warn "将逐个处理"
fi

PATCHED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

for PLUGIN_DIR in "${PLUGIN_DIRS[@]}"; do
    CONFIG_JS="$PLUGIN_DIR/dist/config.js"

    if [ ! -f "$CONFIG_JS" ]; then
        err "找不到 config.js: $CONFIG_JS"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi

    # 读 package.json 拿版本号 (诊断用)
    PKG_JSON="$PLUGIN_DIR/package.json"
    if [ -f "$PKG_JSON" ]; then
        VERSION=$(python3 -c "import json; print(json.load(open('$PKG_JSON')).get('version', 'unknown'))" 2>/dev/null || echo "unknown")
    else
        VERSION="unknown"
    fi

    log "插件版本: $VERSION"
    log "配置文件: $CONFIG_JS"

    # ---------- 2. 验证当前状态 ----------
    if grep -qF "$BGE_LINE" "$CONFIG_JS"; then
        ok "patch 已存在 (BAAI/bge-m3: 1024) — 无需重打"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    if [ "$VERIFY_ONLY" -eq 1 ]; then
        warn "patch 不存在，但 --verify-only 模式不动文件"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi

    # ---------- 3. 备份 ----------
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP="$CONFIG_JS.bak-before-repatch-$TIMESTAMP"
    cp -p "$CONFIG_JS" "$BACKUP"
    log "已备份: $BACKUP"

    # ---------- 4. 精准插入 (用 python 而非 sed 避免转义问题) ----------
    if ! python3 - "$CONFIG_JS" "$ANCHOR_LINE" "$BGE_LINE" <<'PY'
import sys
path, anchor, bge_line = sys.argv[1], sys.argv[2], sys.argv[3]

with open(path) as f:
    src = f.read()

# 情况 1: anchor 后面有逗号 (e.g. text-embedding-3-large 后面通常有逗号 + 闭合 })
# 情况 2: anchor 是最后一行 (没逗号)
# 我们的 anchor 是 text-embedding-3-large: 3072 — 后面一定有 }, 所以没逗号
# 但保险起见, 我们用正则智能处理

import re
# 找 EMBEDDING_DIMENSIONS 这个 object literal 块
pattern = r'(const\s+EMBEDDING_DIMENSIONS\s*=\s*\{[^}]*?)(\}\s*;)'
m = re.search(pattern, src, re.DOTALL)
if not m:
    print(f"❌ 找不到 EMBEDDING_DIMENSIONS object literal", file=sys.stderr)
    sys.exit(1)

body, closing = m.group(1), m.group(2)
# 检查最后一行有没有逗号
last_char = body.rstrip()[-1] if body.rstrip() else ''
sep = ',' if last_char != ',' else ''

# 检查是否已有 bge-m3 (再保险一次)
if 'BAAI/bge-m3' in body:
    print(f"⚠️  bge-m3 已存在, 跳过")
    sys.exit(0)

# 插入新条目
new_body = body.rstrip() + sep + '\n' + bge_line + '\n'
new_src = src.replace(m.group(0), new_body + closing)

with open(path, 'w') as f:
    f.write(new_src)
print(f"✅ patch 已打入")
PY
    then
        err "Python 插入失败: $CONFIG_JS"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        continue
    fi

    # ---------- 5. 验证结果 ----------
    if grep -qF "$BGE_LINE" "$CONFIG_JS"; then
        ok "patch 验证通过 (BAAI/bge-m3: 1024 已加入白名单)"
        PATCHED_COUNT=$((PATCHED_COUNT + 1))
    else
        err "patch 验证失败 — 请人工检查 $CONFIG_JS"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

# ---------- 6. 汇总 ----------
echo ""
log "汇总: $PATCHED_COUNT patched, $SKIPPED_COUNT skipped, $ERROR_COUNT errors"

# verify-only 模式：退出码 1 表示需要 patch
if [ "$VERIFY_ONLY" -eq 1 ] && [ "$ERROR_COUNT" -gt 0 ]; then
    warn "verify-only 模式：检测到 patch 缺失，需手动重打"
    exit 1
fi

# 其他错误：退出码 1
if [ "$ERROR_COUNT" -gt 0 ]; then
    err "有 $ERROR_COUNT 个错误，请检查上方输出"
    exit 1
fi

# ---------- 7. 可选: 硬重启 gateway ----------
if [ "$PATCHED_COUNT" -gt 0 ] && [ "$RESTART_AFTER" -eq 1 ]; then
    log "硬重启 gateway (让 plugin 重新加载 patched 代码)..."
    systemctl --user restart openclaw-gateway
    sleep 12
    log "验证 memory-lancedb 初始化..."
    if journalctl --user -u openclaw-gateway.service --since "30 seconds ago" --no-pager -q 2>&1 | grep -qE "memory-lancedb:.*(initialized|disabled)"; then
        if journalctl --user -u openclaw-gateway.service --since "30 seconds ago" --no-pager -q 2>&1 | grep -q "disabled until configured"; then
            err "memory-lancedb 仍报 disabled — patch 失败或 config 缺失 apiKey"
            exit 1
        else
            ok "memory-lancedb 启动正常"
        fi
    else
        warn "未看到 memory-lancedb 初始化日志（也许还在启动中）"
    fi
fi

ok "完成"
