# MEMORY-pi-agent.md — Pi Agent (ACPX) 配置档案

> 从 `MEMORY-decisions.md` 拆出来的 Pi Agent 主题子域 (2026-08-05)。
> 主题: Pi Agent (ACPX) 在 OpenClaw 里的完整配置 + 调试经验 + 教训。
> 主索引见 → `MEMORY.md`（🔒 决策段 / 子文件索引表 / 系统状态快照）。
>
> **加载规则**: OpenClaw bootstrap 走精确 basename 匹配（看 `run-attempt-V636cwT5.js` 白名单），`MEMORY-*.md` 不在白名单，按需 `read` 加载。

---

## 2026-08-05 Pi Agent (ACPX) 配置修复 — C 路径落地

**症状**: `sessions_spawn({runtime:"acp", agentId:"pi"})` 报 `spawn_failed | Internal error -32603`

**根因 (5 步法实测定位)**: `mergeAgentRegistry` (`acpx/dist/live-checkpoint-mdAaF3qK.js:487`) 只接受 string command:

```js
for (const [name, command] of Object.entries(overrides)) {
    if (!normalized || !command.trim()) continue;   // ← 崩在这
    merged[normalized] = command.trim();
}
```

- acpx **内置** `pi` agent: `"npx pi-acp@^0.0.26"` (**string**)
- OpenClaw 原配置 `plugins.entries.acpx.config.agents.pi = {command:"pi-acp", args:["--no-session"]}` (**object**)
- TypeError 被外层捕获 → 包装成 `Internal error -32603` (**完全看不见真实原因**)

**修复决策**: 用户拍板 **C 路径** (`agents.list[].runtime.type="acp"` 入口,官方推荐写法)

- `agents.list` 新增 pi entry (`id="pi"`, `runtime.type="acp"`, `runtime.acp={agent:"pi", backend:"acpx", mode:"persistent"}`)
- `plugins.entries.acpx.config.agents` 设为 `{}` (避免 mergeAgentRegistry 触发)
- `acp.defaultAgent = "pi"` + `acp.allowedAgents = ["pi"]` 保持不变
- gateway SIGUSR1 热重载 (**不需要硬重启**)
- 备份: `/tmp/openclaw.json.bak-pi-acp-fix-20260805-102942`

**验证证据**:

| 探针 | 结果 |
|---|---|
| `openclaw status` | Agents 1 → **2** ✅ |
| sessions_spawn 探针 5 | `status:accepted`, childSessionKey `agent:pi:acp:d6163467-...` ✅ |
| 子会话状态 | `status:done`, label=`pi-probe-fix-1` ✅ |
| pi 回复 | `ok` (21s 完成) ✅ |

**三个工具配套记录** (5 步法第 1 步关键工具):

1. **直接 `node -e` 调 `acpx/runtime.createAgentRegistry({overrides:{pi:{...}}})`** — 复现 TypeError, 不靠推断就能定位 bug
2. **`python3 + subprocess` 直接给 `pi-acp` 喂 JSON-RPC initialize** — 证明 pi-acp 包本身完全正常 (protocolVersion 1, 6 auth methods, image/loadSession 齐全) — 排除 pi-acp 自身 bug
3. **sessions_spawn(runtime="acp") 探针** — 端到端验证 spawn 成功

**教训** (升 `AGENTS.md`/`.learnings/LEARNINGS.md` 候选):

1. **"-32603 Internal error" 是 OpenClaw ACP 路径的"包装垃圾箱"** — 任何真实错误 (TypeError / ENOENT / 配置缺失) 都被压成这条。同样的"-32603"也可能来自 codex/claude/gemini/opencode harness, 必须看**底层 stderr** 或 `codex-acp-wrapper.stderr.*.log` (`~/.openclaw/state/acpx/`) 才能定位
2. **OpenClaw ACP 配置两条路径不能混用**:
   - 旧/错误路径: `plugins.entries.acpx.config.agents` (object format, **会让 mergeAgentRegistry 崩**)
   - 新/正确路径: `agents.list[].runtime.type="acp"` + `runtime.acp.agent` (**官方推荐**, 支持完整 command+args+cwd+env)
3. **"配置写好了" ≠ "能跑"** — 07-29 写了 `plugins.entries.acpx.config.agents.pi` 但 39 天没人调过 (0 个 pi session 历史)。配置类工作**必须 sessions_spawn 实测**才能签字
4. **5 步法不可压缩**: 跳过"看错误日志 → 看源码 → node -e 复现"任何一步都只能猜。`-32603` 文字提示误导性极强 (看起来像 RPC 协议错, 实际是 JS TypeError)

**对应 .learnings/LEARNINGS.md**: `category=best_practice, content="ACP agent 配置必须 sessions_spawn 实测,不能只看 JSON 是否写对; -32603 Internal error 是包装错误,必须看底层 stderr 或源码"`

---

## 2026-08-06 Pi Agent 实测验证 + 模型策略确认（跟随默认）

**端到端实测**（非纸面检查）：

| 步骤 | 操作 | 结果 |
|------|------|------|
| 1 | 检查 `openclaw.json` | ✅ `agents.list` 含 pi（`runtime.type="acp"` + acpx + persistent）；`acp.allowedAgents=["pi"]` |
| 2 | 确认包已安装 | ✅ `@automatalabs/pi-acp@0.3.0` + `@earendil-works/pi-coding-agent@0.82.1` |
| 3 | `sessions_spawn(runtime="acp", agentId="pi")` 探针 | ✅ `status: accepted` |
| 4 | 读子会话历史 | ✅ Pi 实际回复（model 显示 `ark-code-latest`） |
| 5 | 统计 | ✅ 耗时 25s，状态 `done` |

**验证结论**：C 路径修复仍有效，未回退；Pi 可用。

**模型策略（用户 @ 12:26 拍板：不指定模型，跟随默认）**：
- `agents.list` 的 pi entry **无 `model` 字段**（keys 仅 `['id','runtime']`）→ 天然继承 `agents.defaults.model.primary`
- 默认模型 = `volcano/ark-code-latest`；fallbacks 7 个（qwen3.7-plus/max、qwen3.6-flash、glm-5.2、deepseek-v4-pro、deepseek-v4-flash、qwen3.8-max-preview）
- `acp` 配置块无 model 覆盖（keys 无 model）
- **实测确认**：Pi 实际用的就是 `ark-code-latest`（默认模型）
- **与 main entry 的区别**：`agents.list` 的 main 显式指定 `minimax/MiniMax-M3`（历史遗留，主会话用自己的模型）；pi 不指定 → 跟随默认。两者独立，互不影响
- **无需修改任何配置**：现状已满足

---

## 相关外部引用

- OpenClaw ACP 文档: `https://docs.openclaw.ai/zh-CN/tools/acp-agents` 和 `https://docs.openclaw.ai/tools/acp-agents-setup`
- acpx GitHub: `https://github.com/openclaw/acpx`
- pi 包: `@earendil-works/pi-coding-agent` v0.82.1 (07-29 安装, npm 全局)
- pi-acp 包: `@automatalabs/pi-acp` v0.3.0 (07-29 安装, npm 全局)
- acpx 插件源码: `~/.openclaw/npm/projects/openclaw-acpx-052d680d6d/node_modules/@openclaw/acpx/dist/`
- OpenClaw 源码相关: `acp-spawn-CtlOotd2.js` (spawn 入口), `runtime-DXAKhVSX.js` (-32603 判定)
