# TOOLS-mcp-sequential-thinking.md — Sequential Thinking MCP（1 工具）

> Sequential Thinking 顺序推理 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @modelcontextprotocol/server-sequential-thinking`
- **包来源**：Anthropic 官方顺序推理
- **工具数**：1
- **启动延迟**：4.4s
- **传输**：stdio

---

## 1 个工具

`sequentialthinking` — 带元数据的链式思考

---

## 核心参数

| 参数 | 类型 | 用途 |
|------|------|------|
| `thought` | string | 当前思考内容 |
| `thoughtNumber` | int | 当前步号（1-based）|
| `totalThoughts` | int | 预估总步数（可动态调）|
| `nextThoughtNeeded` | bool | 是否需要下一步 |
| `isRevision` | bool | 是否修订前一步 |
| `revisesThought` | int | 修订哪一步 |
| `branchFromThought` | int | 从哪一步分支 |
| `branchId` | string | 分支标识 |
| `needsMoreThoughts` | bool | 是否需要追加步数 |

---

## 常用调用示例

```bash
# 第 1 步（基线）
mcporter call sequential-thinking.sequentialthinking \
  thought="问题本质是 Y，分解为 3 子任务" \
  thoughtNumber=1 totalThoughts=3 nextThoughtNeeded=true

# 第 2 步（继续）
mcporter call sequential-thinking.sequentialthinking \
  thought="子任务 1：先验证 A" \
  thoughtNumber=2 totalThoughts=3 nextThoughtNeeded=true

# 修订第 1 步（修正基线）
mcporter call sequential-thinking.sequentialthinking \
  thought="修正：实际是 4 子任务" \
  thoughtNumber=3 totalThoughts=4 \
  isRevision=true revisesThought=1 nextThoughtNeeded=true

# 分支（探索替代路径）
mcporter call sequential-thinking.sequentialthinking \
  thought="分支 A：假设 X 不成立，结果..." \
  thoughtNumber=4 totalThoughts=5 \
  branchFromThought=2 branchId="alt-A" nextThoughtNeeded=true

# 最后一步（封口）
mcporter call sequential-thinking.sequentialthinking \
  thought="综合结论：采取方案 B" \
  thoughtNumber=5 totalThoughts=5 nextThoughtNeeded=false
```

---

## 何时使用

✅ **适合**：
- 复杂多步推理（10+ 步）
- 中途发现需要修正基线
- 探索多条分支路径
- 把推理过程留作可审计日志

❌ **不适合**：
- 简单问题（用 think-tool 即可）
- 一次性决策（直接推理更快）

---

## 与 think-tool 的对比

| 维度 | sequential-thinking | think-tool |
|------|--------------------|-----------:|
| **结构** | 链式 + 元数据 | 简单追加 |
| **修订** | ✅ `revisesThought` | ❌ |
| **分支** | ✅ `branchFromThought` | ❌ |
| **完成标志** | ✅ `nextThoughtNeeded` | ❌ |
| **适合场景** | 复杂 + 多修正 + 多分支 | 简单多步 |

---

## 已知限制

- 单工具多参数易传错 → 调用前必查 schema
- 修订/分支会**保留旧条目**，不会清除（历史完整）
- `branchId` 字符串需要稳定命名（用于回溯）

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建