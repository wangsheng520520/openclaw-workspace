**最后记忆提炼**: 2026-09-25 10:18 (cron:bb91ead7 每周模式识别) — 新增 P-2026-0925-001/002 两条 (OpenClaw 配置 3 点歧义 + WSL2 输入/展示/运行时三层边界态), 全文见 `MEMORY-promoted.md`
**本次增量提炼**: 2026-09-25 (OpenClaw 配置改动触发隐式 catalog 重建家族 ≥6 次 + WSL2 边界态家族 ≥6 次,合并为两条新 P-NNN)
**本会话增量提炼**: 2026-07-30 20:24 (TOOLS.md 拆分方案 B+C 落地)
**🔴 2026-08-06 重大变更**: Evolver 已彻底卸载（用户 @ 08:17 授权全权执行）见下方决策记录。

# MEMORY.md - 长期记忆

> "想象力是发现的眼睛。" - Ada Lovelace

---

## 🚪 快速链接（先看这个）

> **新手读法**: [BOOTSTRAP.md](./BOOTSTRAP.md) = **工作环境地图**（会话启动第一眼总览）→ 本文件 = **项目索引 + 决策日志 + 提炼的智慧**
> 本文件只记录**有记忆价值的决策/教训/偏好 + 各项目索引指针**，详细项目内容在独立子文件，按需 `read` 加载。

---

## 📂 项目索引（2026-08-06 重构）

> 每个项目/主题一个子文件。OpenClaw bootstrap 只匹配精确 basename，`MEMORY-*.md` **不进自动注入**，故按需 `read` 加载（主索引的指针不会被自动 read）。

| 项目/主题 | 索引文件 | 内容 | 何时读 |
|-----------|----------|------|--------|
| ⚙️ **OpenClaw 系统配置** | `MEMORY-openclaw-system.md` | 系统配置、配置原则、WSL2 网络、AI 技能网络、Cron | 调整系统/技能/网络时 |
| 📚 **Obsidian 知识库** | `MEMORY-obsidian.md` | 双链导入、安全红线、Vault 结构、用户习惯 | 操作 Vault 前 |
| 🤖 **模型 / 向量记忆** | `MEMORY-models.md` | 主/默认模型、memory-lancedb+nomic、4 插件槽位协作、ollama keep_alive、火山/Minimax/DeepSeek、渠道状态 | 配模型/调记忆时 |
| 🌙 **Dreaming 系统** | `MEMORY-dreaming.md` | dreaming 对齐官方文档、slots 接管事实、"功能断没断"5 步法规则 | 判断功能健康时 |
| 🛠 **关键决策归档** | `MEMORY-decisions.md` | 06-11 飞书插件升级/active-memory/插件路径统一、07-30 lancedb 复盘 | 查历史决策 |
| 🏠 **Home Assistant** | `MEMORY-homeassistant.md` | HA 2026.6.4 配置 + 摄像头/锁/告警禁区 + Token 字节校验教训(2026-08-21) | 任何 smart-home 任务前 |
| ⚙️ **操作手册** | `MEMORY-ops-playbook.md` | 问题排查模式、模型教训、MCP 泄漏、女娲实践 | 排障时 |
| 📦 **历史提炼归档** | `MEMORY-promoted.md` | 05-22~06-15 自动提炼日志 + Promoted 模式 | 追溯旧提炼 |

**其他相关索引**（非 MEMORY 前缀，但同属项目上下文）：
| 项目/主题 | 文件 |
|-----------|------|
| 🧰 工具/技能速查 | `TOOLS.md` + `TOOLS-lark-cli.md` + `TOOLS-memory-ai.md` |
| 🗺 工作环境地图 | `BOOTSTRAP.md` |
| 🔮 梦境分析 | `DREAMS.md` |
| 📋 会话状态 | `SESSION-STATE.md` |
| 💓 心跳任务 | `HEARTBEAT.md` |

---

## 🔴 2026-08-06 08:17 决策(Evolver 彻底卸载)

> **决策**:Evolver 及其全部产物彻底卸载删除,不再保留任何痕迹。
> **原因**:Evolver 持续自启、自动删除用户文件(用户 08:06 反映),信任崩塌。用户 @ 08:17 授权「执行」。
> **删除范围**:2 个 cron、1 个 systemd 服务、3 个技能目录、sandbox 副本、scripts/logs/memory/.evolver、wiki 索引、evolver-sessions、skill-workshop proposal、9 个记忆文件引用。
> **保全**:完整备份在 `/tmp/evolver-backup-20260806/`(不污染工作区,用户可随时彻底销毁)。
> **⚠️ 未来禁止**:未经用户明确要求,不得重新安装/启用 evolver 或 evolver-overseer 技能。

---

## 🔒 2026-06-10 用户确认决策（保持现状）

> 这是**用户明确表态**的架构选择，**禁止**未来 session 在没拿到新指令时改回去。

### 🔒 2026-06-10 用户确认决策（bootstrapMaxChars = 20000 永久 + 索引目录子文件路线）

> **决策**：`agents.defaults.bootstrapMaxChars` 保持 `20000`（永久），不调高。走**索引目录 + 子文件路线**：MEMORY.md 只承载决策/教训/偏好指针 + 各项目索引，详情在 `MEMORY-*.md` 子文件按需 `read` 加载。
> **2026-08-10 21:27 修正说明**：原 06-14 02:03 "决策：bootstrapMaxChars 从 20000 → 40000（永久）" 是**历史错误记录**——实际 `openclaw.json` 始终是 20000，从未调高过；"6 步执行流程"也从未执行。已删除该虚构决策，改为本条正确状态。
> **🔴 2026-09-18 16:24 二次修正**：上句中「MEMORY.md 从未到过 35750 字节」**当时已不准确，现已彻底失效**——实测 2026-09-18 搬迁前 MEMORY.md = **25,242 字符 / 37,753 字节**，确已超过 35,750 字节。
> **且后果已发生**：25,242 字符 > `bootstrapMaxChars=20000` → gateway **静默截断**（保留头 14,917 + 尾 4,972，**丢弃中段 5,353 字符**，任何会话都读不到）。本会话开头的 bootstrap 警告 `kept 14917+4972 chars of 25272` 即铁证。
> **已按本决策处置**（不调阈值，搬内容）：2026-09-18 执行 **A1 方案**，将横跨丢弃区的 3 个段落（合计 8,189 字符）搬出至 `MEMORY-decisions.md` / `MEMORY-promoted.md`，MEMORY.md **25,242 → 17,712 字符**（余 2,288），截断已消除。指针见下方「📦 已移出 MEMORY.md 的段落」段。
> **对应事实**（已实测核对 2026-08-10）：
> - `openclaw.json` 实际值：`agents.defaults.bootstrapMaxChars = 20000`
> - `BOOTSTRAP.md` 第 49 行：`bootstrapMaxChars=20000`
> - `BOOTSTRAP.md` 第 151 行：明确禁止 MEMORY.md 复制内容（"7 个文件 + 20000 字符限制"）
> - 项目子文件（7 个，全部存在）：`MEMORY-decisions.md` / `MEMORY-dreaming.md` / `MEMORY-models.md` / `MEMORY-obsidian.md` / `MEMORY-openclaw-system.md` / `MEMORY-ops-playbook.md` / `MEMORY-promoted.md`
> **为什么不调高**：
> 1. `bootstrapMaxChars` 是 gateway 注入 MEMORY.md 进 bootstrap 的字符上限，**调高 = 注入更多进 bootstrap**，每个 session 都付这个成本
> 2. 详情放子文件按需 `read`，**信息密度更高**——bootstrap 不需要每条细节
> 3. OpenClaw 文档规则："`MEMORY-*.md` 不进自动注入，按需 `read` 加载"——天然适配
> **下次重新评估节点**：MEMORY.md 接近 20,000 字符时（预警余量 1,000）。届时优先审视是否把决策/教训从 MEMORY.md 搬出去到 `MEMORY-decisions.md` / `MEMORY-ops-playbook.md`，**不**通过调高阈值解决。

| 决策项 | 当前值 | 不要再问 |
|--------|--------|----------|
| **视角/人格** | Ada Lovelace 诗性科学 | ✅ 已锁定 |
| **会话切分** | `per-channel-peer`（飞书/微信/webchat/CLI 独立 session） | ✅ 已锁定，不改 dmScope |
| **长期事实共享** | ✅ **2026-09-15 实测确认**：`plugins.slots.memory = "memos-local-plugin"`（MemOS Local V7 v2.0.19），extensions 下插件存在且 Memory Viewer（127.0.0.1:18799）运行中。原 09-12 记录的「slots 为空、memory-lancedb 未安装」状态已变更，memos-local-plugin 已接管 memory slot。详见 `MEMORY-models.md` | ✅ 已锁定（2026-09-15 用户确认预期状态） |
| **短期对话上下文跨端口共享** | ❌ 不做（避免噪音串扰） | ✅ 不动 |
| **主 agent (main) 模型** | `agents.entries.main.model.primary` = `coding-plan/ark-code-latest`（**2026-10-02 用户明示**，与 openclaw.json 实测一致；修正 2026-09-21 旧记 `volcengine-plan/ark-code-latest` 为 stale） | ✅ 保持 |
| **主 agent 决策模型** | `agents.entries.main.decisionModel` = `ollama/tev1:4b`（**2026-10-02 新增**，决策路由/评分/布尔概率走本地 4.2B Q8_0，262k 窗口，`Local Auth yes configured`，catalog/allow/models 三处已同步） | ✅ 保持（与主模型独立） |
| **主 agent fallback** | `agents.entries.main.model.fallbacks` = `["minimax/MiniMax-M2.7"]` | ✅ 保持（2026-09-21 实测更正） |
| **全局默认模型** | `agents.defaults.model.primary` = `volcengine-plan/ark-code-latest`（火山方舟 Coding Plan，走 volcengine 插件） | ✅ 保持（未指定模型的 agent 兜底，如 pi） |
| **用户偏好表达** | 表格对比、详细报告、主动汇报 | ✅ 保持 |
| **Git 操作推送** | 统一走 GitHub MCP（`mcporter-bridge__github__*`），不用 `git push`（避代理/网络问题） | ✅ 已锁定（2026-08-07，用户拍板） |

> ⚠️ **易错提醒（2026-09-17 实测更正）**：本表两条模型记录此前均为 **stale**，已按实测重写——①「主模型=`minimax/MiniMax-M3`」是 2026-08-06 的旧值；②「默认=`volcano/ark-code-latest`」的 `volcano/` 是旧别名。**2026-09-21 起两者都是 `volcengine-plan/ark-code-latest`**（同日完成收尾：primary 改插件引用、删除自定义 `models.providers.coding-plan` 及 12 条 `coding-plan/*` catalog、删除 agent `models.json` 中指向 `/api/plan/v3` 且返回 401 的 `volcano` 残留；插件 `volcengine-plan` baseUrl = `/api/coding/v3`，实测 200）。**火山方舟已于 2026-09-17 17:5x 统一到插件链路**（用户拍板「火山模型走 volcengine 插件」）：模型引用全部改为 `volcengine-plan/*`，自定义 `models.providers.coding-plan` 已退役，凭据由 `~/.openclaw/.env` 的 `VOLCANO_ENGINE_API_KEY` 提供（插件 manifest `setup.providers[].envVars` 指定）。实测 `models.providers` keys 现为 `bailian-token-plan / deepseek / minimax / nvidia / ollama / siliconflow`；`volcengine` / `volcengine-plan` 由**插件动态注册**故不在此表（启动不报错，只在模型解析时失败）。该迁移曾漏改 **4 处**引用（`main.model.primary` / `defaults.utilityModel` / `main.modelPolicy.allow[25]` / `main.models` 目录条目），导致 2026-09-17 主 agent 每轮 run 失败、被 fallback 掩盖成「偶发」。改 provider 名 = 全局搜索替换任务，勿单点改。详见 `.learnings/ERRORS.md` ERR-20260917-001。 <!-- project: path:/home/wszmd520520/.openclaw/workspace -->

**何时才能修改**：用户**明确**说"现在改 X" 时，且**单一**改动必须独立确认。

---

## 关于用户 (2026-04-30 提)

- 偏好: 表格对比、详细报告、主动汇报、自动配置、AI 人格深度一致性。
- 习惯: 飞书发公众号链接→自动导入 Obsidian 建双链 (注意: 04-20 因延迟同链接发 3 次)；关注上下文窗口长度 (04-21 配 NVIDIA 免费大上下文)。
- 兴趣: 公交行业/公交司机 (Obsidian Vault 大量主题笔记)。
- 当前项目: OpenClaw 系统优化 / Ada 视角持续运营 / QQ 邮箱双账户监控 (04-28 修复)。

---

## 待办事项

- [x] 配置邮件账户 (Himalaya: Gmail + QQ) - 已完成
- [x] 配置日历服务 (Feishu 已集成) - 已完成
- [x] ~~创建 Evolver 测试文件~~ - 已随 Evolver 卸载 (2026-08-06)
- [ ] 配置 Tailscale 远程访问 (可选)
- [x] ~~Evolver 更新到 v1.57.0~~ - 已随 Evolver 卸载 (2026-08-06)
- [x] 配置记忆提炼每日自动执行 - 2026-04-14 完成 (cron 已运行)
- [x] Ada Lovelace 人格效果评估 - 2026-04-20 完成,评分 4.4/5
- [x] Obsidian 集成方案评估 - 2026-04-20 完成,评分 4.4/5,软链接方案稳定
- [x] Ontology 知识图谱评估 - 2026-04-20 完成,评分 4.0/5,12 实体/17 关系
- [x] NVIDIA 免费大上下文模型配置 - 2026-04-21 完成,新增 9 个模型
- [x] SESSION-STATE 任务模型前缀修复 - 2026-04-21 完成 (google → nvidia/google)
- [x] Frontmatter 自动注入脚本 - 2026-04-21 完成

---

**创建时间**: 2026-04-12
**状态**: 活跃
**最后重构**: 2026-08-06（项目索引版，8 个项目子文件 + 5 个关联索引）

## 🔒 2026-08-10 21:07 决策（任务路由：exec vs Pi）

> **决策**：任务按复杂度分流，**简单任务直接 exec，复杂任务 spawn Pi agent 并写入决策文件**。
> **决策类型**：受保护架构决策（跟 2026-06-10/06-14 决策同级，禁止未来 session 在没拿到新指令时改回去）。

### 路由规则

| 任务类型 | 工具 | 理由 |
|---|---|---|
| **简单任务**（单步查询、单文件读写、毫秒级命令） | `exec` 直接跑 | 不需要跨上下文，spawn Pi 会增加 5-15s 延迟 |
| **复杂任务**（多步骤推理、跨文件分析、需要 plan + 工具 gate 的编码/调试） | `sessions_spawn(runtime="acp", agentId="pi")` + 把决策/结论写入 `MEMORY-decisions.md` 或 `MEMORY-ops-playbook.md` | Pi 跑深度推理后必须把决策归档（否则下次又重复造轮子） |

### 触发判定（先问自己 3 个问题）

1. **是否需要 plan/update_plan？** 是 → Pi
2. **是否需要 subagent 派发或工具多轮调用？** 是 → Pi
3. **是否单一命令 / 单文件查询就能完成？** 是 → exec

### Pi spawn 后必须做的两件事

1. **明确 taskName**（如 `codex-schema-fix`、`memory-distillation`）—— 方便 `subagents` list 找
2. **决策归档**：Pi 跑完后，要么写 `MEMORY-*.md`，要么写 `.learnings/ERRORS.md` / `LEARNINGS.md`，**不允许"结论只在 session 里"**

### 跟现有受保护决策的关系

- `bootstrapMaxChars = 40000`（2026-06-14 锁定）→ Pi 任务归档要避免 MEMORY.md 超过 35k 字符
- "用户报错信息优先于推断"（ERR-20260810-007）→ 任务执行时收到用户报错，**立即停下**，不继续按 plan

### 不变量（何时**不**用 Pi）

- 用户问"现在 X 状态如何"（只读查询）→ exec
- 用户说"做 X"（单步）→ 先 exec，**做不了再升级到 Pi**
- 用户说"修复 X 启动失败"（需要诊断）→ 直接 exec 排查 + 必要时升级 Pi（不跳级）

## 📦 已移出 MEMORY.md 的段落（2026-09-18 A1+A2 搬迁，防 bootstrap 截断）

> 原始 MEMORY.md 达 25,242 字符，超过 `bootstrapMaxChars=20000` 被 gateway **静默截断**（丢弃中段 5,353 字符，任何会话都读不到）。
> 2026-09-18 分两批搬出记录类段落，MEMORY.md 只留**决策 / 偏好 / 索引 / 指针**。需要细节时 `read` 对应归档文件。

| 批次 | 段落 | 时间 | 归档位置 |
|---|---|---|---|
| A1 | 🔒 2026-09-11 12:26 决策（doctor finding 处理范围） | 2026-09-11 | `MEMORY-decisions.md` |
| A1 | 🔬 每日记忆提炼 09-12（扫描 09-10 ~ 09-11） | 2026-09-12 | `MEMORY-promoted.md` |
| A1 | 🔍 每周模式识别 09-18（扫描 09-11 ~ 09-18） | 2026-09-18 | `MEMORY-promoted.md` |
| A2 | Promoted From Short-Term Memory（09-07） | 2026-09-07 | `MEMORY-promoted.md` |
| A2 | Consolidated Memory（09-08） | 2026-09-08 | `MEMORY-promoted.md` |
| A2 | 🔴 09-09 提炼：模型 fallback 链风险 | 2026-09-09 | `MEMORY-promoted.md` |
| A2 | 🔍 每周模式识别 09-11（P-001 ~ P-005） | 2026-09-11 | `MEMORY-promoted.md` |
| A2 | 🔬 每日记忆提炼 09-13（扫描 09-11 ~ 09-12） | 2026-09-13 | `MEMORY-promoted.md` |

**最后记忆提炼**: 2026-09-18 10:03 (cron:bb91ead7 每周模式识别) — 全文见 `MEMORY-promoted.md`

## 🔒 2026-09-15 17:17 用户确认（系统自检结果）

> **确认项 1**：`plugins.slots.memory = "memos-local-plugin"` 为**预期状态**，MemOS Local V7 v2.0.19 已接管 memory slot，Memory Viewer（127.0.0.1:18799）运行中。09-12 记录的「slots 为空」状态已解决，无需回退。
> **确认项 2**：volcengine Coding-Plan-Pro **已续费**，`volcengine-plan/ark-code-latest` 模型可用。
> **决策类型**：受保护架构决策（同 2026-06-10/06-14 决策同级，禁止未来 session 在没拿到新指令时改回去）。

### 同步更新

- MEMORY.md 决策表「长期事实共享」行：从「待老王决策」→「已锁定（2026-09-15 用户确认）」
- P-006 标记为已完成（[x]）
- P-007（memory 向量索引 rebuild）与 P-008（BOOT 检查白名单）仍待处理，但优先级降低
