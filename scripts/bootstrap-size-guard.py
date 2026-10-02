#!/usr/bin/env python3
"""bootstrap-size-guard.py — bootstrap 文件超限截断的自动预警

背景（ERR-20260918-001 同族）:
  gateway 对每个 bootstrap 文件按 `agents.defaults.bootstrapMaxChars`（默认 20000 **字符**）截断。
  超限时**静默截断**——保留头 + 尾，丢弃中段，任何会话都读不到，且不报错。
  2026-09-18 实测 MEMORY.md 25,242 字符被丢中段 5,353 字符，无人发现。

为什么需要本脚本:
  doctor 里确实有 `core/doctor/bootstrap-size` 检查（实测能正确报警），
  但它是 **opt-in 检查**：默认 `openclaw doctor --lint` 跳过它（checksRun=33, skipped=30），
  必须显式 `--only core/doctor/bootstrap-size` 或 `--all` 才会跑。
  且裸 `openclaw doctor`（交互式）在本环境会挂起，无法作为自动预警链路。
  → 本脚本封装那唯一可靠的调用形式，供 cron / 手动定期预警。

用法:
  python3 scripts/bootstrap-size-guard.py            # 检查，有发现则打印并 exit 1
  python3 scripts/bootstrap-size-guard.py --notify   # 额外推送飞书（需 lark-cli）
  python3 scripts/bootstrap-size-guard.py --quiet    # 健康时完全静默（cron 用）

退出码: 0 = 健康（或未超限）; 1 = 存在超限发现; 2 = 检查本身无法执行
"""
import json
import os
import subprocess
import sys

HOME = os.path.expanduser("~")
WORKSPACE = os.path.join(HOME, ".openclaw", "workspace")
CHECK_ID = "core/doctor/bootstrap-size"
FEISHU_CHAT = "oc_e8a582e5e3d7f43455144e0e07e011ad"  # p2p "王胜"
LOG = os.path.join(WORKSPACE, "logs", "bootstrap-size-guard.log")


def log(msg: str) -> None:
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    import datetime
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{ts} {msg}\n")


def resolve_cli() -> str:
    """显式解析 openclaw 路径（cron 的 PATH 被隔离，nvm 不自动加载）。
    见 ERR-20260907-001：cron env.PATH=/usr/bin:/bin 导致 exit 127。"""
    node_bin = os.path.join(HOME, ".nvm", "versions", "node", "v24.21.0", "bin")
    for cand in (
        os.path.join(node_bin, "openclaw"),
        os.path.join(HOME, ".local", "bin", "openclaw"),
    ):
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    return "openclaw"


def run_check(cli: str):
    """调用 doctor 的 bootstrap-size 检查。返回 findings 列表。

    实测兜底链路（2026-09-20）：
    1) doctor --json 偶尔 stdout=0 字节（gateway diagnostic mode 下
       stderr 写 log 但 stdout 不输出 JSON）—— 重试 + 软失败
    2) 重试用 `--lint --all --json`（更多检查器容忍 noise）
    3) 都失败 → 硬算兜底：直接 wc -m 数 MEMORY.md 字符，不依赖 doctor 子进程
    """
    findings, last_err = _run_doctor_with_retry(cli)
    if findings is not None:
        return findings
    log(f"doctor 链路全失败，软 fallback 走硬算: {last_err}")
    return _hard_fallback()


def _find_json_payload(stdout: str):
    """从 doctor 混合 stdout 里挑出 {"ok" 开头的那一行 JSON。
    插件日志会混入 stdout（实测 2026-09-20 看到首行就是 memos-local 的
    "running in diagnostic mode" info 日志）。不假设位置，找最后一行。
    """
    last = None
    for line in stdout.splitlines():
        s = line.strip()
        if s.startswith('{"ok"'):
            last = s
    return last


def _run_doctor_with_retry(cli):
    """尝试两次 doctor 调用（strict + --all 放宽）。返回 (findings, last_err)。
    findings=None 表示两次都失败；调用方应走硬算兜底。
    """
    env = dict(os.environ)
    env["PATH"] = (
        os.path.join(HOME, ".nvm", "versions", "node", "v24.21.0", "bin")
        + ":" + os.path.join(HOME, ".local", "bin")
        + ":" + env.get("PATH", "/usr/bin:/bin")
    )
    last_err = ""
    attempts = (
        [cli, "doctor", "--lint", "--only", CHECK_ID, "--json"],
        [cli, "doctor", "--lint", "--all", "--json"],
    )
    # 2026-09-20：cron 链路实测 doctor 子进程在本环境会卡很久（原 180s 太长），
    # 硬算 fallback 是常态路径，doctor 调用只是"加分项"。
    # 单次 doctor 限 30s，整体最多 70s（两次+Python 启动+fallback）。
    DOCTOR_TIMEOUT_S = 30
    for cmd in attempts:
        try:
            proc = subprocess.run(
                cmd, cwd=WORKSPACE, env=env, capture_output=True, text=True, timeout=DOCTOR_TIMEOUT_S,
            )
        except subprocess.TimeoutExpired:
            last_err = f"doctor 检查超时（{DOCTOR_TIMEOUT_S}s）"
            continue

        if not proc.stdout or proc.stdout.strip() == "":
            last_err = f"doctor stdout 空（exit={proc.returncode}）"
            continue

        payload = _find_json_payload(proc.stdout)
        if payload is None:
            last_err = (
                f"doctor stdout 无 {{ok}} JSON 行（exit={proc.returncode}）"
                f" first={proc.stdout.splitlines()[0][:120]!r}"
            )
            continue

        try:
            return json.loads(payload).get("findings", []), ""
        except json.JSONDecodeError as e:
            last_err = f"doctor JSON parse fail: {e}"
            continue

    return None, last_err


# 硬算兜底（2026-09-20 引入）：不依赖 doctor 子进程
# gateway 截断阈值 = agents.defaults.bootstrapMaxChars (默认 20000 字符)
# 实测路径：直接读 MEMORY.md / SOUL.md / USER.md / AGENTS.md 字符数
BOOTSTRAP_FILES = ("MEMORY.md", "SOUL.md", "USER.md", "AGENTS.md")


def _read_bootstrap_max_chars() -> int:
    """从 openclaw.json 读 agents.defaults.bootstrapMaxChars，默认 20000。"""
    cfg = os.path.join(HOME, ".openclaw", "openclaw.json")
    try:
        with open(cfg, "r", encoding="utf-8") as f:
            d = json.load(f)
        return int(d.get("agents", {}).get("defaults", {}).get("bootstrapMaxChars", 20000))
    except (OSError, KeyError, ValueError):
        return 20000


def _hard_fallback() -> list:
    """直接 wc -m 数 bootstrap 文件字符数，判断是否超 agents.defaults.bootstrapMaxChars=20000。

    返回 findings 列表（结构与 doctor 一致：message / path / fixHint）。
    """
    threshold = _read_bootstrap_max_chars()
    findings = []
    for fname in BOOTSTRAP_FILES:
        path = os.path.join(WORKSPACE, fname)
        if not os.path.isfile(path):
            continue
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            char_count = len(content)
        except OSError as e:
            findings.append({
                "message": f"{fname} 读取失败: {e}",
                "path": path,
                "fixHint": "检查文件权限/磁盘",
            })
            continue

        if char_count > threshold:
            findings.append({
                "message": (
                    f"{fname} 超限：{char_count} 字符 > {threshold} 阈值，"
                    f"将被静默截断丢弃中段"
                ),
                "path": path,
                "fixHint": (
                    "把内容搬去 MEMORY-*.md 子文件（不调阈值），"
                    "参见 MEMORY.md A1 决策"
                ),
            })
    return findings


def notify(text: str) -> bool:
    """推飞书 p2p。失败不抛（预警失败不应掩盖检查结果），只记日志。"""
    env = dict(os.environ)
    env["PATH"] = (
        os.path.join(HOME, ".nvm", "versions", "node", "v24.21.0", "bin")
        + ":" + os.path.join(HOME, ".local", "bin")
        + ":" + env.get("PATH", "/usr/bin:/bin")
    )
    # 实测 lark-cli 在 nvm bin 下（不在 ~/.local/bin），两者都试
    lark = ""
    for cand in (
        os.path.join(HOME, ".nvm", "versions", "node", "v24.21.0", "bin", "lark-cli"),
        os.path.join(HOME, ".local", "bin", "lark-cli"),
    ):
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            lark = cand
            break
    if not lark:
        log("notify SKIP: lark-cli 未找到")
        return False
    try:
        r = subprocess.run(
            [lark, "im", "+messages-send", "--chat-id", FEISHU_CHAT, "--text", text],
            env=env, capture_output=True, text=True, timeout=60,
        )
        ok = r.returncode == 0
        log(f"notify {'ok' if ok else 'FAIL'} rc={r.returncode} {r.stderr[-200:]!r}")
        return ok
    except Exception as e:  # noqa: BLE001 — 预警失败不应中断检查
        log(f"notify EXC {e!r}")
        return False


def main() -> int:
    notify_flag = "--notify" in sys.argv
    quiet = "--quiet" in sys.argv

    cli = resolve_cli()
    try:
        findings = run_check(cli)
    except RuntimeError as e:
        msg = f"🔴 bootstrap-size-guard 无法执行检查: {e}"
        print(msg)
        log(msg)
        return 2

    if not findings:
        if not quiet:
            print("✅ bootstrap 文件均在限内，无截断风险")
        log("ok: no findings")
        return 0

    lines = ["🔴 bootstrap 文件超限预警（将被静默截断）", ""]
    for f in findings:
        lines.append(f"• {f.get('message')}")
        if f.get("path"):
            lines.append(f"  文件: {f['path']}")
        if f.get("fixHint"):
            lines.append(f"  处置: {str(f['fixHint'])[:220]}")
    lines.append("")
    lines.append("背景: 超限文件的「中段」会被丢弃且不报错，任何会话都读不到。")
    lines.append("处置: 把内容搬去 MEMORY-*.md 子文件（不调阈值），参见 MEMORY.md 的 A1 决策。")
    text = "\n".join(lines)

    print(text)
    log(f"WARN findings={len(findings)}")
    if notify_flag:
        notify(text)
    return 1


if __name__ == "__main__":
    sys.exit(main())
