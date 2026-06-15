# TOOLS.md - Local Notes

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

## 我的配置

### 🌤️ 天气预报

- **城市**: 武汉
- **区域**: 黄陂区
- **位置**: 盘龙城 / 汉口北
- **坐标**: 114.2649, 30.6877 (盘龙城)
- **备用坐标**: 114.2858, 30.7089 (汉口北)
- **检查频率**: 每天 2-4 次

### 🔮 memory-lancedb 插件配置（硅基流动 BAAI/bge-m3）

**场景**: 替换 memory-core 的 SQLite 向量存储，改用 LanceDB + 硅基流动嵌入模型，实现高效语义记忆召回。

#### 背景

- memory-lancedb 使用 LanceDB 向量数据库存储记忆
- BAAI/bge-m3 输出 **1024 维**向量（插件内置映射，无需手动指定）
- 硅基流动（SiliconFlow）提供 OpenAI-compatible API，baseUrl: `https://api.siliconflow.cn/v1`
- 通过 `before_prompt_build` hook 自动召回，`agent_end` hook 自动捕获

#### 配置步骤

**第一步：在 openclaw.json 中添加 memory-lancedb 插件配置**

在 `plugins.entries` 下添加：

```json
"memory-lancedb": {
  "enabled": true,
  "config": {
    "embedding": {
      "provider": "openai",
      "model": "BAAI/bge-m3",
      "baseUrl": "https://api.siliconflow.cn/v1",
      "apiKey": "your-siliconflow-api-key"
    },
    "autoRecall": true,
    "autoCapture": true,
    "dreaming": { "enabled": true }
  },
  "hooks": { "allowConversationAccess": true }
}
```

**关键点**：
- `provider: "openai"` ← 插件用 OpenAI 兼容客户端，不支持 `"siliconflow"` 字符串
- `model: "BAAI/bge-m3"` ← 插件内置 1024 维映射，**不要**写 `dimensions` 参数（2026-06-03 实测：写了会报 400 错误）
- `baseUrl` 必须显式指向硅基流动端点，否则会打到 OpenAI 官方

**第二步：在 plugins.enabled 中启用插件**

```json
"plugins": {
  "enabled": ["memory-lancedb", ...],
  "entries": { "memory-lancedb": { ... } }
}
```

**第三步：重启 Gateway**
```bash
gateway restart
```

#### ⚠️ 已知陷阱

| 陷阱 | 错误现象 | 解决方案 |
|------|---------|---------|
| 手动指定 `dimensions` 参数 | 400 错误，初始化失败 | 删除 `dimensions` 字段，插件根据 model 自动推导 1024 |
| `provider` 写 `"siliconflow"` | 插件无法识别 | 改写 `"openai"`，baseUrl 覆盖端点即可 |
| 缺失 `baseUrl` | API 请求打到 OpenAI 官方（无 key/配额） | 必须显式写出硅基流动 baseUrl |
| 新 DB 路径无写权限 | LanceDB 初始化失败 | 确认路径可写（默认 `~/.openclaw/memory/lancedb`）|
| DB 重建 | LanceDB 重新初始化会清空历史记忆 | 避免删 DB，记忆需重新导入 |

#### 验证命令

```bash
gateway status
# 检查 LanceDB 初始化日志
gateway logs 2>&1 | grep -i lancedb
# 测试记忆召回
memory_recall query="测试"
```

#### 降级方案

临时回退：设置 `enabled: false`，同时确保 memory-core（SQLite 向量版）已启用。

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

---

### 📅 日历服务

#### ✅ Feishu 日历 (已配置)

**状态**: ✅ 已集成 (通过飞书渠道)

**配置**:
- 飞书应用 ID: `cli_a911625db7f8dcc2`
- 连接模式：WebSocket
- 群策略：开放

**使用方式**:
```bash
# 心跳检查自动通过飞书检查日历事件
# 无需手动配置
```

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

Add whatever helps you do your job. This is your cheat sheet.

---

### 🦎 Evolver + 变色龙代理（WSL2 持久化）

**背景**：WSL2 直连 `https://evomap.ai` 可能被 Cloudflare `REGION / NETWORK unavailable` 拦截；Windows 浏览器可访问通常是因为走了变色龙加速器。

**变色龙端口**：
- SOCKS 可用：`127.0.0.1:1234`（已验证可让 `curl --proxy socks5h://127.0.0.1:1234 https://evomap.ai/a2a/hello` 到达业务 API）
- 备用端口：`127.0.0.1:9876`

**Evolver 持久化入口**：
- Watchdog：`/home/wszmd520520/.openclaw/workspace/scripts/evolver-watchdog.sh`
- HTTP CONNECT → SOCKS5 桥：`/home/wszmd520520/.openclaw/workspace/scripts/evolver-http-connect-to-socks5.js`
- hubFetch preload：`/home/wszmd520520/.openclaw/workspace/scripts/evolver-hubfetch-env-proxy-preload.js`

**为什么需要 preload**：Evolver 的 `src/gep/hubFetch.js` 使用项目依赖里的 `undici.fetch` + 自定义 dispatcher，默认不会吃 Node v24 `--use-env-proxy`。preload 用 `_setFetchImplForTest` 将 hubFetch 改为 `global.fetch` 并丢弃 direct dispatcher，使 `NODE_OPTIONS=--use-env-proxy` 生效。

**Watchdog 行为**：
- 启动时检测 `127.0.0.1:1234`
- 可用 → 启动/复用 `127.0.0.1:18080` HTTP CONNECT 桥，并设置：
  - `HTTP_PROXY=http://127.0.0.1:18080`
  - `HTTPS_PROXY=http://127.0.0.1:18080`
  - `NODE_OPTIONS=--use-env-proxy --require=/home/wszmd520520/.openclaw/workspace/scripts/evolver-hubfetch-env-proxy-preload.js`
- 不可用 → 自动 unset 代理变量，直连启动

**验证成功标志**：
```text
[evolver-proxy-preload] hubFetch now uses global.fetch/env proxy
[lifecycle] hello OK, node_id=node_dc8f215d85d552d9
[Heartbeat] Registered with hub. Node: node_dc8f215d85d552d9
```

**状态目录迁移（2026-06-14 17:30）**：
- 旧状态目录：`/home/wszmd520520/.openclaw/workspace/skills/evolver/memory/evolution`，停在 `cycleCount=395`（最后 `#0395`，2026-06-12 23:07）；迁移验证后已按用户要求删除该旧目录（2026-06-14 17:37），只保留备份。
- 新运行目录：`/home/wszmd520520/.openclaw/workspace/memory/evolution`，由 `OPENCLAW_WORKSPACE=/home/wszmd520520/.openclaw/workspace` 决定。
- 已将旧目录 overlay 到新目录，并保留新目录 06-14 的 `#0145~#0153` 增量文件；新目录 `evolution_state.json` 以旧 `395` 为准。
- 备份：`/tmp/evolver-state-migration-20260614-173027/{old-skills-evolver-memory-evolution.tgz,new-workspace-memory-evolution.tgz}`。
- 验证：重启 watchdog 后新路径从 `395` 接续到 `396`，生成 `gep_prompt_Cycle_#0396_run_1781429485317.*`，Hub `hello OK` + `Registered with hub`；删除旧目录前新路径已推进到 `cycleCount=399`。


---

### 🐦 lark-cli (飞书官方 CLI)

**版本**: 1.0.19
**配置**: `~/.lark-cli/openclaw/config.json`
**认证**: OAuth Device Flow，已授权用户 王胜 (ou_e5f06d7a314911f40b2a0bb1a454b2ca)
**PATH**: `$HOME/.nvm/versions/node/v24.14.0/bin` (需 export PATH)
**复用飞书 App**: cli_a911625db7f8dcc2 (与 OpenClaw 共用)

**优先级规则**：飞书操作优先使用 lark-cli，而非 OpenClaw 内置的 feishu_* 工具

**14 个业务域 + 200+ 命令**：

| 域 | 快捷命令示例 | 用途 |
|-----|-------------|------|
| calendar | `+agenda`, `+create`, `+freebusy`, `+suggestion` | 日历/日程管理 |
| im | `+messages-send`, `+messages-search`, `+chat-create`, `+chat-search` | 消息/群聊 |
| docs | `+fetch`, `+create`, `+update`, `+search`, `+media-insert` | 文档操作 |
| drive | `+upload`, `+download`, `+export`, `+import`, `+move` | 云盘管理 |
| wiki | `+node-create`, `+move` | 知识库 |
| mail | `+triage`, `+send`, `+reply`, `+thread`, `+watch` | 邮件管理 |
| task | `+create`, `+complete`, `+search`, `+get-my-tasks` | 任务管理 |
| base | (CRUD via base subcommands) | 多维表格 |
| sheets | (CRUD via sheets subcommands) | 电子表格 |
| slides | (CRUD via slides subcommands) | 演示文稿 |
| approval | instances, tasks | 审批流程 |
| attendance | (查询) | 考勤 |
| okr | (只读) | OKR |
| vc/minutes | (只读) | 会议/妙记 |

**三层架构**：
1. **Shortcuts (+命令)** — 人和 AI 友好的高级命令
2. **API Commands** — 与平台同步的标准 API
3. **Raw API** (`lark-cli api GET /open-apis/...`) — 完整覆盖

**常用命令**：
```bash
export PATH="$HOME/.nvm/versions/node/v24.14.0/bin:$PATH"

# 日历
lark-cli calendar +agenda                    # 今日日程
lark-cli calendar +create --summary "会议" --start "2026-04-25 14:00" --end "2026-04-25 15:00"

# 消息
lark-cli im +messages-send --chat-id <id> --content "hello"  # 发消息
lark-cli im +chat-search --query "群名"      # 搜群
lark-cli im +messages-search --query "关键词"  # 搜消息

# 文档
lark-cli docs +fetch --url <doc_url>          # 读文档
lark-cli docs +search --query "关键词"        # 搜文档

# 邮件
lark-cli mail +triage                         # 邮件列表
lark-cli mail +send --to user@example.com --subject "标题" --body "内容"

# 任务
lark-cli task +get-my-tasks                   # 我的任务
lark-cli task +create --summary "任务名"      # 创建任务

# 通用 API
lark-cli api GET /open-apis/calendar/v4/calendars
```

**输出格式**：`--format json|table|csv|pretty|ndjson`
**分页**：`--page-all` 自动翻页，`--page-limit N` 限制页数
**过滤**：`--jq <expr>` 或 `-q <expr>` JQ 表达式过滤
**身份**：`--as user|bot|auto` 切换用户/机器人身份

**lark-cli vs feishu_* 工具对比**：
| 场景 | 用 lark-cli | 用 feishu_* |
|------|------------|-------------|
| 日历查看/创建 | ✅ 优先 | ❌ 不支持 |
| 邮件收发 | ✅ 优先 | ❌ 不支持 |
| 任务管理 | ✅ 优先 | ❌ 不支持 |
| 审批流程 | ✅ 优先 | ❌ 不支持 |
| 文档读写 | ✅ 优先 | ⚠️ 可用但 lark-cli 更简洁 |
| 知识库操作 | ✅ 优先 | ⚠️ 可用 |
| 消息发送 | ⚠️ 可用 | ✅ OpenClaw 渠道集成更好 |
| Bitable CRUD | ⚠️ 可用 | ✅ feishu_bitable_* 更方便 |
