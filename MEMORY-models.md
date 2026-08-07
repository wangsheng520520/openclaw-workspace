# MEMORY-models.md — 模型 / 向量记忆 / 渠道配置档案

> 从 `MEMORY.md` 拆分出的 "模型配置 + memory-lancedb 向量记忆 + 各渠道状态" 子域 (2026-08-06)。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：`MEMORY-*.md` 不自动注入，按需 `read` 加载。

---

## memory-lancedb + 硅基流动 BAAI/bge-m3 (2026-06-04, 06-12 压缩, 07-30 重大修正)

- ⚠️ **2026-07-30 22:10 重大修正**：之前的"必须 dimensions: 1024"结论**是错的**！
  - 真实根因 = **07-02 手动 patch 插件白名单**（加 `"BAAI/bge-m3": 1024`），**07-15 npm 装 2026.7.1 覆盖了 patch**，plugin 从 07-17 起静默失败 16 天
  - **真正能工作的配置** = 07-14 前那份：**不写 apiKey、不写 dimensions**（Path B 走 host adapter）
  - **必做 patch** = 在 `dist/config.js:32-35` 给 `EMBEDDING_DIMENSIONS` 加 `"BAAI/bge-m3": 1024` 条目
  - 任何 `npm install` 都会覆盖 patch → **必须重打**
  - 完整复盘见 `TOOLS-memory-ai.md` + `.learnings/LEARNINGS.md (2026-07-30 22:00 条目)`
  - 当前 slot = `memory-lancedb`（已恢复 + 已重打 patch + 已硬重启验证）

---

## 模型配置（三层区分，2026-08-06 实测 openclaw.json）

> ⚠️ 易混淆点：**全局默认 ≠ 主会话模型**。以 openclaw.json 实值为准（08-06 12:39 核对）。

| 层级 | 配置项 | 模型 | 谁在用 |
|------|--------|------|--------|
| **主 agent (main)** | `agents.list[0].model.primary` | `minimax/MiniMax-M3` | 主会话/日常交互、飞书/webchat 主对话 |
| **全局默认** | `agents.defaults.model.primary` | `volcano/ark-code-latest`（火山方舟 Ark） | 未指定模型的 agent 兜底（如 pi） |
| **pi (ACP)** | 无 model 字段（null） | → 跟随全局默认 `volcano/ark-code-latest` | Pi Agent 会话 |

**关键结论**：
- 主会话（main）实际用 `minimax/MiniMax-M3`；pi 无 own model → 用全局默认 `volcano/ark-code-latest`
- `volcano` = 火山方舟 Ark（provider baseUrl 已切到 Coding Plan: ark.cn-beijing.volces.com/api/coding/v3）；`volcengine-plan/` 是旧别名写法，现已统一为 `volcano/`
- **易错教训**：别把 `agents.defaults.model.primary`（全局默认）当成主会话模型。

**其他模型**：`deepseek/deepseek-v4-pro` + `deepseek/deepseek-v4-flash`（2026-08-05 用户配置）；硅基流动 SiliconFlow（BAAI/bge-m3 嵌入 + 其余模型）；bailian-token-plan（qwen3.7/max/plus、qwen3.6-flash、glm-5.2、deepseek-v4-pro）**全部 fallbacks**

---

## 渠道 / 服务状态

| 渠道 | 状态 | 备注 |
|------|------|------|
| 邮件 (Himalaya) | ✅ 已配置 | Gmail (wszmd1793@gmail.com) + QQ (601701001@qq.com) |
| 日历/通知 (飞书) | ✅ 已集成 | WebSocket 连接 |
| lark-cli | ✅ 已安装 | v1.0.71, 复用飞书App |

> ⚠️ 完整渠道运行细节见 `TOOLS.md` + `TOOLS-lark-cli.md` + `TOOLS-memory-ai.md`

---

## 火山 Coding Plan 套餐切换 (2026-08-07 12:02)

**用户操作**: 火山模型换套餐（Coding Plan），提供新 API 凭据。

**配置变更**:
- baseUrl: `https://ark.cn-beijing.volces.com/api/plan/v3` → `https://ark.cn-beijing.volces.com/api/coding/v3`
- apiKey: `ark-fc2bb5ed-...` → `ff622315-85eb-43dc-a1a8-d229a08aa4c3`
- 模型名: `ark-code-latest`（不变）
- api 适配: `openai-completions`（不变，新套餐 OpenAI 兼容端点 /api/coding/v3）

**变更位置**:
- `openclaw.json` → `models.providers.volcano.baseUrl`（reloadKind=hot）
- `secrets/default.json` → `models.volcano.apiKey` / `models.volcengine.apiKey` / `models.volcengine-plan.apiKey`（3 处统一更新）
- `profiles.volcengine.default.key` 已是新 key（未动）

**验证**:
- ✅ curl 新端点 + 新 key → 200 OK（"好哒..."响应）
- ✅ gateway 日志: `[reload] config hot reload applied (models.providers.volcano.baseUrl)`
- ✅ JSON 合法性 + secrets 权限 600
- 备份: `/tmp/openclaw.json.bak-20260807-1202` + `/tmp/secrets-default.json.bak-20260807-1202`

**新套餐双协议**（备忘）:
- OpenAI 兼容: `https://ark.cn-beijing.volces.com/api/coding/v3`（已配）
- Anthropic 兼容: `https://ark.cn-beijing.volces.com/api/coding`（未用，如需切换 api=anthropic-messages）
