
## [SEC-20260504-003] weekly_security_audit_warnings

**Logged**: 2026-05-04T02:00:00Z
**Priority**: low
**Type**: security-audit
**审计周期**: 2026-W18
**上次审计**: 2026-04-27 (SEC-20260427-002)

### 审计结果: 4 warnings, 0 critical issues

**Warning 1 — `.env` 包含明文密钥**
- 文件 `.env` 中含有 `FEISHU_APP_SECRET` 明文
- **缓解措施**: 文件权限 600（仅所有者可读写）+ 已加入 `.gitignore`
- **风险等级**: 低（已有防护，但建议未来使用环境变量或密钥管理工具）
- **状态**: 已缓解，持续监控 ✅（本周无变化）

**Warning 2 — `MEMORY.md` 可能包含密钥**
- 扫描匹配到 `token/key` 关键词
- 实际内容: 历史日志中的 API 变更记录，非真实密钥
- **状态**: 误报，无需处理 ✅（本周无变化）

**Warning 3 — `TOOLS.md` 可能包含密钥（误报）**
- 扫描匹配到 `token` 关键词
- 实际内容: 占位符 `YOUR_BOT_TOKEN`，非真实密钥
- **状态**: 误报，无需处理 ✅（本周无变化）

**Warning 4 — `AGENTS.md` 缺少提示注入防御（误报）**
- 脚本模式匹配未命中
- 实际: AGENTS.md 第 "安全边界" 章节已包含完整的提示注入防御规则
- **状态**: 误报，无需处理 ✅（本周无变化）

### 本周结论
- 与上周审计结果一致，新增 1 项 MEMORY.md warning（同为历史记录中的关键词，非真实密钥）
- 4 项 warning 均为已知状态（已缓解或误报）
- 建议: 审计脚本可优化误报率（排除注释/历史日志中的关键词匹配）

---

## [SEC-20260427-002] weekly_security_audit_warnings

**Logged**: 2026-04-27T02:00:00Z
**Priority**: low
**Type**: security-audit
**审计周期**: 2026-W17
**上次审计**: 2026-04-20 (SEC-20260420-001)

### 审计结果: 3 warnings, 0 critical issues

**Warning 1 — `.env` 包含明文密钥**
- 文件 `.env` 中含有 `FEISHU_APP_SECRET` 明文
- **缓解措施**: 文件权限 600（仅所有者可读写）+ 已加入 `.gitignore`
- **风险等级**: 低（已有防护，但建议未来使用环境变量或密钥管理工具）
- **状态**: 已缓解，持续监控 ✅（本周无变化）

**Warning 2 — `TOOLS.md` 可能包含密钥（误报）**
- 扫描匹配到 `token` 关键词
- 实际内容: 占位符 `YOUR_BOT_TOKEN`，非真实密钥
- **状态**: 误报，无需处理 ✅（本周无变化）

**Warning 3 — `AGENTS.md` 缺少提示注入防御（误报）**
- 脚本模式匹配未命中
- 实际: AGENTS.md 第 "安全边界" 章节已包含完整的提示注入防御规则
- **状态**: 误报，无需处理 ✅（本周无变化）

### 本周结论
- 与上周审计结果完全一致，无新增风险
- 3 项 warning 均为已知状态（已缓解或误报）
- 建议: 审计脚本可优化误报率（增加中文关键词匹配）

---

## [SEC-20260420-001] weekly_security_audit_warnings (已归档)

**Logged**: 2026-04-20T00:26:00Z
**Priority**: low
**Type**: security-audit

### 审计结果: 3 warnings, 0 critical issues

**Warning 1 — `.env` 包含明文密钥**
- 文件 `.env` 中含有 `FEISHU_APP_SECRET` 明文
- **缓解措施**: 文件权限 600（仅所有者可读写）+ 已加入 `.gitignore`
- **风险等级**: 低（已有防护，但建议未来使用环境变量或密钥管理工具）
- **状态**: 已缓解，持续监控

**Warning 2 — `TOOLS.md` 可能包含密钥（误报）**
- 扫描匹配到 `token` 关键词
- 实际内容: 占位符 `YOUR_BOT_TOKEN`，非真实密钥
- **状态**: 误报，无需处理

**Warning 3 — `AGENTS.md` 缺少提示注入防御（误报）**
- 脚本模式匹配未命中
- 实际: AGENTS.md 第 "安全边界" 章节已包含完整的提示注入防御规则
- **状态**: 误报，无需处理

### 建议改进
- 考虑将 `.env` 中的密钥迁移到系统环境变量或密钥管理服务
- 审计脚本可优化误报率（增加中文关键词匹配）

- Reproducible: yes
- Source: cron/security-audit
- Tags: security, audit, weekly, env-secret

---

## [ERR-20260414-006] subagent_gateway_timeout

**Logged**: 2026-04-14T08:57:00Z
**Priority**: medium
**Status**: pending
**Area**: infra

### Summary
Phase 4 质量验证的 3 个子 Agent 全部因 gateway tick timeout 失败

### Error
```
gateway closed (4000): tick timeout
Gateway target: ws://127.0.0.1:18789
```

### Context
- SKILL.md 有 31KB (604行)，子 Agent 读取后消耗大量上下文
- 3 个子 Agent (sanity/edge/voice) 全部在读取 SKILL.md 后超时
- 返回的结果是 SKILL.md 全文而非测试结果
- 临时方案：在主会话中手动执行 Phase 4 验证

### Suggested Fix
- 大文件的子 Agent 任务需要增加超时限制
- 或将 SKILL.md 拆分为摘要版供验证 Agent 使用
- 或在 spawn 时使用 runTimeoutSeconds 参数增加超时

### Metadata
- Reproducible: yes
- Source: error
- Tags: subagent, gateway, timeout, skill-size

---

## [ERR-20260425-007] feishu_command_not_found

**Logged**: 2026-04-24T16:14:38Z  
**Priority**: low  
**Status**: pending  
**Area**: tools  

### Summary
HEARTBEAT 日历检查任务失败：`feishu` 命令不存在

### Error
```
error: unknown command 'feishu'
```

### Context
- 任务：HEARTBEAT.md 每日检查 - 24-48 小时内的日历事件
- 预期：使用 feishu CLI 读取飞书日历
- 实际：系统中未安装 feishu 命令
- 影响范围：仅日历检查功能，其他功能正常

### Suggested Fix
- 检查 feishu CLI 是否已安装及路径配置
- 或改为使用飞书 API 替代 CLI
- 或在心跳任务中跳过该检查直到工具可用

### Metadata
- Reproducible: yes
- Source: heartbeat
- Tags: feishu, cli, calendar, heartbeat

---

## [ERR-20260425-008] async_exec_sigterm_failure

**Logged**: 2026-04-25T14:32:33Z  
**Priority**: low  
**Status**: pending  
**Area**: exec/infra  

### Summary
Async background exec command (wild-val session) terminated unexpectedly with SIGTERM signal

### Error
```
Exec failed (wild-val, signal SIGTERM)
```

### Context
- Task: Spawned background async exec command
- Completion status: Failed with termination signal
- No explicit user-facing impact identified yet
- Cause unknown (may be intentional termination, resource limit, or system restart)

### Suggested Fix
- Check if the wild-val session was intentionally terminated
- Monitor for repeated SIGTERM failures in background exec tasks
- Add proper exit code handling and cleanup for background exec tasks
- Review if the associated task was completed before termination

### Metadata
- Reproducible: unknown
- Source: exec-event
- Tags: exec, sigterm, background-task, async

---

## [SEC-20260511-004] weekly_security_audit_warnings

**Logged**: 2026-05-11T02:00:00Z
**Priority**: low
**Type**: security-audit
**审计周期**: 2026-W19
**上次审计**: 2026-05-04 (SEC-20260504-003)

### 审计结果: 3 warnings, 0 critical issues

**Warning 1 — `.env` 包含明文密钥（重复告警）**
- 同 SEC-20260504-003，持续存在
- `FEISHU_APP_SECRET` 等凭证明文存储于 `.env`
- **缓解措施**: 文件权限 600 + `.gitignore`
- **状态**: 已缓解 ✅（本周无变化）

**Warning 2 — `TOOLS.md` 可能包含密钥（误报）**
- grep 匹配到 `token/key` 关键词
- **实际情况**: 占位符文本 `YOUR_BOT_TOKEN`，非真实密钥
- **状态**: 误报，无需处理 ✅

**Warning 3 — `AGENTS.md` 可能缺少 prompt injection 防御（误报）**
- 扫描警告提示缺少防御规则
- **实际情况**: AGENTS.md 第 95-100 行已有完整提示注入防御说明
- **状态**: 误报，扫描工具局限性 ✅

### 结论
本周安全状况正常，无新增问题。3 个 warning 中 2 个为已知/已缓解，1 个为扫描工具误报。

