# MEMORY-ops-playbook.md — 操作手册归档

> 从 `MEMORY.md` 拆分出来的"操作手册 + 04-15~05 系统运行观察"子域 (2026-07-30)。
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
- 建立双链时要先检柢 Vault 中已有的相关笔记

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