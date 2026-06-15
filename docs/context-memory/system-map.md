# OpenClaw Context & Memory System Map

> Generated from local OpenClaw official docs and runtime audit. Keep this file as a human-readable map; do not treat it as a replacement for `openclaw status`, `openclaw memory status`, or official docs.

## Official layers

1. **Workspace bootstrap context**
   - Source: `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, optional `MEMORY.md`.
   - Controlled by `agents.defaults.contextInjection`, `bootstrapMaxChars`, `bootstrapTotalMaxChars`, and truncation warnings.

2. **Daily and curated memory files**
   - `MEMORY.md`: compact durable facts/preferences/decisions.
   - `memory/YYYY-MM-DD.md`: detailed daily notes, indexed for recall but not normally injected every turn.

3. **Semantic memory search**
   - Config: `agents.defaults.memorySearch`.
   - Current target provider/model: `openai-compatible` + `BAAI/bge-m3` via SiliconFlow.
   - Sources: `memory`; extra paths include `obsidian-vault`.

4. **Active memory**
   - Bundled `active-memory` plugin, version inherited from OpenClaw.
   - Runs a bounded blocking memory sub-agent for eligible direct sessions.
   - With `plugins.slots.memory = memory-lancedb`, it should use LanceDB recall (`memory_recall`) by default.

5. **LanceDB memory backend**
   - Plugin: `memory-lancedb`.
   - Owns active memory slot via `plugins.slots.memory = "memory-lancedb"`.
   - Stores vector memory under `~/.openclaw/memory/lancedb` unless overridden.

6. **Memory wiki**
   - Plugin: `memory-wiki`.
   - Compiled wiki/claims/provenance layer; does not replace the active memory plugin.
   - Current mode should be verified with `openclaw wiki status` / `wiki_status`.

7. **Obsidian vault integration**
   - Workspace symlink: `obsidian-vault -> /mnt/d/Obsidian知识库文件`.
   - Do not move/delete/rename vault markdown with shell commands; use `obsidian-cli` for moves/renames.

## Operational checks

- `openclaw status`
- `openclaw plugins list`
- `openclaw memory status --index --agent main`
- `openclaw memory search "test query"`
- `openclaw wiki status`
- `wiki_lint` after meaningful wiki mutations

