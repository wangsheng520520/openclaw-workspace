# MEMORY-obsidian.md — Obsidian 知识库集成档案

> 从 `MEMORY.md` 拆分出的 "Obsidian 知识库集成" 子域 (2026-08-06)。
> 主索引见 → `MEMORY.md`。
>
> **加载规则**：`MEMORY-*.md` 不自动注入，按需 `read` 加载。

---

## Obsidian 知识库集成 (2026-04-14)

**配置完成**:
- ✅ 软链接创建: `workspace/obsidian-vault` → `D:\Obsidian知识库文件`
- ✅ SOUL.md 添加 Obsidian 安全规则(禁止 mv/rm,强制 obsidian-cli)
- ✅ 创建笔记模板: `00-模板/笔记模板.md` + `AI采集模板.md`
- ✅ 创建 SOP 工作流: `SOP_CONTENT.md`(收集→整理→创作→发布)
- ✅ 强制 YAML Frontmatter 元数据管理
- ✅ Vault: 408 篇笔记,7 个主目录

**安全红线**:
- 禁止 mv/rm/cp 操作 Vault 文件
- 必须使用 obsidian-cli move/create
- 创建笔记必须注入 Frontmatter

---

## 用户行为与双链习惯

- 飞书发公众号链接 → 自动导入 Obsidian 建双链 (注意: 04-20 因延迟同链接发 3 次)
- 用户兴趣: 公交行业/公交司机 (Obsidian Vault 大量主题笔记)
