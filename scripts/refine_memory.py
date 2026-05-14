#!/usr/bin/env python3
"""
每日记忆提炼脚本 - 自动分析近期记忆，提炼到 MEMORY.md
不依赖 LLM，直接分析并写入，防止模型幻觉
"""
import json
import os
import re
from datetime import datetime, timedelta

MEMORY_DIR = "/home/wszmd520520/.openclaw/workspace/memory"
HEARTBEAT_FILE = os.path.join(MEMORY_DIR, "heartbeat-state.json")
MEMORY_MD = "/home/wszmd520520/.openclaw/workspace/MEMORY.md"
DAILY_GLOB = os.path.join(MEMORY_DIR, "????-??-??.md")

def read_file(path, limit_chars=5000):
    """安全读取文件前 N 字符"""
    if not os.path.exists(path):
        return ""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return f.read()[:limit_chars]
    except:
        return ""

def extract_key_facts(content):
    """从记忆中提取关键事实（纯规则匹配，无 LLM）"""
    facts = []
    lines = content.split('\n')
    for line in lines:
        stripped = line.strip()
        # 提取带时间戳的事件
        if re.match(r'^\d{4}-\d{2}-\d{2}', stripped):
            facts.append(stripped[:150])
        # 提取 ## 标题段落
        elif stripped.startswith('## '):
            facts.append(stripped[:120])
    return facts[-10:]  # 最多 10 条

def update_heartbeat(now_str):
    """更新心跳状态"""
    if not os.path.exists(HEARTBEAT_FILE):
        print(f"⚠️  文件不存在: {HEARTBEAT_FILE}")
        return False
    try:
        with open(HEARTBEAT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)
        data['lastMemoryRefinement'] = now_str
        if 'systemStatus' not in data:
            data['systemStatus'] = {}
        data['systemStatus']['memoryRefinement'] = f"✅ 正常 ({now_str[:10]} {now_str[11:16]})"
        with open(HEARTBEAT_FILE, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("✅ heartbeat-state.json")
        return True
    except Exception as e:
        print(f"❌ heartbeat 更新失败: {e}")
        return False

def update_memory_md(now_str, summary_lines):
    """更新 MEMORY.md"""
    if not os.path.exists(MEMORY_MD):
        print(f"⚠️  MEMORY.md 不存在: {MEMORY_MD}")
        return

    with open(MEMORY_MD, 'r', encoding='utf-8') as f:
        content = f.read()

    # 更新最后提炼时间
    marker = f"**最后记忆提炼**: {now_str[:10]} {now_str[11:16]}"

    # 在 "## 待办事项" 或 "## 项目与上下文" 之前插入提炼摘要
    section_marker = "## 待办事项"
    if section_marker not in content:
        section_marker = "## 项目与上下文"
    if section_marker not in content:
        section_marker = "## "

    summary_block = f"\n{marker}\n**自动提炼**:\n"
    for line in summary_lines:
        summary_block += f"- {line}\n"

    if section_marker in content:
        idx = content.find(section_marker)
        new_content = content[:idx] + summary_block + "\n" + content[idx:]
    else:
        new_content = content + "\n" + summary_block

    with open(MEMORY_MD, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("✅ MEMORY.md")

def get_recent_daily_memories():
    """获取最近 7 天有变动的 daily memory 文件"""
    today = datetime.now()
    recent = []
    for i in range(1, 8):
        date = today - timedelta(days=i)
        path = os.path.join(MEMORY_DIR, date.strftime("%Y-%m-%d") + ".md")
        if os.path.exists(path):
            recent.append((date.strftime("%m-%d"), path))
    return recent

def main():
    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00")
    print(f"[{now}] 开始记忆提炼...")

    # 1. 更新 heartbeat
    update_heartbeat(now)

    # 2. 读取近期记忆
    recent = get_recent_daily_memories()
    print(f"📁 扫描 {len(recent)} 个近期记忆文件...")

    all_facts = []
    for label, path in recent:
        content = read_file(path)
        facts = extract_key_facts(content)
        for f in facts:
            all_facts.append(f"[{label}] {f}")

    # 去重保留最新
    seen = set()
    unique_facts = []
    for fact in reversed(all_facts):
        key = fact[:80]
        if key not in seen:
            seen.add(key)
            unique_facts.insert(0, fact)

    # 3. 写入 MEMORY.md 摘要（限制条数）
    update_memory_md(now, unique_facts[:8])

    # 4. 检查 MEMORY.md 大小（防止无限膨胀）
    size = os.path.getsize(MEMORY_MD)
    print(f"📊 MEMORY.md: {size/1024:.1f} KB")
    if size > 200 * 1024:  # > 200KB 警告
        print("⚠️  MEMORY.md 过大（>200KB），建议精简")

    print(f"[{datetime.now().strftime('%Y-%m-%dT%H:%M:%S+08:00')}] 完成! 共提炼 {len(unique_facts)} 条事实")

if __name__ == "__main__":
    main()
