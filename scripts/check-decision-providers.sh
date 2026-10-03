#!/usr/bin/env bash
# check-decision-providers.sh -- 后期复查：OpenClaw 是否出现了可用的决策模型 provider。
#
# 背景（2026-10-02 查文档后拍板）：
#   decisionModel 不是普通会话模型角色，它只接受「决策 provider 插件」注册的模型
#   （DecisionProviderV1；插件在 openclaw.plugin.json 里用
#    contracts.decisionProviders + decisionModels 声明）。
#   官方文档 concepts/decision-models.md 目前只列 ONNX 与 TypeSafe AI 两家，
#   且两者都还是「未发布候选插件」。ollama 不是决策 provider，
#   所以 agents.entries.main.decisionModel="ollama/tev1:4b" 在 Control UI 的
#   Decision 选择器里只会显示为「已禁用」。该键已于 2026-10-02 删除。
#
# 这个脚本就是「后期再看是否支持 ollama」的入口：升级 OpenClaw 或新装插件后跑一次。
#
# 用法: bash ~/.openclaw/workspace/scripts/check-decision-providers.sh
# 退出码: 0 = 仍无任何决策 provider；10 = 发现有决策 provider（人工复核是否支持 ollama）
set -u

OPENCLAW_ROOT=/home/wszmd520520/.nvm/versions/node/v24.21.0/lib/node_modules/openclaw

mapfile -t ROOTS < <(
  printf '%s\n' \
    "$HOME/.openclaw/plugins/node_modules" \
    "$HOME/.openclaw/npm/node_modules" \
    "$OPENCLAW_ROOT"
)

existing=()
for root in "${ROOTS[@]}"; do
  [ -d "$root" ] && existing+=("$root")
done

echo "== OpenClaw 决策模型 provider 复查 =="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "版本: $(grep -m1 '"version"' "$OPENCLAW_ROOT/package.json" 2>/dev/null | tr -d ' ,"' | cut -d: -f2 || echo unknown)"
echo

manifest_count=$(find "${existing[@]}" -name openclaw.plugin.json 2>/dev/null | wc -l)
echo "扫描插件清单: ${manifest_count} 个 (openclaw.plugin.json)"

hits=$(grep -rl --include=openclaw.plugin.json -e decisionProviders -e decisionModels "${existing[@]}" 2>/dev/null || true)

if [ -z "$hits" ]; then
  echo "结果: 未发现任何决策 provider 插件。"
  echo "      agent 的 decisionModel 角色保持关闭（这是预期状态）。"
  echo
  echo "下次复查时机: openclaw 升级后 / 官方插件市场上架决策 provider 后。"
  echo "官方文档: $OPENCLAW_ROOT/docs/concepts/decision-models.md"
  exit 0
fi

echo "结果: 发现以下插件声明了决策模型能力——"
echo "$hits" | while read -r f; do echo "  - $f"; done
echo

if echo "$hits" | xargs -r grep -il "ollama" | grep -q .; then
  echo ">>> 有插件提到 ollama，重点复核！可能已支持 ollama 决策模型。"
else
  echo ">>> 暂未看到 ollama 相关声明；先确认这些 provider 是否满足需求"
  echo "    （ONNX 只能跑分类器，TypeSafe 需要凭证）。"
fi
echo
echo "确认可用后再写回配置，例如:"
echo "  openclaw config patch --stdin <<'JSON'"
echo "  {\"agents\":{\"entries\":{\"main\":{\"decisionModel\":\"<provider>/<model>\"}}}}"
echo "  JSON"
exit 10
