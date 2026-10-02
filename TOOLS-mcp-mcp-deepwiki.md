# TOOLS-mcp-mcp-deepwiki.md — DeepWiki MCP（1 工具）

> DeepWiki 维基百科深度查询 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y mcp-deepwiki@latest`
- **包来源**：DeepWiki 社区包
- **工具数**：1
- **启动延迟**：10.0s（最慢 — 需拉较多依赖）
- **传输**：stdio
- **数据源**：deepwiki.com（GitHub 仓库/维基百科深度聚合）

---

## 1 个工具

`deepwiki_fetch` — 拉取仓库/库的深度 Markdown 文档

---

## 参数

| 参数 | 类型 | 用途 |
|------|------|------|
| `url` | string | 仓库 URL / owner/repo / 双词 "owner repo" / 单关键词 |
| `maxDepth` | int | 0 = 单站点，1 = 多站点（默认 1）|
| `mode` | string | `aggregate`（默认）或 `pages` |
| `verbose` | bool | 是否含全部详情 |

---

## URL 格式（4 种都接受）

```
1. 完整 URL：        https://github.com/vercel/next.js
2. owner/repo：      vercel/next.js
3. 双词 owner repo： vercel next.js
4. 单关键词：        react
```

---

## 常用调用示例

```bash
# 标准：取某个 GitHub 仓库的深度文档
mcporter call mcp-deepwiki.deepwiki_fetch \
  url="vercel/next.js" \
  maxDepth=1

# 完整 URL
mcporter call mcp-deepwiki.deepwiki_fetch \
  url="https://github.com/facebook/react"

# 单关键词（自动聚合）
mcporter call mcp-deepwiki.deepwiki_fetch \
  url="postgresql"

# 单站点（maxDepth=0）
mcporter call mcp-deepwiki.deepwiki_fetch \
  url="openai/whisper" \
  maxDepth=0

# 详细模式（包含所有可能的页面）
mcporter call mcp-deepwiki.deepwiki_fetch \
  url="vercel/next.js" \
  verbose=true mode=aggregate
```

---

## 与其他文档工具的对比

| 维度 | mcp-deepwiki | context7 | exa-search | web_fetch |
|------|--------------|----------|------------|-----------|
| **数据源** | DeepWiki（聚合）| Context7 库 | 神经网络 | 任意 URL |
| **粒度** | 仓库级 | 库 API 概念 | 通用文章 | 单页 |
| **版本感知** | 否（默认 latest）| ✅ 精确版本 | 否 | 否 |
| **代码片段** | ✅ | ✅（带 GitHub 链接）| ❌ | 取决于页面 |
| **返回格式** | Markdown | Markdown | 摘要 | Markdown/Text |

---

## 何时使用

✅ **适合**：
- 了解某开源项目整体架构（"X 项目是做什么的、怎么组织的"）
- 查通用概念（"什么是 Y 协议"）
- 仓库级 README/文档聚合

❌ **不适合**：
- 库 API 精确查询 → **context7**
- 实时新闻/博客 → **exa-search**
- 指定 URL 抓取 → **web_fetch**

---

## 已知限制

- **启动最慢**（10.0s）— 频繁调用不划算
- 仓库 huge 时返回内容很长（注意 context 限制）
- 无版本感知（拿到的是默认分支 latest 状态）
- 中文资料覆盖较弱（主要英文 GitHub）

---

## 性能优化建议

- 优先用 `maxDepth=0`（单站点，更快）
- 仅需 README 时传 `mode=aggregate`（默认）
- 批量查多个库时**复用连接**，避免反复启动

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建