# TOOLS-mcp-exa-search.md — Exa Search MCP（2 工具）

> Exa 神经网络搜索 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx exa-mcp-server`
- **包来源**：Exa 官方 mcp-server
- **工具数**：2
- **启动延迟**：4.5s
- **传输**：stdio
- **API key**：需要 Exa API key

---

## 2 个工具

| 工具 | 用途 |
|------|------|
| `web_search_exa` | 神经网络搜索（语义，不是关键词）|
| `web_fetch_exa` | 抓取指定 URL 全文 |

---

## web_search_exa 参数

| 参数 | 类型 | 用途 |
|------|------|------|
| `query` | string | **自然语言描述**理想页面（不是关键词）|
| `numResults` | int | 返回数量（默认 10）|

**特殊类别**：
- `category:people` — LinkedIn 风格（人物）
- `category:company` — 公司信息

示例：
```
query="blog post comparing React and Vue performance"
query="category:people John Smith software engineer"
```

---

## 常用调用示例

```bash
# 基础搜索（语义查询）
mcporter call exa-search.web_search_exa \
  query="OpenAI GPT-5 release announcement 2026" \
  numResults=5

# 找人
mcporter call exa-search.web_search_exa \
  query="category:people Sarah Chen AI researcher Hugging Face" \
  numResults=3

# 找公司
mcporter call exa-search.web_search_exa \
  query="category:company Anthropic PBC recent funding" \
  numResults=3

# 抓取多个 URL（批量）
mcporter call exa-search.web_fetch_exa \
  urls='["https://example.com/page1","https://example.com/page2"]' \
  maxCharacters=3000
```

---

## 与传统搜索的区别

| 维度 | Exa (神经网络) | Google (关键词) |
|------|---------------|----------------|
| **匹配方式** | 语义相似 | 关键词匹配 |
| **结果质量** | 长文/博客优先 | 短摘/SEO 优化 |
| **查询建议** | 描述理想页面 | 列关键词 |
| **API 价格** | $5/月 1000 次 | 多数免费 |

---

## 何时使用 vs 其他搜索工具

✅ **exa-search 适合**：
- 查最新研究论文 / 博客
- 查人物 / 公司背景
- 描述性查询（"X 是怎么工作的"）

❌ **其他更合适**：
- 库文档 → **context7**
- 维基概念 → **mcp-deepwiki**
- 指定 URL → **web_fetch**
- 实时新闻 → **web_search**

---

## 已知限制

- API key 配额（Exa 收费）
- `numResults` 越大费用越高
- 不返回中文搜索结果排序优化（英文为主）

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建