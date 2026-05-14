**最后记忆提炼**: 2026-05-13 14:49

# MEMORY.md - 长期记忆

> "想象力是发现的眼睛。" - Ada Lovelace

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

### 系统配置原则

1. **技能分层**: 系统插件在 `plugins.entries` 配置,工作区技能自动加载
2. **记忆三层**: MEMORY.md(手动提炼) → daily memory(自动记录) → .dreams(梦境分析)
3. **API 密钥管理**: 使用 `.env` 文件集中管理,权限 600
4. **主动汇报**: 任务完成后主动汇报结果,不等待用户询问
5. **受保护字段写入**: `bootstrapMaxChars`、`agents.defaults` 等受保护字段不可通过 config.patch 修改,需直接编辑 openclaw.json + gateway restart 热重载
6. **心跳架构原则**: 心跳必须独立 session lane + lightContext:false,否则每 30 分钟阻塞主会话 5-7 分钟

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

### Evolver 新进展 (04-23)
- **Evolver Bridge 启用**: `EVOLVE_BRIDGE=true` 允许引擎应用进化变更并验证失败时回滚
- 双轨记忆架构: `workspace/memory/` (日常自动) + `~/memory/` (长期结构化,含 projects/people/decisions/knowledge/preferences)

### 系统自治运行观察 (04-15~04-23)

**用户静默期 (04-15~04-19, 6天)**:
- 系统全部自治组件稳定运行,无人类干预
- Evolver Watchdog 有效维持进化引擎存活
- 博客监控持续产出日报,每日 30-66 篇新文章
- 梦境系统、记忆提炼、SESSION-STATE 检查均正常

**04-20 傍晚用户回归** (~22:30):
- 用户通过飞书发送微信公众号链接,要求导入 Obsidian 并建立双链
- 文章主题:《公交司机的真心话:所谓疲劳驾驶,不过是说说而已》
- 提取方案:web_fetch 和 jina.ai 均失败,Tavily 成功提取
- 成功建立 7 条双链(5 条公交行业 + 2 条安全驾驶)
- 用户重复发送同一链接 3 次(可能因飞书消息延迟)

**04-21 晚 用户活跃** (20:32~21:05):
- 配置 NVIDIA 免费大上下文模型(9 个新增 + 1 个更新)
- 探索阿里 vs NVIDIA Qwen 3.5 上下文差异(1M vs 128K)
- 启动 Evolver 技能自动模式(PID 4183)
- **关键发现**:闭源优化版 vs 开源权重版,上下文窗口差异显著

**04-23 火山方舟配置完成**:
- 新增 `volcengine-plan/ark-code-latest` 作为主模型
- 新增 `volcengine-plan/kimi-k2.5` (Moonshot K2.5)
- 新增 `volcengine-plan/glm-5.1` (智谱最新旗舰,200K 上下文,深度思考模式)
- 小米模型更新: `mimo-v2-pro` 上下文升级到 1M
- **volcengine 插件自动管理模型发现**,无需手动注册
- **第二次 MCP 泄漏致系统瘫痪** (14:05): ~300 进程耗尽内存,用户手动重启 Gateway 恢复
- **15:31 自动清理**: 147 进程,释放 7.7GB

**04-23 技能新增** (21个): causal-inference(因果推理), clawmind(AI知识共享), brainstorming(设计工作流), memory(平行无限记忆系统 `~/memory/`)

**Evolver Bridge 启用**: `EVOLVE_BRIDGE=true` 允许引擎应用进化变更并验证失败时回滚

**04-22~23 静默期**: 系统自治稳定运行,梦境系统正常

**04-23 火山方舟配置完成**:
- 新增 `volcengine-plan/ark-code-latest` 作为主模型
- 新增 `volcengine-plan/kimi-k2.5` (Moonshot K2.5)
- 新增 `volcengine-plan/glm-5.1` (智谱最新旗舰,200K 上下文,深度思考模式)
- 小米模型更新: `mimo-v2-pro` 上下文升级到 1M

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
- **关键教训**: 子 agent 并行 = MCP 进程风暴(500+); 串行 + lightContext 是最优策略

### 04-29 系统清理与验证

**OpenClaw 双全局安装清理** (04-29 21:41~22:00):
- 发现两个全局安装: nvm版 + 系统版 (版本相同 v2026.4.26)
- 根因: systemd 服务指向 nvm 路径但实际使用系统版本
- **修复**: 卸载 nvm 版，统一 systemd 指向 `/usr/lib/node_modules/openclaw`
- 验证: `which openclaw` → `/usr/bin/openclaw` ✅

**语义搜索功能验证** (04-29 ~22:27):
| 属性 | 值 |
|------|-----|
| 提供商 | SiliconFlow (OpenAI compatible) |
| 模型 | `BAAI/bge-m3` |
| 索引覆盖 | `memory/*.md` + `memory/dreaming/` + `obsidian-vault/` + `MEMORY.md` |
| 搜索耗时 | ~5.0s |
| 状态 | ✅ 正常运行 |

**MCP 按需启动机制** (04-29 晚):
- Gateway 采用 MCP 按需启动，当工具被调用时自动拉起对应服务
- 不再预加载，31 个冗余进程问题已解决
- 内存预计释放 ~500MB+

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


**最后记忆提炼**: 2026-05-13 20:12
**自动提炼**:
- [05-07] ## Evolver 手动审查 (05-07 00:17~00:25)
- [05-07] ## 深度系统自检 (05-07 07:49~08:11)
- [05-07] ## 安全加固执行 (05-07 11:15~11:42)
- [05-07] ## v2026.5.6 升级 + Doctor 修复 (05-07 13:56~14:57)
- [05-07] ## 插件丢失恢复 + memory-lancedb 安装 (05-07 15:14~16:28)
- [05-06] ## 系统维护 (05-05 夜间 → 05-06 凌晨)
- [05-06] ## 当前系统状态
- [05-06] ## 待观察


**最后记忆提炼**: 2026-05-13 20:18
**自动提炼**:
- [05-07] ## Evolver 手动审查 (05-07 00:17~00:25)
- [05-07] ## 深度系统自检 (05-07 07:49~08:11)
- [05-07] ## 安全加固执行 (05-07 11:15~11:42)
- [05-07] ## v2026.5.6 升级 + Doctor 修复 (05-07 13:56~14:57)
- [05-07] ## 插件丢失恢复 + memory-lancedb 安装 (05-07 15:14~16:28)
- [05-06] ## 系统维护 (05-05 夜间 → 05-06 凌晨)
- [05-06] ## 当前系统状态
- [05-06] ## 待观察


**最后记忆提炼**: 2026-05-14 04:05
**自动提炼**:
- [05-13] ## 梦境记忆系统异常检测
- [05-13] ## 梦境记录 (03:00 CST)
- [05-13] ## 根因分析 (03:15 CST)
- [05-07] ## Evolver 手动审查 (05-07 00:17~00:25)
- [05-07] ## 深度系统自检 (05-07 07:49~08:11)
- [05-07] ## 安全加固执行 (05-07 11:15~11:42)
- [05-07] ## v2026.5.6 升级 + Doctor 修复 (05-07 13:56~14:57)
- [05-07] ## 插件丢失恢复 + memory-lancedb 安装 (05-07 15:14~16:28)

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


## Promoted From Short-Term Memory (2026-05-13)

<!-- openclaw-memory-promotion:memory:memory/2026-04-29.md:27:30 -->
- | 时间 | 事件 | |------|------| | 04-27 20:32 | 用户飞书消息："在吗？" | | 04-27 20:32+ | 用户请求：导入微信公众号文章到 Obsidian 并建立双链 | [score=0.832 recalls=0 avg=0.620 source=memory/2026-04-29.md:27-30]
