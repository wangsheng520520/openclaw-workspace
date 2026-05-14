#!/bin/bash
# Frontmatter 自动注入脚本
# 用于在创建 Obsidian 笔记时自动注入 YAML Frontmatter

set -e

# 参数检查
if [ $# -lt 2 ]; then
    echo "用法：$0 <笔记路径> <标题> [阶段] [标签...]"
    echo "  笔记路径：Obsidian Vault 中的完整路径"
    echo "  标题：笔记标题"
    echo "  阶段：灵感|选题 | 创作 | 已发布 (默认：灵感)"
    echo "  标签：可选的标签列表"
    exit 1
fi

NOTE_PATH="$1"
TITLE="$2"
STAGE="${3:-灵感}"
shift 3
TAGS=("$@")

# Obsidian Vault 路径
VAULT_PATH="/mnt/d/Obsidian知识库文件"

# 生成日期
CREATED=$(date +%Y-%m-%d)

# 生成标签 YAML 数组
if [ ${#TAGS[@]} -eq 0 ]; then
    TAGS_YAML="[]"
else
    TAGS_YAML="["
    for i in "${!TAGS[@]}"; do
        if [ $i -gt 0 ]; then
            TAGS_YAML+=", "
        fi
        TAGS_YAML+="'${TAGS[$i]}'"
    done
    TAGS_YAML+="]"
fi

# 创建目录（如果不存在）
NOTE_DIR=$(dirname "$NOTE_PATH")
mkdir -p "$VAULT_PATH/$NOTE_DIR"

# 生成 Frontmatter
FRONTMATTER="---
title: $TITLE
stage: $STAGE
created: $CREATED
source: openclaw-auto
tags: $TAGS_YAML
related: []
---

"

# 检查文件是否已存在
if [ -f "$VAULT_PATH/$NOTE_PATH" ]; then
    # 文件已存在，检查是否已有 Frontmatter
    if head -1 "$VAULT_PATH/$NOTE_PATH" | grep -q "^---$"; then
        echo "⚠️  文件 $NOTE_PATH 已存在 Frontmatter，跳过注入"
        exit 0
    else
        # 在文件开头插入 Frontmatter
        TEMP_FILE=$(mktemp)
        echo "$FRONTMATTER" > "$TEMP_FILE"
        cat "$VAULT_PATH/$NOTE_PATH" >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$VAULT_PATH/$NOTE_PATH"
        echo "✅ 已为现有文件 $NOTE_PATH 注入 Frontmatter"
    fi
else
    # 创建新文件
    echo "$FRONTMATTER" > "$VAULT_PATH/$NOTE_PATH"
    echo "✅ 已创建新笔记 $NOTE_PATH 并注入 Frontmatter"
fi

# 显示生成的 Frontmatter
echo ""
echo "📋 生成的 Frontmatter:"
echo "---"
echo "title: $TITLE"
echo "stage: $STAGE"
echo "created: $CREATED"
echo "source: openclaw-auto"
echo "tags: $TAGS_YAML"
echo "related: []"
echo "---"
