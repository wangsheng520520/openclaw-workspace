# MEMORY-ops-playbook.md — 操作手册归档

> 从 `MEMORY.md` 拆出来的"操作手册 + 04-15~05 系统运行观察"子域 (2026-07-30)。
> 主题：问题排查模式、04 月用户静默期观察、模型配置教训、技能扩展、关键经验总结等。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：OpenClaw bootstrap 走精确 basename 匹配（看 `run-attempt-V636cwT5.js` 白名单），`MEMORY-*.md` 不在白名单，按需 `read` 加载。

---

### 问题排查模式 (06-12 压缩 15→8 条, 详细在 .learnings/ERRORS.md)

- himalaya 挂起：`timeout 15` 包裹；QQ 邮箱需 `--config config-qq.toml`。
- 微信文章提取失败：优先 Tavily，web_fetch/jina.ai 效果差。
- 子 Agent 超时：`runTimeoutSeconds` 调 600+（大型调研）。
- MCP 进程 >20：`pkill -f "mcp-server|mcp-deepwiki" + systemctl --user restart`。
- 模型切换异常：检查 `agents.defaults` 是否含新模型；fallback 链不能为空。
- A2A 环境变量缺失：技能 UI 显示封锁但看门狗 exec 时单独传 env，进程实际正常。
- Gateway 回滚：升 systemd 服务配置版本；CLI 滞后：`npm install -g openclaw@latest` + 重建 symlink。
- 飞书配对失败：`openclaw pairing approve feishu <code>`。

---

### 女娲造人术实践经验 (2026-04-14, 已沉淀到 skill)

- Phase 0-5 完整流程首次跑通：调研 6 Agent / 2h / 196KB → 提炼 30min → 验证 3/3 → 精炼 20min。三重验证（跨域复现+生成力+排他性）有效。

---

### 系统自治运行观察 (04-15~04-20)

**用户静默期 (04-15~04-19, 6天)**:
- 系统全部自治组件稳定运行,无人类干预
- 博客监控持续产出日报,每日 30-66 篇新文章
- 梦境系统、记忆提炼、SESSION-STATE 检查均正常

**04-19 Obsidian 文档同步**:
- 子 Agent 成功更新了 8 篇 OpenClaw 官方文档到 Obsidian 知识库
- 涉及 Hooks、Channels、Skills 等核心文档

**04-20 用户回归** (~00:30):
- 用户通过飞书发送微信公众号链接,要求导入 Obsidian 并建立双链
- 文章主题:《公交司机的真心话:所谓疲劳驾驶,不过是说说而已》
- 提取方案:web_fetch 和 jina.ai 均失败,Tavily 成功提取
- 成功建立 7 条双链(5 条公交行业 + 2 条安全驾驶)
- 用户重复发送同一链接 3 次(可能因飞书消息延迟或未看到回复)

**微信文章导入经验**:
- web_fetch 对微信公众号文章提取效果差
- r.jina.ai 对微信公众号也不稳定
- **Tavily 是微信公众号文章提取的最佳选择**
- 建立双链时要先检索 Vault 中已有的相关笔记

---

### 模型配置教训 (04-21)

- **NVIDIA 模型前缀问题**: 所有 cron 任务的模型配置必须使用完整前缀 `nvidia/` (如 `nvidia/google/gemma-4-31b-it`),否则会被识别为独立 provider
- **阿里 vs NVIDIA 上下文差异**: 阿里闭源优化版 Qwen 3.5 (1M) vs NVIDIA 开源权重版 (128K),同模型不同托管方上下文窗口差异显著

### 模型配置教训 (04-21~04-23)

- **火山方舟 Coding Plan** (04-23): `volcengine-plan/ark-code-latest` (豆包 Seed Code,262K,reasoning) + `glm-5.1` (智谱旗舰,200K,深度思考) + `kimi-k2.5` (Moonshot,262K); 插件自动管理模型发现

---

### 04-23 重大事件：MCP 泄漏致系统瘫痪

**第二次大规模泄漏 (14:05)**:
- ~300 个重复 MCP 进程耗尽 15GB 内存
- 所有 4 个备选模型超时,Gateway 也无响应
- 用户手动重启 Gateway 完全恢复

**自动清理 (15:31)**:
- Cron 任务 `b2e01aaf` 自动清理 147 个重复进程
- 释放 7.7GB 内存 (13.9GB → 6.1GB)
- 预防性维护机制有效

---

### 技能扩展 (04-23) - 共 21 个

| 技能 | 功能 |
|------|------|
| causal-inference | 因果推理层(因果图+反事实预测) |
| clawmind | AI Agent 知识共享平台 |
| brainstorming | 设计工作流(意图→方案→设计文档) |
| memory | 平行无限记忆系统(`~/memory/`) |

---

### 系统自治运行观察 (04-15~04-29, 总结)

- 4 月静默期 (04-15~04-19) + 04-20~29 多次用户回归 + 4 次 MCP 泄漏 (04-23 14:05 ~300 进程 + 04-26 63 进程 + 04-27 147 进程 + 04-29 31 进程冗余)
- 4-29 起 MCP 改为按需启动,内存压力根本性解决 (释放 ~500MB+)
- 详见 `.learnings/ERRORS.md` (含所有事件详细时间线)

---

### 关键经验总结 (2026-04-13~14, 一次沉淀)

- 女娲造人术：6 Agent 并行调研效率高 (196KB/~2h)，Phase 4 质量验证 (Sanity+Edge+Voice) 是 Skill 质量关键。
---

### GitHub MCP 操作手册 (2026-08-07)

**背景**: 08-07 代理 (127.0.0.1:1234 变色龙) 故障时 git push/fetch 全挂; 改用 GitHub MCP 后成功。用户 11:50 拍板: **Git 操作统一走 GitHub MCP**。

**为什么 MCP 优于 git push**:
- GitHub MCP 走 GitHub REST API 直连 (免代理, 免网络波动)
- create_or_update_file / push_files 直接创建 remote commit
- list_commits 可实时查 remote 真实状态

**常用 MCP 工具** (mcporter-bridge__github__*):
| 工具 | 用途 |
|------|------|
| `create_or_update_file` | 单文件创建/更新 (需 owner/repo/path/content/message/branch) |
| `push_files` | 多文件单 commit 推送 |
| `list_commits` | 查 remote commit 历史 (拿真实 sha) |
| `get_file_contents` | 读 remote 文件验证 |

**MCP 推送 vs 本地 git 的差异**:
- MCP 创建的 commit **不在本地对象库** → `git update-ref` 会报 nonexistent object
- 本地引用对齐方法: `git -c http.proxy= -c https.proxy= fetch github main`
  (临时绕开 .git/config 的 [http]/[https] proxy 配置, 不改文件)

**实操流程 (推送文件)**:
1. 本地 `git show HEAD:<path> > /tmp/file` 提取内容 (确保与 commit 一致)
2. MCP `create_or_update_file` 推送 (content = 文件全文)
3. MCP `list_commits` 拿 remote 新 sha
4. `git -c http.proxy= -c https.proxy= fetch github main` 对齐本地引用
5. 验证: `git show github/main:<path> | md5sum` vs 本地 `md5sum <path>`

**⚠️ 注意**: .git/config 有工作区级 `[http] proxy = socks5://127.0.0.1:1234` — 这是 git 强制走代理的根因; 用 `-c http.proxy=` 临时禁用即可, 不要改 .git/config (避免污染其他 remote)。

---

## mcporter 升级流程 (2026-08-07 实战, 0.12.3 → 0.13.0)

**一句话**: npm 装新版 + 停旧 daemon/serve + 清 socket + 启新 daemon/serve + **curl 验证 initialize 不超 60s**

**详细步骤**:
1. `npm i -g mcporter@<ver>` (12s 左右, 30-40 packages changed)
2. 备份: `cp workspace/config/mcporter.json /tmp/mcporter.json.bak-<ts>`
3. 停旧进程: `kill <old_daemon_pid> <old_serve_pid>` (用 `ps aux | grep mcporter` 找 PID)
4. 清 socket: `rm -f ~/.mcporter/daemon/*.sock` (防新版用旧 sock 路径)
5. 启新 daemon: `nohup mcporter daemon start --foreground > /tmp/mcporter-daemon.log 2>&1 &`
6. 启新 serve: `nohup mcporter serve --http 3099 > /tmp/mcporter-serve.log 2>&1 &`
7. **硬约束验证**: curl POST /mcp initialize 必须 < 60s (记忆 1 timeout=60 不变)
8. 端到端验证: `mcporter list` (13 servers healthy) + curl /mcp tools/list + curl tools/call 实际跑一个

**踩坑点**:
- ❌ 不停 daemon 直接装新版 → 旧进程继续用 0.12.3 binary, 新版无效
- ❌ 不清 socket → 新 daemon 可能拿到旧 sock 路径, 启动失败
- ❌ 跳过 curl initialize 验证 → 13 server 冷启动超时不会被发现 (回到 -32001)
- ✅ 关键不变量: openclaw.json mcp.servers.mcporter-bridge.timeout=60 + connectTimeout=10 升级后**不动**

**当前版本** (2026-08-07 12:30): mcporter **0.13.0**, daemon PID 39541, serve PID 39554

---

## Playwright MCP 修复流程 (2026-08-16 实战)

**症状**: `browser_navigate` 调用时报
`Chromium distribution 'chrome' is not found at /opt/google/chrome/chrome`
（WSL2 没装系统 Chrome，但 Playwright MCP 默认 `--browser chrome` 找系统 Chrome）

**根因 (三层)**:
1. **配置层**: playwright-mcp 默认 channel='chrome'（系统 Chrome）；要传 `--browser chromium` 才能用 Playwright 自带 binary
2. **路径层**: bridge 实际读 `~/.mcporter/mcporter.json`（**不是** `~/.openclaw/workspace/config/mcporter.json`）——CLI 显示的 source 是 workspace 的，但 spawn 实际用 ~/.mcporter 的
3. **Binary 层**: WSL2 上 `~/.cache/ms-playwright/` 已有 chromium-1217，但 Playwright MCP 1.61+ 要 chromium-1237（版本不匹配）

**修复步骤 (3 步)**:
1. **改两份 mcporter.json** (都加 `"--browser", "chromium"` 到 playwright args):
   - `~/.openclaw/workspace/config/mcporter.json`
   - `~/.mcporter/mcporter.json`
2. **重启 bridge 让它重读配置**:
   - `systemctl --user restart mcporter-bridge` (会重新 spawn daemon + 所有子进程)
3. **补齐缺失的 binary**:
   - `npx @playwright/mcp@latest install-browser chrome-for-testing`
   - 下载 ~300MB 到 `~/.cache/ms-playwright/chromium-1237` + chromium_headless_shell-1237
   - **未遇代理问题** (npm 走 npmmirror 镜像, binary 走 cdn.playwright.dev)

**验证测试 (3 个核心工具)**:
```
mcporter-bridge__playwright__browser_navigate https://example.com
# → "Example Domain" 标题 = 加载成功
mcporter-bridge__playwright__browser_snapshot
# → 完整 a11y tree = 解析成功
mcporter-bridge__playwright__browser_close
# → "No open tabs" = 清理成功
```

**踩坑点 (本次踩过的)**:
- ❌ 改 `workspace/config/mcporter.json` 后 kill 子进程 / kill daemon → mcporter daemon 不 reload 配置（缓存进内存）
- ❌ `mcporter daemon restart` → 它 spawn 新 daemon 但仍用旧 args（daemon 不读磁盘，只从 bridge 内存拿）
- ❌ 改完不重启 bridge → 永远生效不了（**bridge 才是配置源**）
- ❌ kill 子进程后立刻重新 spawn → 旧 args 复活
- ✅ 正确流程: 改 ~/.mcporter/mcporter.json + 重启 bridge + install-browser

**配置层关键洞察**: `mcporter config list` 显示 source 是 workspace 的，但 bridge 实际读 ~/.mcporter 的——**两个 config 文件都要改**，因为：
- workspace 版本是 CLI (`mcporter list/call`) 用
- ~/.mcporter 版本是 bridge/daemon 用

**记忆不变量**: 任何时候改 mcporter server args，**必须**:
1. 改 `~/.mcporter/mcporter.json` (这个才是 bridge 读的)
2. `systemctl --user restart mcporter-bridge`
3. 用对应工具做端到端验证

---

## OpenClaw env 类清理安全流程 (2026-08-16 实战)

**触发场景**：清任何 .env / systemd Environment* / openclaw.json env 段 / shell rc 中的遗留配置

**核心原则**（来自本次实战）：
1. **不要相信记忆，先实测**（memory #1 硬规则）—— 配置可能改过、可能多源、可能 stale
2. **先查官方文档**（memory #3）—— `docs/help/environment.md` 和 `docs/gateway/configuration-reference.md` 必读
3. **多源头排查**——env 可能分布在 5+ 个位置，单点清理无效
4. **改前必备份**——回滚能力是底线
5. **不要把 OpenClaw 搞死了**（用户硬约束）—— 任何破坏性操作前确认回滚路径

**Env 优先级（官方文档）**：
```
1. Process environment (systemd Environment + EnvironmentFile)
2. CWD .env (workspace .env)
3. Global .env (~/.openclaw/.env)
4. Config env block (openclaw.json env 段)
5. Optional login-shell import (env.shellEnv.enabled)
```
**关键洞察**：systemd EnvironmentFile 比 openclaw.json 优先级高——只改 JSON 不够

**完整排查清单**（按优先级倒序排查）：

| 位置 | 命令 | 说明 |
|------|------|------|
| `~/.openclaw/openclaw.json` env 段 | `awk '/"env":/,/^  \},/' ~/.openclaw/openclaw.json` | 第 4 优先级 |
| `~/.openclaw/.env` | `cat ~/.openclaw/.env` | 第 3 优先级 |
| `~/.openclaw/workspace/.env` | `cat ~/.openclaw/workspace/.env` | 第 2 优先级（如果是 CWD）|
| `~/.config/systemd/user/<service>.service.d/*.conf` | `ls ~/.config/systemd/user/*.service.d/` | systemd drop-in |
| `~/.config/systemd/user/<service>.service` | `cat <service>.service` | systemd 主 unit（含 EnvironmentFile=） |
| `~/.openclaw/gateway.systemd.env`（或 unit 里的 EnvironmentFile 路径）| `cat <EnvironmentFile path>` | 第 1 优先级，最权威 |
| `~/.bashrc` / `~/.profile` / `~/.zshrc` | `grep -E "<VAR>" ~/.bashrc ~/.profile` | shell 启动文件 |

**清理步骤（6 步，缺一不可）**：

```bash
# Step 1: 摸清现状（不要凭记忆）
echo "=== Find all source files ==="
grep -lrE "<KEYWORD>" /etc /home ~/.openclaw ~/.bashrc ~/.profile 2>/dev/null
# 用 xxd 检查真值 vs 占位符
xxd <file> | grep "<known_secret_pattern>"

# Step 2: 备份所有目标文件
for f in <list>; do
  cp -p "$f" "$f.y5-cleanup-$(date +%Y%m%d-%H%M%S)"
done

# Step 3: 编辑（按文件类型选工具）
# .env / .conf / .service → edit 工具
# openclaw.json → edit 工具 + JSON 验证
edit /path/to/file edits=[{oldText: ..., newText: ""}]  # 删整段用空字符串

# Step 4: JSON 合法性（仅 openclaw.json 必做）
python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null && echo "JSON OK"

# Step 5: daemon-reload + restart（仅 systemd 单元改了必做）
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
# 等 ~30s 大服务重启
sleep 15

# Step 6: 验证（5 维度全过才算完）
systemctl --user status openclaw-gateway | head -10   # Active: active
GATEWAY_PID=$(systemctl --user show -p MainPID openclaw-gateway | cut -d= -f2)
cat /proc/$GATEWAY_PID/environ | tr '\0' '\n' | grep -i "<KEYWORD>"  # 应空
grep -lrE "<KEYWORD>" <所有源文件>  # 应空
session_status  # 200 OK
跑一个 MCP 工具  # 验证功能性
```

**备份管理**（避免备份本身成为攻击面）：
- 备份移到 `/tmp/y-cleanup-archive-<timestamp>/`（隔离目录）
- `chmod 700` 目录 + `chmod 600` 文件
- 真 secret 用 sed 替换为 `***REDACTED-<KEY>-<DATE>***`
- 保留文件结构用于回滚参考，但不保留真凭证

**绝对禁止**（从本次反例提炼）：
- ❌ 单源清理（只看 .env 不看 systemd）
- ❌ 不备份就改（一旦改坏无回滚）
- ❌ 改 systemd unit 但不 daemon-reload（重启用旧 unit）
- ❌ 改 openclaw.json 不验证 JSON（启动失败）
- ❌ 备份留在默认路径（chmod 644 任何人可读）
- ❌ 备份里留真 secret（攻击面转移）

---

## 📋 2026-08-25 决策：删除 qwen/* 死配置（DashScope coding 套餐残留）

**触发**：用户反映 UI 模型选择列表里"阿里模型重复了两套"

**5 步实测**（先实测，再列方案）：

| 步 | 维度 | 发现 |
|---|---|---|
| 1 | 效果层 | UI 显示两套 `qwen3.x` 模型（`bailian-token-plan/qwen3.x` + `qwen/qwen3.x`） |
| 2 | 配置层 | `models.providers` 里有**两个** provider 都指向阿里：`bailian-token-plan`（百炼 token-plan 套餐，baseUrl=`token-plan.cn-beijing.maas.aliyuncs.com`）和 `qwen`（DashScope coding 套餐，baseUrl=`coding.dashscope.aliyuncs.com`）。**baseUrl 不同 = 不同 API key = 不同计费** |
| 3 | 历史层 | `memory/secrets-migration-checklist-20260823.md` 仍提到 `profiles.qwen.default.key`；`memory/2026-04-23.md` 提到 04-23 时期主模型是 `qwen/qwen3.5-plus`；后续 `bailian-token-plan` 套餐上线（2026-08-17 左右，见 `memory/dreaming/light/2026-08-18.md`）后主力迁过去 |
| 4 | 代码层 | `grep -E 'qwen/|bailian-token-plan/'` 引用方 — `qwen/*` 在 `primary/fallbacks/agents.list[].model` 里**零引用**；`bailian-token-plan/*` 占 fallback 链 5/8 |
| 5 | 用户层 | 用户问"模型选择里两套阿里"，期望**单一阿里来源** |

**判断**：qwen provider 是"历史化石"（04 月主力 → 08 月被 bailian-token-plan 替代），当前零运行时引用，但仍在 `agents.defaults.models` 里让 UI 显示成"重复"。

**操作**（A 方案 = 最小化清理 + 历史可逆）：
1. **删除** `agents.defaults.models` 里 8 个 `qwen/*` 键
2. **删除** `models.providers.qwen` 整个 provider 块
3. **连带清理** `auth.profiles.qwen:default`（指向已删 provider 的死引用）+ `plugins.allow` 里的 'qwen' 占位（保持一致）
4. **保留** `secrets/default.json` 里的 `profiles.qwen.default.key`（用户未拍板删 secrets；留作未来 re-enable 参考）
5. **不动** `siliconflow/Qwen/*`（独立硅基流动 provider，走 NVIDIA 免费层，不属于"阿里模型"）

**实测验证**（8 项全过）：
- `bailian-token-plan` provider 仍在 ✅
- `agents.defaults.models` 已无 `qwen/*` ✅
- 仍含 6 个 `bailian-token-plan/*` ✅
- fallback 链仍含 `bailian-token-plan/qwen3.7-plus` ✅
- `auth.profiles` 已无 qwen ✅
- `plugins.allow` 已无 qwen ✅
- `models.providers` 已无 qwen ✅
- JSON 格式有效 ✅

**改动量**：文件 40173 → 36337 字节（-3836，-9.5%）；providers 8→7；models 23→15；auth profiles 7→6；plugins allow 24→23。

**备份**：`openclaw.json.bak-cleanup-qwen-20260825-0745`（含 qwen 完整 provider + auth profile + plugins allow + 8 个 model 键）— 一键回滚：

```bash
cp -p ~/.openclaw/openclaw.json.bak-cleanup-qwen-20260825-0745 ~/.openclaw/openclaw.json
# 然后 hot reload（gateway 自动检测）
```

**未来避免**：配置清理前**必须**先 grep 引用方扫一遍（fallback / primary / agents.list[].model / auth.profiles / plugins.allow），避免遗漏连带配置变成"半删状态"导致启动报错。

**为什么不直接 cat 重写**：本修改涉及 4 个不同 section（agents.defaults.models / models.providers / auth.profiles / plugins.allow），用 Python dict 操作精确删除避免引入格式错误（JSON 缩进/逗号/数组索引全靠手工极易错）。

---

## 📋 2026-09-07 决策：Dashboard memory page "插件不可用" 是 UI bug（功能完全正常）

**触发**：用户问"设置记忆页面显示 memory plugin unavailable 不可用啊？"

**5 步实测**（先 D 实测，再列方案）：

| 步 | 维度 | 发现 |
|---|---|---|
| 1 | 效果层 | dashboard 设置 → memory → 显示 `active-memory` 和 `memory-wiki` 两个 addon 是 "状态未知" badge；`memory-core` 显示 "Disabled"（slot 已被 lancedb 占用，预期行为） |
| 2 | 配置层 | `openclaw plugins list --json` 实测：4 个 memory plugin **全部 `enabled=True, status='loaded'`** |
| 3 | 历史层 | 8/19 决策切到 nomic MOE + lancedb + `plugins.slots.memory = "memory-lancedb"`；memory-core 被 slot 排斥但 config 仍在（`Config warnings: plugins.entries.memory-core: plugin disabled (memory slot set to "memory-lancedb") but config is present`） |
| 4 | 代码层 | dashboard dist `config-page-CjGWfrmZ.js` 里有 addons 渲染函数 `Qi()`：把 `state=null` 当成 `state='unknown'`，显示"未知"badge。`Ki()` 函数判断 `state` 字段，但 `openclaw plugins list --json` 输出里 `state: None` |
| 5 | 用户层 | 用户记忆里有"功能断没断 5 步法"硬规则——dashboard 显示 ≠ 实际功能 |

**根因**（精确代码位置）：

```js
// /home/wszmd520520/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw/dist/control-ui/assets/config-page-CjGWfrmZ.js
function Ki(e, t) {
  return e.kind === 'ready'
    ? !t?.installed || t.state === 'not-installed' || t.state === 'error'
      ? 'unknown'   // ← plugin list 输出 state=None → 走这里
      : t.enabled ? 'enabled' : 'disabled'
    : e.kind === 'loading' ? 'loading' : 'unknown'
}

function Qi(e) {
  switch (e) {
    case 'enabled':  return B({ kind: 'ok', label: 'Enabled' });
    case 'disabled': return B({ kind: 'muted', label: 'Disabled' });
    case 'loading':  return B({ kind: 'muted', label: 'Loading' });
    default:         return B({ kind: 'muted', label: 'stateUnknown' });  // ← "未知"
  }
}
```

**实测功能状态**（08:37 + 09:01 + 09:07 三次复测）：

| 维度 | 状态 |
|---|---|
| memory_search 工具 | ✅ 正常（返回 3 条结果，~6.7s） |
| memory-lancedb plugin | ✅ enabled=True, status=loaded |
| memory slot | ✅ 指向 memory-lancedb |
| 4 个 memory plugin | ✅ 全部 enabled, status loaded |

**不可修复的原因**：

- dashboard 的 Ki 函数判断 `t.state` 字段，但 `openclaw plugins list --json` 输出里没有 `state` 字段
- 改 openclaw.json 加 `kind` 字段？**不可行**——`plugins.entries.*.additionalProperties: False`，schema 直接 reject（`config validate` 报 "Unrecognized key: kind"）
- dashboard 端代码逻辑是 closed source，**无法 patch**

**判断**：**dashboard 显示与实际功能不一致是已知 UI bug**，但**不影响任何 memory 工具调用**。与 2026-07-06 的 "memory_search 不可用是误判" 同类——写进 "功能断没断" 5 步法硬规则。

**未来用户问类似问题时的标准回复**：

1. **memory_search / memory_recall / memory_store / memory_forget** 实测都正常
2. dashboard addons 段（active-memory / memory-wiki）的"未知" badge 是 dashboard 端 `Ki()` 函数对 `state=null` 的 fallback，**不是真故障**
3. memory-core 的 "Disabled" 是 **slot 已被 memory-lancedb 占用**（8/19 决策的预期状态）
4. **不必修**（dashboard 端代码 + openclaw.json schema 双重锁）

---

## 📋 2026-09-07 决策：blog-monitor.sh 修复 (脚本 grep 永远匹配空 bug)

**触发**：用户问"博客监控扫描怎么没有推送啊？"（9/7 09:16）

**5 步实测**（先 D 实测，再列方案）：

| 步 | 维度 | 发现 |
|---|---|---|
| 1 | 效果层 | 9/7 08:00 cron 跑了 (32s exit0)，但飞书没收到推送；最近 9/4 20:01 推送过 87 篇后，9/5 火山 Ark 断连 3 次 error，之后一直 "No new articles — NO_REPLY" |
| 2 | 配置层 | cron `18e7edd8-9125-41dc-9a9a-38e07b330d55` payload 改成了 `command` (argv=`bash blog-monitor.sh`) — 9/6 后从 agentTurn 改来避开 Ark |
| 3 | 历史层 | 9/5 22:03 / 20:09 / 08:02 三次 `volcano/ark-code-latest request failed` → agentTurn payload 在火山断连期间挂了 → 改回 command payload |
| 4 | 代码层 | `blogwatcher scan` 输出格式：`Source: RSS \| Found: 20 \| New: 0`（大写 N + 冒号 + 数字）；`blogwatcher articles` 列表格式：`[22906] [new] title`（中括号 + new）。**两者输出格式不同** |
| 5 | 用户层 | 用户期待"能收到推送"——历史推送过 87 篇（9/4），现在完全没推送，逻辑断裂 |

**根因**（精确代码行）：

```bash
# /home/wszmd520520/.openclaw/workspace/main/scripts/blog-monitor.sh:13 (修复前)
NEW_LINES=$(printf '%s\n' "$SCAN_OUT" | grep '\[new\]' | head -10)
#         ↑ grep 永远匹配空！scan 输出是 "New: 0" 不是 "[new]"
#         → NEW_LINES 永远空 → 永远走 NO_REPLY
```

**修复方案 A2**：绕过 `scan` 输出的格式差异，直接 SQL 读 `is_read=0` 文章（数据源统一）

**新脚本逻辑**（已部署 `/home/wszmd520520/.openclaw/workspace/main/scripts/blog-monitor.sh`）：

1. `blogwatcher scan` 触发（更新 DB）+ `|| true` 防 scan error 让脚本挂掉
2. `python3 sqlite3` 查 `articles.is_read=0 ORDER BY discovered_date DESC LIMIT 10`
3. 拼接 markdown + `lark-cli im +messages-send --chat-id ... --markdown`
4. 推送成功 → SQL `UPDATE is_read=1` 标记这 10 条已读
5. `set -e` + 所有失败立即退出

**验证**（9/7 12:06 实测）：
- ✅ `lark-cli` 返回 `ok: true`, `message_id: om_x100b66d7ca142cacb2aa242de7cf215`
- ✅ 10 篇 marked as read
- ✅ chat_id `oc_e8a582e5e3d7f43455144e0e07e011ad` (王胜 p2p) 收到
- ✅ cron `18e7edd8` 配置不用改，下次自动 9/7 20:00 跑

**Lancedb-like 长期效果**：
- 修复前：crontab 跑但脚本永远 NO_REPLY，飞书永远收不到推送（since 9/5 22:16）
- 修复后：每次 cron 跑推 10 条最新未读，飞书实际收到（since 9/7 12:06 实测）

**教训（写进硬规则）**：
- **脚本 grep 文本前必须先看输出格式**——别假设 `articles` 视图格式 = `scan` 输出格式
- **`scan` 输出是机器摘要（`Found: X \| New: 0`），`articles` 输出是人类可读（`[new]`）**——两者格式不同
- **修 cron 脚本前必须先手动跑一遍验证**（不能直接靠 "AI 推理" 改）
- **关键路径要避开字符串解析**，优先用 SQL/JSON 等结构化查询（这次改用 sqlite3 直接查 DB 就是这个教训）

**对照之前的 "MEMORY-ops-playbook 8/19 cron 架构决策"**：cron `18e7edd8` 当时 payload 是 agentTurn (LLM 摘要)，9/5 Ark 断连后改成 command payload，但 command payload 的 bash 脚本从一开始就有 bug——直到 9/7 用户主动反馈才发现 (16 天静默失败)。**改进措施**：今后任何 command payload 脚本改动必须先手动跑一次 dry-run 验证。


---

## 📋 2026-09-07 决策：Dashboard "update in progress" 假阳性 (target version = current)

**触发**：用户截图 — "OpenClaw update in progress: requested. 已完成0 个阶段, 共 7 个" 从昨天系统升级到 9.2 后一直显示

**5 步实测**（先 D 实测，再列方案）：

| 步 | 维度 | 发现 |
|---|---|---|
| 1 | 效果层 | dashboard 设置 → 更新 dialog 一直显示 "OpenClaw update in progress: requested" + 0/7 phases 完成 |
| 2 | 配置层 | `openclaw --version` = `2026.9.2 (3928bad)` (当前版本); gateway PID 477283 9/7 02:51 启动; `update_runs` 表只有 1 条记录: phase=`requested`, status=`running`, target=9.2 |
| 3 | 历史层 | 9/6 23:16:54 触发 update command (pid 460126), 9/6 23:28:52 exit code 0, handoff 路径 `/tmp/openclaw-update-run-handoff-Hblcwz/handoff.log` |
| 4 | 代码层 | dashboard dist `update-run-view-DVwiT6Fy.js` + `update-run-projection-lALEhkx7.js` 渲染 `update.run.changed` event; phase 枚举 `['requested','staging','validating','repairing','activating','restarting','verifying','finished']`; step status `['pending','in_progress','completed','failed','skipped']` |
| 5 | 用户层 | 用户记忆里有 "dashboard 显示 ≠ 实际功能" 硬规则 |

**根因**（精确到代码行 + DB 表）：

dashboard 从 `state.openclaw.sqlite` 的 `update_runs` 表读数据。该表只有 1 条记录：

```json
{
  "run_id": "49ea63a3-2ac5-4708-b600-fa5ea603da7b",
  "created_at_ms": 1788707985533,  // 2026-09-06T23:19:45+08:00
  "phase": "requested",            // 永远卡在 requested
  "status": "running",              // 永远 running
  "target_json": "{}",            // 目标版本 = 9.2 = 当前版本
  "before_json": "{\"version\":\"2026.9.2\"}",
  "steps_json": "[{\"step\":\"requested\",\"status\":\"in_progress\",\"startedAtMs\":1788707985533}]"  // 只有这一步
}
```

dashboard 显示规则（dashboard dist `update-run-projection-lALEhkx7.js`）：

```js
g = l.filter(e => e.status === 'completed').length      // 已完成
_ = l.filter(e => e.status !== 'skipped').length        // 总数
compactLabel = s(`updates.run.progress`, {completed: String(g), total: String(_)})  // 老王看到的 "已完成 0 个阶段, 共 7 个"
```

`phase` 字段：`requested` 是 phase 枚举第一个状态，gateway 因为 `target_version == current_version` 跳过了后续 staging/validating/activating/... 全部 phase，但 dashboard 没收到任何 transition event，phase 永远停在 `requested`。

**判断**：dashboard 假阳性 — 跟 9/7 早上 "memory plugin unavailable" 是同类 (dashboard UI bug)，但**不影响任何功能**。

**给老王的标准回复**：

1. 点 dialog "关闭" 按钮即可，不影响功能
2. 这是 OpenClaw 9.2 dashboard 的已知 UI bug，跟 memory page / update page 同一类（phase 永远停在 requested）
3. 如果想彻底清掉，可以手动 SQL 把 `update_runs.status='running'` 改成 `'succeeded'` + `phase='finished'`，但没必要

**改进措施（待做）**：等 OpenClaw 9.3+ 修复 dashboard update phase tracking，或在 `update.run.changed` event 推送逻辑里加 "target == current → 直接发 finished event"。


---

## 📋 2026-09-07 决策：Memory watch "index sources changed" 是设计行为 (atomic retry)

**触发**：用户报"日志显示 12:55 警告: 内存同步失败（watch）：错误：内存源内存/2026-09-07.md 在索引时发生更改;重试内存索引。"

**5 步实测**（先 D 实测，再列方案）：

| 步 | 维度 | 发现 |
|---|---|---|
| 1 | 效果层 | dashboard 没有报错；memory_search 工具仍可用 |
| 2 | 配置层 | `memory/2026-09-07.md` 存在，20 行 759 bytes，是 HEARTBEAT_OK 记录 |
| 3 | 历史层 | 8/19 决策 memory slot = memory-lancedb；7/30 修过 indexing race |
| 4 | 代码层 | OpenClaw memory-core 用 fs.watch + atomic snapshot 守 invariant (index 时文件不能改)；任何写入触发 "index sources changed" → retry |
| 5 | 用户层 | 9/7 早上 memory_search unavailable 是已知 UI bug 类；这次是 watch 行为不是 bug |

**实测证据**：

```bash
# stat 文件
stat memory/2026-09-07.md
# Birth: 2026-09-07 03:08:11 (手动补)
# Modify: 2026-09-07 12:55:22 (heartbeat 跑后被改)
# Change: 2026-09-07 12:55:22

# cron lastRun
openclaw cron list --json
# c6df3ff2 heartbeat-main lastRunAtMs: 1788756839617 = 12:53:59 CST
# 跟 modify 12:55:22 间隔 83s — heartbeat 跑完后写文件，watch 检测到变化 → 报错
```

**根因**：

OpenClaw memory watch 用 fs.watch + atomic snapshot 比对 file hash。任何写入（heartbeat 跑、auto-capture、dreaming promotion、用户编辑）都会触发 "index sources changed"，watch 自动 retry 重建 index。retry 是 self-healing 设计——保证 index 永远跟文件内容一致。

**memory_search 实测**（12:55 watch error 之后）：

```bash
openclaw memory search "memory watch index sources changed"
# 输出: Config warnings: plugins.entries.memory-core: plugin disabled 
# (memory slot set to "memory-lancedb") but config is present
# → 只有已知 warning, searchMs 正常, results 正常
```

**判断**：不是 bug，是 OpenClaw 设计行为。retry 自动完成，memory_search 不受影响。

**对照 "功能断没断 5 步法"**：

| 5 步法 | 这次 |
|---|---|
| 效果层 | memory_search 工具能用 ✅ |
| 配置层 | index 525/529 files ✅ |
| 历史层 | 7/30 修过类似 race ✅ |
| 代码层 | watch atomic snapshot 设计 ✅ |
| 用户层 | 已知 watch 行为 + self-healing ✅ |

**结论**：watch warning 是正常 noise。如果频率太高（如 > 10 次/小时），可考虑 heartbeat 不再写 9/7.md 或手动 file lock（不推荐）。**当前不需要修**。


---

## mcporter 故障模式（2026-09-21 落地，13/13 unhealthy 修复链）

**症状**：`mcporter list` 显示 "0 healthy; 13 errors" + 错误信息 "Previous daemon exited unexpectedly; verify retirement of its transports before deliberate recovery. No replacement was launched." 或 "code: 'daemon_unresponsive'"。

**5 步排查**（基于官方 `docs/daemon.md` + `dist/daemon/host.js` 源码）：

| 步 | 命令 | 看什么 |
|---|---|---|
| 1 | `pgrep -af mcporter` | 哪些进程在跑（HTTP bridge + daemon + systemd wrap） |
| 2 | `cat ~/.mcporter/daemon/user.json` | 上代 pid 是否还活；generation 是否变 |
| 3 | `ls -la ~/.mcporter/daemon/user.sock` | socket 是否 0 字节 + 老 mtime（= stale） |
| 4 | `systemctl --user status mcporter-daemon.service` | service 状态（`active` / `activating` / `failed`）+ restart counter |
| 5 | `tail /tmp/mcporter-daemon.log /tmp/mcporter-bridge.log` | 错误码 + stack trace |

**3 种 daemon 错误码含义**：
- `exit 127`：shebang `#!/usr/bin/env node` 找不到 node → **systemd PATH 问题** → 写 Drop-In
- `daemon_unresponsive`：读到 `user.json`（上代 metadata）→ **stale state 没清** → `rm user.json`
- `EADDRINUSE 3099`：daemon 试图 listen 3099，HTTP 桥占着 → **不该手动跑 daemon**（systemd service 已配 `mcporter daemon start --foreground`，应让 systemd 管理）

**完整修法**（按顺序）：
```bash
# 1. 杀残留 + 清 stale socket
pkill -f 'mcporter daemon start' 2>/dev/null
kill <HTTP-bridge-PID>  # 找 pgrep -af 'mcporter serve'
mcporter daemon stop
rm -v ~/.mcporter/daemon/user.sock 2>/dev/null

# 2. 启用 daemon service（如未 enable）
systemctl --user enable mcporter-daemon.service

# 3. 镜像 bridge 的 Drop-In（如 daemon 没有）
mkdir -p ~/.config/systemd/user/mcporter-daemon.service.d/
cat > ~/.config/systemd/user/mcporter-daemon.service.d/env-override.conf <<'EOF'
[Service]
Environment=PATH=/home/<user>/.nvm/versions/node/<ver>/bin:/usr/local/bin:/usr/bin:/bin:/home/<user>/.local/bin:/home/<user>/.npm-global/bin:/home/<user>/bin:/home/<user>/.bun/bin:/home/<user>/.nix-profile/bin:/home/<user>/.local/share/pnpm
Environment=HOME=/home/<user>
Environment=TMPDIR=/tmp
EOF
systemctl --user daemon-reload

# 4. 清 stale metadata + 重启 daemon
systemctl --user stop mcporter-daemon.service
rm -v ~/.mcporter/daemon/user.json
systemctl --user start mcporter-daemon.service

# 5. 等 5-8s 验证
sleep 5
mcporter daemon status  # 应显示 "Daemon pid <新 PID>"
mcporter list           # 应显示 "X healthy"
```

**永久化收益**：`enable` + Drop-In + `user.json` 删除三者都持久；下次 daemon 异常退到 user.json 残留时**仍需手动清理**。

**反向信号**：如果 `mcporter daemon status` 显示 "Daemon is not running" + `user.sock` 不存在 + `user.json` 含上代 pid —— 100% 是 `daemon_unresponsive` 路径，按上面 step 4 修。

---

### Drop-In 对称性 bug（mcporter 0.13.13 安装脚本缺陷）

**现象**：`mcporter-bridge.service` 装了 Drop-In（含 PATH/HOME/TMPDIR），**`mcporter-daemon.service` 没装**——两个 service 不对称。

**实测证据**：
```bash
# bridge 有 Drop-In
ls ~/.config/systemd/user/mcporter-bridge.service.d/env-override.conf   # 存在（348 B, 2026-09-13）
# daemon 没有
ls ~/.config/systemd/user/mcporter-daemon.service.d/                    # No such file or directory
```

**后果**：bridge 能启动（PATH 里有 node），daemon 启动即 exit 127（`/usr/bin/env: 'node': No such file or directory`）。

**修法**：把 bridge 的 Drop-In **逐字节镜像**到 daemon（用 `diff` 强制验证一致）：
```bash
diff ~/.config/systemd/user/mcporter-bridge.service.d/env-override.conf \
     ~/.config/systemd/user/mcporter-daemon.service.d/env-override.conf
# 期望：无输出（完全一致）
```

**易错点**：手工重写 PATH 时容易写错路径段（如 `.bin` vs `bin`）——**必须用 `diff` 校验**，不要凭记忆重敲。

---

## 插件启用/停用必须走「改配置 + 重启网关」（2026-10-02 落地）

**背景**：`openclaw plugins enable/disable` 会触发**全量插件运行时重载**。这台机器上插件收不掉自己的在途调用，重载必然超时，并在进程内留下一个半坏的运行时。**只读确认状态请用 `openclaw plugins inspect <id>`，不要用 enable 去「确认」。**

**实测证据**（2026-10-02 11:46，一次多余的 `plugins enable openclaw`，该插件本来就是 enabled）：
```text
plugins.setEnabled 219247ms ✗  Plugin runtime application failed during prepared
                               model runtime reload: prepared model runtime
                               publication (workspace plugins; agent main) timed out
Gateway generation 3: replacement applied.
Plugin firecrawl forced retirement after 5000ms: 1 still-running call(s)
Plugin tavily    forced retirement after 5000ms: 1 still-running call(s)
Plugin exa       forced retirement after 5000ms: 1 still-running call(s)
```

**后果（关键：别只看 readyz）**：进程没退出、`readyz` 一直报 `ready:true`，但 agent 运行时已经坏了——
```text
Error: prepared model runtime publication (workspace plugins; agent main) timed out
  → chat.metadata 失败  = 控制台「模型认证状态不可得」
  → heartbeat failed: prepared reply dispatch runtime owner was not published for main
```
`readyz` 只检查 HTTP 层 + 事件循环，**不覆盖 agent 运行时**，所以「ready」和「能干活」是两件事。

**修法**：
```bash
# 1. 备份
cp -p ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-$(date +%Y%m%d-%H%M%S)
# 2. 直接改 plugins.entries.<id>.enabled（不要用 plugins enable/disable）
# 3. 重启前必须校验
openclaw config validate
# 4. 重启网关
systemctl --user restart openclaw-gateway.service
# 5. 等 ready 后验证
openclaw plugins inspect <id>     # Status 应为 enabled 或 disabled
```
只想补回状态（不改启用状态）时，第 2 步可省，直接 `systemctl --user restart openclaw-gateway.service`。

**易错点**：
- `<id>` 不在 `plugins.allow` 里时，即使 `enabled: true` 也不会加载；`plugins.deny` 优先级最高。
- 重启要预留 7–10 分钟：`http server listening` 单次实测 130–246 秒，之后还有 sidecar 阶段；期间 `readyz` 可能已经返回 ready。
- 看到「模型认证状态不可得」先在日志里搜 `prepared model runtime publication`——有这条就是运行时坏了，**重启即可，不必去查模型配置或 API key**。

---

## CLI 回合命令必须显式加 `--timeout`（2026-10-02 实测）

`openclaw agent` 的默认 `--timeout` 是 **30000 ms**。而本机单个回合的准备阶段经常远超它：

```text
prep stages totalMs = 64914
  bootstrap-context  37104ms   ← 工作区 bootstrap 文件（SESSION-STATE.md / DREAMS.md / MEMORY-promoted.md 等）
  core-plugin-tools  22398ms
  （同一回合 memos 召回另计 20.3s，已含在 prep 内）
```

超时后 CLI 打印的是连接类错误，极易被误判成网关故障：

```text
Connection dropped without a close frame (check network and gateway load)
Gateway process stopped or became unreachable (confirm it is still running)
```

**判断方法**：同时看网关进程与端口。2026-10-02 13:50 那次实测——`MainPID` 未变、`18789` 仍在监听、同一时刻 UI 请求（`talk.catalog` / `sessions.viewers.set` / `agent.identity.get`）全部成功，纯粹是 **CLI 自己先放弃了**；日志里还有一条明确说明：

```text
Gateway agent call connection closed; the Gateway may still be running this turn (accepted run <runId>).
```

**用法**：
```bash
openclaw agent -m "..." --timeout 180000          # 回合类命令一律显式加 --timeout
systemctl --user show openclaw-gateway.service -p MainPID -p Result   # 先确认网关是否真挂了
ss -ltn | grep 18789
```

**易错点**：
- 不要因为 CLI 报连接错误就去重启网关——先确认 `MainPID` 和端口，两者都正常就只是 CLI 超时，重跑即可。
- 反过来，这条也说明**本机回合启动本身就慢**（prep 65s）。如果哪天要优化，`bootstrap-context` 是最大头（9 月 29 日实测 26.9s，10 月 2 日 37.1s，在变慢）。

<!-- project: path:/home/wszmd520520/.openclaw/workspace -->
