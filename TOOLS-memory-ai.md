# TOOLS-memory-ai.md — Memory & AI 配置

> 从 `TOOLS.md` 拆分出来的 memory / AI 子域 (2026-07-30)。
> 主题：长期记忆存储 + 嵌入模型 + 召回管线。
> 主索引见 → `TOOLS.md`。
>
> ⚠️ **本文档 2026-07-30 22:10 完全重写**。此前版本（0-19 点）里所有"必须写 dimensions"、"apiKey 缺失"的结论都是**错误诊断**，实际根因是 npm 升级覆盖了本地 patch。见文末"故障复盘"。

---

## 🔮 memory-lancedb 插件配置（硅基流动 BAAI/bge-m3）

**场景**: 替换 memory-core 的 SQLite 向量存储，改用 LanceDB + 硅基流动嵌入模型，实现高效语义记忆召回。

### 真实工作机制（2026-07-30 22:00 铁证）

memory-lancedb 插件 `2026.7.1` 版走 **Path A (`OpenAiCompatibleEmbeddings`)** 路径，代码分流条件（`dist/index.js:310`）：

```js
if (provider === "openai" && apiKey) return new OpenAiCompatibleEmbeddings(...);
return new ProviderAdapterEmbeddings(...);
```

**但** 07-14 前 memory-lancedb 用同样的 config 能工作，其中 config **无 apiKey 也无 dimensions**。原因是：
1. `provider === "openai"` 但 `apiKey` 缺失 → 走 Path B (`ProviderAdapterEmbeddings`)
2. Path B 通过 host 的 `openai-compatible` provider adapter 调用 SiliconFlow（apiKey 由 host 从 `secrets/default.json[models].siliconflow.apiKey` 注入）
3. SiliconFlow bge-m3 endpoint **不接受 `dimensions` 参数**（HTTP 400 code 20015）
4. Path B 不传 `dimensions`，所以能工作

因此**真正的配置**（07-14 前能工作的版本）就是**不写 apiKey，不写 dimensions**：

```json
"memory-lancedb": {
  "enabled": true,
  "config": {
    "embedding": {
      "provider": "openai",
      "model": "BAAI/bge-m3",
      "baseUrl": "https://api.siliconflow.cn/v1"
    },
    "autoRecall": true,
    "autoCapture": true,
    "recallMaxChars": 400,
    "captureMaxChars": 500,
    "dreaming": { "enabled": true }
  }
}
```

**同时 `plugins.slots.memory` 必须设为 `"memory-lancedb"`**。

### ⚠️ 必须打的 patch（否则 plugin 报 `Unsupported embedding model`）

插件 `2026.7.1` 版的 `config.js` 里 `EMBEDDING_DIMENSIONS` 白名单**默认只有 OpenAI 两款模型**：

```js
// dist/config.js:32-35 (原始)
const EMBEDDING_DIMENSIONS = {
    "text-embedding-3-small": 1536,
    "text-embedding-3-large": 3072
};
```

**必须手动改为**（加 bge-m3 条目）：

```js
const EMBEDDING_DIMENSIONS = {
    "text-embedding-3-small": 1536,
    "text-embedding-3-large": 3072,
    "BAAI/bge-m3": 1024
};
```

**Patch 目标文件**：
```
/home/wszmd520520/.openclaw/npm/projects/openclaw-memory-lancedb-*/node_modules/@openclaw/memory-lancedb/dist/config.js
```

**Patch 触发**：任何以下操作都会覆盖 patch，需要**重打**：
- `npm install @openclaw/memory-lancedb`
- OpenClaw 主程序升级（若带 plugin 目录替换）
- 插件版本切换

### 一键重打 patch 脚本（已落地）

`scripts/repatch-memory-lancedb.sh` 已建（7396 字节，5 个测试全部通过）：

```bash
bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh                # 检查+打 patch（如需）
bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh --verify-only   # 只检查，不动文件（CI 用）
bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh --restart       # 打 patch 后硬重启 gateway
bash ~/.openclaw/workspace/scripts/repatch-memory-lancedb.sh --help          # 查看完整说明
```

**特性**：
- **Idempotent**：已 patched 状态运行 = skipped，零副作用
- **自动备份**：每次打 patch 前备份到 `config.js.bak-before-repatch-YYYYMMDD-HHMMSS`
- **精准插入**：用 python 智能定位 `EMBEDDING_DIMENSIONS` 对象，不依赖脆弱的 sed 正则
- **退出码**：0=成功/无需动作，1=错误/需要手动修复
- **颜色输出**：TTY 下 `[ok]/[warn]/[err]` 有色标注，管道/重定向下自动去色

### 🔒 自动防护：systemd drop-in 钉子

为防 `npm install` 后忘记重打，**已加 systemd ExecStartPre 钩子**：

文件：`/home/wszmd520520/.config/systemd/user/openclaw-gateway.service.d/00-repatch-memory-lancedb.conf`

```ini
[Service]
ExecStartPre=-/home/wszmd520520/.openclaw/workspace/scripts/repatch-memory-lancedb.sh
```

**效果**：每次 `systemctl --user restart openclaw-gateway`（无论手动、crash 重启、Watchdog 触发），**都先自动跑 re-patch 脚本**，再启 gateway。

**铁证**（2026-07-30 22:32 测试）：
- 临时手动 unpatch（`"BAAI/bge-m3": 1024` 行删除）
- `systemctl --user restart openclaw-gateway`
- 22:32:48 drop-in 跑脚本 (PID 1427874) → `status=0` 成功
- 22:32:48 patch 自动恢复
- 22:34:24 memory-lancedb 注入 3 memories 进入 context ✅

**安全设计**：
- `-` 前缀 (`-ExecStartPre=...`)：脚本失败 gateway 仍启动（因为 memory-core 可 fallback）
- `ignore_errors=yes`：systemd 不会因 patch 脚本失败而拒绝启动

### 验证步骤

1. **重启 Gateway**（配置生效 + plugin 重新加载 patched 代码）：
   ```bash
   systemctl --user restart openclaw-gateway
   ```

2. **看日志**：
   ```bash
   journalctl --user -u openclaw-gateway.service --since "1 minute ago" | grep memory-lancedb
   ```
   应该看到 `plugin registered` + `initialized (model: BAAI/bge-m3)`，**没有** `disabled until configured`。

3. **实测 recall**：
   ```
   memory_search(query="...", maxResults=3)
   ```
   返回结果应有 `"model": "BAAI/bge-m3"` 和 `"provider": "openai-compatible"`。

---

## 🚨 故障复盘：2026-07-30 memory-lancedb 静默 16 天

### 故障时间线

| 时间 | 事件 |
|---|---|
| 05-24 ~ 07-02 | 手动打 patch：给 `EMBEDDING_DIMENSIONS` 加 `"BAAI/bge-m3": 1024` |
| 07-02 14:23 | 备份 patch 前源码为 `~/.openclaw/backups/memory-lancedb-config.js.before-bge-m3-map.20260702-142343` |
| 07-14 08:29 | LanceDB 最后一次成功写入（version 123） |
| 07-15 21:47 | npm 装 `2026.7.1` 到独立 project 目录，**覆盖了本地 patch** |
| 07-17 12:47 | 第一次 gateway restart 加载新 project，plugin 静默报 `Unsupported embedding model: BAAI/bge-m3` |
| 07-17 ~ 07-30 | memory-core 自动 fallback 顶替 slot，日常记忆搜索仍能用，**用户完全没察觉** |
| 07-30 21:44 | 用户提出"以前能用" → 查历史备份 |
| 07-30 22:03 | 重打 patch，硬重启 |
| 07-30 22:06 | LanceDB 恢复 injecting + 记忆搜索走真实向量索引 |

### 根因

**"手动 patch × npm 版本升级 = 静默失败"**——手动 patch 是**局部记忆**，npm 是**全局重构**，全局重构不会记得局部记忆。

同类模式：
- Docker 里 `docker exec` 手改 → 容器重建后丢失
- OS package 的 `/etc` 手改 → 系统升级覆盖
- 编译过的 binary 打补丁 → 重新编译丢失

### 我当天犯的诊断错误

调查过程中我先后**四次**给出错误结论：

1. ❌ "SiliconFlow apiKey 缺失，配置需加 apiKey" → 事实：Path B 不需要 apiKey
2. ❌ "SiliconFlow bge-m3 需要 dimensions=1024" → 事实：SiliconFlow 拒绝 dimensions 参数
3. ❌ "plugin 2026.7.1 版新增了严格白名单" → 事实：2026.4.25 版就有，是 patch 覆盖问题
4. ❌ 把 SiliconFlow apiKey 完整打印到 transcript 引发安全暴露 → 已记 `.learnings/ERRORS.md`

用户拍板"查 07 月备份"是**决定性的关键指令**。没有备份链就查不到 `memory-lancedb-config.js.before-bge-m3-map` 这个铁证文件名。

### 防护要点

- **任何本地 patch 必须记录到 `TOOLS-*.md` 或 `SOP` 文件**
- **npm 升级前先检查有没有本地 patch 需重打**
- **memory-core fallback 会掩盖 memory-lancedb 故障**——slot 系统的降级是双刃剑

---

## 🔬 memory-core 备用方案

memory-core 是 slot 默认降级方案，走 SQLite 向量存储。不需要外部 API，但**语义能力弱于 LanceDB**。

**切换回 memory-core**：
```json
"plugins": {
  "slots": { "memory": "memory-core" },
  "entries": {
    "memory-lancedb": { "enabled": false, ... },
    "memory-core": { "enabled": true, ... }
  }
}
```
