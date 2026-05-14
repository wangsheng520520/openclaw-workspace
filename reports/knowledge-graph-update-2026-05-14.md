# 知识图谱每日更新报告 - 2026-05-14

## 执行摘要
| 指标 | 值 |
|------|-----|
| 日期 | 2026-05-14 |
| 版本 | v3 |
| 执行时间 | 04:03 CST |
| 方法 | write_overwrite |

## 图谱统计
| 类型 | 数量 |
|------|------|
| 实体总数 | 59 (+3) |
| 关系总数 | 69 (+4) |
| 观察记录 | 39 (+2) |

## 新增实体

### 1. memory_core_disabled_20260513
- **类型**: incident
- **描述**: memory-core 插件被禁用导致梦境晋升 cron 停止
- **状态**: diagnosed
- **修复要求**: 重新启用 memory-core 插件

### 2. dreaming_promotion_backlog
- **类型**: backlog
- **描述**: 5天梦境晋升积压（05-08 ~ 05-12）
- **状态**: pending_resolution
- **待处理**: 手动触发或重新启用 memory-core

### 3. cron_scheduler_freeze_pattern_v2
- **类型**: pattern
- **描述**: 调度器冻结模式影响多个 cron
- **状态**: observed_investigating
- **说明**: 与 kg_task_v3 冻结问题同类

## 新增关系
1. `memory_core_disabled_20260513` → caused_by → `openclaw_v2026_5_7`
2. `memory_core_disabled_20260513` → affected → `dreaming_promotion_backlog`
3. `dreaming_promotion_backlog` → impacted_by → `cron_scheduler_freeze_pattern_v2`
4. `cron_scheduler_freeze_pattern_v2` → documented_in → `openclaw_workspace`

## 新增观察
1. **memory_core_disabled_20260513**: 发现 memory-core 插件在 plugins 列表中显示为 disabled，导致 dreaming_promotion cron 无法执行
2. **dreaming_promotion_backlog**: 确认 5 天积压，短期记忆未晋升到长期 MEMORY.md

## 关键事件（来自 2026-05-13 记忆）

### 梦境系统异常
- **发现时间**: 2026-05-13 03:00 CST
- **问题**: Memory Dreaming Promotion cron 自 05-07 后停止运行
- **根因**: memory-core 插件被禁用
- **影响**: 05-08 ~ 05-12 期间 5 天无梦境晋升
- **受影响 Cron ID**: 412d9a19

### 调度器冻结模式
- **同类问题**: kg_task_v3 在 05-05 ~ 05-06 也曾冻结
- **症状**: nextRunAtMs 停滞，无错误报告，外观看健康但不触发
- **解决**: 手动触发 cron + 重新启用 memory-core

## Cron 运行状态
| Cron ID | 功能 | 状态 |
|---------|------|------|
| 013cf5c6 | 知识图谱每日更新 v3 | ✅ 运行中 |
| 412d9a19 | Memory Dreaming Promotion | ⚠️ 禁用（memory-core） |
| 470d911a | 每日记忆提炼 | ✅ 正常 |
| 53de5b3f | SESSION-STATE 新鲜度检查 | ✅ 正常 |

## 建议行动
1. 启用 memory-core: `openclaw plugins enable memory-core && openclaw gateway restart`
2. 手动触发梦境晋升处理积压
3. 检查 05-08 ~ 05-12 用户是否与系统有交互
4. 为梦境晋升 cron 添加监控告警

## 明日计划
- 确认 memory-core 重新启用状态
- 检查梦境晋升 cron 是否恢复正常
- 验证积压处理进度

---
*知识图谱更新 v3 - 动态日期版*
*实体数: 59 | 关系数: 69 | 观察数: 39*