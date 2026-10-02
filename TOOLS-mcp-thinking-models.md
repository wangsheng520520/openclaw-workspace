# TOOLS-mcp-thinking-models.md — Thinking Models MCP（19 工具）

> 思维模型库 MCP 服务器深度文档。
> 索引见 → `TOOLS-mcp-servers.md`。

---

## 元数据

- **启动命令**：`npx --no-cache @thinking-models/mcp-server`
- **包来源**：思维模型 MCP（团队）
- **工具数**：19
- **启动延迟**：4.7s
- **传输**：stdio
- **特殊**：`--no-cache` 强制每次拉最新版本

---

## 19 个工具

- `analyze-learning-system` — 分析系统学习状况
- `count-models` — 统计模型总数
- `create-thinking-model` — 创建新模型
- `detect-knowledge-gap` — 检测知识缺口
- `emergent-model-design` — 组合源模型 → 新模型
- `explain-reasoning-process` — 解释推理过程
- `generate-validate-hypotheses` — 假设生成 + 验证
- `get-categories` — 取模型分类
- `get-model-info` — 取模型详情
- `get-model-usage-stats` — 模型使用统计
- `get-related-models` — 相关模型推荐
- `get-server-version` — 服务器版本
- `get-started-guide` — 新手指南
- `interactive-reasoning` — 交互式推理
- `list-models` — 列出模型
- `recommend-models-for-problem` — 基于问题推荐模型
- `record-user-feedback` — 记录用户反馈
- `search-models` — 关键词搜索模型
- `update-thinking-model` — 更新模型内容

---

## 常用调用示例

```bash
# 推荐适合问题的模型
mcporter call thinking-models.recommend-models-for-problem \
  problem_keywords='["决策","风险评估"]' \
  problem_context="新产品上市的市场风险" \
  limit=5

# 列出所有"系统思考"类模型
mcporter call thinking-models.list-models category="系统思考"

# 取某个模型详情
mcporter call thinking-models.get-model-info model_id=digital_marketing_funnel fields="all"

# 创建新模型（缺口填补）
mcporter call thinking-models.create-thinking-model \
  id="my_new_model" \
  name="我的新模型" \
  definition="..." \
  purpose="..." \
  category="决策制定"

# 解释推理过程
mcporter call thinking-models.explain-reasoning-process \
  problemDescription="判断新业务方向" \
  reasoningSteps='[{"description":"分析市场","modelIds":["market_analysis"]}]' \
  conclusion="..."

# 搜索模型
mcporter call thinking-models.search-models query="AARRR漏斗" limit=3
```

---

## 何时使用

✅ **适合**：
- 解决结构化问题前选模型
- 学习新的思维框架
- 系统化整理"已知不知道"型知识

❌ **不适合**：
- 创造性写作（用 brainstorming 技能）
- Bug 调试（用 systematic-debugging 技能）
- 一次性查询（直接知识库够用）

---

## 已知限制

- 模型质量依赖于源库覆盖范围
- 创建/更新模型需明确 `category` 和 `definition`
- 反馈系统会记录用户评价，用于改进推荐

---

## 历史变更

- 2026-09-17 13:28：E 方案深度文档创建