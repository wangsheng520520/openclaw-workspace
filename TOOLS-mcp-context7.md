# TOOLS-mcp-context7.md — Context7 MCP（2 工具）

> Context7 库文档查询 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @upstash/context7-mcp@latest`
- **包来源**：Upstash 官方 Context7 MCP
- **工具数**：2
- **启动延迟**：5.0s
- **传输**：stdio
- **API**：Context7 公共 API（部分可能需 key）

---

## 2 个工具

| 工具 | 用途 |
|------|------|
| `resolve-library-id` | 库名 → Context7 library ID |
| `query-docs` | 用 ID 查文档/代码片段 |

---

## 工作流（标准两阶段）

```
libraryName (e.g. "React.js")
  ↓ resolve-library-id
libraryId (e.g. "/reactjs/react.dev")
  ↓ query-docs
Markdown 文档 + 代码片段（带 GitHub 源链接）
```

**注意**：query-docs **强烈推荐先 resolve**，除非用户已提供 `/org/project/v1.2.3` 形式 ID。

---

## resolve-library-id 参数

| 参数 | 类型 | 用途 |
|------|------|------|
| `query` | string | 用户查询（用于排序相关度）|
| `libraryName` | string | 库官方名（如 "Next.js" 而非 "nextjs"）|

**返回字段**：
- `libraryId`：格式 `/org/project`
- `Source Reputation`：High / Medium / Low / Unknown
- `Code Snippets`：可用代码片段数
- `Benchmark Score`：质量评分（0-100）
- `Versions`：可用版本列表

---

## query-docs 参数

| 参数 | 类型 | 用途 |
|------|------|------|
| `libraryId` | string | `/org/project[/version]` |
| `query` | string | 单一主题查询（不要多主题混合）|

**返回**：Markdown 格式的文档片段，含可运行代码 + GitHub 源 URL。

---

## 常用调用示例

```bash
# 1. 解析库名
mcporter call context7.resolve-library-id \
  query="React useEffect data fetching with cleanup" \
  libraryName="React.js"
# → 返回候选：/reactjs/react.dev (Benchmark 91.68, 4075 snippets)

# 2. 查询文档
mcporter call context7.query-docs \
  libraryId="/reactjs/react.dev" \
  query="useEffect cleanup function with AbortController"

# 3. 精确版本查询（跳过 resolve）
mcporter call context7.query-docs \
  libraryId="/vercel/next.js/v15.1.8" \
  query="App Router server components data fetching"
```

---

## 评分三件套

每个 `resolve-library-id` 返回都会带：

| 字段 | 用途 | 选用建议 |
|------|------|---------|
| **Source Reputation** | 权威性 | 优先 High / Medium |
| **Code Snippets** | 文档密度 | 数字越大越详细 |
| **Benchmark Score** | 整体质量 | > 80 可靠 |

---

## 何时使用 vs 其他文档工具

| 任务 | 推荐工具 |
|------|---------|
| 查 React/Vue/Next.js/Express 用法 | **context7**（精确 + 评分）|
| 查通用概念/历史 | **mcp-deepwiki** |
| 查最新博客/新闻 | **exa-search** |
| 查指定网页 | **web_fetch** |

---

## 已知限制（来自 schema 注释）

1. **每个问题最多调用 3 次 query-docs** — 超出后用最佳结果
2. **query 不含敏感信息**（API key/密码/个人数据）— 送到 Context7 API
3. **查询单主题**（不要 "routing + auth + caching" 塞一个）
4. 一些非常新的库可能未收录（resolve 返回空）

---

## 何时不该用

- **用户只问"什么是 X"**（概念） → 用 mcp-deepwiki
- **用户要查具体 URL** → 用 web_fetch
- **极冷门库**（resolve 无结果） → 退而求其次用 web_fetch 搜官网

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建