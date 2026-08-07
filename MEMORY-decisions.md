# MEMORY-decisions.md — 关键决策归档（2026-06-11 系列）

> 从 `MEMORY.md` 拆分出来的"已完成关键决策"子域 (2026-07-30)。
> 主题：飞书插件升级、active-memory 模型切换、插件路径统一、API key 修复等已完成事件。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：OpenClaw bootstrap 走精确 basename 匹配（看 `run-attempt-V636cwT5.js` 白名单），`MEMORY-*.md` 不在白名单，按需 `read` 加载。

---

## 2026-06-11 active-memory 401 → 修复 → 200 OK 铁证

**结论**：volcengine API key `ff622315-85e...` 失效 → active-memory 切到 `siliconflow/Qwen/Qwen2.5-7B-Instruct`

**已做**：
- `openclaw.json`: `active-memory.config.model` = `siliconflow/Qwen/Qwen2.5-7B-Instruct` (modelFallback = `deepseek/deepseek-v4-flash`)
- OpenClaw v2026.6.5 自动 hot reload, 14:55:04 applied（**不需要 SIGUSR1/restart**）
- 备份: `/tmp/openclaw.json.bak-2026-06-11-1454`
- **15:04 首次 200 OK** (JSONL `/tmp/openclaw/openclaw-2026-06-11.log`): trace_id `e84c60afb9494f8716e7b47cc18c2335`, `activeProvider=siliconflow activeModel=Qwen/Qwen2.5-7B-Instruct done status=ok elapsedMs=5989`

**待办**：
- 去火山方舟 console 重新生成 API key,告诉我写到 `secrets/default.json[models][volcengine-plan].apiKey`
- Codex 升级应**同步升 bundled plugins** (feishu 仍 v2026.6.1)

**教训**（详见 `.learnings/ERRORS.md`）：
- v6.5 hot reload 自动检测文件改动,1.5 秒内应用（v6.1 无此能力）
- API key 失效时 v6.5 主动暴露,v6.1 silent
- Codex 升级应同步升 plugins

---

## 2026-06-11 15:31 火山 API key 修复 + active-memory 永久策略

**用户决策**：
1. **新 key**: `ark-d82cfb7d-09b3-4fdd-892b-b1a4c41a1fb7-9a372` (46 字符, Agent Plan 专属 API Key)
2. **active-memory 永久** = `siliconflow/Qwen/Qwen2.5-7B-Instruct` (modelFallback = `deepseek/deepseek-v4-flash`)

**已做**：
- `secrets/default.json[models][volcengine-plan].apiKey`: `ff6223...` (36, 失效) → `ark-d82cfb7d-...` (46, Agent Plan 风格)
- 备份: `/tmp/secrets.default.json.bak-2026-06-11-1525` (2492 bytes)
- curl 验证 200 OK: `Authorization: Bearer ark-...` 在 OpenAI /v3 和 Anthropic /v1/messages 端点都工作
- v6.5 file watcher 是否对 secrets/default.json 生效：⏳ 待观察（之前只测过 openclaw.json 改动）

**理解更新**：
- 火山方舟有 2 种 key 格式: `***-xxxx-...` (传统 36 字符) vs `ark-xxxx-...` (Agent Plan 46 字符, 新)
- 之前 14:47 我用 OpenAI 标准 `Authorization: Bearer` 测过 `***-` key → 401 失效
- 这次用同一种 `Authorization: Bearer` 测 `ark-` key → 200 OK ✅
- 结论: **不是格式问题, 是 key 是否被火山方舟承认** (老 key 平台已删)

**active-memory 永久 = siliconflow 的意义**：
- 火山 key 即使未来再失效, active-memory 仍工作 (siliconflow 51 字符 key 独立有效)
- **不**回切 volcengine, 除非用户明确指示

**火山方舟 baseUrl**（已记入）：
- OpenAI 协议: `https://ark.cn-beijing.volces.com/api/plan/v3`
- Anthropic 协议: `https://ark.cn-beijing.volces.com/api/plan/v1/messages` (实测 200)

---

## 2026-06-11 15:36-15:53 飞书插件升级 + 永久待解问题

**目标**：把 feishu 插件从 v6.1 升到 v6.5 修复 feishu-dedup "openKeyedStore is only available for trusted plugins" 错误

**实际结果**：
- ✅ global path 升 v6.1 → v6.5 (`/root/.nvm/.../node_modules/@openclaw/feishu`)
- ✅ projects path 升 v6.1 → v6.5 (`/home/wszmd520520/.openclaw/npm/projects/openclaw-feishu-dc69f44688/...`)
- ✅ projects package.json 同步更新 (`@openclaw/feishu: "2026.6.5"`)
- ✅ Gateway 重启 56493 → 56904, 13 plugins loaded, WebSocket ready
- ❌ **feishu-dedup 错误仍复发** (15:53:37 仍报 `openKeyedStore is only available for trusted plugins`)

**根因（已锁定 v6.5 Core 源码）**:
`registry-CQTOYCVL.js` 第 ~500 行:
```js
const assertPluginStateAllowed = () => {
  const record = pluginRuntimeRecordById.get(pluginId) ?? registry.plugins.find(...);
  if (record?.origin !== "bundled" && record?.trustedOfficialInstall !== true) {
    throw new Error("openKeyedStore is only available for trusted plugins in this release.");
  }
};
```

- `feishu` origin = npm/global or npm/projects (**不是 bundled**)
- `feishu` trustedOfficialInstall = false (npm install 不是 OpenClaw 官方安装)

**结论**：**升 v6.5 解决不了** — feishu 插件在 OpenClaw v6.5 中**被列为非 trusted 插件**, 失去 `openKeyedStore` API 权限。

**实际影响**:
- ✅ 飞书 WebSocket 通信正常 (`client ready` + `event-dispatch is ready`)
- ✅ 飞书消息收发功能正常
- ⚠️ 飞书消息**去重 (dedup)** 功能失效 — 可能 1-2 天内偶发重复通知
- ⚠️ `default.json` 已清空 (`{}`), 插件**每次重启**都会尝试 legacy import → 都失败

**待办（无法在用户端修复）**:
- 在 OpenClaw 项目 (EvoMap / GitHub) 申请 feishu 升为 trusted plugin
- 或等待 OpenClaw v6.6+ 调整 trusted plugin 列表
- 或放弃 feishu-dedup 功能, 接受偶尔重复通知

**备份**:
- `/tmp/feishu-plugin.bak-2026-06-11-1536/` (v6.1 完整备份, 49M)
- `package.json.bak-2026-06-11-1548` (v6.1 projects pkg.json)

**教训（详见 `.learnings/ERRORS.md`）**:
1. **OpenClaw 插件有 2 个路径**: global (`~/.nvm/.../node_modules`) + projects (`~/.openclaw/npm/projects/...`) — **升一个不够, 两个都要升**
2. **`npm install --no-save` 不改 package.json** — 需要 `--save` 或手动编辑
3. **升版本前要看 OpenClaw 是否有 trusted plugin 限制** — feishu/active-memory 等非 bundled 插件在 v6.5 受限
4. **gateway tool "restart" 模式是 emit** (只触发 hooks, 不真正 restart) — 真 restart 要用 `systemctl --user restart`
5. **systemctl restart 35s 超时是正常的** (Gateway 内存清理 + plugins lazy load) — exec 工具 35s 超时**不代表失败**

---

## 2026-06-11 16:14-16:21 卸 projects/feishu, OpenClaw 自动 fallback global

**目标**: 项目更整洁 — 卸 projects 路径的 feishu, 让 OpenClaw 自动 fallback global

**操作**:
- `cd /home/wszmd520520/.openclaw/npm/projects/openclaw-feishu-dc69f44688 && npm uninstall @openclaw/feishu`
- `removed 42 packages` (feishu + 41 个依赖)
- `package.json` `dependencies: {}` (feishu 引用已删)
- `systemctl --user restart openclaw-gateway` (走完 shutdown 3.7s + 启动 15.7s)
- **新 Gateway PID 58042** (16:15:46 启动)

**OpenClaw 实际行为**:
- 物理路径 `~/.openclaw/npm/projects/openclaw-feishu-dc69f44688/node_modules/@openclaw/feishu` 不存在 ✅
- OpenClaw 启动时找不到 projects path feishu, **自动 fallback global path** ✅
- plugins_json 实际加载: `manifestPath: /home/wszmd520520/.nvm/versions/node/v24.14.0/lib/node_modules/@openclaw/feishu/openclaw.plugin.json`
- **但** installed_plugin_index 表 `installPath` 字段仍记录旧 projects 路径 → "shared SQLite state conflicting metadata" 警告仍在 (已知基线, 06-07 已记入)

**doctor 警告变化**:
- ✅ **feishu duplicate plugin id 警告: 1 → 0** (消了)
- ⚠️ 其他 4 个 duplicate plugin id (acpx / diagnostics-otel / diffs / lobster): 不变 (它们的项目目录还在)
- ⚠️ "shared SQLite state conflicting metadata": 不变 (OpenClaw 决定 "Left plugin install index in place" — 不主动改 SQLite state)

**feishu-dedup 错误 (仍存在)**:
- 16:16:02 仍报 `openKeyedStore is only available for trusted plugins in this release.`
- **符合预期** — 不是路径问题, 是 OpenClaw v6.5 Core 政策 (origin ≠ "bundled" && trustedOfficialInstall ≠ true)
- global 与 projects 同样受限, 卸 projects 不修这个问题

**备份**:
- `/tmp/openclaw-feishu-dc69f44688-bak-2026-06-11-1614/` (完整 49M 备份)
- `/tmp/openclaw-feishu-pkg.bak-2026-06-11-1614` (projects package.json)
- `/tmp/openclaw-feishu-pkg-lock.bak-2026-06-11-1614` (projects package-lock.json)

**教训 (详见 .learnings/ERRORS.md)**:
1. **OpenClaw 自动 fallback** — 卸了 projects path, **不需要改任何 config** OpenClaw 自动用 global path
2. **installed_plugin_index.installPath 字段是陈旧数据** — OpenClaw 不会主动清理 (这是 known 已知基线)
3. **卸 projects 不修 trusted plugin 限制** — global 与 projects 同样受 OpenClaw v6.5 限制
4. **doctor "conflicting metadata" 警告独立于 duplicate plugin id** — 前者是 SQLite state 内部冲突, 后者是 npm 路径冲突

---

## 2026-06-11 16:41-16:45 卸载 4 个 global 插件，保留 user-level

**背景**:
- 4 个插件 (acpx / diagnostics-otel / diffs / lobster) 同时存在两个路径:
  - user-level: ~/.openclaw/npm/node_modules/@openclaw/<name> (版本新: 5.12~5.26, OpenClaw 内部 release 渠道装的)
  - global: ~/.nvm/.../node_modules/@openclaw/<name> (版本老: 5.2~5.7, npm 装的)
- 两个路径同时存在触发 "duplicate plugin id" doctor 警告

**方案**: 用户拍板 — 卸 global（老版本），保留 user-level（新版本）

**操作**:
- `npm uninstall -g @openclaw/acpx @openclaw/diagnostics-otel @openclaw/diffs @openclaw/lobster`
- removed 269 packages (4 个插件 + 依赖)
- Gateway restart (PID 59484, 16:43:19 启动)

**效果**:
- ✅ doctor 警告: 6 → 2 (-4 条 duplicate plugin id 全部消了)
- ✅ 4 个插件仍从 user-level 加载（版本不变: 5.18/5.12/5.12/5.26）
- ✅ 功能零影响（acpx ACP runtime ready + lobster workflow 正常）
- ⚠️ 剩余 2 条 = "Left plugin install index" state 基线（06-07 已记入）

**备份**:
- /tmp/openclaw-acpx-userlevel-bak-2026-06-11-1631/ (180K)
- /tmp/openclaw-diagnostics-otel-userlevel-bak-2026-06-11-1631/ (100K)
- /tmp/openclaw-diffs-userlevel-bak-2026-06-11-1631/ (9.6M)
- /tmp/openclaw-lobster-userlevel-bak-2026-06-11-1631/ (12M)

**关键教训 (详见 .learnings/ERRORS.md)**:
1. **OpenClaw 有两套插件路径**: user-level npm (~/.openclaw/npm/) + global npm (~/.nvm/.../node_modules/@openclaw/)
2. **user-level 版本通常比 global 新** — 卸 global 保留 user-level = 消警告 + 不丢功能
3. **user-level 路径是 OpenClaw 内部 release 渠道装的** — npm registry 404，不是 npm install 能装到的
4. **优先级 user-level > global** — OpenClaw 正确加载 user-level，global 是"多余"的
5. **全局 npm uninstall -g 不影响 OpenClaw 加载** — OpenClaw 通过 plugins.load.paths 找 user-level

---

## 2026-06-11 17:07-17:14 飞书插件统一到 user-level + plugins.load.paths 更新

**操作**:
1. `cd ~/.openclaw/npm && npm install @openclaw/feishu@2026.6.5` (安装到 user-level, added 295 packages)
2. `npm uninstall -g @openclaw/feishu` (卸载 global, removed 42 packages)
3. `openclaw.json` → `plugins.load.paths` 添加 `/home/wszmd520520/.openclaw/npm/node_modules/@openclaw` (user-level 路径)
4. Gateway restart (PID 62296)

**效果**:
- ✅ feishu 从 user-level 加载 (WebSocket 正常, bot open_id resolved)
- ✅ global feishu 已删
- ✅ doctor 警告: 仅 2 条 state 基线
- ⚠️ feishu-dedup 错误仍报 (trusted 限制, 与路径无关)
- ✅ 5 个插件路径完全统一: acpx/diagnostics-otel/diffs/lobster/feishu 全部 user-level

**备份**:
- `/tmp/openclaw-feishu-userlevel-bak-2026-06-11-1707/` (v6.5 完整备份)

**关键教训**:
1. **plugins.load.paths 需要包含 user-level 路径** — 只有 global 路径时, user-level 路径的插件不会被发现
2. **npm install --prefix 在 user-level 目录可以装插件** — 需手动指定 `cd ~/.openclaw/npm && npm install`
3. **plugins.allow 中 feishu 保留** — 不需要移除(与 diagnostics-prometheus 不同, feishu 是核心插件)
4. **feishu-dedup 错误与路径无关** — 是 OpenClaw v6.5 Core trusted 限制, global/user-level/projects 都一样
---

## 2026-07-30 22:00 memory-lancedb 静默 16 天 → 完整复盘 + patch 恢复

**症状**：07-17 12:47 → 07-30 22:00，memory-lancedb 一直报 `Unsupported embedding model: BAAI/bge-m3`，但 memory-core 自动 fallback 顶替 slot，用户完全无感。

**根因链**（铁证，来自 `~/.openclaw/backups/memory-lancedb-config.js.before-bge-m3-map.20260702-142343`）：

1. **07-02 14:23**：手动 patch 插件 `EMBEDDING_DIMENSIONS` 白名单，加 `"BAAI/bge-m3": 1024`
2. **07-14 08:29**：LanceDB 最后一次成功写入（version 123，铁证来自 `memories.lance/_versions/18446744073709551514.manifest` mtime）
3. **07-15 21:47**：npm 装 `2026.7.1` 到独立 project 目录，**覆盖了本地 patch**（目录 mtime = 2026-07-15 21:47:26）
4. **07-17 12:47**：gateway SIGUSR1 重启后 plugin 第一次报 disabled（journalctl 铁证）
5. **07-17 ~ 07-30**：16 天静默失败，每次 gateway 重启都报，但 memory-core fallback 掩盖

**修复**（22:03 落地）：

1. **patch**（写入 plugin 源码）：
   - 文件：`/home/wszmd520520/.openclaw/npm/projects/openclaw-memory-lancedb-6a4d78c41e__openclaw-generation__g-a39a72904fe34382/node_modules/@openclaw/memory-lancedb/dist/config.js`
   - 备份：`dist/config.js.bak-before-bge-m3-patch-20260730-220236`
   - 改动：第 32-35 行加 `"BAAI/bge-m3": 1024`

2. **openclaw.json embedding 清理**（移除我之前误加的 apiKey/dimensions，恢复 07-14 干净状态）：
   ```json
   "embedding": {
     "provider": "openai",
     "model": "BAAI/bge-m3",
     "baseUrl": "https://api.siliconflow.cn/v1"
   }
   ```

3. **`systemctl --user restart openclaw-gateway`** 硬重启

4. **验证**（22:06 铁证）：
   ```
   22:06:00 [plugins] memory-lancedb: plugin registered
   22:06:08 [plugins] memory-lancedb: injecting 3 memories into context
   ```
   `memory_search` 返回 `"provider": "openai-compatible", "model": "BAAI/bge-m3"`，走真实向量索引。

**用户拍板**（22:10）：
- 把这次故障根因 + 防护要点记到 `.learnings/LEARNINGS.md` (2026-07-30 22:00)
- 把 apiKey 暴露事件记到 `.learnings/ERRORS.md` (2026-07-30 21:30)
- 重写 `TOOLS-memory-ai.md`（之前 95 行全是错误结论）
- 修正 `MEMORY.md` 第 99 行（之前"必须 dimensions"是错的）

**用户拍板**（22:10）**待办**（不立即执行）：
- ⏳ 轮换 SiliconFlow apiKey（transcript 已暴露 51 字符 key），等用户拿到新 key
- ⏳ 建 `scripts/repatch-memory-lancedb.sh`（gateway 启动前自动检查 + 重打 patch）

**教训**（详见 `.learnings/LEARNINGS.md`）：

- "手动 patch × 全局重构 = 静默失败" — 任何本地 patch 都必须文档化 + 自动化重打
- **查历史备份是定位"以前能用"类问题的第一动作**，不是猜代码路径
- **memory-core fallback 是双刃剑**：降级掩盖故障，需要主动监控 slot 实际用的是哪个 plugin
- **journalctl 3 天窗口 + 备份 mtime + LanceDB 数据 mtime** 三个时间戳交叉验证是定位历史真相最可靠的方法

**状态快照**（2026-07-30 22:10）：

- `plugins.entries.memory-lancedb.enabled = true` ✅
- `plugins.entries.memory-lancedb.config.embedding` = `{provider:openai, model:BAAI/bge-m3, baseUrl:https://api.siliconflow.cn/v1}` ✅
- `plugins.slots.memory = "memory-lancedb"` ✅
- plugin 2026.7.1 patched（白名单 + bge-m3: 1024）✅
- Gateway PID 1425501, 22:03 启动 ✅
- 记忆搜索走 LanceDB 真实向量索引 ✅

---

## mcporter 升级 0.12.3 → 0.13.0 (2026-08-07 12:30)

**触发**: 用户拍板"直接升 0.13.0"（changelog 含 MCP 2.0 协议 + 大量 bugfix + OAuth 安全增强）

**操作**:
1. `npm i -g mcporter@0.13.0`（12s，38 packages changed）
2. 停旧 daemon (PID 1770) + 旧 serve (PID 606)
3. 清理旧 socket (`~/.mcporter/daemon/*.sock`)
4. 启动新 daemon (PID 39541) + 新 serve (PID 39554)
5. 验证 4 项：CLI version / initialize / tools list / amap 真实调用

**关键不变量 (记忆 1 硬约束)**: 
- openclaw.json `mcp.servers.mcporter-bridge.timeout=60` + `connectTimeout=10` **升级后保留生效**
- curl initialize 耗时 <1s（13 server 冷启动远未触发 60s 边界）
- 13 servers + 160 tools 全部就绪

**新版本主要改进 (MCP 2.0)**:
- 支持 MCP 协议 2026-07-28 (stateless + server/discover 协商)
- 双协议桥接 (serve 单一端点兼容 2026-07-28 + 2025-era)
- OAuth RFC 9207 issuer 验证 + Client ID Metadata Documents
- Daemon socket timeout = 闲置预算 (progress frame 刷新)，OAuth 长流程不再重启 daemon
- TypeScript SDK v2 升级，v1 仅作 legacy 测试 fixture

**rollback 路径** (如有问题):
```bash
kill 39541 39554
rm -f ~/.mcporter/daemon/*.sock
npm i -g mcporter@0.12.3
nohup mcporter daemon start --foreground &
nohup mcporter serve --http 3099 &
```

**memory-order 检查**: 0.12.3 (2026-07-01) → 0.12.4 (2026-08-02) → 0.13.0 (2026-08-04)；直接跳 0.12.4 升 0.13.0 是用户拍板（changelog 显示 0.13.0 已有完整 migration + 0.12.4 是过渡版本）
