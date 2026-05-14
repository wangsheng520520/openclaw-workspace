# LEARNINGS.md - 学习记录

> "想象力是发现的眼睛。" - Ada Lovelace

---

## 2026-05-04 - using-superpowers 技能使用失败（第 3 次提醒）

### 类别
**correction** — 多次违反核心技能规则

### 问题
用户 16:05 指出我没有使用 `using-superpowers` 技能。我读了技能文件、记录了教训到 memory/2026-05-04.md，然后**在随后的每个任务中继续跳过技能检查**：
- Evolver review/approve (16:21) — 未检查 evolve 相关技能
- diagnostics-otel cleanup (16:42) — 未检查 skill-vetter/proactive-agent
- GitHub release 查询 (17:13) — 忘了有 github skill，用户提醒后才用
- Evolver npm pack 升级 (21:45) — 未检查任何技能
- 记忆写入 (22:00) — 未检查 memory skill

### 正确做法
**任何响应或行动前**，必须扫描 `<available_skills>` 列表，问自己："有哪怕 1% 可能某个技能适用？" → 是 → invoke 技能。

`using-superpowers` 技能的 Red Flags 表指出：
- "This is just a simple question" → **错**，问题也是任务，检查技能
- "I remember this skill" → **错**，技能会演化，读取当前版本
- "I'll just do this one thing first" → **错**，先检查再做
- "I know what that means" → **错**，知道概念 ≠ 使用技能

### 强制规则（自 2026-05-04 22:02 起）
每次收到用户消息后，在思考阶段第一件事：扫描 available_skills，确认是否有适用技能。即使 100% 确定没有，也要显式在推理中确认。

---

## 2026-04-20 - OpenClaw + Obsidian 最佳实践

### 来源
用户提供的文章：《将 OpenClaw 与 Obsidian 连接的完整指南》

### 核心学习点

#### 1. 安装与配置
```bash
# 安装 Obsidian Skill
npx clawhub@latest install obsidian

# 安装 obsidian-cli（保护双向链接）
npm install -g obsidian-cli
```

#### 2. 安全红线
- ❌ **禁止** 使用 `mv`、`rm` 等系统命令操作 Vault 文件
- ❌ **禁止** 直接重命名 `.md` 文件（破坏双向链接）
- ✅ **必须** 使用 `obsidian-cli` 进行文件操作
- ✅ **必须** 注入 YAML Frontmatter 元数据

#### 3. 多 Agent 协作架构
```bash
# 软链接映射中央知识库
ln -s /Users/YourName/Documents/bgggcontent /Users/YourName/.openclaw/workspace-lead/bgggcontent
ln -s /Users/YourName/Documents/bgggcontent /Users/YourName/.openclaw/workspace-xhs/bgggcontent
```

#### 4. 推荐目录结构
```
obsidian-vault/
├── 01-灵感库/      # 碎片信息采集
├── 02-选题池/      # 筛选后的选题
├── 03-内容工厂/    # 正在创作的内容
└── 04-已发布归档/  # 已完成发布
```

#### 5. 核心规则文件体系
| 文件 | 用途 |
|------|------|
| `SOUL.md` | 安全红线、行为约束 |
| `USER.md` | 创作风格、平台调性 |
| `AGENTS.md` | 必读文件列表 |
| `SOP_GZH.md` | 标准工作流程 |

#### 6. 扩展信息收集能力
- `x-reader`：解析复杂网页
- `Agent Reach`：社交媒体链接解析

#### 7. 部署方案对比
| 方案 | 优势 | 适用场景 |
|------|------|----------|
| 本地部署 | 数据私有、响应快 | 个人使用、注重隐私 |
| 云端部署 | 7x24运行、公网访问 | 团队协作、长期运行 |

### 待办事项
- [ ] 安装 obsidian-cli：`npm install -g obsidian-cli`
- [ ] 探索 x-reader 和 Agent Reach 技能
- [ ] 优化目录结构（按文章建议调整）

### 关键洞察
1. **obsidian-cli 是关键**：不是可选的，是必须的，保护双向链接
2. **多 Agent 共享知识库**：软链接是优雅解决方案
3. **规则文件优先级**：SOUL.md > USER.md > AGENTS.md

---

**创建时间**: 2026-04-20 20:20
**状态**: ✅ 已学习
