# TOOLS-mcp-mcp-server-chart.md — AntV Chart MCP（27 工具）

> AntV 图表生成 MCP 服务器深度文档（27 种图表类型）。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @antv/mcp-server-chart`
- **包来源**：AntV 官方 mcp-server-chart
- **工具数**：27（按图表类型分）
- **启动延迟**：4.8s
- **传输**：stdio
- **输出**：服务器本地 HTML（路径可通过 `mcporter call` 返回值取得）+ 可选 PNG/JPG/SVG（Playwright 渲染）

---

## 27 个图表工具

### 基础图表（10）
- `generate_area_chart`、`generate_bar_chart`、`generate_column_chart`
- `generate_line_chart`、`generate_pie_chart`、`generate_scatter_chart`
- `generate_histogram_chart`、`generate_boxplot_chart`、`generate_violin_chart`
- `generate_waterfall_chart`

### 多维与对比（5）
- `generate_radar_chart`、`generate_funnel_chart`、`generate_sankey_chart`
- `generate_dual_axes_chart`、`generate_liquid_chart`

### 文本与表格（4）
- `generate_word_cloud_chart`、`generate_spreadsheet`（含 pivot）
- `generate_venn_chart`、`generate_treemap_chart`

### 地图（4）
- `generate_pin_map`、`generate_path_map`、`generate_district_map`

### 流程与结构（5）
- `generate_flow_diagram`、`generate_fishbone_diagram`
- `generate_network_graph`、`generate_organization_chart`、`generate_mind_map`

---

## 常用调用示例

```bash
# 柱状图（最常用）
mcporter call mcp-server-chart.generate_column_chart \
  title="销售对比" \
  data='[{"category":"北京","value":825},{"category":"上海","value":1200},{"category":"深圳","value":1100}]' \
  width=800 height=500

# 折线图（带 group 多系列）
mcporter call mcp-server-chart.generate_line_chart \
  data='[{"time":"2025","value":23,"group":"A"},{"time":"2026","value":32,"group":"A"}]' \
  title="年度趋势"

# 漏斗图（用户旅程）
mcporter call mcp-server-chart.generate_funnel_chart \
  data='[{"category":"访问","value":50000},{"category":"购物车","value":35000},{"category":"订单","value":25000}]'

# 思维导图
mcporter call mcp-server-chart.generate_mind_map \
  data='{"name":"主主题","children":[{"name":"子1"},{"name":"子2"}]}'

# 路径地图（旅游路线）
mcporter call mcp-server-chart.generate_path_map \
  title="西安一日游" \
  data='[{"data":["西安钟楼","大唐不夜城","大雁塔"]}]'

# 双轴图（销售额柱+利润率线）
mcporter call mcp-server-chart.generate_dual_axes_chart \
  categories='["Q1","Q2","Q3","Q4"]' \
  series='[{"type":"column","data":[100,150,200,250],"axisYTitle":"销售额"},{"type":"line","data":[0.1,0.12,0.15,0.18],"axisYTitle":"利润率"}]'

# 雷达图（产品对比）
mcporter call mcp-server-chart.generate_radar_chart \
  data='[{"name":"设计","value":70,"group":"iPhone"},{"name":"性能","value":85,"group":"iPhone"}]'
```

---

## 输出格式

每个图表工具返回 `{htmlFilePath, filePath}`：
- `htmlFilePath`：HTML 源（始终存在）
- `filePath`：主产物（HTML 或 PNG/JPG/SVG，看 `format` 参数）

**PNG/SVG/JPG 渲染**：依赖 Playwright（需 `npm install playwright && npx playwright install chromium`）。

---

## 主题与样式

每个工具接受 `theme` 参数（`default`/`academy`/`dark`）+ `style` 参数（背景色/调色板/纹理）：
- `texture: "rough"` → 手绘风格
- `palette`：自定义颜色数组
- `backgroundColor`：背景色

---

## 何时使用

✅ **适合**：
- 数据可视化报告
- 仪表盘组件
- 文档/演示文稿插图

❌ **不适合**：
- 实时数据流（每次调用渲染一次，不适合秒级刷新）
- 大数据点（>1000 点浏览器渲染会卡）

---

## 已知限制

- 路径地图 / pin_map 仅支持**中国行政区划**（district_map 限于境内）
- 网络图、组织图最大深度为 3
- Sankey 图节点对齐：`left`/`right`/`justify`/`center`

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建