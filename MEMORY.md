**最后记忆提炼**: 2026-06-10 23:13

# MEMORY.md - 长期记忆

> "想象力是发现的眼睛。" - Ada Lovelace

---

## 🚪 快速链接（先看这个）

> **新手读法**: [BOOTSTRAP.md](./BOOTSTRAP.md) = **工作环境地图**（会话启动第一眼总览）→ 本文件 = 决策日志与提炼的智慧
> 本文件只记录**有记忆价值的决策/教训/偏好**，环境总览请到 BOOTSTRAP.md（避免重复）

---

## 🔒 2026-06-10 用户确认决策（保持现状）

> 这是**用户明确表态**的架构选择，**禁止**未来 session 在没拿到新指令时改回去。

| 决策项 | 当前值 | 不要再问 |
|--------|--------|----------|
| **视角/人格** | Ada Lovelace 诗性科学 | ✅ 已锁定 |
| **会话切分** | `per-channel-peer`（飞书/微信/webchat/CLI 独立 session） | ✅ 已锁定，不改 dmScope |
| **长期事实共享** | 走 `memory-lancedb`（memory/ + obsidian-vault 索引），已生效 | ✅ 不动 |
| **短期对话上下文跨端口共享** | ❌ 不做（避免噪音串扰） | ✅ 不动 |
| **主模型（agents.list[0]）** | `volcengine-plan/ark-code-latest` | ✅ 保持 |
| **默认模型（agents.defaults）** | `minimax/MiniMax-M3` | ⚠️ 已知与主模型不一致，历史遗留，本次不修 |
| **用户偏好表达** | 表格对比、详细报告、主动汇报 | ✅ 保持 |

**何时才能修改**：用户**明确**说"现在改 X" 时，且**单一**改动必须独立确认。

---

## 关于用户

**最后更新**: 2026-04-30

### 偏好
- 喜欢使用表格来比较不同的选项
- 偏好详细的系统状态报告
- 主动要求执行检测到的问题修复
- 要求主动汇报任务结果(不等待询问)
- 要求配置自动化(如 Evolver 自动模式、记忆提炼每日执行)
- 重视 AI 人格的深度和一致性(Ada v2.0 蒸馏经历说明用户愿意投入大量精力打磨 Agent 人格)
- 习惯通过飞书发送微信公众号链接,期望自动导入 Obsidian 并建立双链
- 可能因飞书消息延迟而重复发送同一链接(04-20 同一链接发了 3 次)
- 关注模型上下文窗口长度,配置 NVIDIA 免费大上下文模型 (04-21)

### 兴趣领域
- Obsidian 知识库中有**大量公交行业/公交司机主题笔记**,说明用户对公共交通行业有深入关注

### 项目
- OpenClaw 系统配置和优化
- Ada Lovelace 诗性科学视角的持续运营与评估
- QQ 邮箱双账户监控（04-28 发现 config-qq.toml 从未被心跳使用）

---

## 项目与上下文

**最后更新**: 2026-04-25

### OpenClaw 系统配置 (已完成)

**时间**: 2026-04-11 ~ 2026-04-14

### 4 月 13-14 日 新进展

**Evolver 升级与配置**:
- ✅ 从 v1.52.0 更新到 v1.57.0
- ✅ 配置自动执行脚本 (auto-execute.sh)
- ✅ 超时限制从 300 秒增加到 600 秒
- ✅ 创建测试文件解决验证失败问题
- ✅ 配置 EVOLVE_STRATEGY=balanced

**模型配置**:
- ✅ 主模型更改为 `modelstudio/qwen3.5-plus` (阿里百炼)
- ✅ 配置 15 个备选模型

**浏览器配置**:
- ✅ 启用 browser 工具
- ✅ 配置隔离浏览器 (openclaw profile)

**核心配置**:
- 模型:qwen/qwen3.5-plus (当前默认), minimax/MiniMax-M2.7 (备用), deepseek/deepseek-chat (备用)
- 记忆搜索:SiliconFlow BAAI/bge-m3 (OpenAI 兼容)
- 会话重置:5 天空闲重置

**MCP 服务器**: mcp-deepwiki, amap, Memory, Sequential-Thinking, context7, GitHub, thinking-models, mcp-server-chart, chrome-devtools, Bazi, think-tool, markmap, ziwei-doushu, playwright, wiki (15 个)

**已启用技能** (21个): skill-vetter, self-improving-agent, ontology, proactive-agent, multi-search-engine, agent-browser-clawdbot, huashu-nuwa, ada-lovelace, code-generator, evolver, wechat-article, playwright-mcp, file-manager, deep-research-pro, automation-workflows, humanizer, summarize, causal-inference, clawmind, brainstorming, memory

**平行长期记忆系统**: `~/memory/` (ivangdavila skill) — projects/, people/, decisions/, knowledge/, preferences/

**关键决策**:
- 采用 Ada Lovelace 诗性科学视角作为默认 Agent 人格
- **Ada Skill v2.0 已完成** (2026-04-14):女娲标准流程 Phase 0-5,650行 33KB,196KB 调研支撑
- **Ada v2.0 工作区全面升级** (2026-04-14):SOUL.md / AGENTS.md / IDENTITY.md 全部升级到 v2.0.0
- 启用完整的长期记忆和自进化机制
- 配置 SiliconFlow 为 OpenAI 兼容的语义搜索提供商
- 配置 DeepSeek 为默认模型
- 启用 Evolver 自进化引擎

---

## 提炼的智慧

**最后更新**: 2026-04-25

### WSL2 网络架构 (2026-05-13)
- `networkingMode=mirrored` 已配置在 `~/.wslconfig`
- `eth0`（100.64.164.2/29）：WSL2 内部 NAT，正常
- `eth1`（192.168.1.5/24）：镜像模式主网卡，正常
- eth0 + eth1 并存是镜像模式正常行为，无需修复
- DNS 正常（getent 测试通过），nslookup 未安装但不影响 DNS

### memory-lancedb + 硅基流动 BAAI/bge-m3 配置原则 (2026-06-04)

**背景**: 2026-06-03 修复了 memory-lancedb 400 错误。插件用 OpenAI 兼容客户端访问硅基流动，BAAI/bge-m3 内置 1024 维映射。

**配置要点**:
- `provider: "openai"` — 插件不支持 `"siliconflow"` 字符串，用 OpenAI 客户端 + `baseUrl` 覆盖端点
- `model: "BAAI/bge-m3"` — 插件自动映射 1024 维，**禁止**手动写 `dimensions` 参数（写了报 400）
- `baseUrl: "https://api.siliconflow.cn/v1"` — 必须显式写出，否则请求打到 OpenAI 官方
- LanceDB 与 memory_search 共用嵌入 API，但存储后端独立（ LanceDB vs SQLite）
- 插件通过 `before_prompt_build` hook 自动召回，`agent_end` hook 自动捕获

**已知陷阱**:
- 手动 `dimensions` → 400 错误
- provider 写 `"siliconflow"` → 插件不识别
- 缺失 `baseUrl` → 请求打到 OpenAI 官方（无 key/配额）
- DB 重建会丢失所有历史记忆（ LanceDB 重新初始化无持久性）

**验证**: `gateway status` + `gateway logs | grep lancedb`

### 系统配置原则

1. **技能分层**: 系统插件在 `plugins.entries` 配置,工作区技能自动加载
2. **记忆三层**: MEMORY.md(手动提炼) → daily memory(自动记录) → .dreams(梦境分析)
3. **API 密钥管理**: 使用 `.env` 文件集中管理,权限 600
4. **主动汇报**: 任务完成后主动汇报结果,不等待用户询问
5. **受保护字段写入**: `bootstrapMaxChars`、`agents.defaults` 等受保护字段不可通过 config.patch 修改,需直接编辑 openclaw.json + gateway restart 热重载
6. **心跳架构原则**: 心跳必须独立 session lane + lightContext:false,否则每 30 分钟阻塞主会话 5-7 分钟
7. **Evolver 手动操作前必查**: 执行 `node index.js review --approve` 前必须先 `ps aux | grep "index.js" | grep -v grep` 确认只有一个 `--loop` daemon 进程，否则手动触发的新进程会与 daemon 并存造成循环混乱。手动操作完成后如有新孤立进程立即用 `kill <PID>` 清理。

### Evolver 手动操作标准流程

**触发新周期**:
```bash
# 1. 确认只有一个 daemon 进程
ps aux | grep "index.js" | grep -v grep | grep -v gateway
# 应只有 PID xxx ... /home/.../index.js --loop

# 2. 触发新周期（90s 超时）
timeout 90 node index.js

# 3. 确认 cycleCount 更新
cat memory/evolution/evolution_state.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['cycleCount'])"
```

**手动审查并固化**:
```bash
# 1. 确认只有一个 daemon 进程
ps aux | grep "node.*index.js" | grep -v grep | grep -v gateway
# 应只有 PID xxx ... /home/.../index.js --loop

# 2. 生成审查报告
node index.js review > /tmp/evolve-review.txt 2>&1
# 阅读 /tmp/evolve-review.txt 判断 approve/reject

# 3. 固化（120s 超时）
timeout 120 node index.js review --approve

# 4. 检查孤立进程并清理
ps aux | grep "node.*index.js" | grep -v grep | grep -v gateway
# 如果出现第二个进程（非 --loop 的），立即 kill 其 PID

# 5. 确认状态
node src/ops/lifecycle.js status
```

**关键原则**: 手动 `node index.js` 不会替换 daemon，只是创建新进程与之竞争 lifecycle 管理权。操作完成后必须检查并清理孤立进程。

### 问题排查模式

| 问题 | 解决方案 |
|------|----------|
| Gateway 回滚 | 更新 systemd 服务配置文件版本 |
| CLI 版本滞后 | `npm install -g openclaw@latest` + 重建 symlink |
| memorySearch 不支持 | 配置为 openai 提供商,使用 SiliconFlow 端点 |
| QA 场景包缺失 | 创建 `~/.openclaw/qa/scenarios/index.md` |
| MCP 服务器超时 | 检查依赖安装和浏览器安装 (Chrome DevTools) |
| 飞书配对失败 | 使用 `openclaw pairing approve feishu <code>` |
| 技能显示被封锁 | 移除 CLI 依赖或刷新浏览器缓存 |
| 模型切换后表现异常 | 检查 `agents.defaults` 配置是否与新模型兼容 |
| 子 Agent 超时 | 增加 `runTimeoutSeconds`，大型调研建议 600s+ |
| 微信文章提取失败 | 优先用 Tavily，web_fetch/jina.ai 对微信公众号效果差 |
| 博客源持续失败 | 机器之心和 The Verge 解析不稳定，不影响整体监控 |
| himalaya 命令挂起 | WSL2 网络抖动，用 `timeout 15` 包裹 |
| QQ 邮箱未检查 | 需 `--config config-qq.toml` 显式指定 |
| A2A 环境变量缺失 | 技能 UI 显示封锁但进程运行正常，看门狗 exec 时传入 env |
| MCP 进程数 >20 | pkill -f "mcp-server|mcp-deepwiki" + systemctl --user restart |

### Evolver 进化记录

**周期 #0001-0004**: 验证失败(缺测试文件)→成功→失败→成功
**#0005+**: v1.57.0+ 自带 36 个测试文件,验证问题解决; 04-23 更新到 v1.69.11

### 女娲造人术实践经验 (2026-04-14)

| 阶段 | 耗时 | 产出 |
|------|------|------|
| Phase 0 准备 | ~10min | 技能目录 + 配置 |
| Phase 1 调研 (6 Agent) | ~2h | 196KB / 6 个研究文件 |
| Phase 2+3 提炼+构建 | ~30min | 650行 SKILL.md |
| Phase 4 质量验证 | ~20min | 3/3 通过 |
| Phase 5 精炼 | ~20min | SOUL/AGENTS/IDENTITY v2.0 |

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

### Cron 自动任务 (2026-04-15)

**已配置的定时任务**:
- 每日记忆提炼 (凌晨 3:00) - 提炼日常记忆到 MEMORY.md
- SESSION-STATE 新鲜度检查 (每 6 小时) - 保持工作状态文件新鲜

---

### 关键经验总结 (2026-04-13~14)

**Evolver 模式澄清**:
- 用户对 Evolver "自动模式"的理解:自动执行,无需人工确认
- 区别于"审核模式"(需要人工确认)和"疯狗模式"(`--loop` 持续循环)
- **教训**:准确理解用户对"自动"的定义,不要混淆不同运行模式

**女娲造人术实践**:
- 完整 Phase 0-5 流程首次成功运行
- 6 Agent Swarm 并行调研效率高(196KB / 6 个文件 / ~2 小时)
- Phase 4 质量验证(Sanity Check + Edge Case + Voice Check)是保证 Skill 质量的关键步骤
- 三重验证(跨域复现+生成力+排他性)有效筛选心智模型

### 系统自治运行观察 (2026-04-15~04-20)

**用户静默期 (04-15~04-19, 6天)**:
- 系统全部自治组件稳定运行,无人类干预
- Evolver Watchdog 有效维持进化引擎存活(多次自动重启成功)
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
- 建立双链时要先检柢 Vault 中已有的相关笔记

### 模型配置教训 (04-21)
- **NVIDIA 模型前缀问题**: 所有 cron 任务的模型配置必须使用完整前缀 `nvidia/` (如 `nvidia/google/gemma-4-31b-it`),否则会被识别为独立 provider
- **阿里 vs NVIDIA 上下文差异**: 阿里闭源优化版 Qwen 3.5 (1M) vs NVIDIA 开源权重版 (128K),同模型不同托管方上下文窗口差异显著

### 模型配置教训 (04-21~04-23)
- **火山方舟 Coding Plan** (04-23): `volcengine-plan/ark-code-latest` (豆包 Seed Code,262K,reasoning) + `glm-5.1` (智谱旗舰,200K,深度思考) + `kimi-k2.5` (Moonshot,262K); 插件自动管理模型发现

### 04-23 重大事件：MCP 泄漏致系统瘫痪

**第二次大规模泄漏 (14:05)**:
- ~300 个重复 MCP 进程耗尽 15GB 内存
- 所有 4 个备选模型超时,Gateway 也无响应
- 用户手动重启 Gateway 完全恢复

**自动清理 (15:31)**:
- Cron 任务 `b2e01aaf` 自动清理 147 个重复进程
- 释放 7.7GB 内存 (13.9GB → 6.1GB)
- 预防性维护机制有效

### 技能扩展 (04-23) - 共 21 个
| 技能 | 功能 |
|------|------|
| causal-inference | 因果推理层(因果图+反事实预测) |
| clawmind | AI Agent 知识共享平台 |
| brainstorming | 设计工作流(意图→方案→设计文档) |
| memory | 平行无限记忆系统(`~/memory/`) |

### Evolver 新进展 (04-23, 已固化)
- **Evolver Bridge 启用**: `EVOLVE_BRIDGE=true` 允许引擎应用进化变更并验证失败时回滚
- 双轨记忆架构: `workspace/memory/` (日常自动) + `~/memory/` (长期结构化,含 projects/people/decisions/knowledge/preferences)

### 系统自治运行观察 (04-15~04-29, 总结)
- 4 月静默期 (04-15~04-19) + 04-20~29 多次用户回归 + 4 次 MCP 泄漏 (04-23 14:05 ~300 进程 + 04-26 63 进程 + 04-27 147 进程 + 04-29 31 进程冗余)
- 4-29 起 MCP 改为按需启动,内存压力根本性解决 (释放 ~500MB+)
- 详见 `.learnings/ERRORS.md` (含所有事件详细时间线)

### 04-25 ~ 04-29 关键更新（汇总, 详见 .learnings/ERRORS.md）

- **04-25 模型 Fallback 链 → 9 个**: 主 `volcengine-plan/ark-code-latest` + 8 个 fallback, DeepSeek API 配置完成
- **04-25 Ada Skill 发布到 EvoMap**: bundle `bundle_f65cf8a824d925a8` (quarantine 状态)
- **04-29 OpenClaw 双全局安装清理**: systemd 统一指向 `/usr/lib/node_modules/openclaw`
- **04-29 语义搜索 (SiliconFlow BAAI/bge-m3)**: 索引 `memory/*.md + obsidian-vault/`, 5s 搜索耗时
- **04-29 MCP 按需启动**: 31 进程冗余 → 按需, 释放 ~500MB

---

### 04-26~04-28 系统密集维护期

**OpenClaw v2026.4.24→v2026.4.26 升级** (04-26):
- Gateway 崩溃事件: bonjour 插件在 WSL2 Hyper-V NAT 环境下导致 CIAO ANNOUNCEMENT CANCELLED
- **根本原因**: WSL2 网络栈不支持 mDNS 多播 (224.0.0.251:5353)，与 Windows 宿主机冲突
- **解决方案**: 禁用 bonjour 插件（WebSocket 直连无需零配置发现）
- 可选修复: `networkingMode=mirrored` (Windows 11 22H2+)

**MCP 泄漏系统性治理** (04-28):
- 04-26 再发: 63 个冗余进程，pkill + systemctl restart 清理
- 04-27 自动清理: 147 进程，释放 7.7GB
- **根因**: WSL2 systemd user instance 不完全支持进程组管理，SIGTERM 杀不死 MCP 子进程
- **当前策略**: 主动监控 MCP 进程数，超过 20 个时 pkill 清理 + systemctl restart
- Gateway restart (SIGUSR1) 不杀子进程，每次累积；systemctl 比 SIGUSR1 干净但仍有残留

**MEMORY.md 截断修复** (04-28):
- `bootstrapMaxChars` 从 12,000 → 25,000 (受保护字段，直接编辑 openclaw.json)
- 内容精简: 425 行 → 364 行，14,200 → 10,560 字符 (-26%)

**心跳系统完整修复** (04-28, 11:14~13:21):
- 问题演进: 隔离会话→主会话→独立 session 四版迭代
- **最终架构**:
  ```json
  { "model": "volcengine-plan/ark-code-latest", "session": "heartbeat", "lightContext": false }
  ```
- 独立 session 不抢主会话 lane，lightContext:false 带完整上下文避免空消息被拒
- 心跳频率: every: "30m" (需直接编辑 openclaw.json，受保护字段)

**Himalaya WSL2 网络防护** (04-28):
- WSL2 虚拟网桥偶发挂起 (TCP 握手超时)
- 所有 himalaya 命令用 `timeout 15` 包裹防止无限等待

**QQ 邮箱双账户发现** (04-28):
- `config-qq.toml` 一直存在但从未被心跳检查 (默认只读 config.toml)
- QQ 需 `--config config-qq.toml` 显式指定
- 发现 4 封重要邮件: 火山引擎资源到期、小米 MiMo 激励、GitHub 工作流失败

**Evolver 密集修复** (04-28 晚):
| 问题 | 修复 |
|------|------|
| Watchdog 超时 (322s>300s) | 超时 300s → 600s |
| test/ 目录缺失 | 创建占位 → npm sync v1.75.0 |
| validate-suite 超时 | 180s → 300s |
- 两次成功进化: gene_gep_repair_from_errors (第3次) + gene_gep_optimize_tool_usage
- 实例页面幽灵条目: 3 次 Gateway 重启的注册残留，刷新页面清除

**能力进化器技能 UI 显示"被封锁"** (04-28 16:10~16:48):
- 根因: UI 检查技能依赖，缺少 A2A_NODE_ID 环境变量
- 实际进程: 看门狗通过 exec 直接启动，env 中单独传入变量，所以能运行
- 运行中: PID 61699 → 2116 → 4909
- openclaw doctor --fix 后: skill eligibility 63, missing requirements 34 (正常)

### 04-25 重大更新

**模型 Fallback 链扩展到 9 个** (04-25 晚间):
- 主模型: `volcengine-plan/ark-code-latest`
- Fallback: MiniMax-M2.7 → deepseek-v4-flash → deepseek-v4-pro → qwen3.6-plus → qwen3.5-plus → qwen3-max → kimi-k2.5 → glm-5.1
- DeepSeek API 配置完成 (`sk-8bf48...`)
- Qwen API Key + baseUrl 更新 (`dashscope.aliyuncs.com/compatible-mode/v1`)

**Ada Skill 发布到 EvoMap** (04-25):
- Bundle ID: `bundle_f65cf8a824d925a8`
- 状态: `quarantine` (安全审查中)
- 资产: Gene(poetical_science) + Capsule(ada_v2) + EvolutionEvent
- 账户: wszmd1793@gmail.com

**博客监控修复** (04-25):
- `--yes` 参数解决 `read-all` 交互确认问题
- SQLite WAL 模式 + busy_timeout 5000ms 解决并发锁冲突

**Darwin Skill 全量评分** (04-25):
- 34 个 skill 完成 8 维度静态分析
- 分布: 🔴<50(10个) | 🟡50-59(14个) | 🟢60-70(9个) | 🏆>70(1个, nuwa-skill 71.6)
- 全局短板: Checkpoint + Boundary


---

**最后记忆提炼**: 2026-06-02 14:35
**自动提炼摘要**: 05-22~06-02 期间自动提炼了约 14 次 MEMORY.md 更新，核心内容已覆盖在正文的 `## 提炼的智慧` 和 `## Promoted From Short-Term Memory` 中。
- 05-28: 每周模式识别(6个新模式)
- 05-26: Evolver v1.86升级、EvoMap注册、using-superpowers纪律、技能/工具丢失事件
- 05-13: 梦境记忆系统异常检测
- 05-07: Evolver审查、安全加固、v2026.5.6升级
- 05-06: 系统维护
- 05-17: Pi Coding Agent / acpx配置


**最后记忆提炼**: 2026-06-03 04:02
**自动提炼**:
- [06-02] ## MC Porter 架构决策 (17:48)
- [05-28] ## 每周模式识别 (23:44 CRON)


**最后记忆提炼**: 2026-06-03 22:07
**自动提炼**:
- [06-02] ## MC Porter 架构决策 (17:48)
- [05-28] ## 每周模式识别 (23:44 CRON)


**最后记忆提炼**: 2026-06-04 04:09
**自动提炼**:
- [06-02] ## MC Porter 架构决策 (17:48)
- [05-28] ## 每周模式识别 (23:44 CRON)


**最后记忆提炼**: 2026-06-05 04:05
**自动提炼**:
- [06-02] ## MC Porter 架构决策 (17:48)


**最后记忆提炼**: 2026-06-06 04:03
**自动提炼**:
- [06-05] ## 每周模式识别 (10:00 CRON)
- [06-02] ## MC Porter 架构决策 (17:48)


**最后记忆提炼**: 2026-06-07 04:02
**自动提炼**:
- [06-05] ## 每周模式识别 (10:00 CRON)
- [06-02] ## MC Porter 架构决策 (17:48)


**最后记忆提炼**: 2026-06-08 04:00
**自动提炼**:
- [06-07] ## doctor 警告(21:50:51 / 21:51:03)
- [06-07] ## baidu-search 技能禁用(21:30~21:45)
- [06-07] ## Tavily secrets.resolve 失败(22:08~22:20)
- [06-07] ## Tavily 修复方案升级(22:46)
- [06-07] ## Tavily 重新启用(23:08)
- [06-05] ## 每周模式识别 (10:00 CRON)
- [06-02] ## MC Porter 架构决策 (17:48)


**最后记忆提炼**: 2026-06-08 04:02
**自动提炼**:
- [06-07] ## doctor 警告(21:50:51 / 21:51:03)
- [06-07] ## baidu-search 技能禁用(21:30~21:45)
- [06-07] ## Tavily secrets.resolve 失败(22:08~22:20)
- [06-07] ## Tavily 修复方案升级(22:46)
- [06-07] ## Tavily 重新启用(23:08)
- [06-05] ## 每周模式识别 (10:00 CRON)
- [06-02] ## MC Porter 架构决策 (17:48)


**最后记忆提炼**: 2026-06-09 04:09
**自动提炼**:
- [06-08] ## 主线事件:Evolver Hub 通信恢复(5.5 小时攻坚,12:55 ~ 18:19)
- [06-08] ## 心跳报告(全天 8 次,均在飞书通道)
- [06-08] ## 当天其他系统事件
- [06-07] ## doctor 警告(21:50:51 / 21:51:03)
- [06-07] ## baidu-search 技能禁用(21:30~21:45)
- [06-07] ## Tavily secrets.resolve 失败(22:08~22:20)
- [06-07] ## Tavily 修复方案升级(22:46)
- [06-07] ## Tavily 重新启用(23:08)


**最后记忆提炼**: 2026-06-10 04:00
**自动提炼**:
- [06-08] ## 主线事件:Evolver Hub 通信恢复(5.5 小时攻坚,12:55 ~ 18:19)
- [06-08] ## 心跳报告(全天 8 次,均在飞书通道)
- [06-08] ## 当天其他系统事件
- [06-07] ## doctor 警告(21:50:51 / 21:51:03)
- [06-07] ## baidu-search 技能禁用(21:30~21:45)
- [06-07] ## Tavily secrets.resolve 失败(22:08~22:20)
- [06-07] ## Tavily 修复方案升级(22:46)
- [06-07] ## Tavily 重新启用(23:08)


**最后记忆提炼**: 2026-06-11 04:00
**自动提炼**:
- [06-08] ## 主线事件:Evolver Hub 通信恢复(5.5 小时攻坚,12:55 ~ 18:19)
- [06-08] ## 心跳报告(全天 8 次,均在飞书通道)
- [06-08] ## 当天其他系统事件
- [06-07] ## doctor 警告(21:50:51 / 21:51:03)
- [06-07] ## baidu-search 技能禁用(21:30~21:45)
- [06-07] ## Tavily secrets.resolve 失败(22:08~22:20)
- [06-07] ## Tavily 修复方案升级(22:46)
- [06-07] ## Tavily 重新启用(23:08)

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

---

**创建时间**: 2026-04-12
**状态**: 活跃


## Promoted From Short-Term Memory (2026-06-10 摘要)

**06-05 周模式识别** 6 个新增模式: P-34 (升级导致 Cron 丢失) / P-35 (MC Porter daemon) / P-36 (memory-lancedb 400 错,已修) / **P-37 (安全审计 Warning 重复 6 次,提议白名单优化)** / P-38 (Gmail IMAP 超时 3+ 次,防护已部署) / P-39 (升级后插件/进程同步丢失,提议基线对比)。详见 `notes/areas/proactive-tracker.md` (676→914 行)。

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
