#!/bin/bash
# Evolver 看门狗启动脚本
# 仅检查 Evolver 进程是否运行 (简单任务，使用免费模型)
# Evolver 实际扫描工作使用 minimax/MiniMax-M2.7

set -e

cd ~/.openclaw/workspace

# 加载环境变量
export $(grep -v '^#' ~/.openclaw/.env | xargs)

# Evolver 配置
# 注意：看门狗仅检查进程状态，使用免费模型
# 实际 Evolver 扫描使用主模型 (由 .env 中的 EVOLVE_MODEL 控制，默认不设置即使用主模型)
export EVOLVE_STRATEGY=balanced

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 启动 Evolver 看门狗..."
echo "  - 看门狗模型：siliconflow/Qwen/Qwen3-8B (仅检查进程状态)"
echo "  - Evolver 扫描模型：minimax/MiniMax-M2.7"
echo "  - 策略：$EVOLVE_STRATEGY"

# 启动看门狗模式
npx evolver run --watchdog
