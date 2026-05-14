# HEARTBEAT.md — 心跳检查任务

> **模型**: 继承 `agents.defaults.model.primary` (当前 `minimax/MiniMax-M2.7`)
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
| 系统心跳 (每 30 分钟) | `volcengine-plan/ark-code-latest` | `openclaw.json` → `agents.defaults.heartbeat.model` |
| HEARTBEAT.md 检查任务 | `volcengine-plan/ark-code-latest` | 主模型 |
| Evolver 看门狗 (进程检查) | `siliconflow/Qwen/Qwen3-8B` | `evolver-watchdog.sh` (仅检查进程状态) |
| Evolver 实际扫描 | `volcengine-plan/ark-code-latest` | 主模型 |
| 用户交互会话 | `volcengine-plan/ark-code-latest` | 主模型 |

**成本优化策略**:
- **简单监控任务** (Evolver 看门狗进程检查) → 免费模型
- **深度分析任务** (心跳检查、Evolver 扫描、用户交互) → 主模型 `ark-code-latest`

---

## 心跳架构 (2026-04-28 最终)

经过 4 次架构迭代，最终方案：

```json
"heartbeat": {
  "model": "volcengine-plan/ark-code-latest",
  "session": "heartbeat",
  "lightContext": false,
  "every": "30m"
}
```

**关键设计**：
- `session: "heartbeat"` — 独立持久 session，不抢主会话 lane，不阻塞用户交互
- `lightContext: false` — 带完整上下文，避免空消息 → API 拒绝 → Fallback 风暴
- `model: ark-code-latest` — 主模型，无限流问题
- `every: "30m"` — 显式设置 30 分钟间隔（2026-04-28 修复，此前缺失导致频率过高）

**演化历程**：
| 版本 | 配置 | 结果 |
|------|------|------|
| v1 | 隔离+轻量+MiniMax | 空消息 → 9层Fallback全失败 → 231s阻塞 |
| v2 | 主会话+MiniMax | 每30分钟卡主会话5-7分钟 |
| v3 | 主会话+ark-code-latest | 仍卡主会话（架构问题非模型问题） |
| **v4** | **session:heartbeat+完整上下文+ark-code-latest** | ✅ 无阻塞，无报错 |
| **v4.1** | **v4 + every:30min** | 🔧 2026-04-28 18:52 修复心跳频率过高问题 |

**配置位置**: `~/.openclaw/openclaw.json` → `agents.defaults.heartbeat`
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
