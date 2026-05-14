# 模型配置说明

> 最后更新：2026-04-20 13:55

---

## 模型分配策略

| 任务类型 | 使用模型 | 频率 | 说明 |
|----------|----------|------|------|
| **系统心跳** | `siliconflow/Qwen/Qwen3-8B` | 每 30 分钟 | OpenClaw 内部心跳机制，简单状态检查 |
| **HEARTBEAT.md 检查任务** | `qwen/qwen3.5-plus` | 每日 2-4 次 | 邮件/日历/天气/通知检查，用户可见 |
| **Evolver 看门狗** | `siliconflow/Qwen/Qwen3-8B` | 持续运行 | 仅检查 Evolver 进程是否存活 |
| **Evolver 实际扫描** | `qwen/qwen3.5-plus` | 周期性 | 代码分析、优化建议，深度任务 |
| **用户交互会话** | `qwen/qwen3.5-plus` | 按需 | 与用户的对话交互 |

---

## 配置位置

| 配置项 | 文件 | 配置值 |
|--------|------|--------|
| 主模型 | `~/.openclaw/openclaw.json` | `agents.defaults.model.primary: "qwen/qwen3.5-plus"` |
| 系统心跳模型 | `~/.openclaw/openclaw.json` | `agents.defaults.heartbeat.model: "siliconflow/Qwen/Qwen3-8B"` |
| Evolver 策略 | `~/.openclaw/.env` | `EVOLVE_STRATEGY=balanced` |
| Evolver 模型 | (不设置) | 默认使用主模型 `qwen/qwen3.5-plus` |

---

## 成本优化逻辑

```
简单监控任务 (免费模型)
├─ 系统心跳 (每 30 分钟，状态检查)
└─ Evolver 看门狗 (进程存活检查)

深度分析任务 (主模型)
├─ HEARTBEAT.md 检查任务 (邮件/日历/天气/通知)
├─ Evolver 实际扫描 (代码分析/优化)
└─ 用户交互会话
```

---

## 相关文件

- `~/.openclaw/openclaw.json` — 主配置文件
- `~/.openclaw/.env` — 环境变量 (API 密钥、Evolver 策略)
- `~/.openclaw/workspace/evolver-watchdog.sh` — Evolver 看门狗启动脚本
- `~/.openclaw/workspace/HEARTBEAT.md` — 心跳检查任务定义

---

## 验证命令

```bash
# 检查主模型配置
openclaw config get agents.defaults.model.primary

# 检查心跳模型配置
openclaw config get agents.defaults.heartbeat.model

# 检查 Evolver 进程
ps aux | grep evolver

# 查看 Evolver 日志
tail -f /tmp/evolver-watchdog.log
```
