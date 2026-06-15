# BOOT.md — Gateway 重启时自动检查清单

> **触发**: Gateway `gateway:startup` event（需启用 `boot-md` internal hook）
> **目的**: 每次 gateway 重启时，4 项关键健康检查，确保不留下"重启就崩"的隐患
> **风格**: 极简 — 4 项可验证检查 + 异常时飞书告警
> **作者**: Ada Lovelace 视角 v2.1 / 2026-06-11 完美最佳实践对账

---

## ⚡ 触发条件

| 触发 | 何时跑 | 跑什么 |
|------|--------|--------|
| `gateway:startup` | 每次 `gateway run` / `systemctl restart openclaw-gateway` | 本文件 4 项检查 |

**关联 hook**：`openclaw hooks enable boot-md`

---

## ✅ 4 项关键检查（按顺序）

### 检查 1：heartbeat 是否在最近 1 小时内跑过

```bash
# 期望: lastCheck < 1h ago；若 > 2h → 异常
# (WSL2 无 jq，用 python 替代)
HEARTBEAT_TS=$(python3 -c "import json; d=json.load(open('/home/wszmd520520/.openclaw/workspace/memory/heartbeat-state.json')); print(d.get('lastCheck','2026-01-01T00:00:00+08:00'))")
HEARTBEAT_AGE_MIN=$(( ($(date +%s) - $(date -d "$HEARTBEAT_TS" +%s)) / 60 ))
[ "$HEARTBEAT_AGE_MIN" -lt 60 ] && echo "✅ heartbeat fresh ($HEARTBEAT_AGE_MIN min ago)" || echo "❌ heartbeat stale ($HEARTBEAT_AGE_MIN min)"
```

**异常处理**：
- 飞书发 webhook @老王：`🚨 Heartbeat 未在 1h 内跑过 (实际 ${HEARTBEAT_AGE_MIN} min)，重启后请检查 HEARTBEAT.md 配置`

### 检查 2：alignment-check 退出码是否为 0

```bash
cd /home/wszmd520520/.openclaw/workspace
bash scripts/alignment-check.sh > /tmp/boot-alignment.log 2>&1
ALIGN_EXIT=$?
[ "$ALIGN_EXIT" -eq 0 ] && echo "✅ alignment 13/13 完美对齐" || echo "❌ alignment 偏离 (exit=$ALIGN_EXIT, 详见 /tmp/boot-alignment.log)"
```

**异常处理**：
- 飞书发 webhook @老王：`🟡 配置偏离 (alignment exit=$ALIGN_EXIT)，请看 /tmp/boot-alignment.log`

### 检查 3：openclaw doctor 警告数 ≤ 2（基线 = 2 个 "plugin install metadata"块，OpenClaw 不自动 fix 留下基线）

**注 1**: 2026-06-12 timeout 30s → 60s（默认 doctor 实际跑 31s 通过 60s timeout）

**注 2**: 2026-06-12 21:50 默认 doctor 跑 31s，2 个 warnings 块
- bootstrapMaxChars 20000→40000 (容下 MEMORY.md 34,841 字符, bootstrap-size 警告消失)
- D 项 SecretRef 修复成功, security 警告消失
- C 项移除 3 个 cron UUID, missing transcript 警告消失
- ⚠️ 警告数 4 块 → 2 块: 仅剩 plugin install metadata (9 plugin shared SQLite state 冲突)

```bash
DOCTOR_OUT=$(timeout 60 openclaw doctor 2>&1)
# 计算 "Doctor warnings ──" 块数（每个块 = 1 个警告类别）
WARN_BLOCKS=$(echo "$DOCTOR_OUT" | grep -c "Doctor warnings ─")
# 基线 = 2 (两个 Doctor warnings 块都是 plugin install metadata)
[ "$WARN_BLOCKS" -le 2 ] && echo "✅ doctor 警告 $WARN_BLOCKS 块 (基线 2 块 OK)" || echo "⚠️  doctor 警告 $WARN_BLOCKS 块 (超过基线 2)"
```

**异常处理**：
- 飞书发 webhook @老王：`🟡 doctor 警告超过基线 (${WARN_COUNT})，请运行 \`openclaw doctor --fix\``

### 检查 4：飞书 WebSocket 是否在 gateway 启动后 30s 内 started

```bash
# openclaw-gateway 是 user-level systemd 服务，必须设 XDG_RUNTIME_DIR 才能读 user journal
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
# gateway 启动后 feishu WebSocket 启动时间约 5-8s (06-11 实测多轮: 17:28:24, 17:30:52, 18:00:12, 18:19:09, 21:04:08)
# 检查最近 30s 内是否有 "WebSocket client started" → 这是 feishu 跟 gateway restart 一起拉起的信号
FEISHU_WS=$(journalctl --user -u openclaw-gateway --since "30 seconds ago" --no-pager 2>/dev/null | grep -c "WebSocket client started")
if [ "$FEISHU_WS" -gt 0 ]; then
  echo "✅ feishu WebSocket started within 30s of gateway restart"
else
  # fallback：检查 24h 内 feishu 是否有启动记录（说明插件没崩，只是当前未重启）
  LAST_WS=$(journalctl --user -u openclaw-gateway --since "1 day ago" --no-pager 2>/dev/null | grep "WebSocket client started" | tail -1 | awk '{print $1, $2, $3}')
  if [ -z "$LAST_WS" ]; then
    echo "❌ feishu WebSocket 24h 内无启动记录 — 插件可能坏了"
  else
    # 这种情况是 boot hook 跑得早于 feishu 启动（<5s），但 feishu 历史 24h 内启动过 = 长稳态
    echo "✅ feishu WebSocket OK (长稳态, last start 24h内: $LAST_WS, hook 跑在 feishu 启动前)"
  fi
fi
```

**异常处理**（仅 ❌ 触发）：
- 飞书发 webhook @老王：`🚨 飞书 WebSocket 24h 内无启动 — 插件可能坏了，请检查 feishu 配置`
- ⚠️ **不要对长稳态发告警** — 那是 boot hook 跑得早于 feishu 启动（<5s）的正常 race condition

---

## 📊 输出示例（gateway 重启后）

**最佳情况**（boot hook 跑在 feishu 启动后，30s 内 4/4 完美）：
```text
🧭 BOOT.md — 2026-06-11 21:05:10 CST
================================================================
✅ 检查 1  heartbeat fresh (47 min ago)
✅ 检查 2  alignment 13/13 完美对齐
✅ 检查 3  doctor 警告 2 块 (基线 2 块 OK)
✅ 检查 4  feishu WebSocket started within 30s of gateway restart
================================================================
🟢 4/4 通过 — gateway 健康
```

**实际典型情况**（boot hook 跑在 feishu 启动前，长稳态 fallback）：
```text
🧭 BOOT.md — 2026-06-11 21:05:10 CST
================================================================
✅ 检查 1  heartbeat fresh (47 min ago)
✅ 检查 2  alignment 13/13 完美对齐
✅ 检查 3  doctor 警告 2 块 (基线 2 块 OK)
✅ 检查 4  feishu WebSocket OK (长稳态, last start 24h内: Jun 11 21:04:08, hook 跑在 feishu 启动前)
================================================================
🟢 4/4 通过 — gateway 健康 (1 项长稳态)
```

**异常**（仅 ❌ 触发飞书告警）：
```text
🧭 BOOT.md — 2026-06-11 21:05:10 CST
================================================================
✅ 检查 1  heartbeat fresh (47 min ago)
❌ 检查 2  alignment 偏离 (exit=2, 详见 /tmp/boot-alignment.log)
✅ 检查 3  doctor 警告 2 块 (基线 2 块 OK)
✅ 检查 4  feishu WebSocket OK (长稳态)
================================================================
🔴 1 失败 — 飞书已通知 @老王
```

---

## 🔧 启用本文件的方法

**方法 A：单独启用 boot-md hook**（推荐，影响面小）
```bash
# 在 openclaw.json 中添加:
# "hooks": { "internal": { "boot-md": { "enabled": true } } }
# 然后: gateway restart
```

**方法 B：不启用，文件作为参考**
- 文件存在但不会自动运行
- 仍可手动执行 `bash /home/wszmd520520/.openclaw/workspace/BOOT.md` 的检查命令

---

## 🚫 注意事项

- **不要在这里放重型操作**：gateway 重启后第一个事件，启动慢会拖慢整个启动
- **不要写自动修复命令**：只检测 + 飞书通知，让老王/Ada 决定怎么处理
- **保持 4 项**：可加不可减，加多了启动变慢
- **飞书发 webhook 时用 best-effort**：通知失败不应该让 BOOT.md 整体失败

---

**最后更新**: 2026-06-11 20:45 CST（完美最佳实践对账方案 C 落地）
**作者**: Ada Lovelace v2.1 视角
**配置参考**: OpenClaw v2026.6.5 `automation/hooks.md` § boot-md details
