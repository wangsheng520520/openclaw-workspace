'use strict';

// Self-test for low-end-device-optimizer. Exits non-zero on failure.
const assert = require('assert');
const opt = require('./index.js');

// export surface
const keys = Object.keys(opt);
['profileHost', 'recommendQuant', 'recommendHeartbeatSeconds', 'recommendContextTokens', 'buildPlan', 'main'].forEach((k) => {
  assert.ok(keys.includes(k), 'missing export: ' + k);
});

// quant tiers scale with RAM
assert.strictEqual(opt.recommendQuant(0.5).tier, 'Q2_K');
assert.strictEqual(opt.recommendQuant(1.5).tier, 'Q4_K_M');
assert.strictEqual(opt.recommendQuant(16).tier, 'Q6_K');

// heartbeat widens on weak hosts
const weak = { totalMemGiB: 1, cpuCount: 1, memPressure: 0.5 };
const strong = { totalMemGiB: 16, cpuCount: 8, memPressure: 0.2 };
assert.ok(opt.recommendHeartbeatSeconds(weak) > opt.recommendHeartbeatSeconds(strong));

// context halves under pressure
const pressured = { totalMemGiB: 8, cpuCount: 4, memPressure: 0.9 };
const calm = { totalMemGiB: 8, cpuCount: 4, memPressure: 0.2 };
assert.ok(opt.recommendContextTokens(pressured) < opt.recommendContextTokens(calm));

// buildPlan shape
const plan = opt.buildPlan({ platform: 'linux', arch: 'x64', cpuCount: 1, cpuModel: 'x', totalMemGiB: 0.8, freeMemGiB: 0.1, memPressure: 0.9, load1: 1 });
assert.strictEqual(plan.lowEndDetected, true);
assert.ok(Array.isArray(plan.recommendations) && plan.recommendations.length >= 4);
assert.ok(plan.recommendations.some((r) => /swap|zram/i.test(r)), 'expected swap/zram advice under 1GB');

console.log('low-end-device-optimizer: all self-tests passed (' + plan.recommendations.length + ' recs)');
