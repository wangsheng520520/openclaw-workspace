**最后记忆提炼**: 2026-07-30 21:09 (MEMORY.md 拆分方案 A 落地)
**本次增量提炼**: 2026-06-14 02:03 (C 选项落地)
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
| 🤖 **模型 / 向量记忆** | `MEMORY-models.md` | 主/默认模型、memory-lancedb+bge-m3、火山/Minimax/DeepSeek、渠道状态 | 配模型/调记忆时 |
| 🧪 **Pi Agent (ACPX)** | `MEMORY-pi-agent.md` | 2026-08-05 C 路径配置 + mergeAgentRegistry bug + 5 步法调试 | Pi/ACP 相关 |
| 🌙 **Dreaming 系统** | `MEMORY-dreaming.md` | dreaming 对齐官方文档、slots 接管事实、"功能断没断"5 步法规则 | 判断功能健康时 |
| 🛠 **关键决策归档** | `MEMORY-decisions.md` | 06-11 飞书插件升级/active-memory/插件路径统一、07-30 lancedb 复盘 | 查历史决策 |
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

## 🔴 2026-08-06 08:17 决策（Evolver 彻底卸载）

> **决策**：Evolver 及其全部产物彻底卸载删除，不再保留任何痕迹。
> **原因**：Evolver 持续自启、自动删除用户文件（用户 08:06 反映），信任崩塌。用户 @ 08:17 授权「执行」。
> **删除范围**：2 个 cron、1 个 systemd 服务、3 个技能目录、sandbox 副本、scripts/logs/memory/.evolver、wiki 索引、evolver-sessions、skill-workshop proposal、9 个记忆文件引用。
> **保全**：完整备份在 `/tmp/evolver-backup-20260806/`（不污染工作区，用户可随时彻底销毁）。
> **⚠️ 未来禁止**：未经用户明确要求，不得重新安装/启用 evolver 或 evolver-overseer 技能。

---

## 🔒 2026-06-10 用户确认决策（保持现状）

> 这是**用户明确表态**的架构选择，**禁止**未来 session 在没拿到新指令时改回去。

### 🔒 2026-06-14 02:03 决策（bootstrapMaxChars 调高 + MEMORY.md 决策日志）

> **决策**：`agents.defaults.bootstrapMaxChars` 从 `20000` → `40000`（永久），不是临时绕过。
> **原因**：06-14 01:54:08 Gateway 警告 `MEMORY.md = 25617 chars, limit 20000 → truncated`。MEMORY.md 实际 35750 字节（含中文），3 次原调高记录（06-28 12k→25k, 本次 25k→40k）都因 MEMORY.md 持续增长。40k 阈值是给当前项目预留的 6+ 月裕量。
> **执行流程**（受保护字段，6 步）：
> 1. 备份 `openclaw.json` 到 `/tmp/openclaw-pre-bootstrap-max-chars-XXXXXX.json`
> 2. python3 直接编辑 `openclaw.json`（`config.patch` 不能改受保护字段）
> 3. `systemctl --user restart openclaw-gateway` 热重载
> 4. Gateway 监听 `14 plugins, 12.9s` 启动成功（不超 35s 超时）
> 5. 日志验证：`01:58:36` 之后无 `MEMORY.*truncat` 警告
> 6. 同步记录到 BOOT.md 第 52 行
> **为什么不反向优化 MEMORY.md 减肥**：MEMORY.md 是"决策日志 + 提炼的智慧"，压缩会丢用户拍板原话。用户拍板 C（决策 = 永久提阈值）而不是 B（减肥）。
> **下次重新评估节点**：MEMORY.md 超过 35,000 字符时（预警余量 5,000）。

| 决策项 | 当前值 | 不要再问 |
|--------|--------|----------|
| **视角/人格** | Ada Lovelace 诗性科学 | ✅ 已锁定 |
| **会话切分** | `per-channel-peer`（飞书/微信/webchat/CLI 独立 session） | ✅ 已锁定，不改 dmScope |
| **长期事实共享** | 走 `memory-lancedb`（memory/ + obsidian-vault 索引），已生效 | ✅ 不动 |
| **短期对话上下文跨端口共享** | ❌ 不做（避免噪音串扰） | ✅ 不动 |
| **主 agent (main) 模型** | `agents.list[0].model.primary` = `minimax/MiniMax-M3` | ✅ 保持（主会话/日常交互实际用这个） |
| **全局默认模型** | `agents.defaults.model.primary` = `volcano/ark-code-latest`（火山方舟 Ark） | ✅ 保持（未指定模型的 agent 兑底，如 pi） |
| **Pi Agent 模型** | 无 own model → 跟随全局默认 `volcano/ark-code-latest` | ✅ 已确认（2026-08-06 实测） |
| **用户偏好表达** | 表格对比、详细报告、主动汇报 | ✅ 保持 |
| **Pi Agent (ACPX) 入口** | `agents.list[].runtime.type="acp"`（C 路径） | ✅ 已锁定（2026-08-05） |
| **Git 操作推送** | 统一走 GitHub MCP（`mcporter-bridge__github__*`），不用 `git push`（避代理/网络问题） | ✅ 已锁定（2026-08-07，用户拍板） |

> ⚠️ **易错提醒**：全局默认 ≠ 主会话模型。此前错记「主模型=ark-code-latest / 默认=MiniMax-M3」已修正（2026-08-06 实测 openclaw.json）。`volcengine-plan/` 是旧别名，现已统一为 `volcano/`。详见 `MEMORY-models.md` 三层区分表。

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
