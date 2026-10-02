# TOOLS-mcp-memory.md — Memory 知识图谱 MCP（9 工具）

> Memory 知识图谱 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @modelcontextprotocol/server-memory`
- **包来源**：Anthropic 官方 @modelcontextprotocol/server-memory
- **工具数**：9
- **启动延迟**：4.5s
- **传输**：stdio
- **持久化**：本地 JSON / SQLite（看配置）

---

## 9 个工具

| 工具 | 用途 |
|------|------|
| `create_entities` | 批量创建实体（带 observations） |
| `create_relations` | 批量创建关系（主动语态）|
| `add_observations` | 给实体加观察 |
| `delete_entities` | 删除实体（含关联关系）|
| `delete_observations` | 删除特定观察 |
| `delete_relations` | 删除特定关系 |
| `search_nodes` | 语义搜索节点 |
| `open_nodes` | 按名字打开节点 |
| `read_graph` | 读整个图 |

---

## 核心概念

**Entity（实体）**：知识图谱的节点，含 `name` / `entityType` / `observations[]`。
**Relation（关系）**：实体间的边，含 `from` / `to` / `relationType`。
**Observation（观察）**：实体的文本描述片段（数组，可累加）。

---

## 常用调用示例

```bash
# 创建实体（用户 + 项目）
mcporter call Memory.create_entities entities='[
  {"name":"张三","entityType":"Person","observations":["AI 研究员","住在武汉"]},
  {"name":"Ada视角项目","entityType":"Project","observations":["女娲造人术","诗性科学"]}
]'

# 创建关系（张三在做 Ada视角项目）
mcporter call Memory.create_relations relations='[
  {"from":"张三","relationType":"works_on","to":"Ada视角项目"}
]'

# 追加观察
mcporter call Memory.add_observations observations='[
  {"entityName":"Ada视角项目","contents":["2026-04-14 v2.0 上线"]}
]'

# 语义搜索
mcporter call Memory.search_nodes query="AI研究员"

# 按名字打开节点
mcporter call Memory.open_nodes names='["张三","Ada视角项目"]'

# 读整个图
mcporter call Memory.read_graph

# 删除实体（含关系级联）
mcporter call Memory.delete_entities entityNames='["旧项目"]'
```

---

## 与其他记忆系统的关系

| 系统 | 关系 |
|------|------|
| **Obsidian Vault** | Memory 是结构化图谱，Obsidian 是 Markdown 文件 |
| **MEMORY.md / 工作记忆文件** | 文档型，Memory 是图谱型 |
| **memos_local_plugin**（OpenClaw 槽位） | 替代品？或互补？实际 OpenClaw 已用 memos-local-plugin 接管 memory slot（详见 `MEMORY-models.md` 09-15 决策） |

---

## 何时使用

✅ **适合**：
- 项目实体/关系/进度跟踪
- 人物关系图谱
- 跨会话知识累加

❌ **不适合**：
- 大段文档存储（用 Obsidian）
- 全文检索（用 Lucene / 内存向量）
- 实时高频写入（图谱查询延迟较高）

---

## 已知限制

- 实体名是主键，**重复名会被忽略**而非报错
- 删除实体级联删除所有关系
- observations 是纯文本，**无结构**（避免存 JSON 在内）

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建