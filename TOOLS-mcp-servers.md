# TOOLS-mcp-servers.md — mcporter 13 个 MCP 服务器总览（E 方案深度版）

> mcporter（**v0.13.13**）管理的 13 个 Model Context Protocol 服务器总览索引。
> **本文件是索引**，每个服务器的深度内容见对应子文件 `TOOLS-mcp-<name>.md`。
> 主索引见 → `TOOLS.md`。
>
> **加载规则**：`TOOLS-*.md` 不自动注入，按需 `read` 加载（OpenClaw bootstrap 只匹配精确 basename）。
>
> **创建日期**：2026-09-17（方案 E：总览 + 13 个深度子文件）
> **数据快照**：`2026-09-20T13:42:00+08:00`（北京时间 2026-09-20 21:42，mcporter v0.13.13 + v0.13.11→v0.13.13 升级后实测）
> **上一快照**：`2026-09-16T23:21:49.122Z`（v0.13.11，已过期）

---

## ⚠️ 关键事实（先读）

0. **mcporter CLI 不在 OpenClaw 默认 PATH** — 使用前需 `export PATH="$HOME/.nvm/versions/node/v24.21.0/bin:$PATH"`（与 lark-cli 同款踩坑）。
1. **守护进程 PID 26353 运行稳定** — daemon socket `/home/wszmd520520/.mcporter/daemon/user.sock`，2 个客户端 connected（webchat + OpenClaw 自动恢复）。
2. **13 个服务器全部 stdio 传输** — 全部通过 `npx -y <package>@latest` 或本地 binary 启动，无 HTTP/SSE 传输。
3. **健康检查模式（v0.13.13）** — `mcporter list` 默认 per-server timeout 30s，**并发启动所有服务器报告 readiness**（v0.13.11 有 false negative bug：list 显示 6 个 offline 但实际 13 个全可用；v0.13.13 修复，13/13 healthy）。
4. **配置真实源**：`config/mcporter.json`（3.7KB）就是 13 服务器定义源；本目录（TOOLS-mcp-*.md）是人类可读深度文档，**不替代真实配置**。
5. **本目录结构**：1 个总览（本文件）+ 13 个深度子文件，每个子文件含 schema/调用示例/能力边界/问题排查。
6. **daemon 卡死修复（2026-09-20）** — `mcporter v0.13.11 daemon` 异常死亡后留下 `~/.mcporter/daemon/user.json`（单用户 daemon metadata），下次启动时 `daemon_unresponsive` 拒绝。`migrate --stop-legacy` **不处理 user.json**（只管 `daemon-[a-f0-9]+\.json` legacy per-config）。**唯一正路**：`rm user.json + user.sock` 后 `daemon start`（官方文档 `mcporter.sh/daemon.html` 明文背书："Resolve unverified ownership manually"）。详见 `.learnings/ERRORS.md` ERR-20260920-001。

---

## 13 个 MCP 服务器清单 + 深度子文件指针（按工具数降序）

| # | 服务器名 | 工具数 | 启动 | 类别 | 深度子文件 |
|---|---------|--------|------|------|-----------|
| 1 | **github** | 45 | 1.0s | 代码协作 | → `TOOLS-mcp-github.md` |
| 2 | **chrome-devtools** | 29 | 5.5s | 浏览器自动化 | → `TOOLS-mcp-chrome-devtools.md` |
| 3 | **mcp-server-chart** | 27 | 4.8s | 图表生成 | → `TOOLS-mcp-mcp-server-chart.md` |
| 4 | **playwright** | 26 | 4.8s | 浏览器自动化 | → `TOOLS-mcp-playwright.md` |
| 5 | **thinking-models** | 19 | 4.7s | 思维模型 | → `TOOLS-mcp-thinking-models.md` |
| 6 | **amap** | 12 | 3.8s | 地图服务 | → `TOOLS-mcp-amap.md` |
| 7 | **Memory** | 9 | 4.5s | 知识图谱 | → `TOOLS-mcp-memory.md` |
| 8 | **markmap** | 4 | 7.0s | 思维导图 | → `TOOLS-mcp-markmap.md` |
| 9 | **think-tool** | 4 | 4.4s | 思考工具 | → `TOOLS-mcp-think-tool.md` |
| 10 | **sequential-thinking** | 1 | 4.4s | 顺序推理 | → `TOOLS-mcp-sequential-thinking.md` |
| 11 | **exa-search** | 2 | 4.5s | Web 搜索 | → `TOOLS-mcp-exa-search.md` |
| 12 | **context7** | 2 | 5.0s | 库文档 | → `TOOLS-mcp-context7.md` |
| 13 | **mcp-deepwiki** | 1 | 10.0s | 维基百科 | → `TOOLS-mcp-mcp-deepwiki.md` |

**总览**：13 服务器 / **183 个工具** / 全部 healthy / 全部 stdio。

---

## 类别分布

- **代码与 GitHub**（1）：github → `TOOLS-mcp-github.md`
- **浏览器自动化**（2）：chrome-devtools、playwright
- **图表与可视化**（2）：mcp-server-chart、markmap
- **思考与推理**（3）：thinking-models、think-tool、sequential-thinking
- **知识与搜索**（4）：Memory、exa-search、context7、mcp-deepwiki
- **地图服务**（1）：amap

---

## mcporter CLI 命令速查

```bash
# 列所有服务器（per-server 30s timeout，可能 4-10s 完成）
mcporter list

# 看某服务器的工具 schema
mcporter list <server> --schema

# 调用工具（三种语法）
mcporter call <server.tool> key=value
mcporter call "linear.create_issue(title: \"Bug\")"
mcporter call <server.tool> --args '{"limit":5}'

# 守护进程
mcporter daemon start|status|stop|restart

# 配置管理
mcporter config list|get|add|remove|import|login|logout

# 认证（OAuth）
mcporter auth <server|url> [--reset]

# 代码生成
mcporter generate-cli --server <name>
mcporter emit-ts <server> --mode client|types
mcporter inspect-cli <path> [--json]
```

**常用 flags**：
| flag | 用途 |
|------|------|
| `--output json` | 机器可读输出 |
| `--config <path>` | 覆盖默认 `./config/mcporter.json` |
| `--stdio "..."` | 临时 stdio 调用（不走 daemon） |

---

## 何时使用哪个服务器（决策表）

| 任务 | 推荐服务器 | 深度子文件 |
|------|-----------|-----------|
| 查 React/Vue/Next.js 等库的用法 | **context7** | → `TOOLS-mcp-context7.md` |
| 查通用概念/历史 | **mcp-deepwiki** | → `TOOLS-mcp-mcp-deepwiki.md` |
| 查最新公告/博客/新闻 | **exa-search** | → `TOOLS-mcp-exa-search.md` |
| GitHub 仓库/Issue/PR 操作 | **github** | → `TOOLS-mcp-github.md` |
| 浏览器自动化/截图/填表 | **playwright** 或 **chrome-devtools** | → 对应子文件 |
| 生成图表（柱状/折线/漏斗等 27 种） | **mcp-server-chart** | → `TOOLS-mcp-mcp-server-chart.md` |
| 生成思维导图/大纲 | **markmap** | → `TOOLS-mcp-markmap.md` |
| POI 搜索/路径规划/天气 | **amap** | → `TOOLS-mcp-amap.md` |
| 复杂多步推理 | **sequential-thinking** | → `TOOLS-mcp-sequential-thinking.md` |
| 思维模型库推荐 | **thinking-models** | → `TOOLS-mcp-thinking-models.md` |
| 知识图谱（实体/关系/查询） | **Memory** | → `TOOLS-mcp-memory.md` |
| 思考过程记录 | **think-tool** | → `TOOLS-mcp-think-tool.md` |

---

## 常见问题排查

| 现象 | 原因 | 解决 |
|------|------|------|
| `mcporter: command not found` | PATH 未导出 | `export PATH="$HOME/.nvm/versions/node/v24.21.0/bin:$PATH"` |
| `mcporter list` 卡 30s+ | 某 server 启动失败 | 加 `timeout 30` 包裹；或 `mcporter daemon restart` |
| 守护进程未运行 | daemon 被 kill | `mcporter daemon start` |
| 某 server 报 `failed to start` | npx 下载失败 / 网络问题 | `mcporter list <server> --schema` 单独调试 |
| 工具调用 401/403 | 需 OAuth 认证 | `mcporter auth <server>` |
| 想了解某 server 全部工具 | 需要看 schema | `mcporter list <server> --schema` 然后查对应 `TOOLS-mcp-<name>.md` |

---

## 历史变更

- **2026-09-17 13:28**：E 方案落地（总览 + 13 个深度子文件，共 14 个文件）
- 数据快照：`2026-09-16T23:21:49.122Z`（北京时间 2026-09-17 07:21，mcporter list 实测）