# ERR-2026-08-19-001 — OpenClaw builtin memory index hangs at SQLite write (not publish)

**Date**: 2026-08-19 12:00-12:47
**Severity**: High (memorySearch 离线化不可用)
**Status**: Root cause identified, fix attempted (E1), partial improvement
**Author**: Ada agent (with deep investigation, not gut-feel)

---

## 🎯 Symptom

`openclaw memory index --force --agent main` hangs:
- Process shows `do_epoll_wait` or `sigsuspend` waiting
- `memory_index_chunks` table never updated
- After 5+ min, killed by SIGTERM/SIGKILL
- `cache` table stays empty
- `main` file `mtime` never changes

User noticed: "以前 memorySearch 用 SiliconFlow 都好好的,为什么切到 ollama 后挂?"

## 🚨 Root Cause (after 1+ hour of investigation)

**Actual root cause: NOT publish stage, NOT ollama keep_alive. The bottleneck is `OpenClaw writing embedded chunks back to the temporary SQLite file`.**

Evidence chain:
1. ✅ ollama `/api/embed` batch=16 = 5.6s (health)
2. ✅ `publishMemoryDatabaseTables` ATTACH + INSERT 185 chunks = 0.4s (isolated test)
3. ❌ After batch completed, temporary SQLite file mtime stops advancing (12:44:43 stuck)
4. ❌ Log shows batch start/completed alternating, NO error/warning printed
5. ❌ Process state: `do_epoll_wait` or `sigsuspend` (waiting for something that never comes)
6. ❌ SiliconFlow era had the SAME issue (11:34 stuck at 185 chunks, not 2294)

User memory "以前用 SiliconFlow 好好的" was **inaccurate** — it was working because **lancedb plugin** (not builtin) was the actual search path. Builtin index was broken even then.

## 🔧 Fix Attempts

| Attempt | Action | Result |
|---------|--------|--------|
| A | Backup + wait longer | No, only 16 chunks per 30s written |
| B | Change `inlineBatchTimeoutMs` 600s → 30s (E1) | Partial: ollama calls faster, but SQLite write still hangs at ~48 chunks |
| C | Increase `--timeout 900` → 1800s | No improvement |
| D | Set ollama `keep_alive=24h` | No improvement (already in memory at hang time) |

## 🧠 Diagnosis Methods Used

1. **Isolated publish test**: ATTACH + INSERT 185 chunks in 0.4s (proves publish is NOT the bottleneck)
2. **Process fd inspection**: Saw temp SQLite file opened, but file mtime stuck
3. **Compare SiliconFlow era**: 11:34 also stuck at 185 chunks (proves this is OpenClaw builtin bug, not provider-specific)
4. **Batch progress measurement**: After E1, batch completed ~11 in 4 min, but chunks written only 48

## 💡 Lessons

1. **Always isolate test the suspected bottleneck before committing to a fix**
   - I assumed publish was broken for 30+ minutes based on guesswork
   - Real test (ATTACH + INSERT) proved publish works fine in 0.4s
2. **Verify user's memory claims with evidence**
   - User said "以前 SiliconFlow 都好好的" — this was wrong; it was lancedb plugin that worked
3. **E1 fix is partial, not complete**
   - Kept inlineBatchTimeoutMs: 30*1000 (no harm, future-proofs against truly hanging batches)
   - But root cause is in OpenClaw's batch-result → SQLite-write path, not in ollama

## 🎯 What To Do Next (recommendations)

1. **Keep E1 patch**: 1-line change, no harm if OpenClaw fixes upstream bug
2. **Revert memorySearch to SiliconFlow** (or keep trying ollama with longer timeouts)
3. **File upstream issue** at https://github.com/openclaw/openclaw with detailed reproduction
4. **Until upstream fix**: rely on `memory-lancedb` plugin (works fine with ollama)

## 📂 Files

- Patch dir: `/tmp/openclaw-patch-20260819-1228/`
- Modified: `/home/wszmd520520/.nvm/versions/node/v24.15.0/lib/node_modules/openclaw/dist/extensions/ollama/index.js:61`
  - Before: `inlineBatchTimeoutMs: 10 * 6e4` (600s)
  - After: `inlineBatchTimeoutMs: 30 * 1000` (30s)
---

## 🔴 2026-08-19 13:08 最终真相(推翻前面的"SQLite 写卡死"诊断)

### 真正的根因:不是 bug,是 CPU 推理慢

经过系统性隔离测试,根因 100% 确认:

| 测试 | 结果 |
|---|---|
| SQLite 写入(50 chunks,chunks+FTS+触发器) | **0.06s(866 chunks/s)** ✅ |
| OpenAI SDK 模拟 OpenClaw 调用(4 文本) | **3.8-4.5s/次,无重试** ✅ |
| 手动 ollama 短文本(2 字符) | **9.41s** |
| 手动 ollama 100 字符 | 27.76s |
| 手动 ollama 400 字符 | 13.17s |
| 手动 ollama 800 字符 | 26.13s |
| 真实 chunk 单条(752 字符) | **22.33s** |
| 真实 4-chunk batch | **45.10s** |

### 为什么之前误判"卡死"

1. **看起来像卡死**:每 batch 26s,2294 chunks 要 3-7 小时 → 观察窗口内"永远不完成"
2. **误判为 SQLite 写卡**:临时文件 mtime 停滞(实际是 WAL 模式,主文件不更新)
3. **误判为 ollama 超时**:短文本测试 4.6s 让 E1(超时 600s→30s)看起来合理,实际真实 chunk 45s 会**触发 E1 的 30s 超时重试,让问题更糟!**

### 模型事实

- bge-m3: 566.70M 参数,F16 精度,BERT family
- 跑在 **Windows 侧 ollama**(WSL2 localhost 转发)
- **CPU 推理**,每个请求固定 10-45s(与长度弱相关)
- Windows 侧无 GPU 加速(或未启用)

### 教训

1. **性能问题必须用真实数据测,不能用合成短文本**:短文本 4.6s 让所有"超时"假设看起来合理
2. **"每 batch 26s"不等于"卡死"**:要看吞吐率 vs 总量(2294 × 20s ≈ 7h)
3. **WAL 模式下 mtime 停滞≠没写入**:chunks 实际在增长(0→31→48)
4. **E1 改动(30s 超时)是负优化**:真实 chunk 45s > 30s,会触发重试/split,应回滚到 600s 或更高

### 建议方案(供决策)

| 方案 | 说明 | 可行性 |
|---|---|---|
| **G1: 换量化版 bge-m3** | `ollama pull bge-m3:latest` 默认 F16 → 找量化版(Q4/Q8) | 需确认 ollama 是否有 bge-m3 量化版 |
| **G2: Windows 侧 GPU 加速** | ollama 用 CUDA 跑 bge-m3(如果 Windows 有 NVIDIA GPU) | 需确认 GPU |
| **G3: 换小模型** | 如 `nomic-embed-text`(137M)或 `all-minilm`(23M),CPU 快 10-50x | 质量略降但可接受 |
| **G4: 接受慢,后台跑** | 启动后等 3-7 小时,期间不重启 | 可行但体验差 |
| **G5: 回滚 SiliconFlow** | memorySearch 用云端 API(快),放弃离线 | 失去离线能力 |

---

## ERR-2026-08-19-002 — 19:38 cron: Obsidian vault 全量 reindex 中途 revision race 回滚

**Date**: 2026-08-19 19:38
**Severity**: Medium (cron 触发的 obsidian reindex 失败,主 sqlite 状态未变)
**Status**: Detected, **不擅自重试**(等用户决策)

### 现象

cron job `d30b93dd-...` 检查 obsidian reindex 状态:
- 进程 503985 已消失
- 临时 reindex DB `openclaw-agent.sqlite.memory-reindex-*` 不存在
- 主 sqlite 仍为旧状态: **chunks=2291 sources=258 obsidian_files=0** (完全没并入)
- `/tmp/mem_index_obsidian.log` 末尾:
  ```
  [memory] embeddings: batch completed  (×154 批)
  Memory index failed (main): Memory index changed while full reindex was building
  (expected revision 48924, found 48927); retry the full reindex.
  ```

### 根因

memory 插件的并发安全保护:reindex 期间,主索引被另一个写入路径改了 revision
(48924 → 48927),插件主动放弃本次重建,回滚到主 sqlite → 临时 reindex DB 被清。

### 与 ERR-001 的关系

- ERR-001(12:00)卡在 SQLite write 阶段
- ERR-002(19:38)进入了 publish 阶段(154 批 embedding 都跑完了),但被并发保护打断
- 两次都是 builtin memory index 的不稳定性,触发来源不同

### 已采取行动

- 仅诊断 + 写日志,**不 kill/不重启 reindex**(用户明确指示"只观察 + 决策")
- 本轮 cron 不删,等用户拍板下一步

### 候选方案(供用户决策)

| 方案 | 思路 | 风险 |
|---|---|---|
| A. 静默窗口重跑 | 等无写入活动时(凌晨/心跳间隔)触发 `--force` | 再次撞 race,还是不写入 |
| B. 改用 lancedb 路径 | 既然 lancedb plugin 是真实搜索路径(参见 ERR-001 备注),绕开 builtin | 需要确认 lancedb 是否仍可用 |
| C. 关闭 cron | 停止自动重试,改为手动触发 | 信息透明度下降 |
| D. 锁文件机制 | 让 cron 先 `flock` 主 sqlite 防止写入冲突 | builtin 内部写入仍可能绕开锁 |

### 给后续 cron 的 hint

下次再检查时，优先看：
1. 进程是否在跑 → 不在则看主 sqlite obsidian_files 是否 > 0
2. 如果 chunks 仍 2291 / obsidian_files=0 且日志末尾是 "Memory index changed while full reindex was building" → **别重跑**，这是 revision race，直接汇报用户

---

## 🔄 ERR-2026-08-19-003 — 22:50 优化 ollama 冷启动，推翻 "keep_alive 无效" 错误结论

**Date**: 2026-08-19 22:50
**Severity**: Low（之前错记 keep_alive 优化无效，实际是**有效但没测对方法**）
**Status**: ✅ 优化完成，性能提升 50x
**Author**: Ada agent

### 🔴 错误结论

ERR-001 的 Fix Attempt D 写着：
> | D | Set ollama `keep_alive=24h` | No improvement (already in memory at hang time) |

**这误导了用户决策**——用户因此以为 keep_alive 方案不可行，走了 8/19 12:00 → 13:52 切 bge-m3 → nomic 的弯路。

### 真正的错误原因

当时测的"keep_alive=24h"是**在 OpenClaw memory-lancedb plugin 调用 ollama 时**测的。**但 memory-lancedb plugin 的 `OpenAiCompatibleEmbeddings.embed()` 代码里**根本不带 `keep_alive` 参数**（实测验证：grep `keep_alive` 在 plugin dist/index.js 返回 0 匹配）——所以无论怎么改请求，plugin 都不告诉 ollama 延长 keep_alive。

**那个"24h 无效"测的是错的层**——测的是 plugin 调用，不是 ollama server 端配置。

### ✅ 正确方案（已落地，22:50 验证通过）

**改 ollama server 端环境变量**（不是改 plugin 调用）：

Windows 管理员 PowerShell 一次性执行：
```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "-1", "Machine")
```

**不需要重启 ollama** —— ollama 在请求时读 OLLAMA_KEEP_ALIVE（行为已实测）。

### 实测验证

| 操作 | 优化前 | 优化后 |
|------|--------|--------|
| 已 loaded → 5 次连续嵌入 | 0.55-0.61s | 0.55-0.61s（一样）|
| 手动 unload + 重新嵌入 | **30-47s 冷启动** | **47s 冷启动**（一样，因为 unload 是主动的）|
| 5min idle 后再次嵌入（被动）| **30s 冷启动** | **0.6s 热调用**（永不 unload）|
| `expires_at` 显示 | 5min 后过期 | **2318-11-29（292 年后）** = 永久 |

### 关键发现

1. **ollama 不是 Windows 服务**（`Stop-Service ollama` 报 "Cannot find"），所以改环境变量不需要重启服务
2. **ollama 0.32 行为**：`/api/ps` 返回的 `expires_at` = `MaxDateTime - 当前时间`（292 年后）当 keep_alive=-1
3. **memory-lancedb plugin 内部**完全不传 keep_alive → 不修改 plugin 源码
4. **副作用**：模型常驻内存约 1GB（你 23GB RAM 不痛不痒）

### 教训

1. **优化要测对层**：之前测的是 plugin 行为（错），这次测的是 ollama server 行为（对）
2. **不要从单一测试就下"无效"结论**：应该先理解测的是哪一层，再下结论
3. **`Stop-Service` 报 "Cannot find" 不代表进程停了** —— ollama 不是服务形态，不能用服务命令管理

### 相关文档

- 完整方案记录：`~/.openclaw/workspace/TOOLS-memory-ai.md` "🚀 ollama keep_alive 优化" 章节
