# TOOLS-mcp-github.md — GitHub MCP（45 工具）

> GitHub 官方 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`/home/wszmd520520/.local/bin/github-mcp-server stdio`
- **包来源**：官方 `github-mcp-server v1.10.1`
- **工具数**：45（最大）
- **启动延迟**：1.0s（最快 — 本地 binary，无 npx 下载）
- **传输**：stdio

---

## 核心能力

GitHub 官方 MCP 提供 GitHub API 全功能访问：

- **仓库操作**：创建/克隆/分叉/搜索/读取文件
- **Issue 管理**：创建/读取/更新/关闭/分配标签
- **PR 操作**：创建/审查/合并/列出/差异
- **分支管理**：创建/列出/同步
- **Workflow/CI**：列出 runs / 触发 / 审查日志
- **Release**：列出 / 读 tag
- **代码搜索**：`search_code` / `search_commits` / `search_issues`
- **团队成员**：`get_team_members` / `get_teams`

---

## 常用调用示例

```bash
# 列某仓库 issues（OPEN 状态）
mcporter call github.list_issues owner=anthropics repo=claude-code state=OPEN perPage=10

# 读文件内容
mcporter call github.get_file_contents owner=vercel repo=next.js path=README.md

# 搜索代码（跨仓库）
mcporter call github.search_code query="useEffect cleanup" language:typescript

# 创建 Issue（带 body + labels）
mcporter call github.issue_write \
  method=create \
  owner=my-org \
  repo=my-repo \
  title="Bug: 登录失败" \
  body="复现步骤：..." \
  labels='["bug","P1"]'

# 读 PR review comments
mcporter call github.pull_request_read method=get_review_comments \
  owner=my-org repo=my-repo pullNumber=42

# 触发 Copilot 审查 PR
mcporter call github.request_copilot_review owner=my-org repo=my-repo pullNumber=42

# 读 Actions workflow run 详情
mcporter call github.get_actions_runs owner=my-org repo=my-repo perPage=20
```

---

## OAuth 认证

GitHub MCP 使用 GitHub OAuth（设备流或 PAT）。如需 OAuth 登录：

```bash
mcporter auth github --reset
```

**推荐**：在 OpenClaw 的 Agent Settings 里连接 GitHub 身份（更稳定），用 `github_identity_status` 检查状态。

---

## 何时使用 vs 不使用

✅ **适合**：
- Issue/PR/Repo 日常管理
- 代码搜索
- CI logs 调查
- Release 管理

❌ **不适合**：
- 一次性 Git 操作（commit/push）— 优先用 GitHub MCP `push_files`/`create_pull_request` 而非本地 git（避开代理问题）
- 巨型 monorepo 全量克隆— 仍是 git clone 更快

---

## 已知限制

- 单 API 调用有 GitHub 限流（5000 req/h 认证，60 req/h 未认证）
- 大型 PR review comments 列表可能分页

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建