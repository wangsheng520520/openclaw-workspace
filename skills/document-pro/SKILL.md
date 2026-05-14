---
name: document-pro
version: 1.1.0
description: |
  文档处理技能：读取、解析、提取 PDF/DOCX/PPT/Excel 的关键信息。
  当用户发送文档并要求"分析"、"总结"、"提取内容"、"转换格式"时触发。
  触发词：分析文档、提取内容、总结报告、读取PDF、解析Word、提取表格。
---

# Document Pro — 文档处理技能 📄

## 触发条件

- 用户发送文档文件（PDF/DOCX/PPTX/XLSX）
- 用户说"分析这个文档"、"总结这份报告"、"提取表格"
- 用户要求"把 XX 转成 Markdown"

## 工作流

### Step 1: 识别文档类型

```
收到文档 →
├── .pdf  → PDF 处理流程
├── .docx → Word 处理流程
├── .pptx → PowerPoint 处理流程
├── .xlsx → Excel 处理流程
├── .txt/.md → 直接读取
└── 其他  → 提示"暂不支持该格式"
```

### Step 2: 提取内容

| 格式 | 工具 | 命令 |
|------|------|------|
| **PDF** | `pdf` 工具（内置） | `pdf pdf="文件路径" prompt="提取全部内容"` |
| **PDF**（备选） | pdfplumber | `python3 -c "import pdfplumber; ..."` |
| **DOCX** | python-docx | `python3 -c "from docx import Document; ..."` |
| **PPTX** | python-pptx | `python3 -c "from pptx import Presentation; ..."` |
| **XLSX** | openpyxl | `python3 -c "from openpyxl import load_workbook; ..."` |

**失败处理**：
- 工具未安装 → `pip install pdfplumber python-docx python-pptx openpyxl`
- 文件损坏 → 提示用户检查文件完整性
- 扫描版 PDF → 提示"需要 OCR，建议用在线工具转换后再处理"

### Step 3: 分析与总结

```
提取的原始内容 →
├── 文档类型和页数/幻灯片数/工作表数
├── 主要内容摘要（200字以内）
├── 关键要点（3-5条）
├── 表格数据（如有，转为 Markdown 表格）
└── 建议的后续操作
```

### Step 4: 输出格式

```markdown
## 📄 文档分析报告

| 项目 | 值 |
|------|-----|
| 文件名 | xxx.pdf |
| 类型 | PDF |
| 页数 | 12 |

### 摘要
（200字概括）

### 关键要点
1. ...
2. ...
3. ...

### 表格数据（如有）
| 列1 | 列2 | 列3 |
|------|------|------|
| ... | ... | ... |

### 建议后续操作
- [ ] ...
```

### Step 5: 保存（可选）

如果用户要求保存到 Obsidian：
- 使用 AI 采集模板
- 保存到 `obsidian-vault/Clippings/` 或指定目录
- ⚠️ 使用 `obsidian-cli create`

## 支持的格式

| 格式 | 读取 | 写入 | 依赖 |
|------|------|------|------|
| PDF | ✅ | — | 内置 pdf 工具 / pdfplumber |
| DOCX | ✅ | ✅ | python-docx |
| PPTX | ✅ | — | python-pptx |
| XLSX | ✅ | ✅ | openpyxl |
| TXT/MD | ✅ | ✅ | 内置 |

## 限制

- 扫描版 PDF 需要 OCR（本技能不含 OCR）
- 复杂排版（多栏、嵌套表格）可能丢失格式
- 图片/图表无法提取内容（只能识别存在）
- 加密/受保护的文档无法处理
- 超大文件（>50MB）可能处理缓慢
