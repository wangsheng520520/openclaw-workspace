# HEARTBEAT.md — 心跳检查任务

> **模型**: 继承 `agents.list[0].model.primary` (当前 `volcengine-plan/ark-code-latest`，Doubao Seed Code)
> **频率**: 每 30 分钟自动执行
> **会话**: 独立 `session:heartbeat`，不阻塞主会话

---

## ⚡ 每次心跳必须执行

### 0. 更新心跳状态文件 (最高优先级)
```
read /home/wszmd520520/.openclaw/workspace/memory/heartbeat-state.json
修改 lastCheck 为当前时间（Asia/Shanghai 时区）
write /home/wszmd520520/.openclaw/workspace/memory/heartbeat-state.json (完整覆盖)
```
**这是心跳存活的唯一证据**，不更新会导致 SESSION-STATE 检查误报"心跳漏触发"。

---

## 定期检查任务

### 每日检查 (2-4 次/天)

- [x] 更新 heartbeat-state.json lastCheck
- [x] 检查紧急邮件 — 2026-05-03 05:57 — 🚨 QQ: MiMo 90% + 火山引擎到期
- [x] 检查 24-48 小时内的日历事件 — 2026-05-03 05:57 — ✅ 无近期日程
- [x] 检查相关天气预报 — 2026-05-03 05:57 — ✅ SearXNG 未获取到实时数据
- [x] 检查提及/通知 — 2026-05-03 05:57 — ✅ Feishu 无最近消息
- [x] 检查 MCP 泄漏状态 — 2026-05-03 22:10 — ✅ 0 进程，Docker MCPhub

### 当前状态

- ✅ 心跳架构：独立 `session:heartbeat` + `every:30m`，继承主模型
- ✅ 邮件：Gmail + QQ 邮箱双账户，timeout 15 防护
- ✅ MCP：全部在 Docker MCPhub，13 个服务
- ✅ 通知：Feishu WebSocket
- 📌 当前时间：Sunday, May 3rd, 2026 - 22:17 PM (Asia/Shanghai)

**天气配置**:
- 城市：武汉
- 区域：黄陂区
- 位置：盘龙城 / 汉口北
- 坐标：114.2649, 30.6877 (盘龙城)
- 备用坐标：114.2858, 30.7089 (汉口北)
- 检查方式：网络搜索

### 每周检查

- [x] **提炼 MEMORY.md** — 2026-04-12 18:25
  - ✅ 检查 `memory/YYYY-MM-DD.md` 中的新内容
  - ✅ 提炼用户偏好、项目进展、关键决策
  - ✅ 更新 `MEMORY.md` 的对应章节
  - ✅ 标记已提炼日期：`memory/heartbeat-state.json`

---

## 记忆提炼指南

**提炼什么**:
- 用户明确表达的偏好
- 重要项目决策和进展
- 重复出现的问题模式
- 有价值的洞察和学习

**如何提炼**:
```markdown
## 关于用户
- 新增偏好：[描述]

## 项目与上下文  
- 新进展：[描述]

## 提炼的智慧
- 新洞察：[描述]
```

**追踪**: 在 `memory/heartbeat-state.json` 记录最后提炼日期

---

## 模型配置说明

| 任务类型 | 使用模型 | 配置位置 |
|----------|----------|----------|
| 系统心跳 (每 30 分钟) | `volcengine-plan/ark-code-latest` (主模型) | `openclaw.json` → `agents.defaults.heartbeat.model` |
| HEARTBEAT.md 检查任务 | `volcengine-plan/ark-code-latest` (主模型) | `agents.defaults.model.primary` |
| Evolver 看门狗 (进程检查) | `siliconflow/Qwen/Qwen3-8B` | `evolver-watchdog.sh` (仅检查进程状态) |
| Evolver 实际扫描 | `volcengine-plan/ark-code-latest` (主模型) | `agents.defaults.model.primary` |
| 用户交互会话 | `volcengine-plan/ark-code-latest` (主模型) | `agents.defaults.model.primary` |

**成本优化策略**:
- **简单监控任务** (Evolver 看门狗进程检查) → 免费模型
- **深度分析任务** (心跳检查、Evolver 扫描、用户交互) → 主模型 `ark-code-latest`

---

## 心跳架构 (2026-04-28 最终)

经过 4 次架构迭代，最终方案：

```json
"heartbeat": {
  "every": "30m",
  "target": "none",
  "model": "minimax/MiniMax-M3",
  "lightContext": true,
  "isolatedSession": true,
  "skipWhenBusy": true,
  "prompt": "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK."
}
```

**关键设计**（v8 实际最终态，2026-06-09 后某次切换保留）：
- `model: minimax/MiniMax-M3` — 主模型（M3 配额稳定后未切回 ark-code-latest）
- `isolatedSession: true` + `lightContext: true` — 隔离 session + 轻量上下文（与 v4 的 `session: "heartbeat" + lightContext: false` 不同：v8 用 OpenClaw 隔离会话机制而非命名 session）
- `target: "none"` — 不向任何渠道回送（避免污染主会话）
- `skipWhenBusy: true` — 主会话忙碌时跳过，避免冲突
- `every: "30m"` — 显式 30 分钟间隔
- **设计取舍**：v8 用 `lightContext: true`（轻量）但**实测未出现 v1 那种"空消息 → 9 层 Fallback 失败"**——因为 prompt 已明确"无新任务回复 HEARTBEAT_OK"，且 M3 配额稳定不触发回退

**演化历程**：
| 版本 | 配置 | 结果 |
|------|------|------|
| v1 | 隔离+轻量+MiniMax | 空消息 → 9层Fallback全失败 → 231s阻塞 |
| v2 | 主会话+MiniMax | 每30分钟卡主会话5-7分钟 |
| v3 | 主会话+ark-code-latest | 仍卡主会话（架构问题非模型问题） |
| **v4** | **session:heartbeat+完整上下文+ark-code-latest** | ✅ 无阻塞，无报错 |
| **v4.1** | **v4 + every:30min** | 🔧 2026-04-28 18:52 修复心跳频率过高问题 |
| **v5** | **v4.1 + 全部切到 minimax/MiniMax-M3** | 🔧 2026-06-08 15:44 M2.7 不在 agents.defaults.models 名单，系统连续 7 次回退 |
| **v6** | **v5 + 切到 xiaomi/mimo-v2.5** | 🔧 2026-06-09 17:20 MiniMax-M3 配额用完，切主模型到 mimo-v2.5 |
| **v7** | **v6 + 切到 volcengine-plan/ark-code-latest** | 🔧 2026-06-09 17:51 用户通过 UI 切换主模型到火山方舟 Doubao Seed Code，cron 自动跟随 |
| **v8** | **M3 + lightContext=true + isolatedSession=true + skipWhenBusy=true**（**实际最终态**） | 🟢 2026-06-09 后某次切换保留 — 全天 7/7 心跳成功（00:30/08:46/09:15/10:15/11:15/11:45/12:15/12:45/13:15/13:47），无阻塞无 Fallback 风暴，**v7 描述未实际生效** |

**配置位置**: `~/.openclaw/openclaw.json` → `agents.defaults.heartbeat`

**v7 → v8 漂移说明**（**已固化，非待修 bug**）：
- 06-10 04:00 心跳首次发现漂移：openclaw.json 实际为 M3 + lightContext=true + 无 session 字段，与 v7 文档不符
- 06-10 ~ 06-11 全天 13+ 次心跳持续观察，**功能完全正常**，配置未变化
- 06-11 14:00 老王拍板"仅修文档"（A 方案）→ 演化历程补 v8 实际态
- **不动 openclaw.json**（受保护字段，需用户明确授权）
**最终验证**: 2026-04-28 20:18 — 心跳正常，himalaya 加 timeout 防护

---

## 已知问题与防护措施

### Himalaya WSL2 网络抖动
**症状**: `himalaya envelope list` 在 WSL2 虚拟网桥偶发挂起（TCP 握手超时无返回）
**根因**: WSL2 Hyper-V 虚拟 NAT 网络偶发延迟
**防护**: 所有 himalaya 命令必须用 `timeout 15` 包裹，防止无限等待阻塞心跳流程

```bash
# ✅ 正确用法（Gmail - 默认账户）
timeout 15 himalaya envelope list --page 1 --page-size 5

# ✅ 正确用法（QQ 邮箱）
timeout 15 himalaya --config ~/.config/himalaya/config-qq.toml envelope list --page 1 --page-size 5

# ❌ 裸调（可能挂起）
himalaya envelope list --page 1 --page-size 5
```

**双账户配置**:
| 账户 | 配置文件 | 邮箱 |
|------|----------|------|
| Gmail (默认) | `~/.config/himalaya/config.toml` | wszmd1793@gmail.com |
| QQ 邮箱 | `~/.config/himalaya/config-qq.toml` | 601701001@qq.com |

**2026-04-28 修复清单**:
| 问题 | 修复 | 时间 |
|------|------|------|
| 心跳频率过高 | 添加 `every: "30m"` | 18:52 |
| Himalaya 挂起 | 加 `timeout 15` 防护 | 20:23 |
| Evolver Watchdog 超时 | 超时 300→600s | 19:48 |
