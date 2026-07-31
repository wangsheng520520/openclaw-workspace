#!/usr/bin/env node
/**
 * Self-test for gep-failure-postmortem.
 * Runs the analyzer against demo samples and asserts key fields.
 */
'use strict';

const assert = require('assert');
const { analyze, buildDemoSamples, FAILURE_MODES, detectLoop, extractGene } = require('./index.js');

function run() {
  const samples = buildDemoSamples();
  assert.ok(samples.length >= 4, 'demo samples must cover at least 4 failure modes');

  // Test 1: validation_blocked
  const v = analyze(samples[0].record);
  assert.strictEqual(v.failure_mode, FAILURE_MODES.VALIDATION_BLOCKED, 'expected validation_blocked');
  assert.strictEqual(v.recommendation.action, 'retry_safe');
  assert.strictEqual(v.gene_used, 'gene_gep_repair_from_errors');

  // Test 2: repeated_gene + loop detection
  const r = analyze(samples[1].record);
  assert.strictEqual(r.failure_mode, FAILURE_MODES.REPEATED_GENE, 'expected repeated_gene');
  assert.strictEqual(r.loop_detected, true, 'loop should be detected when last 3 genes match');
  assert.strictEqual(r.recommendation.action, 'switch_gene');
  assert.strictEqual(r.recommendation.next_intent_hint, 'innovate');

  // Test 3: json_schema_invalid
  const j = analyze(samples[2].record);
  assert.strictEqual(j.failure_mode, FAILURE_MODES.JSON_SCHEMA_INVALID, 'expected json_schema_invalid');
  assert.strictEqual(j.recommendation.action, 'retry_safe');

  // Test 4: stagnation
  const s = analyze(samples[3].record);
  assert.strictEqual(s.failure_mode, FAILURE_MODES.STAGNATION, 'expected stagnation');
  assert.strictEqual(s.recommendation.action, 'switch_intent');

  // Test 5: detectLoop with 2-element array (should be false)
  assert.strictEqual(detectLoop({ recent_genes: ['a', 'a'] }), false, 'loop detection requires >= 3 entries');

  // Test 6: detectLoop with all-distinct
  assert.strictEqual(detectLoop({ recent_genes: ['a', 'b', 'c'] }), false, 'loop should not be detected when genes differ');

  // Test 7: extractGene from raw text
  const rawOnly = analyze({ raw_text: 'some text gene_gep_innovate_from_opportunity more text' });
  assert.strictEqual(rawOnly.gene_used, 'gene_gep_innovate_from_opportunity');

  // Test 8: signals_correlated is an array
  assert.ok(Array.isArray(v.signals_correlated), 'signals_correlated must be an array');

  // Test 9: confidence is a number in [0,1]
  assert.ok(typeof v.confidence === 'number' && v.confidence >= 0 && v.confidence <= 1);

  // Test 10: empty / null record returns unknown mode without throwing
  const u = analyze(null);
  assert.strictEqual(u.failure_mode, FAILURE_MODES.UNKNOWN, 'null record should be unknown');

  process.stdout.write('ok: 10 assertions passed\n');
}

try {
  run();
} catch (e) {
  process.stderr.write('FAIL: ' + (e && e.message ? e.message : String(e)) + '\n');
  if (e && e.stack) process.stderr.write(e.stack + '\n');
  process.exit(1);
}
