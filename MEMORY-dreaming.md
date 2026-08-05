# MEMORY-dreaming.md — Dreaming 系统决策与运行事实 (2026-08-05)

> 从 `MEMORY.md` 拆分出来的"Dreaming 系统"主题子文件 (2026-08-05)。
> 主题：Dreaming 系统对齐官方文档、slots/memory-lancedb 接管 dreaming 调度的事实认定、阈值回退官方默认、workaround 脚本清理。
> 主索引见 → `MEMORY.md`（"🔒 决策"段第 3 条）。
>
> **加载规则**：OpenClaw bootstrap 走精确 basename 匹配（看 `run-attempt-V636cwT5.js` 白名单），`MEMORY-*.md` 不在白名单，按需 `read` 加载。

---

## 🔒 2026-08-05 09:20 决策（Dreaming 系统对齐官方文档 + slots/memory-lancedb 接管 dreaming 调度的事实认定）

> **决策**：保持 `plugins.slots.memory = "memory-lancedb"` 不变；`plugins.entries.memory-core` 整块**保留作备用**（doctor 已知 1 条 warning）；deep phase 阈值回退官方默认；删除 `scripts/dream-runner.sh` + `scripts/dream-sweep.mjs`。
> **拍板人**：用户 @ 09:20 GMT+8，回应"有没有保留 memory-lancedb 又可以运行梦境系统的方法"——方向纠正了助手列 3 个方案代用户决策的做法。
> **执行流程**：备份 `/tmp/openclaw.json.bak-2026-08-05-0920` + `/tmp/dream-workaround-backup-2026-08-05-0920/` → python3 改 `phases.deep` 三个数字 → 删 2 个脚本 → `gateway restart` 热重载 → 三路验证 doctor/memory status/cron list。

### 事实认定（关键纠错，从此不再被质疑）

| 旧印象（错） | 实测真相 |
|---|---|
| memory-core disabled = dreaming 不工作 | memory-lancedb 接管 slot 后**自己实现 dreaming 调度** |
| slot 是互斥的，二选一才能跑 dreaming | slot 是"运行时所有权单一"，但 dreaming 功能归属由 slot owner 接管 |
| dreaming 必须切回 memory-core | **不要切回**——切回会毁掉 07-30 刚修好的 LanceDB bge-m3 链路 |

### 证据链

- `memory-lancedb@2026.7.1` 的 `openclaw.plugin.json` `configSchema.properties.dreaming = { "type": "object" }` 合法
- uiHints `dreaming.help`: "Optional dreaming config consumed when this plugin owns the memory slot"
- `openclaw memory status --deep` 实测：dreaming 全部 enabled、cron `b8abb9c5` 在跑、recall store 512 entries / 20 promoted
- 历史证据 `memory/2026-06-11-1353.md#L404`: "dreaming.enabled: true 在 memory-lancedb 块里也有，删 memory-core 不影响 Dreaming 功能"

### 当前 dreaming 真实配置（已生效）

- frequency: `0 3 * * *` Asia/Shanghai
- deep: `minScore=0.8 · minRecallCount=3 · minUniqueQueries=3 · recencyHalfLifeDays=14 · maxAgeDays=30 · maxPromotedSnippetTokens=160`（**完全 = 官方默认**，2026-08-05 09:20 从放宽值 0.6/2/2 回退）
- cron: `Memory Dreaming Promotion` (`b8abb9c5-525f-4d33-b4d4-932d9f91b29c`)

### 再次确认不可动摇的运行时事实

1. dream 报告写 `DREAMS.md` + `memory/dreaming/{light,rem,deep}/YYYY-MM-DD.md`
2. 持久晋升只写 `MEMORY.md`（仅 deep phase）
3. 机器状态：`memory/.dreams/`（phase-signals.json、short-term-recall.json、daily-ingestion.json、session-corpus/、events.jsonl）
4. **`memory-lancedb` 同时也是 dreaming slot owner**——这是 OpenClaw v2026.5.6+ 设计，不是 bug

### 未来禁止动作（除非用户明确改）

- ❌ 切 `plugins.slots.memory` 回 `memory-core`
- ❌ 删 `plugins.entries.memory-core` 整块（保留作"如果未来需要回退 slot"的快路径）
- ❌ 重新创建 `scripts/dream-*` workaround（memory-lancedb 已接管，workaround 无引用方）
- ❌ 助手列 N 个方案让用户"选 A/B/C"——必须先实测，先 memory_search 历史决策

---

## 🎯 "功能断没断"判断 5 步法（2026-08-05 立，永久规则，禁止跳过）

适用所有"怀疑某个功能是否还在工作"的判断。任何一步发现"功能在工作"，立刻停下，不要列方案让用户选。

| 步 | 维度 | 命令 / 路径 |
|---|---|---|
| 1 | **效果层** | `memory status --deep` / `cron list` / `doctor` 跑一遍看实际输出 |
| 2 | **配置层** | `cat <plugin>/openclaw.plugin.json` 看 schema 实际接受什么 key |
| 3 | **历史层** | `memory_search "功能名 + slot/disable/enable"` 找 3 个月内决策证据 |
| 4 | **代码层** | grep 引用方，搜 `~/.openclaw/extensions/<plugin>/dist` 运行时调用点 |
| 5 | **用户层** | 用户最近是否提过相关问题（反向证据） |

### 反面教材

**2026-08-05 09:11** —— 我凭推断列了 3 个方案（切 memory-core / 放弃 dreaming / 双 slot 实验），差点毁掉 07-30 刚修好的 LanceDB bge-m3 链路。
**纠偏时刻**：用户一句反问"有没有保留 memory-lancedb 又可以跑 dreaming 的方法"才纠偏。
**根因**：(a) 跳过 step 1（没跑 `memory status --deep` 看 dreaming 实际状态）；(b) 跳过 step 3（没 memory_search 找 06-11 那条 evidence）。
**预防**：本 5 步法固化为 AGENTS.md 第零定律的硬性补火，违反 = P-26 同级行为问题。

---

## 🔗 相关资源

| 类型 | 路径 |
|---|---|
| 官方文档 | `~/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw/docs/concepts/dreaming.md` |
| 配置参考 | `~/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw/docs/reference/memory-config.md`（#dreaming） |
| CLI 参考 | `~/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw/docs/cli/memory.md`（#dreaming） |
| memory-lancedb plugin.json | `/home/wszmd520520/.openclaw/npm/projects/.../memory-lancedb/openclaw.plugin.json` |
| 详细复盘 | `.learnings/LEARNINGS.md` 行 1101+（2026-08-05 09:20 条目） |
| DREAMS.md | `/home/wszmd520520/.openclaw/workspace/DREAMS.md`（dream diary 主输出） |
| 报告分目录 | `memory/dreaming/{light,rem,deep}/YYYY-MM-DD.md` |
| 机器状态 | `memory/.dreams/`（phase-signals / short-term-recall / daily-ingestion / session-corpus / events.jsonl） |
| 备份 1 | `/tmp/openclaw.json.bak-2026-08-05-0920`（改前 openclaw.json） |
| 备份 2 | `/tmp/dream-workaround-backup-2026-08-05-0920/`（删掉的 dream-* 脚本） |