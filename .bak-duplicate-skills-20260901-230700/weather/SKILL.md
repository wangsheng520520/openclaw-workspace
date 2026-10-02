---
name: weather
description: Get current weather and forecasts (no API key required).
homepage: https://wttr.in/:help
metadata: {"clawdbot":{"emoji":"🌤️","requires":{"bins":["curl"]}}}
---

# Weather Skill

查询全球天气，无需 API key。支持主服务 + 备用服务的自动切换。

## 架构概览

```
用户输入地点
    ↓
[1] wttr.in 主查询
    ↓ 成功 → 输出结果
    ↓ 失败 → [2] Open-Meteo 备用查询
               ↓ 成功 → 输出结果
               ↓ 失败 → 返回错误信息
```

## 工作流程

### Step 1: 解析地点

将用户输入的地名转换为 URL 编码：
- 空格转 `+`：`New York` → `New+York`
- 特殊字符需 URL 编码

**Checkpoint**: 若地点为空或明显无效（如纯数字），在执行前提示用户确认。

### Step 2: 主查询 — wttr.in

```bash
# 快速单行格式（推荐）
curl -s "wttr.in/${地点}?format=3"

# 完整输出（含预报）
curl -s "wttr.in/${地点}?T"

# PNG 图片
curl -s "wttr.in/${地点}.png" -o /tmp/weather.png
```

常用 format 代码：
| 代码 | 含义 |
|------|------|
| `%l` | 地点名 |
| `%c` | 天气状况图标 |
| `%t` | 温度 |
| `%h` | 湿度 |
| `%w` | 风速风向 |
| `%m` | 月相 |

单位参数：`?m` (公制) · `?u` (英制)
范围参数：`?1` (仅今天) · `?0` (仅当前)

### Step 3: 备用查询 — Open-Meteo

**触发条件**：wttr.in 请求失败、超时、或返回无效数据。

1. 先通过地理编码获取坐标：
```bash
curl -s "https://geocoding-api.open-meteo.com/v1/search?name=${地点}&count=1"
```

2. 用坐标查询天气：
```bash
curl -s "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current_weather=true"
```

返回 JSON 格式，包含 `temperature`, `windspeed`, `weathercode`。

## 异常处理

| 异常场景 | 处理方式 |
|----------|----------|
| curl 超时（>10s） | 自动切换到 Open-Meteo |
| 地点无法识别 | 返回 "Location not found"，提示用户检查输入 |
| 网络完全不可达 | 返回友好错误：「无法连接天气服务，请检查网络」 |
| 服务返回乱码/空 | 尝试备用服务，仍失败则返回原始错误 |

## 参数速查

- **地点**：支持城市名、机场代码（LAX、JFK）、地标
- **单位**：默认公制（°C, km/h），加 `?u` 切换英制
- **格式**：默认 text，加 `.png` 获取图片

## 注意事项

- 无需 API key，直接可用
- wttr.in 在部分地区可能响应慢，设置超时避免卡住
- 两个服务的数据可能略有差异，属正常现象
