---
name: mcporter
description: Step-by-step workflow to audit, migrate, and validate MCP servers from OpenClaw Gateway to MC Porter daemon
---

# MC Porter 技能

> "The engine might act upon other things besides number." — Ada Lovelace

MC Porter 是一个独立的 MCP 服务器运行时守护进程，可以管理所有 MCP 服务的生命周期，实现从 OpenClaw Gateway 的进程分散管理模式到统一守护进程的转变。

---

## 最终架构 (2026-06-02 确认)

### 当前架构

```
OpenClaw Gateway (openclaw.json → mcp.servers = 空)
└── 无 MCP 进程 ✅ (Gateway 零开销)

MC Porter Daemon (独立管理)
├── PID: 64545
├── socket: ~/.mcporter/daemon/daemon-9abb92a283a6.sock
├── 配置: ~/.openclaw/workspace/config/mcporter.json
└── 13 个 keep-alive 服务器 (stdio 模式)
    ├── amap: connected
    ├── playwright: connected
    ├── chrome-devtools: connected
    ├── exa-search: connected
    ├── github: connected
    └── ... 全部 13 healthy
```

### 决策记录 (2026-06-02)

**选择**: 保持 MC Porter daemon 独立运行架构，通过 CLI 工具调用

**原因**: 
- MC Porter serve bridge 需要 OpenClaw MCP 支持外部 SSE/HTTP MCP 端点
- OpenClaw 当前 MCP 传输层不支持连接外部 MCP bridge
- MC Porter CLI (`mcporter call`) 已能正常工作

### 调用方式

```bash
# 列出所有服务器
mcporter list

# 调用工具 (格式: server.tool)
mcporter call amap.maps_geo location:"114.264569,30.593354"
mcporter call github.search_repositories query:"openclaw" per_page:3

# 查看服务器 schema
mcporter list amap --schema

# Daemon 管理
mcporter daemon start|status|stop
```

---

## 配置说明

### MC Porter 配置文件

**路径**: `~/.openclaw/workspace/config/mcporter.json`

**关键字段**:
```json
{
  "mcpServers": {
    "amap": {
      "description": "高德地图 MCP",
      "command": "npx",
      "args": ["-y", "@amap/amap-maps-mcp-server"],
      "env": {
        "AMAP_MAPS_API_KEY": "***"
      },
      "lifecycle": "keep-alive"
    }
  }
}
```

### 关键发现：lifecycle 字段

**不是 `keepAlive`**，而是 `lifecycle: "keep-alive"`

```json
{
  "lifecycle": "keep-alive"   // ✅ 正确
}
```

**keep-alive 判断优先级** (按优先级):
1. `MCPORTER_KEEPALIVE=*` 环境变量 → 全部 keep-alive
2. `MCPORTER_DISABLE_KEEPALIVE=server` → 禁用
3. `lifecycle: "keep-alive"` → 显式启用
4. 命令名匹配 `chrome-devtools`, `@playwright/mcp`, `mobile-mcp` → 自动启用

**默认 keep-alive 服务器** (无 lifecycle 字段时):
- `chrome-devtools`
- `playwright`
- `mobile-mcp`

---

## 版本信息

**MC Porter 版本**: 0.11.3 (当前最新)
**安装方式**: npm global (`npm install -g mcporter@latest`)

### 版本历史 (关键版本)

| 版本 | 日期 | 关键更新 |
|------|------|----------|
| **v0.11.3** | 2026-05-21 | 修复空 mcporter config 的 fallback |
| **v0.11.2** | 2026-05-21 | `list --status/--exit-code/--quiet` 健康检查 |
| **v0.11.1** | 2026-05-14 | ES Module bundle 修复 |
| **v0.11.0** | 2026-05-14 | **`mcporter serve`** bridge 功能引入 |
| **v0.10.0** | 2026-05-04 | `mcporter resource` MCP 资源读取 |

### mcporter serve bridge

`mcporter serve` 是 v0.11.0 引入的功能，可以将 daemon 管理的 keep-alive 服务器作为统一 MCP 端点暴露：

```bash
mcporter serve --http 3099     # HTTP 端点
mcporter serve --stdio          # Stdio 端点
mcporter serve --servers a,b,c # 只暴露指定服务器
```

**测试结果**:
- HTTP bridge 协议握手成功 ✅
- 工具列表返回正常 (158+ tools) ✅
- OpenClaw 集成需要 MCP 传输层支持 SSE/HTTP

---

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| `Daemon started for 2 server(s)` | 服务器缺少 `lifecycle: "keep-alive"` 或命名未匹配默认列表 |
| 所有服务器 offline | 检查 npx 命令是否可执行，确保网络可达 |
| `lifecycle: "keep-alive"` 不生效 | 字段名是 `lifecycle` 不是 `keepAlive` |
| 进程数过多 | MC Porter daemon 会启动 MCP 服务器进程，这是正常行为 |
| amap maps_geo 返回错误地址 | 这是因为 API 返回的是坐标最近匹配的地址，不是武汉，需要用正确的坐标 |

---

## 参考资料

- [MC Porter GitHub](https://github.com/openclaw/mcporter)
- [ClawHub 技能页](https://clawhub.ai/steipete/mcporter)
- [MC Porter 版本历史](https://github.com/openclaw/mcporter/releases)

---

**版本**: 1.1.0
**更新**: 2026-06-02
**状态**: 最终架构确认，MC Porter daemon 独立运行