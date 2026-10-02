# TOOLS-mcp-think-tool.md — Think Tool MCP（4 工具）

> Think Tool 思考工具 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @cgize/mcp-think-tool`
- **包来源**：cgize 维护的 mcp-think-tool
- **工具数**：4
- **启动延迟**：4.4s
- **传输**：stdio
- **用途**：在主推理流中插入显式思考步骤

---

## 4 个工具

| 工具 | 用途 |
|------|------|
| `think` | 追加思考步骤（不进主推理流，单独日志）|
| `get_thoughts` | 取所有思考步骤 |
| `clear_thoughts` | 清空思考 |
| `get_thought_stats` | 思考统计 |

---

## 核心概念

"思考"是**显式的中间推理**，与对话中默认的隐藏推理不同：

- 默认推理：模型内部，仅最终答案可见
- Think Tool 推理：**结构化记录**，可被 `get_thoughts` 检索

**目的**：让复杂推理可追溯、可回放、可审计。

---

## 常用调用示例

```bash
# 追加一个思考步骤
mcporter call think-tool.think \
  thought="用户说要做 X，但 X 隐含 3 个子任务，需要先分解"

# 追加并修订前一个
mcporter call think-tool.think thought="修正：实际是 4 个子任务"

# 拿所有思考
mcporter call think-tool.get_thoughts

# 统计
mcporter call think-tool.get_thought_stats

# 清空（慎用）
mcporter call think-tool.clear_thoughts
```

---

## 何时使用

✅ **适合**：
- 长链路推理（每步可追溯）
- 多 Agent 协作（共享思考上下文）
- 复杂决策的"决策日志"

❌ **不适合**：
- 简单查询（直接答案就够）
- 性能敏感场景（每个 think 调用有延迟）

---

## 与 sequential-thinking 的区别

| 维度 | think-tool | sequential-thinking |
|------|-----------|---------------------|
| **记录方式** | 一次性追加 | 链式（带 nextThoughtNeeded）|
| **修订能力** | 否（追加不可改）| 是（带 revisesThought）|
| **分支能力** | 否 | 是（branchFromThought）|
| **完成标志** | 无 | `nextThoughtNeeded: false` |
| **适合** | 简单多步 | 复杂多步 + 可修正

---

## 已知限制

- 思考只是**字符串**，无结构化字段
- 思考会**累积**直到 `clear_thoughts`
- 不影响主推理流（主推理拿不到 think_tool 历史）

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建