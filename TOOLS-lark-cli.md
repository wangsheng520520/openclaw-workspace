# TOOLS-lark-cli.md — lark-cli 飞书 CLI 速查

> lark-cli 飞书命令行工具的子文件 (2026-08-06 建立)。
> 主索引见 → `TOOLS.md`。
>
> **加载规则**：`TOOLS-*.md` 不自动注入，按需 `read` 加载（OpenClaw bootstrap 只匹配精确 basename）。

---

## ⚠️ 关键事实（先读）

1. **lark-cli 不在默认 PATH** — 每次使用前必须 `export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"`
   - 装了但 OpenClaw 默认 shell 不自动加载 → 记得先 export（记忆 2026-06-11 多次踩坑）
2. **版本**：v1.0.71（旧记录 v1.0.19 已过时）
3. **配置复用飞书 App**：`cli_a911625db7f8dcc2`，token 在 `~/.local/share/lark-cli/`
4. **优先级**：飞书操作**推荐 lark-cli**（命令完善），比 OpenClaw feishu_* 工具更精细；但 OpenClaw 消息收发仍走 feishu 插件（WebSocket）

---

## 命令体系（24 个 domain）

**核心高频**：
```bash
lark-cli calendar +agenda                # 今日日程
lark-cli calendar +create --summary "会议" --start "..." --end "..."
lark-cli mail +triage                    # 飞书邮件
lark-cli docs +fetch --url <url>         # 读取飞书文档
lark-cli im ...                          # 消息/群聊
lark-cli wiki ...                        # 知识库
lark-cli sheets ...                      # 表格
lark-cli task ...                        # 任务
lark-cli approval ...                    # 审批
```

**全部 domain**：
application · approval · apps · attendance · base · calendar · contact · docs · drive · event · im · mail · markdown · mindnotes · minutes · note · okr · sheets · slides · task · vc · whiteboard · wiki

**Agent 工具**：
```bash
lark-cli schema <service>.<resource>.<method>   # 查 API 参数/scope/示例
lark-cli api GET <path> [--params <json>]        # 原始 HTTP 逃生口
lark-cli skills list | read                      # 内嵌技能
```

**管理**：auth · config · doctor · profile · update

---

## 常用 flags

| flag | 用途 |
|------|------|
| `--jq <expr>` | 过滤 JSON 输出 |
| `--dry-run` | 预览请求（不实际执行） |
| `--yes` | 高风险写操作需确认（high-risk-write 才需要） |

**风险分级**：每个命令 `--help` 标明 `read | write | high-risk-write`；high-risk-write 必须用户确认后 `--yes`。

---

## 踩坑记录（2026-06-11）

- **PATH 问题**：lark-cli 不在默认 PATH → `command not found`。曾导致 TOOLS.md 写的"优先 lark-cli"实际从未自动生效。
- **教训**：飞书操作若报 `command not found`，先 export PATH 再试；OpenClaw 消息收发靠 feishu 插件，lark-cli 是补充的精细操作层。

---

## 相关

- 工具总览 → `TOOLS.md`
- 环境总览 → `BOOTSTRAP.md`
- 飞书日历/通知配置 → `MEMORY-openclaw-system.md`
