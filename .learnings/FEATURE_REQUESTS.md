# Feature Requests

Capabilities requested by the user.

---

## [FEAT-20260414-001] obsidian_semantic_search

**Logged**: 2026-04-14T07:05:00Z
**Priority**: medium
**Status**: resolved
**Area**: config

### Requested Capability
用户希望 OpenClaw 的语义搜索能够搜索到 Obsidian 知识库中的内容

### User Context
Obsidian 知识库有 408 篇笔记，包含易经、灵感、选题等丰富内容。
用户需要通过自然语言搜索快速定位知识库中的相关笔记。

### Complexity Estimate
simple

### Suggested Implementation
通过 memorySearch.extraPaths 配置将 obsidian-vault 加入索引

### Resolution
- **Resolved**: 2026-04-14T07:05:00Z
- **Notes**: 配置 extraPaths: ["obsidian-vault"]，重启后生效

### Metadata
- Frequency: first_time
- Related Features: memory-search, obsidian

---

## [FEAT-20260414-002] image_recognition_webchat

**Logged**: 2026-04-14T05:26:00Z
**Priority**: high
**Status**: pending
**Area**: infra

### Requested Capability
用户希望通过 Control UI / WebChat 直接发送图片并获得 AI 分析

### User Context
当前内置 qwen provider 硬编码不支持图片，所有图片附件被 Gateway 丢弃。
用户需要频繁发送截图进行问题分析和讨论。

### Complexity Estimate
medium

### Suggested Implementation
- 等待 OpenClaw 新版本支持自定义 provider 的 input 字段覆盖
- 或切换到原生支持图片的 provider（如 OpenAI、Anthropic）
- 临时方案：复制图片到 workspace，用 read 工具分析

### Metadata
- Frequency: recurring
- Related Features: image-tool, gateway, provider

---
