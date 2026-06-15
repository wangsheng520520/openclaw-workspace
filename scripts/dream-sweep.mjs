// dream-sweep.mjs — direct call into the v6.5 dreaming dist modules so the
// light/rem/deep artifacts (memory/dreaming/{light,rem,deep}/<date>.md) are
// produced even though the gateway-side before_agent_reply hook is broken.
//
// This bypasses the missing registerShortTermPromotionDreaming path by
// importing the same dist modules the hook would call. It also runs the
// applyShortTermPromotions step that the CLI "memory promote --apply" runs
// but writes a deep-dreaming report alongside it (which the CLI does not).
import { createRequire } from "node:module";
import path from "node:path";
import process from "node:process";

const require = createRequire(import.meta.url);
const DIST = "/home/wszmd520520/.nvm/versions/node/v24.14.0/lib/node_modules/openclaw/dist";
const distRequire = createRequire(`${DIST}/index.js`);

const WS = process.env.OPENCLAW_WORKSPACE || "/home/wszmd520520/.openclaw/workspace";

const cfg = require("/home/wszmd520520/.openclaw/openclaw.json");
const subsystemLogger = distRequire(`${DIST}/subsystem-CLsYac3M.js`);
const logger = subsystemLogger.createSubsystemLogger
  ? subsystemLogger.createSubsystemLogger({ name: "memory-core" })
  : { info: console.log, warn: console.warn, error: console.error, debug: console.log };

// Resolve the memory-core plugin config the same way runShortTermDreamingPromotionIfTriggered does.
const backend = distRequire(`${DIST}/backend-config-Cwmmfbdu.js`);
const dreamingState = distRequire(`${DIST}/dreaming-state-D7W5VtYL.js`);
const memoryCoreEngine = distRequire(`${DIST}/memory-core-engine-runtime-Dh__cRSt.js`);
const phasesMod = distRequire(`${DIST}/dreaming-phases-BS2qKSWx.js`);
const promotionMod = distRequire(`${DIST}/short-term-promotion-CErYVhvM.js`);
const markdownMod = distRequire(`${DIST}/dreaming-markdown-fK_C_1iP.js`);

const pluginConfig = backend.resolveMemoryBackendConfig ? backend.resolveMemoryBackendConfig({ cfg }) : {};

const sweepNowMs = Date.now();
const workspaces = [WS];

// Step 1: light + REM sweep (writes memory/dreaming/{light,rem}/<date>.md).
await phasesMod.runDreamingSweepPhases({
  workspaceDir: WS,
  pluginConfig,
  cfg,
  logger,
  subagent: undefined,
  detachNarratives: true,
  nowMs: sweepNowMs,
});
console.log("[dream-sweep] light+REM sweep done");

// Step 2: rank + repair + apply + write deep report (mirrors runShortTermDreamingPromotionIfTriggered).
for (const workspaceDir of workspaces) {
  const repair = await promotionMod.repairShortTermPromotionArtifacts({ workspaceDir });
  if (repair.changed) console.log("[dream-sweep] repaired:", repair);

  const candidates = await promotionMod.rankShortTermPromotionCandidates({
    workspaceDir,
    limit: 10,
    minScore: 0.8,
    minRecallCount: 3,
    minUniqueQueries: 3,
    recencyHalfLifeDays: 14,
    maxAgeDays: 30,
    nowMs: sweepNowMs,
  });
  console.log("[dream-sweep] candidates:", candidates.length);

  const applied = await promotionMod.applyShortTermPromotions({
    workspaceDir,
    candidates,
    limit: 10,
    minScore: 0.8,
    minRecallCount: 3,
    minUniqueQueries: 3,
    maxAgeDays: 30,
    maxPromotedSnippetTokens: 4000,
    timezone: "Asia/Shanghai",
    nowMs: sweepNowMs,
  });
  console.log("[dream-sweep] applied:", applied.applied);

  const reportLines = [
    `- Repaired recall artifacts: ${JSON.stringify(repair)}.` ,
    `- Ranked ${candidates.length} candidate(s) for durable promotion.`,
    `- Promoted ${applied.applied} candidate(s) into MEMORY.md.`,
  ];

  await markdownMod.writeDeepDreamingReport({
    workspaceDir,
    bodyLines: reportLines,
    nowMs: sweepNowMs,
    timezone: "Asia/Shanghai",
    storage: { mode: "separate", separateReports: true },
  });
  console.log("[dream-sweep] deep report written");
}

console.log("[dream-sweep] all done");
