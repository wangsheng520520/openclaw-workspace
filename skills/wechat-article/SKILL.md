---
name: wechat-article
description: |
  抓取微信公众号文章，提取标题和内容并输出为 Markdown 格式。
  当用户发送微信公众号链接（mp.weixin.qq.com）或说"抓取公众号文章"、"提取微信文章"、"读取公众号"时触发。
metadata: { "openclaw": { "emoji": "📰", "requires": { "bins": ["python3"], "env": [] } } }
---

# 微信公众号文章抓取 📰

通过公众号链接获取文章的标题和内容，输出为 Markdown 格式。

## 触发条件

- 用户发送 `mp.weixin.qq.com` 链接
- 用户说"抓取公众号文章"、"提取微信文章"、"读取公众号"
- 用户要求保存公众号文章到 Obsidian

## 工作流

### Step 1: 识别链接

```
收到公众号链接 → 验证是否为 mp.weixin.qq.com 域名
├── ✅ 是 → Step 2
└── ❌ 否 → 提示用户这不是公众号链接
```

### Step 2: 提取内容（按优先级尝试）

| 优先级 | 方式 | 命令 | 说明 |
|--------|------|------|------|
| 1️⃣ | **r.jina.ai** | `web_fetch "https://r.jina.ai/<公众号URL>"` | 推荐，成功率最高 |
| 2️⃣ | **Python 脚本** | `python3 skills/wechat-article/scripts/wechat_article.py '<URL>'` | 本地提取 |
| 3️⃣ | **web_fetch** | `web_fetch "<URL>"` | 直接抓取，可能被拦截 |
| 4️⃣ | **浏览器** | 用 browser/playwright 打开页面提取 | 最后手段 |

**失败处理**：
- 方式 1 失败 → 自动尝试方式 2
- 所有方式失败 → 告知用户"该文章有反爬保护，建议手动复制内容"

### Step 3: 格式化输出

```markdown
# 文章标题

**发布时间**: YYYY-MM-DD
**公众号**: 公众号名称
**原文链接**: URL

---

文章正文内容（Markdown 格式）...
```

### Step 4: 保存（可选）

如果用户要求保存到 Obsidian：
1. 使用 AI 采集模板注入 YAML Frontmatter
2. 保存到 `obsidian-vault/01-灵感库/` 或 `Clippings/`
3. ⚠️ 使用 `obsidian-cli create`，不使用系统命令

## 命令行使用

```bash
# 基本使用
python3 skills/wechat-article/scripts/wechat_article.py "https://mp.weixin.qq.com/s/xxx"

# 输出到文件
python3 skills/wechat-article/scripts/wechat_article.py "https://mp.weixin.qq.com/s/xxx" > article.md
```

## 注意事项

- 微信公众号有反爬虫机制，部分文章可能无法获取
- 需要验证码的文章无法自动处理
- r.jina.ai 是第三方服务，敏感内容建议用本地方式
- 提取的内容可能丢失图片（微信图片有防盗链）

## 限制

- 不支持需要登录才能查看的文章
- 不支持已删除/被屏蔽的文章
- 图片提取不稳定（微信防盗链）
- 排版复杂的文章可能格式丢失
