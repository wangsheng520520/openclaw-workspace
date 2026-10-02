# TOOLS-mcp-playwright.md — Playwright MCP（26 工具）

> Playwright 浏览器自动化 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx @playwright/mcp@latest --headless --browser chromium`
- **包来源**：Microsoft Playwright 官方 MCP
- **工具数**：26
- **启动延迟**：4.8s
- **传输**：stdio
- **运行模式**：headless（无头）

---

## 核心能力

通过 Playwright 控制 Chromium 浏览器（headless 启动）：

- **导航**：`browser_navigate`、`browser_navigate_back`
- **快照**：`browser_snapshot`（a11y 树，最常用）
- **截图**：`browser_take_screenshot`（CSS/device 像素）
- **交互**：`browser_click`、`browser_hover`、`browser_press_key`、`browser_type`
- **表单**：`browser_fill_form`（多字段，推荐）/ `browser_select_option`
- **拖放**：`browser_drag`、`browser_drop`（文件/MIME）
- **网络**：`browser_network_requests` / `browser_network_request`
- **控制台**：`browser_console_messages`
- **对话框**：`browser_handle_dialog`
- **Tab 管理**：`browser_tabs`（list/new/close/select）
- **上传**：`browser_file_upload`
- **等待**：`browser_wait_for`（文本出现/消失）
- **评估**：`browser_evaluate`（执行 JS）/ `browser_run_code_unsafe`（RCE 等价）
- **WebMCP**：`browser_webmcp_list`、`browser_webmcp_call`
- **resize**：`browser_resize`

---

## 常用调用示例

```bash
# 打开页面（标准流程）
mcporter call playwright.browser_navigate url=https://example.com

# 取 a11y 快照（找元素 ref）
mcporter call playwright.browser_snapshot

# 用 search 找元素
mcporter call playwright.browser_find text="登录"

# 填表单（一键多字段）
mcporter call playwright.browser_fill_form \
  fields='[{"name":"username","type":"textbox","target":"e1","value":"alice"},{"name":"remember","type":"checkbox","target":"e3","value":"true"}]'

# 点击
mcporter call playwright.browser_click element="登录按钮" target=e5

# 截图（全页）
mcporter call playwright.browser_take_screenshot fullPage=true type=png

# 拖拽
mcporter call playwright.browser_drag startElement="源" startTarget=e1 endElement="目标" endTarget=e2

# 等待文本
mcporter call playwright.browser_wait_for text="成功" time=5

# 取网络请求
mcporter call playwright.browser_network_requests static=false filter="api\."

# 控制台消息（error 级）
mcporter call playwright.browser_console_messages level=error

# 处理 alert 弹窗
mcporter call playwright.browser_handle_dialog accept=true
```

---

## snapshot ref 系统

Playwright MCP 的核心是 a11y snapshot — 每个可交互元素有 `ref="eN"`：

```bash
# 1. 快照
mcporter call playwright.browser_snapshot
# → 返回含 e1, e2, e3... 的结构

# 2. 用 ref 操作（不需要 selector）
mcporter call playwright.browser_click target=e3
```

**两种 ref 风格**：
- `refs="role"`（默认）：基于 role + name 匹配
- `refs="aria"`：Playwright aria-ref，更稳定

---

## 何时使用 vs Chrome DevTools

✅ **playwright 适合**：
- 全新无头浏览器（每次干净 slate）
- 自动化测试（CI）
- 跨标签管理（多 Tab 流程）
- 文件拖放（`browser_drop`）
- 文本搜索定位（`browser_find`）

❌ **chrome-devtools 更适合**：
- 复用已有 Chrome 实例/登录态
- 性能 trace / Lighthouse
- 控制台 + 网络栈调试
- WebMCP 页面注册工具调用

---

## 已知限制

- 默认 headless（无 GUI）—— 如果需要可见浏览器，用 `browser_run_code_unsafe` 改启动参数
- 1 个 browser 进程对应 1 个 tab → 跨 session 不保留
- Playwright `browser_run_code_unsafe` 等价 RCE，需明确授权才用

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建