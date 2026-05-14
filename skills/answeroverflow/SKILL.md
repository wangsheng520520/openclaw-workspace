---
name: answeroverflow
description: |
  触发词：Discord问题、Discord社区讨论、开源库问题、代码报错、库文档找不到答案、
  Discord搜索、社区问答、Discord频道索引、开源项目支持频道
  场景：用户问及Discord中讨论过的技术问题、库的使用问题、代码报错解决方案
trigger: |
  - "Discord"
  - "discord.js" / "d.js" / "DSL"
  - "answeroverflow"
  - "开源库的奇怪bug"
  - "Discord社区"
inputs:
  - 用户的技术问题或错误信息
outputs:
  - Discord社区中原汁原味的讨论和解决方案
  - 线程链接和完整的对话上下文
---

# Answer Overflow Skill

> **评分改进目标**：Checkpoint × Boundary × Workflow × Frontmatter

## What is Answer Overflow?

Answer Overflow 索引了公开的 Discord 支持频道，使其可通过 Google 和直接 API 访问检索。非常适合查找那些**只在 Discord 对话中存在**的解决方案。

---

## Workflow（工作流程）

### Step 1 — 判断是否触发

**输入**：用户的自然语言问题
**判断依据**：是否涉及 Discord 社区讨论、Discord 索引频道、开源库问题（特别是 Discord.js、Prisma、Next.js 等有官方 Discord 的库）
**触发条件**：问题涉及 Discord 技术讨论、开源库使用问题、代码报错（尤其是其他搜索引擎找不到的）

> **Checkpoint 1**：如果问题明显是通用编程问题（非库特定问题），可跳过 Answer Overflow，提示用户直接搜索更高效。

---

### Step 2 — 执行搜索

**工具**：`web_search`（优先）或 MCP Server（备选）

**方式 A — Google 站内搜索（推荐）**
```bash
web_search "site:answeroverflow.com <搜索词>"
# 示例
web_search "site:answeroverflow.com discord.js slash commands"
```

**方式 B — MCP Server 搜索**（当 Google 结果不理想时）
```
MCP工具：search_answeroverflow
参数：query=<搜索词>, server_id=<可选>, channel_id=<可选>
```

> **Checkpoint 2**：如果搜索结果为空或质量低，切换到 Fallback（见下方）。

---

### Step 3 — 解析和筛选结果

**判断标准**：
- 线程是否包含完整的讨论上下文（问题→排查→解决）
- 回答者身份是否可靠（官方团队 vs 社区成员）
- 问题场景是否与用户情况匹配

**输出**：筛选后的线程链接列表（通常取前 3-5 个最相关结果）

---

### Step 4 — 获取详细内容（按需）

**工具**：`web_fetch`

```bash
web_fetch url="https://www.answeroverflow.com/m/<message-id>.md"
```

**替代方式**：在 URL 后加 `/m/` 前缀
```
https://www.answeroverflow.com/m/1234567890123456789
```

> **Checkpoint 3**：如果用户需要更深入的分析某个线程，在获取前确认是否需要（如结果已足够明确可跳过）。

---

### Step 5 — 整合输出

**输出格式**：
1. 简要总结：线程讨论的核心问题
2. 关键解决方案：社区达成的共识或解决方案
3. 原始链接：方便用户跳转查看完整上下文
4. 注意事项：Discord 对话的局限性说明

---

## Boundary（异常处理 & Fallback）

| 异常情况 | Fallback 方案 |
|---------|--------------|
| `web_search` 返回为空 | 尝试更通用的关键词，或使用 MCP `search_answeroverflow` |
| MCP Server 不可用 | 回退到 Google `site:answeroverflow.com` 搜索 |
| `web_fetch` 获取 markdown 失败 | 尝试不带 `.md` 后缀的 URL，或直接提供搜索结果中的摘要 |
| 搜索结果太旧（>1年） | 在结果后标注时间，提醒用户检查是否仍然适用 |
| 结果来自非官方社区频道 | 标注信息来源（官方支持 vs 社区），建议用户交叉验证 |

---

## URL Patterns（快速参考）

| 类型 | 格式 | 示例 |
|------|------|------|
| 线程 | `https://www.answeroverflow.com/m/<message-id>` | `/m/1234567890123456789` |
| 服务器 | `https://www.answeroverflow.com/c/<server-slug>` | `/c/prisma` |
| 频道 | `https://www.answeroverflow.com/c/<server-slug>/<channel-slug>` | `/c/prisma/General` |

## MCP Server 工具一览

| 工具 | 用途 | 适用场景 |
|------|------|---------|
| `search_answeroverflow` | 全站搜索 | 通用问题检索 |
| `search_servers` | 发现已索引的服务器 | 定向搜索特定社区 |
| `get_thread_messages` | 获取线程完整消息 | 需要深入分析某讨论时 |
| `find_similar_threads` | 找相似线程 | 主结果不够理想时 |

## 常用搜索示例

```bash
# Discord.js 相关
web_search "site:answeroverflow.com discord.js slash commands"

# Next.js 相关
web_search "site:answeroverflow.com nextjs app router error"

# Prisma 相关
web_search "site:answeroverflow.com prisma many-to-many"

# 泛搜索
web_search "site:answeroverflow.com <库名/框架名> <具体问题>"
```

## 局限性提示（使用前必读）

⚠️ **Discord 对话的固有限制**：
- 对话风格偏口语化、非正式
- 解决方案可能分散在多轮回复中
- 部分讨论可能未达成明确结论
- 信息时效性参差不齐

💡 **建议**：将 Answer Overflow 结果作为**补充参考**，结合官方文档或其他权威资源综合判断。

## Links

- **官网**：https://www.answeroverflow.com
- **文档**：https://docs.answeroverflow.com
- **MCP Server**：https://www.answeroverflow.com/mcp
- **Discord 社区**：https://discord.answeroverflow.com
