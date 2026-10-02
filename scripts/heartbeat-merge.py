#!/usr/bin/env python3
"""
heartbeat-merge.py — 合并本地极简 heartbeat 态与远程完整快照

设计原则：
- 本地 heartbeat-state.json 是 fcb1cd79 cron 每 30min 写入的极简态
- 远程 main 分支的完整快照是 5.6KB / 22 键的 systemStatus 快照
- 本脚本把两者合并：保留远程所有字段，本地白名单字段覆盖远程同名

白名单覆盖字段（本地新写入的高频字段）：
  - lastCheck
  - pushedBy
  - _lastSessionStateFreshnessCheck
  - _pollNote*（本地增量轮询笔记）

远程保留：systemStatus.* / systemVersion / cronJobs* / toolEnvironment /
            notes / last*Check / alerts[] / _deltaNotes / systemStatus 嵌套

不变量：
- alerts[] 按 type 去重；本地有 a=True → 覆盖；远程有本地无 → 保留
- 失败时不动本地 heartbeat-state.json（保留原极简态），写 logs 退出 0
- 写一份 heartbeat-state.full.json（长期归档完整快照）
"""
import json
import os
import sys
import shutil
import logging
from datetime import datetime, timezone, timedelta
from pathlib import Path

# ---- 配置 ----
WORKSPACE = Path("/home/wszmd520520/.openclaw/workspace")
MEMORY_DIR = WORKSPACE / "memory"
LOCAL_STATE = MEMORY_DIR / "heartbeat-state.json"        # 极简态（fcb1cd79 写入）
FULL_STATE = MEMORY_DIR / "heartbeat-state.full.json"    # 完整快照（归档）
SEED_FILE = MEMORY_DIR / "archive" / "heartbeat-state.full-seed.json"
LOG_FILE = WORKSPACE / "logs" / "heartbeat-merge.log"
LOCK_FILE = MEMORY_DIR / ".heartbeat-merge.lock"

# 本地覆盖白名单（其余字段保留远程）
LOCAL_OVERRIDE_KEYS = {"lastCheck", "pushedBy", "_lastSessionStateFreshnessCheck"}

# ---- 日志 ----
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("heartbeat-merge")


def now_iso_cst() -> str:
    """CST 时区 ISO-8601 时间戳"""
    cst = timezone(timedelta(hours=8))
    return datetime.now(cst).strftime("%Y-%m-%dT%H:%M:%S+08:00")


def deep_merge(remote: dict, local: dict, parent_key: str = "") -> dict:
    """
    深 merge：
    - 默认全部保留远程
    - 白名单父键（parent_key in LOCAL_OVERRIDE_KEYS）→ 本地覆盖远程
    - 白名单父键下的所有 _pollNote* → 本地覆盖远程
    - alerts[] → 按 type 去重合并
    - 其余嵌套 dict → 递归（远程为主，本地新增字段追加）
    """
    result = dict(remote)
    # 顶层调用（parent_key=""）时也启用白名单：所有顶层 LOCAL_OVERRIDE_KEYS
    # 的子键都视为"白名单覆盖"。子层递归时同样生效（parent_key 被传入）。
    whitelist = LOCAL_OVERRIDE_KEYS

    for k, v in local.items():
        # _pollNote* 始终本地覆盖（无论父键是否白名单）
        is_poll_note = k.startswith("_pollNote")
        # 顶层 + 父层白名单都允许覆盖
        is_whitelist = k in whitelist

        if k in result and isinstance(result[k], dict) and isinstance(v, dict):
            result[k] = deep_merge(result[k], v, parent_key=k)
        elif k == "alerts" and isinstance(v, list) and isinstance(result.get(k), list):
            result[k] = merge_alerts(result[k], v)
        elif is_whitelist or is_poll_note:
            # 白名单键或 _pollNote* → 本地覆盖远程
            result[k] = v
        elif k in result:
            # 远程已有此键（非白名单非 _pollNote）→ 保留远程，避免误覆盖
            continue
        else:
            # 远程没有，本地新增字段 → 保留
            result[k] = v

    return result


def merge_alerts(remote_alerts: list, local_alerts: list) -> list:
    """
    alerts[] 合并：按 type 去重；本地有 a=True 覆盖；远程有本地无 → 保留
    """
    by_type = {}
    for a in remote_alerts:
        if isinstance(a, dict) and "type" in a:
            by_type[a["type"]] = a

    for a in local_alerts:
        if isinstance(a, dict) and "type" in a:
            if a.get("a") is True or a["type"] not in by_type:
                by_type[a["type"]] = a

    return list(by_type.values())


def acquire_lock() -> bool:
    """简单文件锁，防止并发执行"""
    if LOCK_FILE.exists():
        # 检查锁是否过期（>5min 视为 stale）
        age = time.time() - LOCK_FILE.stat().st_mtime
        if age > 300:
            log.warning(f"stale lock detected (age={age:.0f}s), removing")
            LOCK_FILE.unlink()
        else:
            log.info(f"another merge is running (lock age={age:.0f}s), skip")
            return False
    LOCK_FILE.write_text(str(os.getpid()))
    return True


import time  # noqa: E402  放在 acquire_lock 之后避免循环依赖


def release_lock():
    try:
        LOCK_FILE.unlink()
    except FileNotFoundError:
        pass


def main():
    if not acquire_lock():
        sys.exit(0)

    try:
        # 1. 读本地极简态（必须存在；fcb1cd79 至少每 30min 写一次）
        if not LOCAL_STATE.exists():
            log.warning(f"local state file missing: {LOCAL_STATE}")
            sys.exit(0)

        try:
            local_data = json.loads(LOCAL_STATE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            log.warning(f"local state JSON decode failed: {e.msg}; leaving as-is")
            sys.exit(0)

        # 2. 读种子完整快照（缺失则退化）
        if not SEED_FILE.exists():
            log.warning(f"seed file missing: {SEED_FILE}; falling back to local-only write")
            # 仅把本地状态写一份归档，保留现有极简态不变
            FULL_STATE.write_text(
                json.dumps(local_data, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            sys.exit(0)

        try:
            seed_data = json.loads(SEED_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            log.warning(f"seed JSON decode failed: {e.msg}; falling back to local-only")
            FULL_STATE.write_text(
                json.dumps(local_data, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            sys.exit(0)

        # 3. 深 merge
        merged = deep_merge(seed_data, local_data)

        # 4. 加 merge 元数据
        merged["_merge"] = {
            "mergedAt": now_iso_cst(),
            "localKeys": sorted(local_data.keys()),
            "seedKeys": sorted(seed_data.keys()),
            "alertsCount": len(merged.get("alerts", [])),
        }

        # 5. 写两份文件
        # 5a. 完整快照（含 merge 元数据）
        FULL_STATE.write_text(
            json.dumps(merged, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

        # 5b. 本地 heartbeat-state.json：保持极简态（fcb1cd79 下次会覆盖）
        #     不写以免破坏 cron 写入约定

        log.info(
            f"merge ok: alerts={len(merged.get('alerts', []))} "
            f"local_keys={len(local_data)} seed_keys={len(seed_data)} "
            f"merged_keys={len(merged)} full={FULL_STATE.stat().st_size}B"
        )

    except Exception as e:
        log.exception(f"unexpected error: {e}")
        sys.exit(0)  # 不让 cron 报警
    finally:
        release_lock()


if __name__ == "__main__":
    main()