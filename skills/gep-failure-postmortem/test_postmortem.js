#!/usr/bin/env node
/**
 * Self-test for gep-failure-postmortem.
 * Runs the analyzer against demo samples and asserts key fields.
 */
'use strict';

const assert = require('assert');
const { analyze, buildDemoSamples, FAILURE_MODES, detectLoop, extractGene, loadFromNarrative } = require('./index.js');

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

  // Test 5: submodule_invisible (new in v0.2.0)
  const sub = analyze(samples[4].record);
  assert.strictEqual(sub.failure_mode, FAILURE_MODES.SUBMODULE_INVISIBLE, 'expected submodule_invisible');
  assert.strictEqual(sub.recommendation.action, 'relocate_or_auditor_patch');
  assert.strictEqual(sub.recommendation.next_intent_hint, 'optimize');
  assert.ok(/submodule/i.test(sub.recommendation.rationale), 'rationale should mention submodule');

  // Test 6: detectLoop with 2-element array (should be false)
  assert.strictEqual(detectLoop({ recent_genes: ['a', 'a'] }), false, 'loop detection requires >= 3 entries');

  // Test 7: detectLoop with all-distinct
  assert.strictEqual(detectLoop({ recent_genes: ['a', 'b', 'c'] }), false, 'loop should not be detected when genes differ');

  // Test 8: extractGene from raw text
  const rawOnly = analyze({ raw_text: 'some text gene_gep_innovate_from_opportunity more text' });
  assert.strictEqual(rawOnly.gene_used, 'gene_gep_innovate_from_opportunity');

  // Test 9: signals_correlated is an array
  assert.ok(Array.isArray(v.signals_correlated), 'signals_correlated must be an array');

  // Test 10: confidence is a number in [0,1]
  assert.ok(typeof v.confidence === 'number' && v.confidence >= 0 && v.confidence <= 1);

  // Test 11: empty / null record returns unknown mode without throwing
  const u = analyze(null);
  assert.strictEqual(u.failure_mode, FAILURE_MODES.UNKNOWN, 'null record should be unknown');

  // Test 12: submodule_invisible is also detected from raw text pattern (not just structured fields)
  const fromText = analyze({ raw_text: 'audit failed: constraint: hollow_commit, the auditor is submodule-blind' });
  assert.strictEqual(fromText.failure_mode, FAILURE_MODES.SUBMODULE_INVISIBLE, 'expected submodule_invisible from text');

  // Test 13: ensure the new mode is exported
  assert.ok(FAILURE_MODES.SUBMODULE_INVISIBLE === 'submodule_invisible', 'SUBMODULE_INVISIBLE must be exported');

  // Test 14: loadFromNarrative parses the most recent "INNOVATE - failed" block
  const tmpDir = require('fs').mkdtempSync('/tmp/gep-pm-');
  const narrativePath = require('path').join(tmpDir, 'evolution_narrative.md');
  require('fs').writeFileSync(narrativePath, [
    '# Evolution Narrative',
    '',
    'A chronological record of evolution decisions and outcomes.',
    '',
    '### [2026-08-05 02:15:44] INNOVATE - failed',
    '- Gene: gene_gep_innovate_from_opportunity | Score: 0.65 | Scope: 6 files, 374 lines',
    '- Signals: [protocol_drift, user_feature_request]',
    '- Strategy:',
    '  1. Extract opportunity signals',
  ].join('\n'));
  const nar = loadFromNarrative(narrativePath);
  assert.strictEqual(nar.found_entry, true, 'should find a failed block');
  assert.strictEqual(nar.intent, 'innovate', 'intent should be parsed lowercase');
  assert.strictEqual(nar.gene_used, 'gene_gep_innovate_from_opportunity', 'gene should be parsed');
  assert.deepStrictEqual(nar.signals, ['protocol_drift', 'user_feature_request'], 'signals should be parsed');
  assert.strictEqual(nar.score, 0.65, 'score should be parsed');
  const narResult = analyze(nar);
  assert.ok(narResult.gene_used === 'gene_gep_innovate_from_opportunity', 'analyzer should accept narrative record');

  // Test 15: loadFromNarrative returns found_entry=false when no candidate paths exist.
  // Use a dedicated tmp dir as cwd so the walk-up search can't discover a real narrative.
  const isolatedCwd = require('fs').mkdtempSync('/tmp/gep-pm-iso-');
  const prevCwd = process.cwd();
  process.chdir(isolatedCwd);
  let empty;
  try {
    empty = loadFromNarrative(null);
  } finally {
    process.chdir(prevCwd);
  }
  assert.strictEqual(empty.found_entry, false, 'missing file -> found_entry=false');

  process.stdout.write('ok: 15 assertions passed\n');
}

try {
  run();
} catch (e) {
  process.stderr.write('FAIL: ' + (e && e.message ? e.message : String(e)) + '\n');
  if (e && e.stack) process.stderr.write(e.stack + '\n');
  process.exit(1);
}
