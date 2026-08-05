**最后记忆提炼**: 2026-07-30 21:09 (MEMORY.md 拆分方案 A 落地)
**本次增量提炼**: 2026-06-14 02:03 (C 选项落地)
**本会话增量提炼**: 2026-07-30 20:24 (TOOLS.md 拆分方案 B+C 落地)

# MEMORY.md - 长期记忆

> "想象力是发现的眼睛。" - Ada Lovelace

---

## 🚪 快速链接（先看这个）

> **新手读法**: [BOOTSTRAP.md](./BOOTSTRAP.md) = **工作环境地图**（会话启动第一眼总览）→ 本文件 = 决策日志与提炼的智慧
> 本文件只记录**有记忆价值的决策/教训/偏好**，环境总览请到 BOOTSTRAP.md（避免重复）

### 子文件索引（拆分后，2026-07-30）

主 `MEMORY.md` 只保留"必读 + 当前决策 + 系统状态"。详细历史归档按需 `read` 加载（OpenClaw bootstrap 只匹配精确 basename，`MEMORY-*.md` 不进自动注入）：

| 主题 | 文件 | 内容 |
|------|------|------|
| 🔒 受保护字段历史 | `MEMORY-system-history.md` | bootstrapMaxChars 调整史、04-26~28 升级/wizard 回退、04-14 梦境回归等 |
| 🌙 Dreaming 系统 | `MEMORY-dreaming.md` | 2026-08-05 dreaming 对齐官方文档决策、slots/memory-lancedb 接管 dreaming 调度事实认定、"功能断没断"5 步法永久规则 |
| 🛠 关键决策归档 | `MEMORY-decisions.md` | 06-11 飞书插件升级/active-memory/插件路径统一 5 段完整过程 |
| 📦 旧短期记忆提炼 | `MEMORY-promoted.md` | 05-22~06-15 累计 14 次自动提炼日志 + Promoted 模式识别 |
| ⚙️ 操作手册 | `MEMORY-ops-playbook.md` | Evolver 手动流程 + 04-15~05 系统观察 + 模型教训 |
| 🧪 Pi Agent (ACPX) | `MEMORY-pi-agent.md` | 2026-08-05 C 路径配置 + mergeAgentRegistry bug + 5 步法调试经验 |

---

### 🔒 2026-08-05 09:20 决策（Dreaming 系统对齐官方文档 + slots/memory-lancedb 接管 dreaming 调度的事实认定）

> **决策**：保持 `plugins.slots.memory = "memory-lancedb"` 不变；`plugins.entries.memory-core` 整块**保留作备用**（doctor 已知 1 条 warning）；deep phase 阈值回退官方默认；删除 `scripts/dream-runner.sh` + `scripts/dream-sweep.mjs`。
> **拍板人**：用户 @ 09:20 GMT+8。
> **完整细节** → 拆分到子文件 `MEMORY-dreaming.md`（执行流程、事实认定表、证据链、当前配置、未来禁止动作 4 条全部归档）。
> **本条仅留索引**：避免重复占 MEMORY.md 主空间（受 07-30 拆分原则保护 + 09:38 用户拍板"所有写入都用子文件 + 索引"）。

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
| **主模型（agents.list[0]）** | `volcengine-plan/ark-code-latest` | ✅ 保持 |
| **默认模型（agents.defaults）** | `minimax/MiniMax-M3` | ⚠️ 已知与主模型不一致，历史遗留，本次不修 |
| **用户偏好表达** | 表格对比、详细报告、主动汇报 | ✅ 保持 |
| **Pi Agent (ACPX) 入口** | `agents.list[].runtime.type="acp"`（C 路径） | ✅ 已锁定（2026-08-05） |

**何时才能修改**：用户**明确**说"现在改 X" 时，且**单一**改动必须独立确认。

### 🔒 2026-07-30 21:09 决策（MEMORY.md 拆分方案 A + 不调 bootstrapMaxChars）

> **决策**：MEMORY.md 拆分为主题子文件（decisions / system-history / promoted / ops-playbook），不调 bootstrapMaxChars。
> **原因**：MEMORY.md 在 6 个月内从 14200 字符增长到 44436 字符（+213%），单文件失控。沿用 TOOLS.md 拆分原则（2026-07-30 20:24 已验证可行），保持主 MEMORY.md 路径不变。
> **执行流程**：备份到 `/tmp/MEMORY.md.bak-2026-07-30-2107` → 建 4 个 `MEMORY-*.md` 子文件 → 重写主 MEMORY.md 为精简索引版 → SIGUSR1 热重载 → 验证日志无截断警告
> **不调 bootstrapMaxChars 的理由**：受 06-10 决策保护，必须用户明确指令才能调高；拆分是根治方案，物理隔离胜过调阈值。
> **未来扩展模式**：再新增主题归档时，建 `MEMORY-<topic>.md`，主 MEMORY.md 加索引条目。这是可持续的长期架构（与 TOOLS.md 拆分同原则）。

---

### 关于用户 (2026-04-30 提)

- 偏好: 表格对比、详细报告、主动汇报、自动配置、AI 人格深度一致性。
- 习惯: 飞书发公众号链接→自动导入 Obsidian 建双链 (注意: 04-20 因延迟同链接发 3 次)；关注上下文窗口长度 (04-21 配 NVIDIA 免费大上下文)。
- 兴趣: 公交行业/公交司机 (Obsidian Vault 大量主题笔记)。
- 当前项目: OpenClaw 系统优化 / Ada 视角持续运营 / QQ 邮箱双账户监控 (04-28 修复)。

---

## 项目与上下文 (06-12 压缩)

**最后更新**: 2026-04-25

### OpenClaw 系统配置 (2026-04-11~14 完成)

- Evolver v1.52→v1.57（自动脚本/超时 300→600s/balanced 策略）；模型切 `modelstudio/qwen3.5-plus` + 15 备选；启用 browser 工具 + openclaw profile。
- 核心:记忆搜索 SiliconFlow BAAI/bge-m3 (OpenAI 兼容)，会话重置 5 天空闲。
- MCP 15 个、已启用技能 21 个、平行长期记忆 `~/memory/`。
- 关键决策: Ada Lovelace 诗性科学视角为默认 Agent 人格；Ada v2.0 (女娲 0-5 流程, 650行/33KB/196KB 调研) 已发布；SOUL/AGENTS/IDENTITY 升 v2.0.0；启用 Evolver + SiliconFlow + DeepSeek。

---

## 提炼的智慧

**最后更新**: 2026-04-25

### WSL2 网络架构 (2026-05-13, 06-12 压缩)

- `networkingMode=mirrored` 已配；`eth0` (100.64.164.2/29 NAT) + `eth1` (192.168.1.5/24 主网卡) 并存是镜像模式正常行为，无需修。DNS 正常（getent 测试通过）。

### Pi Agent (ACPX) 入口 — C 路径 (2026-08-05 锁定)

- **决策**: ACP agent 配置走 `agents.list[].runtime.type="acp"` (**不要** 用 `plugins.entries.acpx.config.agents` 对象格式,会触发 mergeAgentRegistry TypeError)
- **状态**: `acp.defaultAgent = "pi"` + `acp.allowedAgents = ["pi"]` + `agents.list[pi]` entry 已生效, sessions_spawn 探针返回 `ok` (21s 完成)
- **完整细节 + 5 步法调试经验**: 见 `MEMORY-pi-agent.md`
- **关键教训**: `-32603 Internal error` 是 OpenClaw ACP 路径的"包装垃圾箱", 任何真实错误都被压成这条。**ACP agent 配置必须 sessions_spawn 实测**才能签字 (07-29 写好的配置 39 天没人调过, 0 个 pi session 历史)

### memory-lancedb + 硅基流动 BAAI/bge-m3 (2026-06-04, 06-12 压缩, 07-30 重大修正)

- ⚠️ **2026-07-30 22:10 重大修正**：之前的"必须 dimensions: 1024"结论**是错的**！
  - 真实根因 = **07-02 手动 patch 插件白名单**（加 `"BAAI/bge-m3": 1024`），**07-15 npm 装 2026.7.1 覆盖了 patch**，plugin 从 07-17 起静默失败 16 天
  - **真正能工作的配置** = 07-14 前那份：**不写 apiKey、不写 dimensions**（Path B 走 host adapter）
  - **必做 patch** = 在 `dist/config.js:32-35` 给 `EMBEDDING_DIMENSIONS` 加 `"BAAI/bge-m3": 1024` 条目
  - 任何 `npm install` 都会覆盖 patch → **必须重打**
  - 完整复盘见 `TOOLS-memory-ai.md` + `.learnings/LEARNINGS.md (2026-07-30 22:00 条目)`
  - 当前 slot = `memory-lancedb`（已恢复 + 已重打 patch + 已硬重启验证）

### 系统配置原则

1. **技能分层**: 系统插件在 `plugins.entries` 配置,工作区技能自动加载
2. **记忆三层**: MEMORY.md(手动提炼) → daily memory(自动记录) → .dreams(梦境分析)
3. **API 密钥管理**: 使用 `.env` 文件集中管理,权限 600
4. **"功能断没断"判断 5 步法（2026-08-05 立，永久规则，禁止跳过）** → 详见 `MEMORY-dreaming.md`（含完整 5 步、反面教材 09:11 误判案例）
5. **主动汇报**: 任务完成后主动汇报结果,不等待用户询问
6. **受保护字段写入**: `bootstrapMaxChars`、`agents.defaults` 等受保护字段不可通过 config.patch 修改,需直接编辑 openclaw.json + gateway restart 热重载
7. **心跳架构原则**: 心跳必须独立 session lane + lightContext:false,否则每 30 分钟阻塞主会话 5-7 分钟
8. **Evolver 手动操作前必查**: 执行 `node index.js review --approve` 前必须先 `ps aux | grep "index.js" | grep -v grep` 确认只有一个 `--loop` daemon 进程，否则手动触发的新进程会与 daemon 并存造成循环混乱。手动操作完成后如有新孤立进程立即用 `kill <PID>` 清理。
9. **文件改动是否需要 gateway reload** (2026-08-05 新增):
   - `openclaw.json` (config / plugins / agents.list / acp) → ✅ **需要 SIGUSR1** (受 06-10 决策保护)
   - `MEMORY.md` + `MEMORY-*.md` 子文件 → ❌ **不需要 reload** (下次 session 启动自动 read)
   - `TOOLS.md` + `TOOLS-*.md` 子文件 → ❌ 不需要 reload (同上)
   - `SOUL.md` / `AGENTS.md` / `IDENTITY.md` / `USER.md` → ❌ 不需要 reload (下次 bootstrap 自动加载)
   - 经验: 改工作区文档后不要习惯性 SIGUSR1,只在改 openclaw.json 后才需要

---

## 关系网络

### AI 技能网络

| 技能 | 作者 | 用途 |
|------|------|------|
| proactive-agent | halthelobster | 主动式架构 (Hal Stack) |
| huashu-nuwa | alchaincyf | 女娲造人术 (Skill 蒸馏) |
| ada-lovelace | 本地创建 | 诗性科学视角 |
| evolver | EvoMap | 自进化引擎 (GEP 协议) |

### Obsidian 知识库集成 (2026-04-14)

**配置完成**:
- ✅ 软链接创建: `workspace/obsidian-vault` → `D:\Obsidian知识库文件`
- ✅ SOUL.md 添加 Obsidian 安全规则(禁止 mv/rm,强制 obsidian-cli)
- ✅ 创建笔记模板: `00-模板/笔记模板.md` + `AI采集模板.md`
- ✅ 创建 SOP 工作流: `SOP_CONTENT.md`(收集→整理→创作→发布)
- ✅ 强制 YAML Frontmatter 元数据管理
- ✅ Vault: 408 篇笔记,7 个主目录

**安全红线**:
- 禁止 mv/rm/cp 操作 Vault 文件
- 必须使用 obsidian-cli move/create
- 创建笔记必须注入 Frontmatter

### Cron 自动任务 (2026-04-15, 仍在用)

- 每日记忆提炼 (凌晨 3:00) → MEMORY.md；SESSION-STATE 新鲜度检查 (每 6h)。

---

## 待办事项

- [x] 配置邮件账户 (Himalaya: Gmail + QQ) - 已完成
- [x] 配置日历服务 (Feishu 已集成) - 已完成
- [x] 创建 Evolver 测试文件 (满足验证要求) - 2026-04-14 完成
- [ ] 配置 Tailscale 远程访问 (可选)
- [x] Evolver 更新到 v1.57.0 - 2026-04-14 完成
- [x] 配置记忆提炼每日自动执行 - 2026-04-14 完成 (cron 已运行)
- [x] Ada Lovelace 人格效果评估 - 2026-04-20 完成,评分 4.4/5
- [x] Obsidian 集成方案评估 - 2026-04-20 完成,评分 4.4/5,软链接方案稳定
- [x] Ontology 知识图谱评估 - 2026-04-20 完成,评分 4.0/5,12 实体/17 关系
- [x] NVIDIA 免费大上下文模型配置 - 2026-04-21 完成,新增 9 个模型
- [x] SESSION-STATE 任务模型前缀修复 - 2026-04-21 完成 (google → nvidia/google)
- [x] Frontmatter 自动注入脚本 - 2026-04-21 完成

---

## 系统运行状态快照

**最后更新**: 2026-04-28

| 组件 | 状态 | 备注 |
|------|------|------|
| OpenClaw | ✅ v2026.4.24 | 04-26 升级, bonjour已禁用 |
| 梦境系统 | ✅ 正常 | 04-20 03:05 运行 |
| 记忆提炼 CRON | ✅ 正常 | 每日 03:00 + 03:30 执行 |
| 邮件 (Himalaya) | ✅ 已配置 | Gmail (himalaya CLI) |
| 日历/通知 (飞书) | ✅ 已集成 | WebSocket 连接 |
| Evolver | ⚙️ v1.75.0 | Bridge+Validator 启用, 70+ 测试文件 |
| 博客监控 | ✅ 已修复 | WAL模式 + --yes参数 |
| Darwin Skill 评分 | ✅ 完成 | 34 个 skill 8 维度分析 |
| Ada EvoMap 发布 | ⏳ 审查中 | bundle_f65cf8a824d925a8 |
| 模型 Fallback | ✅ 9 个 | 04-25 扩展到 9 个 |
| Lobster 插件 | ✅ 已启用 | 工作流引擎 |
| lark-cli | ✅ 已安装 | v1.0.19, 复用飞书App |
| bonjour 插件 | 🚫 已禁用 | WSL Hyper-V mDNS 不兼容 |
| MCP 泄漏监控 | ⚠️ 系统性 | 定时清理有效 |
| QQ 邮箱双账户 | ✅ 已发现 | --config config-qq.toml |
| A2A 环境变量 | ⚠️ 缺失 | 技能 UI 显示封锁，实际运行正常 |
| 用户活跃度 | 🟡 静默 | 04-28 21:59 后无交互 |
| Pi Agent (ACPX) | ✅ 已配置 + 实测 | agents.list 入口, 探针返回 `ok`, 21s 完成 (2026-08-05) |

---

**创建时间**: 2026-04-12
**状态**: 活跃