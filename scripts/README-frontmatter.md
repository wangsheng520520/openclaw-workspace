# Frontmatter 自动注入脚本

> 创建时间：2026-04-20  
> 位置：`~/workspace/scripts/inject-frontmatter.sh`

---

## 用途

在创建 Obsidian 笔记时自动注入 YAML Frontmatter，确保元数据一致性。

---

## 用法

```bash
# 基本用法
./scripts/inject-frontmatter.sh <笔记路径> <标题> [阶段] [标签...]

# 示例 1：创建灵感笔记
./scripts/inject-frontmatter.sh "01-灵感库/新想法.md" "新想法" "灵感" "AI" "创意"

# 示例 2：创建选题笔记
./scripts/inject-frontmatter.sh "02-选题池/文章选题.md" "文章选题" "选题" "写作"

# 示例 3：创建已发布笔记
./scripts/inject-frontmatter.sh "04-已发布归档/2026-04-20-文章.md" "文章标题" "已发布" "OpenClaw" "AI"
```

---

## 参数说明

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| 笔记路径 | ✅ | — | Obsidian Vault 中的相对路径 |
| 标题 | ✅ | — | 笔记标题（用于 Frontmatter） |
| 阶段 | ❌ | 灵感 | 灵感 \| 选题 \| 创作 \| 已发布 |
| 标签 | ❌ | [] | 可选的标签列表（多个用空格分隔） |

---

## 生成的 Frontmatter

```yaml
---
title: 笔记标题
stage: 灵感
created: 2026-04-20
source: openclaw-auto
tags: ['AI', '创意']
related: []
---
```

---

## 功能特性

- ✅ 自动创建目录（如果不存在）
- ✅ 检测现有文件是否已有 Frontmatter
- ✅ 为无 Frontmatter 的现有文件注入元数据
- ✅ 为新文件创建完整的 Frontmatter
- ✅ 显示生成的 Frontmatter 预览

---

## 集成建议

### 1. 微信文章导入流程

在微信文章提取后自动调用：
```bash
# 提取文章后
./scripts/inject-frontmatter.sh "Clippings/公众号/$(date +%Y-%m-%d)-文章标题.md" "文章标题" "已发布" "微信公众号" "公交行业"
```

### 2. 梦境笔记导出

将梦境系统输出导入 Obsidian 时：
```bash
./scripts/inject-frontmatter.sh "05-官方文档/.dreams/$(date +%Y-%m-%d).md" "梦境 $(date +%Y-%m-%d)" "灵感" "梦境" "记忆"
```

### 3. 自动化 CRON（可选）

添加 CRON 任务自动处理新文件：
```bash
# 每天凌晨 4:30 检查并注入 Frontmatter
30 4 * * * cd ~/.openclaw/workspace && find /mnt/d/Obsidian知识库文件/Clippings -name "*.md" -mtime -1 | while read file; do
    rel_path=${file#/mnt/d/Obsidian知识库文件/}
    ~/.openclaw/workspace/scripts/inject-frontmatter.sh "$rel_path" "$(basename "$file" .md)" "已发布"
done
```

---

## 注意事项

- ⚠️ 脚本需要访问 `/mnt/d/Obsidian知识库文件/`（WSL 路径）
- ⚠️ 确保 Obsidian Vault 已挂载
- ⚠️ 如文件已有 Frontmatter，脚本会跳过注入

---

## 故障排查

**问题**: 脚本提示权限不足
**解决**: `chmod +x ~/workspace/scripts/inject-frontmatter.sh`

**问题**: 目录不存在
**解决**: 脚本会自动创建目录，如失败请手动创建

**问题**: Frontmatter 重复注入
**解决**: 脚本会检测第一行是否为 `---`，已存在则跳过
