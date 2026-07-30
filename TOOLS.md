# TOOLS.md - Local Notes (Index)

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## 📚 子文件索引（拆分后，2026-07-30）

主 `TOOLS.md` 只保留日常快速参考。专题深入内容已拆分到三个主题文件，单文件均 ≤ 16k 字符：

| 主题 | 文件 | 内容 | 何时读 |
|------|------|------|--------|
| 🐦 lark-cli 飞书 CLI | `TOOLS-lark-cli.md` | v1.0.19 安装、命令体系、与 feishu_* 工具优先级 | 飞书操作前查命令 |
| 🦎 Evolver / EvoMap Hub | `TOOLS-evolver-evomap.md` | WSL2 持久化、watchdog、validator、publish 实战、Node 身份陷阱 | evolver 出问题或要 publish |
| 🔮 Memory / AI 模型 | `TOOLS-memory-ai.md` | memory-lancedb + 硅基流动 BAAI/bge-m3 配置 | 配置长期记忆或调整嵌入模型 |

**加载规则**：gateway bootstrap 按文件名注入，所以 `TOOLS-*.md` 这类**不会被自动注入**——它们按需 `read` 加载。日常任务只看主 `TOOLS.md` 即可，避免上下文膨胀。

---

## 我的配置

### 🌤️ 天气预报

- **城市**: 武汉
- **区域**: 黄陂区
- **位置**: 盘龙城 / 汉口北
- **坐标**: 114.2649, 30.6877 (盘龙城)
- **备用坐标**: 114.2858, 30.7089 (汉口北)
- **检查频率**: 每天 2-4 次

---

### 📧 邮件检查

**当前状态**: ✅ 已配置 (Himalaya CLI)

**已配置账户**:

| 账户 | 邮箱 | 提供商 | 状态 |
|------|------|--------|------|
| default | wszmd1793@gmail.com | Gmail | ✅ 已配置 |
| qq | (查看 config-qq.toml) | QQ Mail | ✅ 已配置 |

**常用命令**:
```bash
# 查看收件箱 (最新 5 封)
himalaya envelope list --page 1 --page-size 5

# 查看所有文件夹
himalaya folder list

# 查看特定文件夹
himalaya envelope list --folder "Sent"

# 阅读邮件
himalaya read <ID>

# 发送邮件
himalaya compose
```

**配置文件位置**:
- 主配置：`~/.config/himalaya/config.toml`
- QQ 配置：`~/.config/himalaya/config-qq.toml`

**⚠️ WSL2 防护**：所有 himalaya 命令必须用 `timeout 15` 包裹，防止 TCP 握手挂起阻塞。

---

### 📅 日历服务

#### ✅ Feishu 日历 (已配置)

**状态**: ✅ 已集成 (通过飞书渠道)

**配置**:
- 飞书应用 ID: `cli_a911625db7f8dcc2`
- 连接模式：WebSocket
- 群策略：开放

**使用方式**（推荐 lark-cli，详见 `TOOLS-lark-cli.md`）:
```bash
export PATH="$HOME/.nvm/versions/node/v24.14.0/bin:$PATH"
lark-cli calendar +agenda                # 今日日程
lark-cli calendar +create --summary "会议" --start "..." --end "..."
```

**心跳自动检查**：每次心跳通过飞书渠道自动跑，无需手动配置。

---

#### ⚠️ Google Calendar (可选)

**GOG CLI 状态**: ✅ 已安装 (v0.12.0-dev)
**OAuth 配置**: ⏳ WSL 环境限制，使用 Feishu 替代

如需配置 Google Calendar，请在 Windows 上完成授权后同步 token。

---

### 🔔 提及/通知服务

#### ✅ Feishu 通知 (已配置)

**状态**: ✅ 已集成

**配置**:
- 飞书应用 ID: `cli_a911625db7f8dcc2`
- 连接模式：WebSocket
- 群策略：开放

**检查内容**:
- @提及消息
- 群聊通知
- 私聊消息
- 机器人消息

**自动检查**: 心跳检查时自动通过 Feishu 渠道检查

---

#### ⚠️ 其他通知渠道 (可选)

如需配置其他通知渠道：

**Discord**:
```bash
openclaw config set channels.discord.enabled true
openclaw config set channels.discord.token YOUR_BOT_TOKEN
```

**Telegram**:
```bash
openclaw config set channels.telegram.enabled true
openclaw config set channels.telegram.token YOUR_BOT_TOKEN
```

**WhatsApp**:
```bash
openclaw config set channels.whatsapp.enabled true
# 需要 Meta Business API 配置
```

---

### 🔔 定时提醒

如需启用定时提醒，配置 cron:
```bash
openclaw cron add --name "每日心跳" --schedule "0 9,14,18 * * *" --payload '{"text":"执行心跳检查"}'
```

---

## 🎯 常用命令速查

| 工具 | 命令 | 备注 |
|------|------|------|
| lark-cli | `lark-cli calendar +agenda` | 飞书日程（详见 `TOOLS-lark-cli.md`） |
| lark-cli | `lark-cli mail +triage` | 飞书邮件（详见同上） |
| lark-cli | `lark-cli docs +fetch --url <url>` | 飞书文档（同上） |
| himalaya | `himalaya envelope list --page 1 --page-size 5` | Gmail 收件箱 |
| evolver | `bash scripts/evolver-spawn.sh` | 单次进化（详见 `TOOLS-evolver-evomap.md`） |
| gateway | `gateway restart` | 热重载（SIGUSR1） |
| gateway | `systemctl --user restart openclaw-gateway.service` | 硬重启（修改 env 必须用） |
| 记忆 | `memory_recall query="..."` | 语义召回（详见 `TOOLS-memory-ai.md`） |

---

Add whatever helps you do your job. This is your cheat sheet.