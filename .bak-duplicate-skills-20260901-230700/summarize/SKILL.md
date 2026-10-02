---
name: summarize
description: |
  总结/提取 URL、播客、YouTube、本地文件的文本和字幕。
  触发词：总结这个链接、这个视频讲了什么、提取字幕、摘要、summarize。
  也是"转写 YouTube/视频"的最佳备选方案。
homepage: https://summarize.sh
metadata:
  {
    "openclaw":
      {
        "emoji": "🧾",
        "requires": { "bins": [] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "steipete/tap/summarize",
              "bins": ["summarize"],
              "label": "Install summarize (brew)",
            },
          ],
      },
  }
---

# Summarize 🧾

快速总结 URL、本地文件和 YouTube 链接。

## 触发条件

- 用户说"总结这个链接"、"这个视频讲了什么"
- 用户说"提取字幕"、"transcribe this"
- 用户发送 URL 并要求摘要
- 用户发送本地文件要求总结

## 工作流

### Step 1: 判断输入类型

```
收到总结请求 →
├── YouTube URL → YouTube 处理流程
├── 普通 URL   → 网页总结流程
├── 本地文件   → 文件总结流程
└── 纯文本     → 直接总结
```

### Step 2: 检查工具可用性

```bash
# 检查 summarize CLI 是否已安装
which summarize && echo "✅ CLI 可用" || echo "⚠️ CLI 未安装，用 web_fetch 替代"
```

**两条路径**：

| 路径 | 条件 | 方式 |
|------|------|------|
| **CLI 路径** | summarize 已安装 | `summarize "<URL>" --model google/gemini-3-flash-preview` |
| **替代路径** | CLI 未安装 | `web_fetch "<URL>"` → 手动总结内容 |

### Step 3: 执行总结

**CLI 路径**：
```bash
# 网页/文章
summarize "https://example.com" --model google/gemini-3-flash-preview --length medium

# YouTube（提取字幕+总结）
summarize "https://youtu.be/xxx" --youtube auto

# YouTube（仅提取字幕）
summarize "https://youtu.be/xxx" --youtube auto --extract-only

# 本地文件
summarize "/path/to/file.pdf" --model google/gemini-3-flash-preview
```

**替代路径**：
```bash
# 用 web_fetch 获取内容
web_fetch url="<URL>" extractMode="markdown"
# 然后手动总结
```

### Step 4: 输出格式

```markdown
## 📝 内容摘要

**来源**: [标题](URL)
**类型**: 文章/视频/PDF
**长度**: 约 X 字/X 分钟

### 核心观点
（3-5 句话概括）

### 关键要点
1. ...
2. ...
3. ...

### 值得关注的细节
- ...
```

### Step 5: 保存（可选）

如果用户要求保存：
- 保存到 `obsidian-vault/Clippings/` 或 `01-灵感库/`
- 注入 YAML Frontmatter（source: 网页剪藏）

## 常用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--length` | 输出长度 | short/medium/long/xl |
| `--extract-only` | 仅提取不总结 | YouTube 字幕 |
| `--json` | JSON 格式输出 | 程序化处理 |
| `--youtube auto` | YouTube 字幕提取 | 自动选最佳方式 |
| `--firecrawl auto` | 被拦截网站备选 | 需要 FIRECRAWL_API_KEY |

## API Key 配置

| Provider | 环境变量 | 用途 |
|----------|----------|------|
| Google | `GEMINI_API_KEY` | 默认模型 |
| OpenAI | `OPENAI_API_KEY` | 备选模型 |
| Firecrawl | `FIRECRAWL_API_KEY` | 被拦截网站 |
| Apify | `APIFY_API_TOKEN` | YouTube 备选 |

## 限制

- YouTube 字幕提取依赖第三方服务，可能不稳定
- 需要验证码/登录的页面无法处理
- 超长内容（>50000 字）可能需要分段处理
- CLI 未安装时退化为 web_fetch，总结质量依赖当前模型
