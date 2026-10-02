# TOOLS-mcp-amap.md — 高德地图 MCP（12 工具）

> 高德地图 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx -y @amap/amap-maps-mcp-server`
- **包来源**：高德地图官方 MCP
- **工具数**：12
- **启动延迟**：3.8s（最快之一）
- **传输**：stdio
- **API key**：高德开放平台

---

## 12 个工具

| 工具 | 用途 |
|------|------|
| `maps_geo` | 地址 → 坐标 |
| `maps_regeocode` | 坐标 → 地址 |
| `maps_ip_location` | IP → 位置 |
| `maps_text_search` | 关键词搜索 POI |
| `maps_around_search` | 周边搜索 |
| `maps_search_detail` | POI ID 详情 |
| `maps_direction_walking` | 步行路径 |
| `maps_direction_driving` | 驾车路径 |
| `maps_direction_transit_integrated` | 公交（含火车/地铁）|
| `maps_bicycling` | 骑行路径 |
| `maps_distance` | 距离测量（直线/驾车/步行）|
| `maps_weather` | 城市天气 |

---

## 常用调用示例

```bash
# 地址 → 坐标
mcporter call amap.maps_geo address="武汉黄陂区盘龙城" city="武汉"

# 周边搜索（盘龙城 3km 内餐饮）
mcporter call amap.maps_around_search \
  keywords="餐厅" \
  location="114.2649,30.6877" \
  radius=3000

# 关键词搜索
mcporter call amap.maps_text_search \
  city="武汉" \
  keywords="盘龙城地铁站"

# 驾车路径
mcporter call amap.maps_direction_driving \
  origin="114.2649,30.6877" \
  destination="114.3055,30.5928"

# 公交通勤（跨城必传 cityd）
mcporter call amap.maps_direction_transit_integrated \
  city="武汉" cityd="黄石" \
  origin="..." destination="..."

# 距离测量
mcporter call amap.maps_distance \
  origins="114.2649,30.6877" \
  destination="114.2858,30.7089" \
  type=1

# 天气
mcporter call amap.maps_weather city="武汉"

# POI 详情
mcporter call amap.maps_search_detail id="B023B0ABCDEF"
```

---

## 坐标格式

所有坐标传 `经度,纬度`（注意顺序）：
- 盘龙城：`114.2649,30.6877`
- 汉口北：`114.2858,30.7089`

---

## 何时使用 vs web_fetch + wttr.in

✅ **amap 适合**：
- POI 搜索 / 路径规划 / 距离测量
- IP 定位
- 实时天气（API 准）

❌ **web_fetch + wttr.in 更适合**：
- 7 天天气预测（amap 无历史/预报接口）
- 任意城市快速查询（无需高德 key）

---

## 已知限制

- 需要高德 API key（需在配置中提供）
- 公交通勤 `cityd` 跨城必传
- `maps_weather` 仅支持城市名/adcode，不支持坐标

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建