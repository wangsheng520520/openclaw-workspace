# MEMORY-openclaw-system.md — OpenClaw 系统配置档案

> 从 `MEMORY.md` 拆分出的 "OpenClaw 系统配置 / 系统配置原则 / 关系网络 / WSL2 网络 / Cron 自动任务" 子域 (2026-08-06)。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：`MEMORY-*.md` 不自动注入，按需 `read` 加载。

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
| evomap-node | EvoMap | evolver 连 Hub 节点凭据 (node_id=`74c0d023894c`, 9 文件) — 🔴 已于 2026-08-07 10:34 清理; 备份 `/tmp/evomap-backup-20260807-1031/`; A2A_HUB_URL 仍指向 https://evomap.ai 但无客户端连接 |

---

## Cron 自动任务 (2026-04-15, 仍在用)

- 每日记忆提炼 (凌晨 3:00) → MEMORY.md；SESSION-STATE 新鲜度检查 (每 6h)。
