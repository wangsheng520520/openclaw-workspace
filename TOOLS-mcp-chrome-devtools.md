# TOOLS-mcp-chrome-devtools.md — Chrome DevTools MCP（29 工具）

> Chrome DevTools MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx chrome-devtools-mcp@latest`
- **包来源**：Chrome DevTools MCP 官方包
- **工具数**：29
- **启动延迟**：5.5s（中等）
- **传输**：stdio
- **关联能力**：与 OpenClaw 内置 `browser` 工具共享浏览器

---

## 核心能力

通过 Chrome DevTools Protocol 控制 Chrome 浏览器：

- **页面导航**：`navigate_page`、`new_page`、`close_page`
- **快照**：`take_snapshot`（a11y 树）、`take_screenshot`
- **表单填写**：`fill_form`（多字段）、`fill`、`select_option`
- **交互**：`click`、`hover`、`press_key`、`type_text`
- **网络**：`list_network_requests`、`get_network_request`
- **控制台**：`list_console_messages`、`get_console_message`
- **性能**：`performance_start_trace`、`performance_analyze_insight`
- **截图**：`take_screenshot`、`take_heap_snapshot`
- **emulation**：`emulate`（viewport/network/CPU）
- **选择/窗口**：`select_page`、`resize_page`、`list_pages`
- **WebMCP**：`browser_webmcp_list`、`browser_webmcp_call`

---

## 常用调用示例

```bash
# 列出所有打开页面
mcporter call chrome-devtools.list_pages

# 导航到 URL
mcporter call chrome-devtools.navigate_page type=url url=https://example.com

# 取 a11y 快照（最新交互页面）
mcporter call chrome-devtools.take_snapshot

# 截图（全页 PNG）
mcporter call chrome-devtools.take_screenshot format=png fullPage=true

# 点击元素（用 ref）
mcporter call chrome-devtools.click uid=e12

# 填多字段表单
mcporter call chrome-devtools.fill_form elements='[{"uid":"e1","value":"foo"},{"uid":"e2","value":"bar"}]'

# 看 console error
mcporter call chrome-devtools.list_console_messages level=error

# 看网络请求（指定 URL 过滤）
mcporter call chrome-devtools.list_network_requests filter="api.example.com"

# Lighthouse 审查（除 performance）
mcporter call chrome-devtools.lighthouse_audit device=desktop mode=navigation
```

---

## 何时使用 vs Playwright

✅ **chrome-devtools 适合**：
- 已有 Chrome 实例，复用其 cookies/会话
- 深度性能审计（Lighthouse / performance trace / heap snapshot）
- 调试（看 console + network + stack）
- WebMCP 注册的工具调用（`browser_webmcp_call`）

❌ **playwright 更适合**：
- 全新浏览器实例（每次干净）
- 跨浏览器测试（chromium / firefox / webkit）
- 自动等待 / 稳定 ref 系统
- 长会话多步骤自动化

---

## 浏览器选择与 profile

```bash
# 默认用 OpenClaw 管理的隔离 openclaw 浏览器
mcporter call chrome-devtools.navigate_page type=url url=https://...

# 指定特定 profile（保留登录状态）
mcporter call chrome-devtools.take_snapshot profile=my-profile
```

⚠️ 涉及他人账号或会话前，**必须先获得用户授权**。

---

## 已知限制

- 必须有 Chrome 进程运行（OpenClaw 会自动启动）
- `act:evaluate` 单次超时建议 ≥ 10s
- Chrome DevTools Protocol 某些 trace 类型在 headless 模式不支持

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建