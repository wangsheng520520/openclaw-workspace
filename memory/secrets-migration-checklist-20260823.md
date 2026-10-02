# Secrets Migration Checklist — 下次执行用

> **创建时间**: 2026-08-23 08:47 CST
> **会话上下文**: 全面体检后的 secrets configure 向导退出
> **状态**: 8 PLAINTEXT_FOUND 待迁移，2 REF_SHADOWED 已修 (8/23 08:16)

---

## 🎯 目标：8 → 0 PLAINTEXT_FOUND

**前置数据准备**（建议执行，下次跑向导前确认）：

```bash
# 步骤 1: 备份
cp -a ~/.openclaw/secrets/default.json ~/.openclaw/secrets/default.json.bak-$(date +%Y%m%d-%H%M)

# 步骤 2: 在 ~/.openclaw/secrets/default.json 加 2 个缺失的 profiles
#   profiles.deepseek.default.key   (从 models.json providers.deepseek.apiKey 复制)
#   profiles.volcano.default.key    (从 models.volcano.apiKey 复制: ff6223...a4c3)
#
# ⚠️ 此步骤需用户明确确认 — healthcheck 技能要求"access to sensitive files"
```

**修后 secrets/default.json 应有 profiles**：

```json
{
  "profiles": {
    "minimax-portal": { "default": { "key": "sk-cp-…" } },
    "minimax": {
      "cn": { "key": "sk-cp-…" },
      "global": { "key": "sk-cp-…" }
    },
    "qwen": { "default": { "key": "sk-c70…" } },
    "volcengine": { "default": { "key": "ff6223…" } },
    "deepseek": { "default": { "key": "sk-8bf4…" } },
    "volcano": { "default": { "key": "ff6223…" } }
  }
}
```

---

## 🧭 向导操作清单（按出现顺序）

**起点**：TTY 终端跑 `openclaw secrets configure`

| 顺序 | 向导字段 | 操作 | id |
|---|---|---|---|
| 1 | Continue (provider setup) | ↓ Enter (default provider 已存在) | — |
| 2 | profiles.deepseek:default.key | file → default → **/profiles/deepseek/default/key** | ✅ |
| 3 | profiles.deepseek:default.token | **Skip 同 2 (deepseek token 未用)** | — |
| 4 | profiles.minimax-portal:default.key | **Skip** (LEGACY OAuth) | — |
| 5 | profiles.minimax-portal:default.token | **Skip** | — |
| 6 | profiles.minimax:cn.key | file → default → **/profiles/minimax/cn/key** | ✅ |
| 7 | profiles.minimax:cn.token | **Skip** | — |
| 8 | profiles.minimax:global.key | file → default → **/profiles/minimax/global/key** | ✅ |
| 9 | profiles.minimax:global.token | **Skip** | — |
| 10 | profiles.ollama:default.key | **Skip** (本地 ollama) | — |
| 11 | profiles.ollama:default.token | **Skip** | — |
| 12 | profiles.opencode-go:default.key | **Skip** (未在用) | — |
| 13 | profiles.opencode-go:default.token | **Skip** | — |
| 14 | profiles.opencode:default.key | **Skip** (未在用) | — |
| 15 | profiles.opencode:default.token | **Skip** | — |
| 16 | profiles.qwen:default.key | file → default → **/profiles/qwen/default/key** | ✅ |
| 17 | profiles.qwen:default.token | **Skip** | — |
| 18 | profiles.volcano:default.key | file → default → **/profiles/volcano/default/key** | ✅ |
| 19 | profiles.volcano:default.token | **Skip** | — |
| 20 | profiles.volcengine:default.key | file → default → **/profiles/volcengine/default/key** | ✅ |
| 21 | profiles.volcengine:default.token | **Skip** | — |
| 22 | agents.defaults.memorySearch.remote.apiKey | file → default → **/memorySearch/remote/apiKey** | ✅ |
| 23 | (其他 candidates 如 channels.feishu.appSecret) | **Skip** (改 ref 风险高) | — |
| 24 | gateway.auth.token | **Skip** (gateway 自身认证) | — |

**映射项数**：8 项 Map (deepseek + minimax(2) + qwen + volcano + volcengine + memorySearch)  
**Skip 项数**：约 16 项

---

## ⚠️ 关键决策点

1. **"Apply this plan now?"** → 先选 **No**（生成 plan-out 文件 + 我审阅）
2. **不建议直接 Apply**：先 plan-out /tmp/secrets-plan.json → 我审阅 → 再 apply --from
3. **Apply 后必须 restart gateway**：ref 解析逻辑可能在 runtime 缓存

---

## 📋 验证清单（执行后跑）

```bash
# 1. secrets audit 应显示 plaintext=0
openclaw secrets audit | head -3
# 期望: Secrets audit: findings. plaintext=0, unresolved=0, shadowed=0, legacy=1

# 2. security audit 应保持 0 critical / 2 warn
openclaw security audit --deep --json | python3 -c "
import json, sys
raw = sys.stdin.read()
idx = raw.find('{')
data = json.loads(raw[idx:])
print(f\"critical={data['summary']['critical']}, warn={data['summary']['warn']}, info={data['summary']['info']}\")
"
# 期望: critical=2 (FP), warn=2 (acpx + feishu), info=2

# 3. Gateway reachable (restart 后)
openclaw status | grep -E "Gateway.*reachable"

# 4. 实际 provider 调用测试 (健康)
openclaw health | grep -E "event loop|Feishu|agents"
```

---

## 🔗 历史决策链接

- 8/23 00:38 — 体检发现 8 PLAINTEXT_FOUND + 2 REF_SHADOWED + 2 critical FP
- 8/23 08:16 — 方案 4 部分执行：unset 2 REF_SHADOWED (minimax + volcano apiKey)
- 8/23 08:20 — Gateway restart (PID 3597 → 12725) 应用 trustedProxies
- 8/23 08:35 — secrets configure 向导启动 → 08:47 用户 Ctrl+C 退出（A3a 决策）
- 8/23 08:47 — secrets-migration-checklist 创建（本文件）

---

## 💡 备选方案（如果向导仍卡住）

如果 deepseek / volcano id 预检失败：

**Plan B**: 先把 5 项搞定（minimax×2 + qwen + volcengine + memorySearch），deepseek/volcano 留着：

```bash
# 等 5 项 Map 完后用 __done__ 退出
# 然后手动 openclaw config set 改剩下 3 项的 ref
openclaw config set "models.providers.deepseek.apiKey" '{"source":"file","provider":"default","id":"/models/deepseek/apiKey"}'
# 注意: 这种 set 要 schema 验证 secrets input ref
```

**Plan C**: 全部跳过，PLAINTEXT 现状保留（不推荐）

---

**状态**: 待用户后续在 TTY 终端执行
**下次操作入口**: `openclaw secrets configure`（确保 default.json 已 patch 2 个 profiles）
