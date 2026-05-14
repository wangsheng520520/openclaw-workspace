# 知识图谱每日更新报告

**执行时间**: 2026-05-03 20:00 UTC (2026-05-04 04:00 Asia/Shanghai)  
**Cron ID**: 013cf5c6-8d40-4eb9-9a93-3c8e8f3edc41  
**任务版本**: v2.2

---

## 图谱统计

| 指标 | 数量 |
|------|------|
| 总行数 (JSONL) | 45 |
| 新增实体 (op=create) | 3 |
| 新增关系 (op=relate) | 3 |
| 新增观察 (op=observe) | 2 |

---

## 新增实体

### 1. wsl2_home_env_issue
- **类型**: environment_issue
- **描述**: WSL2 `/init` 将 cron 子 agent 的 HOME 重置为 `/root`，导致 `~` 路径解析错误
- **影响**: SESSION-STATE、heartbeat 等 cron 任务的路径解析失败
- **缓解**: 所有 cron 使用绝对路径替代 `~`

### 2. three_issues_fixed_20260503
- **类型**: maintenance
- **描述**: 2026-05-03 晚间修复的三项问题
  - heartbeat-state.json 写入卡住
  - proactive-tracker.md 误报缺失
  - Dreaming 停摆（05-01 起）
- **状态**: 已完成

### 3. mcp_services_consolidated
- **类型**: infrastructure
- **描述**: MCPhub 服务精简，ziwei-doushu 已移除
- **当前服务数**: 13（原 14）

---

## 新增关系

| From | Rel | To | 说明 |
|------|-----|----|------|
| wsl2_home_env_issue | affects | kg_task_v2_2 | HOME 问题影响图谱更新任务 |
| three_issues_fixed_20260503 | resolved | openclaw_v2026_4_23 | 三项修复已完成 |
| mcp_services_consolidated | managed_by | openclaw_v2026_4_23 | 服务精简由 OpenClaw 管理 |

---

## 新增观察

### wsl2_home_env_issue
- **时间**: 2026-05-03 22:10+08:00
- **发现**: cron spawn 子 agent 时 HOME 变为 `/root`，`~` 路径解析错误

### three_issues_fixed_20260503
- **时间**: 2026-05-03 22:17+08:00
- **三项修复**: heartbeat 时间戳更新 + HEARTBEAT.md 修正 / SESSION-STATE v2 绝对路径 / Dreaming lastDreaming 标记

---

## 关键事件（来源: memory/2026-05-03.md）

1. **MCP Docker 迁移完成** — 全部 14 服务通过 `docker exec mcphub` 运行
2. **会话清理** — 删除 443 个残留文件，释放 57MB
3. **知识图谱 Cron v2.2 部署** — 改用 write 覆盖，修复 JSON 损坏问题
4. **WSL2 HOME 环境变量问题发现** — cron 子 agent HOME 被重置
5. **三项问题修复** — heartbeat 状态、Dreaming 停摆、proactive-tracker 误报
6. **MCPhub 服务精简** — ziwei-doushu 移除，服务数降至 13

---

## 输出

```json
{"entities_created": 3, "relations_created": 3}
```