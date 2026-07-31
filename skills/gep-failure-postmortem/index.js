#!/usr/bin/env node
/**
 * gep-failure-postmortem (v0.1.0)
 *
 * Pure, dependency-free, read-only postmortem analyzer for failed
 * Genome Evolution Protocol (GEP) cycles.
 *
 * Inputs:
 *   --file <path>     Read a GEP cycle record (JSON or raw text) from file
 *   --stdin           Read GEP cycle record from stdin
 *   --demo            Run with built-in synthetic failure samples
 *
 * Output: JSON to stdout with fields:
 *   summary, failure_mode, confidence, signals_correlated, gene_used,
 *   loop_detected, recommendation { action, next_gene_hint,
 *   next_intent_hint, rationale }
 *
 * No side effects. No network. No env mutations.
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ---------- Failure mode taxonomy ----------
const FAILURE_MODES = {
  VALIDATION_BLOCKED: 'validation_blocked',
  REPEATED_GENE: 'repeated_gene',
  BLAST_RADIUS_EXCEEDED: 'blast_radius_exceeded',
  JSON_SCHEMA_INVALID: 'json_schema_invalid',
  MISSING_KNOWLEDGE: 'missing_knowledge',
  STAGNATION: 'stagnation',
  UNKNOWN: 'unknown'
};

const SIGNAL_TO_INTENT_HINT = {
  'stable_success_plateau': 'innovate',
  'recurring_error': 'repair',
  'tool_bypass': 'optimize',
  'hub_search_miss_with_problem': 'innovate',
  'repeated_tool_usage:exec': 'optimize',
  'user_feature_request': 'innovate',
  'capability_gap': 'innovate'
};

// ---------- Pattern matchers ----------
function detectFailureMode(record) {
  const haystack = JSON.stringify(record || {}).toLowerCase();
  const text = (record && (record.raw_text || record.narrative || record.summary) || '').toLowerCase();

  // JSON schema failure
  if (/missing\s+\"?type\"?/i.test(text) ||
      /protocol\s+failure/i.test(text) ||
      /json_schema/i.test(haystack) ||
      /markdown code block/i.test(text)) {
    return { mode: FAILURE_MODES.JSON_SCHEMA_INVALID, confidence: 0.9 };
  }

  // Validation blocked
  if (/(validation|validate).*(fail|block|reject)/i.test(text) ||
      /rollback/i.test(text) ||
      /block:\s*\"?validate/i.test(text) ||
      (record && record.validation_exit && record.validation_exit !== 0)) {
    return { mode: FAILURE_MODES.VALIDATION_BLOCKED, confidence: 0.85 };
  }

  // Blast radius exceeded
  if (/blast\s*radius/i.test(text) && /exceed|over|limit/i.test(text)) {
    return { mode: FAILURE_MODES.BLAST_RADIUS_EXCEEDED, confidence: 0.9 };
  }

  // Repeated gene (loop)
  if (/failure_loop_detected|consecutive_failure_streak|ban_gene|same gene/i.test(text) ||
      (record && Array.isArray(record.recent_genes) && record.recent_genes.length >= 3)) {
    return { mode: FAILURE_MODES.REPEATED_GENE, confidence: 0.85 };
  }

  // Stagnation (check before hub-miss because stagnation often co-occurs with hub misses)
  if (/stable_success_plateau|stagnation/i.test(text) ||
      (record && Array.isArray(record.signals) &&
       record.signals.includes('stable_success_plateau'))) {
    return { mode: FAILURE_MODES.STAGNATION, confidence: 0.75 };
  }

  // Hub miss
  if (/hub_search_miss|no hub match|hub returned nothing/i.test(text) ||
      (record && record.hub_matched === false)) {
    return { mode: FAILURE_MODES.MISSING_KNOWLEDGE, confidence: 0.8 };
  }

  return { mode: FAILURE_MODES.UNKNOWN, confidence: 0.3 };
}

function detectLoop(record) {
  if (!record || !Array.isArray(record.recent_genes)) return false;
  if (record.recent_genes.length < 3) return false;
  const tail = record.recent_genes.slice(-3);
  return tail[0] === tail[1] && tail[1] === tail[2];
}

function extractSignals(record) {
  if (!record) return [];
  if (Array.isArray(record.signals)) return record.signals;
  if (Array.isArray(record.trigger_signals)) return record.trigger_signals;
  // Try to mine signals from raw text
  const text = record.raw_text || record.narrative || JSON.stringify(record);
  const matches = text.match(/[a-z_]+:(?:[a-z_]+|\|)/gi) || [];
  return [...new Set(matches.map(s => s.split(':')[0]))];
}

function extractGene(record) {
  if (!record) return null;
  if (record.gene_used) return record.gene_used;
  if (record.gene) return record.gene;
  if (record.last_run_gene) return record.last_run_gene;
  // Try to find gene_xxx in raw text
  const text = record.raw_text || record.narrative || JSON.stringify(record);
  const m = text.match(/gene_[a-z0-9_]+/);
  return m ? m[0] : null;
}

function pickRecommendation(mode, record) {
  const signals = extractSignals(record);
  const intentHint = signals
    .map(s => SIGNAL_TO_INTENT_HINT[s])
    .filter(Boolean)[0] || null;

  switch (mode) {
    case FAILURE_MODES.VALIDATION_BLOCKED:
      return {
        action: 'retry_safe',
        next_gene_hint: record && record.gene_used ? record.gene_used : null,
        next_intent_hint: record && record.intent ? record.intent : 'repair',
        rationale: 'Fix the specific validation error before retrying with the same gene.'
      };
    case FAILURE_MODES.REPEATED_GENE:
      return {
        action: 'switch_gene',
        next_gene_hint: null,
        next_intent_hint: 'innovate',
        rationale: 'Same gene has failed repeatedly; switch to a gene from a different category.'
      };
    case FAILURE_MODES.BLAST_RADIUS_EXCEEDED:
      return {
        action: 'narrow_scope',
        next_gene_hint: record && record.gene_used ? record.gene_used : null,
        next_intent_hint: record && record.intent ? record.intent : 'optimize',
        rationale: 'Reduce files modified per cycle; prefer smallest viable change.'
      };
    case FAILURE_MODES.JSON_SCHEMA_INVALID:
      return {
        action: 'retry_safe',
        next_gene_hint: record && record.gene_used ? record.gene_used : null,
        next_intent_hint: record && record.intent ? record.intent : 'repair',
        rationale: 'Output rejected for missing required JSON objects; regenerate with strict schema.'
      };
    case FAILURE_MODES.MISSING_KNOWLEDGE:
      return {
        action: 'fetch_hub',
        next_gene_hint: null,
        next_intent_hint: intentHint || 'innovate',
        rationale: 'Hub returned no match; query hub with refined signals or search local memory graph.'
      };
    case FAILURE_MODES.STAGNATION:
      return {
        action: 'switch_intent',
        next_gene_hint: null,
        next_intent_hint: intentHint || 'innovate',
        rationale: 'Stagnation plateau detected; switch to innovate to break out of repetitive cycles.'
      };
    default:
      return {
        action: 'switch_gene',
        next_gene_hint: null,
        next_intent_hint: intentHint || 'innovate',
        rationale: 'Could not classify failure; switch gene to a different category as a safe default.'
      };
  }
}

function buildSummary(record, mode, gene) {
  const sigs = extractSignals(record).slice(0, 3).join(', ') || 'no-signals';
  const geneStr = gene || 'unknown-gene';
  return `failure_mode=${mode} gene=${geneStr} signals=[${sigs}]`;
}

function analyze(record) {
  const det = detectFailureMode(record);
  const loop = detectLoop(record);
  const signals = extractSignals(record);
  const gene = extractGene(record);
  const rec = pickRecommendation(det.mode, record);

  return {
    summary: buildSummary(record, det.mode, gene),
    failure_mode: det.mode,
    confidence: det.confidence,
    signals_correlated: signals,
    gene_used: gene,
    loop_detected: loop,
    recommendation: rec
  };
}

// ---------- Input loading ----------
function loadFromStdin() {
  return new Promise((resolve, reject) => {
    let buf = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', c => { buf += c; });
    process.stdin.on('end', () => {
      try {
        resolve(JSON.parse(buf));
      } catch (_) {
        resolve({ raw_text: buf });
      }
    });
    process.stdin.on('error', reject);
  });
}

function loadFromFile(p) {
  const text = fs.readFileSync(p, 'utf8');
  try {
    return JSON.parse(text);
  } catch (_) {
    return { raw_text: text };
  }
}

function buildDemoSamples() {
  return [
    {
      label: 'validation_blocked',
      record: {
        signals: ['recurring_error', 'stable_success_plateau'],
        gene_used: 'gene_gep_repair_from_errors',
        intent: 'repair',
        narrative: 'validate-suite.js exited with code 1: FAIL: 3 test(s) failed. ROLLBACK triggered.'
      }
    },
    {
      label: 'repeated_gene',
      record: {
        signals: ['tool_bypass', 'repeated_tool_usage:exec'],
        gene_used: 'gene_gep_optimize_tool_usage',
        intent: 'optimize',
        recent_genes: ['gene_gep_optimize_tool_usage', 'gene_gep_optimize_tool_usage', 'gene_gep_optimize_tool_usage'],
        narrative: 'failure_loop_detected on gene_gep_optimize_tool_usage'
      }
    },
    {
      label: 'json_schema_invalid',
      record: {
        signals: ['protocol'],
        gene_used: 'gene_gep_innovate_from_opportunity',
        intent: 'innovate',
        narrative: 'PROTOCOL FAILURE: Missing Mutation object. Output must be RAW JSON.'
      }
    },
    {
      label: 'stagnation',
      record: {
        signals: ['stable_success_plateau', 'hub_search_miss_with_problem'],
        gene_used: 'gene_gep_innovate_from_opportunity',
        intent: 'innovate',
        hub_matched: false,
        narrative: 'Stagnation directive triggered: prefer INNOVATE.'
      }
    }
  ];
}

// ---------- CLI ----------
async function main() {
  const args = process.argv.slice(2);
  let record = null;

  if (args.includes('--stdin')) {
    record = await loadFromStdin();
  } else if (args.includes('--demo')) {
    const samples = buildDemoSamples();
    const out = samples.map(s => ({
      label: s.label,
      postmortem: analyze(s.record)
    }));
    process.stdout.write(JSON.stringify({ postmortems: out }, null, 2) + '\n');
    return;
  } else {
    const fileIdx = args.indexOf('--file');
    if (fileIdx === -1 || fileIdx === args.length - 1) {
      process.stderr.write('usage: gep-failure-postmortem [--stdin | --file <path> | --demo]\n');
      process.exit(2);
    }
    record = loadFromFile(path.resolve(args[fileIdx + 1]));
  }

  const result = analyze(record);
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
}

// Export API for tests / programmatic use
module.exports = {
  analyze,
  detectFailureMode,
  detectLoop,
  extractSignals,
  extractGene,
  pickRecommendation,
  FAILURE_MODES,
  buildDemoSamples
};

if (require.main === module) {
  main().catch(err => {
    process.stderr.write('error: ' + (err && err.message ? err.message : String(err)) + '\n');
    process.exit(1);
  });
}
