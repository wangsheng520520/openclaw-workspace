# 知识图谱每日更新报告 - 2026-05-08

## 运行信息
- **任务版本**: kg_task_v3 (v3)
- **执行时间**: 2026-05-08 04:00 (Asia/Shanghai)
- **Cron ID**: 013cf5c6-8d40-4eb9-9a93-3c8e8f3edc41

## 图谱统计
| 指标 | 数值 |
|------|------|
| 总实体数 | 38 (+5) |
| 总关系数 | 43 (+6) |
| 总观察数 | 25 (+5) |

## 新增实体 (5)
1. **openclaw_v2026_5_6** - OpenClaw v2026.5.6 系统实体
2. **memory_lancedb_integration** - memory-lancedb 插件集成
3. **sandbox_mode_policy** - 沙盒模式配置策略
4. **plugin_recovery_20260507** - 插件恢复记录
5. **evolvers_review_lock_20260507** - Evolver 审查锁观察

## 新增关系 (6)
1. `openclaw_v2026_5_6` → `upgrades` → `openclaw_v2026_4_23`
2. `memory_lancedb_integration` → `part_of` → `openclaw_v2026_5_6`
3. `sandbox_mode_policy` → `governs` → `openclaw_v2026_5_6`
4. `plugin_recovery_20260507` → `restored` → `openclaw_v2026_5_6`
5. `cron_stability_tracker` → `tracks` → `kg_task_v3`
6. *(已有关系补充)*

## 新增观察 (5)
1. openclaw_v2026_5.6 升级事件
2. memory-lancedb 替换 memory-core
3. sandbox_mode=off 决策原因
4. 插件恢复完成记录
5. Evolver 46 文件被拒绝事件

## 昨日关键事件 (2026-05-07)

### 1. OpenClaw v2026.5.6 升级
- v2026.5.2 → v2026.5.6 (c97b9f7)
- Doctor 自动修复 5 项问题

### 2. 沙盒锁死事件
- **问题**: sandbox.mode="all" 在 v2026.5.6 下导致 agent 完全锁死
- **解决**: 切换 sandbox.mode="off"
- **教训**: 同一配置在不同版本行为差异巨大

### 3. 插件恢复
- 恢复 diagnostics-otel + diagnostics-prometheus
- memory-core 被 memory-lancedb 替代
- 最终 22 插件全绿

### 4. Evolver 进化拒绝
- 46 文件超约束（上限 15）
- 根因：Evolver 产生过多变更

## 当前系统状态
| 项目 | 状态 |
|------|------|
| OpenClaw 版本 | v2026.5.6 |
| 插件数 | 22 (全绿) |
| Skills | 77 eligible |
| Cron 状态 | 8/8 OK |
| Config warnings | 0 |
| 内存插件 | memory-lancedb (LanceDB) |

---
Generated: 2026-05-08 04:00 (Asia/Shanghai)
