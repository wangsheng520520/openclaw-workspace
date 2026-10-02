# MEMORY-openclaw-system.md — OpenClaw 系统配置档案

> 从 `MEMORY.md` 拆分出的 "OpenClaw 系统配置 / 系统配置原则 / 关系网络 / WSL2 网络 / Cron 自动任务" 子域 (2026-08-06)。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：`MEMORY-*.md` 不自动注入，按需 `read` 加载。

---

## ⛔ 当前权威事实 (2026-08-16 实测, 防止 recall 漂移)

> **本节优先级最高** — 当 active_memory plugin 从历史档案/dreaming 报告召回出过时的 "OpenClaw v2026.5.28 / Node v24.14.1 / /usr/lib/node_modules/openclaw" 等描述时，**以本节为准**。下面所有"系统配置原则/网络/Cron"段都是当前生效版本。

| 字段 | 当前权威值 (2026-08-16 01:08 GMT+8 实测) | 来源 |
|---|---|---|
| **OpenClaw 版本** | `OpenClaw 2026.7.1-2 (0790d9f)` | `openclaw --version` + `package.json` |
| **Node.js 版本** | `v24.15.0` | `node --version`（WSL2）|
| **OpenClaw 安装路径** | `~/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw`（npm 全局安装到 nvm Node 24.15.0，不是 systemd 系统路径 `/usr/lib/node_modules/openclaw`）| `realpath $(which openclaw)` |
| **启动方式** | `npm install -g openclaw@latest` → 通过 `node` 调 `openclaw.mjs`，**不再**有 systemd service | `package.json` bin 字段 |
| **配置路径** | `~/.openclaw/openclaw.json`（默认） | 默认 schema |
| **plugin 版本矩阵** | 主包 `2026.7.1-2` / stock + tracked plugins `2026.7.1`（patch 0, plugin 滞后）/ weixin `2.4.3` | `openclaw plugins list --json` |

### 历史路径漂移（仅作时间线参考，不要误用为现状）

| 时间段 | 安装路径 | 备注 |
|---|---|---|
| 2026-04-12 ~ 2026-04-30 | `/usr/lib/node_modules/openclaw` + systemd ExecStart | 当时为系统级 npm 全局安装 |
| 2026-05-01 ~ 2026-05-08 | 切到 `~/.npm-global/bin/openclaw` 后又改回 systemd | 多次反复 |
| 2026-05-13 ~ 现在 | **nvm Node 24.x + npm 全局**（`~/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw`）| WSL2 + nvm 路线，无 systemd |

> ⚠️ 上述 3 段时间线**全部正确** — 历史档案 `memory/archive/2026-04-12.md` 到 `memory/dreaming/light/2026-06-06.md` 记载的事实**当时为真**。`<relevant-memories>` 召回时把它们当成"当前事实"展示，是 recall 系统的"时间锚点漂移"，**不是**档案事实错误。**不要修改历史档案**。

### 2026-08-16 compaction 对齐（最近一次配置变更）

- `agents.defaults.compaction.truncateAfterCompaction: false → true`
- 原因：`maxActiveTranscriptBytes: "1mb"` byte guard 被 `truncateAfterCompaction: false` 废掉，对齐 OpenClaw 2026.7.1-2 官方文档（`docs/concepts/compaction.md` L88-92）
- 备份：`/tmp/openclaw.json.bak-2026-08-16-0112`
- 验证：`openclaw config get agents.defaults.compaction` 返回 `truncateAfterCompaction:true`
- 配套报告：`.learnings/2026-08-16-openclaw-2026.7.1-2-alignment.md`

---

## OpenClaw 系统配置 (2026-04-11~14 完成)

- Evolver v1.52→v1.57（已于 2026-08-06 卸载）；模型切 `modelstudio/qwen3.5-plus` + 15 备选；启用 browser 工具 + openclaw profile。
- 核心:记忆搜索 SiliconFlow BAAI/bge-m3 (OpenAI 兼容)，会话重置 5 天空闲。
- MCP 15 个、已启用技能 21 个、平行长期记忆 `~/memory/`。
- 关键决策: Ada Lovelace 诗性科学视角为默认 Agent 人格；Ada v2.0 (女娲 0-5 流程, 650行/33KB/196KB 调研) 已发布；SOUL/AGENTS/IDENTITY 升 v2.0.0；启用 SiliconFlow + DeepSeek。

---

## 系统配置原则

1. **技能分层**: 系统插件在 `plugins.entries` 配置,工作区技能自动加载
2. **记忆三层**: MEMORY.md(手动提炼) → daily memory(自动记录) → .dreams(梦境分析)
3. **API 密钥管理**: 使用 `.env` 文件集中管理,权限 600
4. **"功能断没断"判断 5 步法（2026-08-05 立，永久规则，禁止跳过）** → 详见 `MEMORY-dreaming.md`（含完整 5 步、反面教材 09:11 误判案例）
5. **主动汇报**: 任务完成后主动汇报结果,不等待用户询问
6. **受保护字段写入**: `bootstrapMaxChars`、`agents.defaults` 等受保护字段不可通过 config.patch 修改,需直接编辑 openclaw.json + gateway restart 热重载
7. **心跳架构原则**: 心跳必须独立 session lane + lightContext:false,否则每 30 分钟阻塞主会话 5-7 分钟
8. **自进化引擎已卸载 (2026-08-06)**: Evolver 因自启删文件被彻底移除。若未来调试 `--loop` daemon 类进程，执行前先 `ps aux | grep "index.js" | grep -v grep` 确认唯一实例，避免多进程并存。
9. **EvoMap 节点凭据已清 (2026-08-07 10:34)**: `~/.evomap/` 9 个凭据 (node_id/secret/oauth_token/mailbox 等) 已删; 备份在 `/tmp/evomap-backup-20260807-1031/`。**未来若重连 EvoMap Hub**: 需重新走 OAuth + 拿新 node_id (旧 `74c0d023894c` 已作废)。检查项: `crontab -l | grep evomap` (应为 0) + `systemctl --user list-units | grep evomap` (应为 0) + `ps aux | grep evomap` (应为 0)。
10. **文件改动是否需要 gateway reload** (2026-08-05 新增):
   - `openclaw.json` (config / plugins / agents.list / acp) → ✅ **需要 SIGUSR1** (受 06-10 决策保护)
   - `MEMORY.md` + `MEMORY-*.md` 子文件 → ❌ **不需要 reload** (下次 session 启动自动 read)
   - `TOOLS.md` + `TOOLS-*.md` 子文件 → ❌ 不需要 reload (同上)
   - `SOUL.md` / `AGENTS.md` / `IDENTITY.md` / `USER.md` → ❌ 不需要 reload (下次 bootstrap 自动加载)
   - 经验: 改工作区文档后不要习惯性 SIGUSR1,只在改 openclaw.json 后才需要

---

## WSL2 网络架构 (2026-05-13, 06-12 压缩)

- `networkingMode=mirrored` 已配；`eth0` (100.64.164.2/29 NAT) + `eth1` (192.168.1.5/24 主网卡) 并存是镜像模式正常行为，无需修。DNS 正常（getent 测试通过）。

---

## 关系网络

### AI 技能网络

| 技能 | 作者 | 用途 |
|------|------|------|
| proactive-agent | halthelobster | 主动式架构 (Hal Stack) |
| huashu-nuwa | alchaincyf | 女娲造人术 (Skill 蒸馏) |
| ada-lovelace | 本地创建 | 诗性科学视角 |
| evolver | EvoMap | 自进化引擎 (GEP 协议) — 🔴 已于 2026-08-06 卸载 |
| evomap-node | EvoMap | evolver 连 Hub 节点凭据 (node_id=`74c0d023894c`, 9 文件) — 🔴 已于 2026-08-07 10:34 部分清理; 2026-08-16 04:08 Y3+Y5 完成最终清理（4 个源头：workspace .env / env-override.conf / openclaw.json env 段 / gateway.systemd.env + service unit 主 unit 2 行 Environment）；备份 `/tmp/evomap-backup-20260807-1031/` + `/tmp/y-cleanup-archive-20260816-040752/` (chmod 600 + 真 secret redacted)；A2A_HUB_URL 已从所有源头删除 |

---

## Cron 自动任务 (2026-04-15, 仍在用)

- 每日记忆提炼 (凌晨 3:00) → MEMORY.md；SESSION-STATE 新鲜度检查 (每 6h)。

---

## systemd user service + nvm node 的 PATH 兼容（2026-09-21 落地，mcporter 故障实测）

**问题**：systemd user service 默认 PATH = `/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin`，**不含 `~/.local/bin`、**不含 `~/.nvm/versions/node/<ver>/bin`。任何通过 npm/nvm 安装的可执行包（如 `mcporter`、`pnpm`、自建 CLI），shebang 是 `#!/usr/bin/env node` 都会**失败**：`/usr/bin/env: 'node': No such file or directory` exit 127。

**解药（systemd 官方 Drop-In 模式）**：
1. `mkdir -p ~/.config/systemd/user/<service>.service.d/`
2. 写 `env-override.conf`：`[Service]` section + `Environment=PATH=/home/<user>/.local/bin:/home/<user>/.nvm/versions/node/<ver>/bin:/usr/local/bin:/usr/bin:/bin`
3. 可选 `Environment=HOME=/home/<user>` + `Environment=TMPDIR=/tmp`
4. `systemctl --user daemon-reload`
5. `systemctl --user restart <service>`

**优势 vs 改主 service 文件**：Drop-In 不触碰**主 service**——AGENTS.md「Before config/scheduler edits: preserve/merge」硬规则保护的就是主 service；Drop-In 是 systemd 设计的"覆盖而不修改"机制。

**验证**：Drop-In 生效后 `systemctl --user show <service>` 输出的 `Environment=` 行应包含完整 PATH。

**易错点**：
- 路径名拼写（`.bin` vs `bin`）——用 `diff <bridge_drop-in> <daemon_drop-in>` 强制镜像
- `--user` 不能漏——systemd user service 与 system service 完全隔离
- daemon-reload 后**必须 restart**——reload 只重读配置，不重启进程
