# TOOLS-mcp-markmap.md — Markmap MCP（4 工具）

> Markmap 思维导图 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @jinzcdev/markmap-mcp-server`
- **包来源**：jinzcdev 维护的 Markmap MCP
- **工具数**：4
- **启动延迟**：7.0s（较慢，需下载 Chromium 检查）
- **传输**：stdio
- **输出**：HTML（始终） + 可选 PNG/JPG/SVG（Playwright 渲染）

---

## 4 个工具

| 工具 | 用途 |
|------|------|
| `markdown_to_mindmap` | Markdown 结构 → 思维导图 |
| `list_mindmaps` | 列出已生成导图 |
| `get_mindmap` | 取导图（按绝对路径）|
| `cleanup_mindmaps` | 删除导图（含 dryRun 预览）|

---

## 常用调用示例

```bash
# Markdown → 思维导图（最常用）
mcporter call markmap.markdown_to_mindmap \
  markdown='# 主主题\n## 子主题 1\n### 子子 A\n### 子子 B\n## 子主题 2' \
  format=html

# 从文件读
mcporter call markmap.markdown_to_mindmap \
  inputPath=/home/user/plan.md \
  format=png

# 自定义文件名
mcporter call markmap.markdown_to_mindmap \
  markdown='...' \
  filename=my-plan \
  format=html

# 列出所有已生成
mcporter call markmap.list_mindmaps limit=20

# 取一张（按 filePath）
mcporter call markmap.get_mindmap filePath=/home/.../markmap-2026.html

# 清理（先 dryRun 预览）
mcporter call markmap.cleanup_mindmaps maxAgeDays=7 dryRun=true
mcporter call markmap.cleanup_mindmaps maxAgeDays=7 dryRun=false

# 全部删除（慎用）
mcporter call markmap.cleanup_mindmaps all=true dryRun=false
```

---

## Markdown 结构约定

ATX headings（`#` `##` `###`）+ 嵌套列表（`-`）效果最好：

```markdown
# 项目计划
## 第一阶段
### 任务 1
- 步骤 a
- 步骤 b
### 任务 2
## 第二阶段
```

**最大深度**：默认无限（实际浏览器性能限制 ~6 层）

---

## 输出格式

| format | 速度 | 依赖 |
|--------|------|------|
| `html` | < 1s | 无 |
| `png` | 5-15s | Playwright + Chromium |
| `jpg` | 5-15s | Playwright + Chromium |
| `svg` | 5-15s | Playwright + Chromium |

⚠️ PNG/JPG/SVG 需先 `npm install playwright && npx playwright install chromium`。

---

## 何时使用

✅ **适合**：
- 文档大纲可视化
- 项目计划架构图
- 学习笔记结构化
- 头脑风暴后的"地图化"

❌ **不适合**：
- 流程图（用 mcp-server-chart `flow_diagram`）
- 组织架构图（用 `organization_chart`）
- 时间线（用 SVG 自绘）

---

## 已知限制

- 大文件（>1MB）转 PNG 慢
- 自定义样式有限（颜色受主题限制）
- `cleanup_mindmaps dryRun=false` **不可逆**，默认 maxAgeDays=7

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建