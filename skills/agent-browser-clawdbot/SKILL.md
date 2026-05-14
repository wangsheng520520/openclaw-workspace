---
name: agent-browser
description: "Headless browser automation CLI for AI agents — trigger: 'open browser', 'automate web', 'fill form', 'click button', 'extract data from page', 'scrape website', 'login to site', 'test web flow'. Use when: automating multi-step web workflows, need deterministic element selection by ref, scraping structured data from websites, filling forms programmatically, testing single-page applications, performing headless browser tasks with session isolation."
metadata: {"clawdbot":{"emoji":"🌐","requires":{"commands":["agent-browser"]},"homepage":"https://github.com/vercel-labs/agent-browser"}}
---

# Agent Browser Skill

Fast browser automation using accessibility tree snapshots with refs for deterministic element selection.

## Why Use This Over Built-in Browser Tool

**Use agent-browser when:**
- Automating multi-step workflows
- Need deterministic element selection
- Performance is critical
- Working with complex SPAs
- Need session isolation

**Use built-in browser tool when:**
- Need screenshots/PDFs for analysis
- Visual inspection required
- Browser extension integration needed

## Core Workflow

```bash
# 1. Navigate and snapshot
agent-browser open https://example.com
agent-browser snapshot -i --json

# 2. Parse refs from JSON, then interact
agent-browser click @e2
agent-browser fill @e3 "text"

# 3. Re-snapshot after page changes
agent-browser snapshot -i --json
```

## Key Commands

### Navigation
```bash
agent-browser open <url>
agent-browser back | forward | reload | close
```

### Snapshot (Always use -i --json)
```bash
agent-browser snapshot -i --json          # Interactive elements, JSON output
agent-browser snapshot -i -c -d 5 --json  # + compact, depth limit
agent-browser snapshot -s "#main" -i      # Scope to selector
```

### Interactions (Ref-based)
```bash
agent-browser click @e2
agent-browser fill @e3 "text"
agent-browser type @e3 "text"
agent-browser hover @e4
agent-browser check @e5 | uncheck @e5
agent-browser select @e6 "value"
agent-browser press "Enter"
agent-browser scroll down 500
agent-browser drag @e7 @e8
```

### Get Information
```bash
agent-browser get text @e1 --json
agent-browser get html @e2 --json
agent-browser get value @e3 --json
agent-browser get attr @e4 "href" --json
agent-browser get title --json
agent-browser get url --json
agent-browser get count ".item" --json
```

### Check State
```bash
agent-browser is visible @e2 --json
agent-browser is enabled @e3 --json
agent-browser is checked @e4 --json
```

### Wait
```bash
agent-browser wait @e2                    # Wait for element
agent-browser wait 1000                   # Wait ms
agent-browser wait --text "Welcome"       # Wait for text
agent-browser wait --url "**/dashboard"   # Wait for URL
agent-browser wait --load networkidle     # Wait for network
agent-browser wait --fn "window.ready === true"
```

### Sessions (Isolated Browsers)
```bash
agent-browser --session admin open site.com
agent-browser --session user open site.com
agent-browser session list
# Or via env: AGENT_BROWSER_SESSION=admin agent-browser ...
```

### State Persistence
```bash
agent-browser state save auth.json        # Save cookies/storage
agent-browser state load auth.json        # Load (skip login)
```

### Screenshots & PDFs
```bash
agent-browser screenshot page.png
agent-browser screenshot --full page.png
agent-browser pdf page.pdf
```

### Network Control
```bash
agent-browser network route "**/ads/*" --abort           # Block
agent-browser network route "**/api/*" --body '{"x":1}'  # Mock
agent-browser network requests --filter api              # View
```

### Cookies & Storage
```bash
agent-browser cookies                     # Get all
agent-browser cookies set name value
agent-browser storage local key           # Get localStorage
agent-browser storage local set key val
```

### Tabs & Frames
```bash
agent-browser tab new https://example.com
agent-browser tab 2                       # Switch to tab
agent-browser frame @e5                   # Switch to iframe
agent-browser frame main                  # Back to main
```

## Snapshot Output Format

```json
{
  "success": true,
  "data": {
    "snapshot": "...",
    "refs": {
      "e1": {"role": "heading", "name": "Example Domain"},
      "e2": {"role": "button", "name": "Submit"},
      "e3": {"role": "textbox", "name": "Email"}
    }
  }
}
```

## Best Practices

1. **Always use `-i` flag** - Focus on interactive elements
2. **Always use `--json`** - Easier to parse
3. **Wait for stability** - `agent-browser wait --load networkidle`
4. **Save auth state** - Skip login flows with `state save/load`
5. **Use sessions** - Isolate different browser contexts
6. **Use `--headed` for debugging** - See what's happening

## ⚠️ Sensitive Operations — User Confirmation Required

Before executing any of the following, you MUST present the action to the user and await confirmation (`/approve`):

| Operation | Examples | Why Sensitive |
|-----------|----------|----------------|
| **Form submission** | `fill` + `press Enter`, `click` on submit/confirm | May create/modify data on remote servers |
| **Delete / Remove actions** | Clicking delete, remove, uninstall buttons | Irreversible data loss |
| **Payment / Checkout** | Filling payment forms, confirming purchases | Financial transactions |
| **Login / Authentication** | Filling credentials, submitting login forms | Access to user accounts |
| **Data export / download** | Triggering file downloads, exporting data | May expose sensitive information |
| **Settings / Config changes** | Modifying account settings, preferences | Alters account configuration |

### Confirmation Workflow

```
1. Identify sensitive operation from table above
2. Present action to user: "即将执行: [具体操作描述]"
3. Wait for /approve
4. On approval: execute the operation
5. On rejection or timeout: abort and report
```

### Example Confirmation Prompt

```
⚠️ 敏感操作确认

即将执行: 在 github.com 点击 "Delete repository" 按钮

此操作不可逆，是否继续？
请回复 /approve 确认，或取消操作。
```

## ⛔ Boundary — Error & Exception Handling

### Browser Not Installed

If `agent-browser` command fails with `command not found` or installation errors:

```bash
# Install the CLI
npm install -g agent-browser

# Download Chromium browser
agent-browser install

# Linux: install system dependencies
agent-browser install --with-deps

# Verify installation
agent-browser --version
```

### Page Load Failure

If a page fails to load (network error, 4xx/5xx response):

```bash
# 1. Check current URL and page state
agent-browser get url --json
agent-browser get title --json

# 2. Retry with explicit timeout
agent-browser open https://example.com --timeout 30000

# 3. If persistent failure, report to user:
# "页面加载失败: [具体错误]. 请检查 URL 或网络连接。"
```

### Timeout Handling

For operations that hang or exceed expected time:

```bash
# Wait with explicit timeout (ms)
agent-browser wait 5000

# Wait for element to appear (auto-timeout with feedback)
agent-browser wait @e2

# Wait for specific text or URL
agent-browser wait --text "Loading..." --timeout 10000
agent-browser wait --url "**/dashboard" --timeout 15000

# If wait exceeds limit, report:
# "操作超时 (15s): 页面未跳转到预期 URL。请检查网络或页面逻辑。"
```

### Snapshot/Parse Failures

If `snapshot` returns empty or invalid JSON:

```bash
# 1. Verify page is loaded
agent-browser get title --json

# 2. Reload and retry snapshot
agent-browser reload
agent-browser snapshot -i --json

# 3. If still failing, try headed mode for visual inspection
agent-browser open https://example.com --headed
```

### Session / Browser State Issues

```bash
# List active sessions
agent-browser session list

# Create fresh session if corrupted
agent-browser --session fresh open https://example.com

# Clear state and restart
agent-browser state clear
agent-browser open https://example.com
```

## Checkpoint — Sensitive Page Operations

**Before every sensitive operation (see ⚠️ Sensitive Operations table above), you MUST:**

1. **Pause** — Do not execute immediately
2. **Inform** — Tell the user exactly what will happen
3. **Await** — Wait for `/approve` confirmation
4. **Execute** — Only proceed after explicit approval
5. **Abort** — If user declines or no response in 60s, stop and report

### Checkpoint Example Flow

```
You: 检测到敏感操作: 将在 reddit.com 点击 "Delete Post"
     是否继续？请回复 /approve

User: /approve

You: [执行删除操作]
```

## Example: Search and Extract

```bash
agent-browser open https://www.google.com
agent-browser snapshot -i --json
# AI identifies search box @e1
agent-browser fill @e1 "AI agents"
agent-browser press Enter
agent-browser wait --load networkidle
agent-browser snapshot -i --json
# AI identifies result refs
agent-browser get text @e3 --json
agent-browser get attr @e4 "href" --json
```

## Example: Multi-Session Testing

```bash
# Admin session
agent-browser --session admin open app.com
agent-browser --session admin state load admin-auth.json
agent-browser --session admin snapshot -i --json

# User session (simultaneous)
agent-browser --session user open app.com
agent-browser --session user state load user-auth.json
agent-browser --session user snapshot -i --json
```

## Installation

```bash
npm install -g agent-browser
agent-browser install                     # Download Chromium
agent-browser install --with-deps         # Linux: + system deps
```

## Credits

Skill created by Yossi Elkrief ([@MaTriXy](https://github.com/MaTriXy))

agent-browser CLI by [Vercel Labs](https://github.com/vercel-labs/agent-browser)
