# memory/imports/

外部编码助手的导入记忆落点（官方约定，见 `docs/concepts/memory.md`）。

## 来源

| 子目录 | 来源 |
|---|---|
| `codex/` | Codex CLI：`~/.codex/memories/MEMORY.md` + `memory_summary.md` |
| `claude-code/` | Claude Code：每个项目的 `auto-memory/` 目录 |
| `hermes/` | Hermes：`MEMORY.md` + `USER.md` |

## 当前状态

- **2026-09-29**：目录骨架创建（对齐官方文档）
- 0 份实际导入（待用户从 Control UI → Settings → Import Memory 触发）

## 规则

- 导入文件**不会**自动合并到 `MEMORY.md`——只参与 `memory_search` / `memory_get` 索引。
- 源文件保持原样，不修改。
- 启用 **Replace existing imports** 会做 verified pre-import backup。
