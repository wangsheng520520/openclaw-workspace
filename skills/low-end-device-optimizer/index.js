'use strict';

/**
 * low-end-device-optimizer
 *
 * Report-only advisor for running an AI agent on constrained hardware
 * (CPU-only, low RAM). It profiles the host and emits actionable
 * recommendations. It NEVER edits config, installs runtimes, or executes
 * untrusted commands -- it only reads OS metrics and returns a plan.
 *
 * Strategy source: gene_low_end_device_evo
 *   1. Prefer a lightweight CPU runtime (llama.cpp / ollama).
 *   2. Pick a small quantized model (Q4_K_M or smaller) to fit RAM.
 *   3. Aggressive heartbeat + disable non-essential features.
 *   4. Use swap/zram under ~1GB RAM to avoid OOM.
 *   5. Shrink context size when memory pressure appears.
 */

const os = require('os');

const GiB = 1024 * 1024 * 1024;

/** Read a normalized snapshot of host resources. */
function profileHost() {
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const cpus = Array.isArray(os.cpus()) ? os.cpus() : [];
  const load = os.loadavg()[0] || 0;
  return {
    platform: os.platform(),
    arch: os.arch(),
    cpuCount: cpus.length,
    cpuModel: cpus[0] ? cpus[0].model.trim() : 'unknown',
    totalMemGiB: Number((totalMem / GiB).toFixed(2)),
    freeMemGiB: Number((freeMem / GiB).toFixed(2)),
    memPressure: totalMem > 0 ? Number((1 - freeMem / totalMem).toFixed(2)) : 0,
    load1: Number(load.toFixed(2)),
  };
}

/**
 * Recommend a quantized model tier based on available RAM.
 * Smaller RAM => smaller quant. Report-only guidance.
 */
function recommendQuant(totalMemGiB) {
  if (totalMemGiB < 1) return { tier: 'Q2_K', maxParamsB: 1, note: 'sub-1GB: use tiny 0.5-1B model, expect slow tokens' };
  if (totalMemGiB < 2) return { tier: 'Q4_K_M', maxParamsB: 1.5, note: '1-2GB: 1-1.5B quantized model' };
  if (totalMemGiB < 4) return { tier: 'Q4_K_M', maxParamsB: 3, note: '2-4GB: up to 3B at Q4_K_M' };
  if (totalMemGiB < 8) return { tier: 'Q5_K_M', maxParamsB: 7, note: '4-8GB: 7B at Q4-Q5' };
  return { tier: 'Q6_K', maxParamsB: 13, note: '8GB+: 7-13B at higher quant' };
}

/** Recommend heartbeat cadence (seconds) -- longer on weaker hosts. */
function recommendHeartbeatSeconds(profile) {
  if (profile.totalMemGiB < 2 || profile.cpuCount <= 2) return 900;
  if (profile.totalMemGiB < 4 || profile.cpuCount <= 4) return 600;
  return 300;
}

/** Recommend a context window ceiling (tokens) given RAM + pressure. */
function recommendContextTokens(profile) {
  let base;
  if (profile.totalMemGiB < 2) base = 2048;
  else if (profile.totalMemGiB < 4) base = 4096;
  else if (profile.totalMemGiB < 8) base = 8192;
  else base = 16384;
  // Halve if the host is already under memory pressure.
  if (profile.memPressure >= 0.85) base = Math.max(1024, Math.floor(base / 2));
  return base;
}

/** Build the full optimization plan. Pure function of the profile. */
function buildPlan(profile) {
  const quant = recommendQuant(profile.totalMemGiB);
  const heartbeatSeconds = recommendHeartbeatSeconds(profile);
  const contextTokens = recommendContextTokens(profile);
  const recommendations = [];

  recommendations.push(
    `Runtime: use a CPU-only lightweight runtime (llama.cpp or ollama) instead of a GPU/server stack.`
  );
  recommendations.push(
    `Model: quantize to ${quant.tier} (<= ~${quant.maxParamsB}B params). ${quant.note}.`
  );
  recommendations.push(
    `Heartbeat: widen cadence to ~${heartbeatSeconds}s and disable non-essential features to cut CPU/network overhead.`
  );
  recommendations.push(
    `Context: cap context window near ${contextTokens} tokens to bound memory use.`
  );

  if (profile.totalMemGiB < 1) {
    recommendations.push(
      `Swap: RAM < 1GB detected -- enable swap or zram (>= 2GB) to prevent OOM during peaks.`
    );
  } else if (profile.memPressure >= 0.85) {
    recommendations.push(
      `Pressure: memory pressure ${Math.round(profile.memPressure * 100)}% -- add swap/zram and monitor with htop/btop.`
    );
  }

  const constrained =
    profile.totalMemGiB < 4 || profile.cpuCount <= 2 || profile.memPressure >= 0.85;

  return {
    profile,
    lowEndDetected: constrained,
    quant,
    heartbeatSeconds,
    contextTokens,
    recommendations,
  };
}

/** Main entry: profile host and print the plan. Report-only. */
function main() {
  const profile = profileHost();
  const plan = buildPlan(profile);
  console.log(JSON.stringify(plan, null, 2));
  return plan;
}

module.exports = {
  profileHost,
  recommendQuant,
  recommendHeartbeatSeconds,
  recommendContextTokens,
  buildPlan,
  main,
};

if (require.main === module) {
  main();
}
