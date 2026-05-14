---
version: "2.1.0"
name: code-generator
description: |
  多语言代码生成器。描述需求，生成可运行的代码。
  支持函数/类/API/CRUD/测试/重构/语言转换/项目骨架。
  触发词：生成代码、写个函数、创建类、API接口、CRUD、写测试、重构、转换成Python/JS/Go。
author: BytesAgain
homepage: https://bytesagain.com
---

# ⚡ Code Generator — 多语言代码生成

> 描述你需要什么，得到可运行的代码。

## 触发条件

- 用户说"生成代码"、"写个函数"、"创建一个类"
- 用户要求"写个 API 接口"、"CRUD 操作"
- 用户要求"写测试"、"重构这段代码"
- 用户要求"把这段 Python 转成 Go"

## 工作流

### Step 1: 需求分析

```
收到代码请求 →
├── 明确了语言 → Step 2
├── 未指定语言 → 询问，或根据上下文推断（Web→JS/TS，数据→Python，系统→Go）
└── 给了现有代码 → 判断是重构/转换/测试
```

### Step 2: 选择生成模式

| 命令 | 功能 | 示例 |
|------|------|------|
| `function` | 生成完整函数 | "写一个排序函数" |
| `class` | OOP 类设计 | "创建一个用户管理类" |
| `api` | RESTful 路由 | "写一个用户注册 API" |
| `crud` | 增删改查 | "MySQL 用户表 CRUD" |
| `test` | 单元测试 | "为这个函数写测试" |
| `refactor` | 重构建议 | "优化这段代码" |
| `convert` | 语言转换 | "Python 转 Go" |
| `boilerplate` | 项目骨架 | "创建 Flask 项目" |

### Step 3: 生成代码

每个输出必须包含：
1. 🏷️ 语言标签和建议文件名
2. 📝 完整可运行的代码
3. 💬 关键行内注释
4. ▶️ 使用示例
5. ⚠️ 依赖说明（如需安装包）

### Step 4: 验证检查

```
生成后自检：
- [ ] 代码语法正确？
- [ ] 有无未导入的依赖？
- [ ] 示例能直接运行？
- [ ] 边界情况处理了？
```

## 支持的语言

Python · JavaScript · TypeScript · Go · Java · Rust · PHP · Ruby · C# · Shell

## 命令行使用

```bash
bash scripts/codegen.sh <command> <description>
```

## 输出格式示例

````markdown
### `user_service.py` (Python)

```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class User:
    """用户模型"""
    id: int
    name: str
    email: str
    
    def validate_email(self) -> bool:
        """验证邮箱格式"""
        return '@' in self.email and '.' in self.email.split('@')[1]
```

**使用**：
```python
user = User(id=1, name="老王", email="wang@example.com")
assert user.validate_email() == True
```

**依赖**：Python 3.7+（标准库）
````

## 限制

- 生成的代码是起点，复杂业务逻辑需要人工审查
- 不保证性能最优，侧重可读性和正确性
- 数据库操作生成的是模板，需要适配实际连接配置

## Requirements
- bash 4+
- python3 (standard library only)
