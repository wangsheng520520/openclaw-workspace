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
  // Detects a real failure mode observed when a skill lives in a git submodule
  // (e.g. skills/evolver/) and the parent-repo auditor cannot see submodule
  // working-tree changes: the audit gate flags the commit as hollow_commit
  // even though the gene-declared validations passed. Last seen 2026-08-04
  // in cycle #5002.
  SUBMODULE_INVISIBLE: 'submodule_invisible',
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

  // Submodule-blind auditor: a real and recurring pattern when the change
  // lives under skills/evolver/ (a git submodule) but the parent-repo
  // auditor only sees workspace-level bookkeeping churn and reports
  // hollow_commit. Checked FIRST so that, when a record contains BOTH the
  // hollow_commit marker AND generic validation/rollback language, the
  // more specific cause is surfaced. Without this precedence, a record
  // that says "validations passed but the auditor is submodule-blind and
  // flagged hollow_commit" gets mis-classified as validation_blocked and
  // the next cycle retries the same gene against skills/evolver/src/.
  if (/hollow_commit|hollow commit|constraint:\s*hollow/i.test(text) ||
      /submodule.*blind|auditor.*submodule/i.test(text) ||
      (record && record.gene_validation_passed === true &&
       typeof record.audit_outcome === 'string' &&
       /hollow_commit/i.test(record.audit_outcome))) {
    return { mode: FAILURE_MODES.SUBMODULE_INVISIBLE, confidence: 0.92 };
  }

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
    case FAILURE_MODES.SUBMODULE_INVISIBLE:
      return {
        action: 'relocate_or_auditor_patch',
        next_gene_hint: record && record.gene_used ? record.gene_used : null,
        next_intent_hint: 'optimize',
        rationale: 'The audit gate is submodule-blind and the gene-declared validations already pass. Either (a) move the change out of skills/evolver/ to a parent-repo-visible path, (b) commit the change inside the submodule AND update the parent submodule pointer, or (c) request an auditor patch that walks submodules. Do not retry the same gene against skills/evolver/src/ until visibility is restored.'
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

// Parse the recent failed-cycle entry from evolution_narrative.md.
// Looks for the most recent "INNOVATE/REPAIR/OPTIMIZE/EXPLORE - failed" block
// and synthesises a record the analyzer can consume. Falls back to {raw_text}
// if the file is missing or contains no parseable failure entry.
function loadFromNarrative(narrativePath) {
  const CANDIDATES = [];
  if (narrativePath) CANDIDATES.push(narrativePath);
  CANDIDATES.push(
    'memory/evolution/evolution_narrative.md',
    'skills/evolver/memory/evolution/evolution_narrative.md'
  );
  // Walk up from cwd to find the file (handles running from a skills/ subdir).
  let dir = process.cwd();
  for (let i = 0; i < 6; i++) {
    CANDIDATES.push(path.join(dir, 'memory/evolution/evolution_narrative.md'));
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  let text = null;
  let usedPath = null;
  for (const p of CANDIDATES) {
    try {
      if (fs.existsSync(p)) {
        text = fs.readFileSync(p, 'utf8');
        usedPath = p;
        break;
      }
    } catch (_) { /* keep trying */ }
  }
  if (text === null) {
    return { raw_text: '', source: null, found_entry: false };
  }

  // Find the most recent "- failed" block header line, then read its section
  // until the next blank-line-then-header boundary.
  const lines = text.split(/\r?\n/);
  let blockStart = -1;
  for (let i = 0; i < lines.length; i++) {
    if (/ - failed(?:\s|$)/.test(lines[i]) && /###\s*\[/.test(lines[i])) {
      blockStart = i;
    }
  }
  if (blockStart === -1) {
    return { raw_text: text, source: usedPath, found_entry: false };
  }

  // Determine where the block ends (start of next ### header or end of file).
  let blockEnd = lines.length;
  for (let j = blockStart + 1; j < lines.length; j++) {
    if (/^###\s*\[/.test(lines[j])) { blockEnd = j; break; }
  }
  const block = lines.slice(blockStart, blockEnd).join('\n');

  const intentMatch = block.match(/(INNOVATE|REPAIR|OPTIMIZE|EXPLORE)/i);
  const intent = intentMatch ? intentMatch[1].toLowerCase() : null;
  const geneMatch = block.match(/Gene:\s*([a-z0-9_]+)/);
  const gene_used = geneMatch ? geneMatch[1] : null;
  const signalsMatch = block.match(/Signals:\s*\[([^\]]*)\]/);
  const signals = signalsMatch
    ? signalsMatch[1].split(',').map(s => s.trim()).filter(Boolean)
    : [];
  const scoreMatch = block.match(/Score:\s*([\d.]+)/);
  const score = scoreMatch ? parseFloat(scoreMatch[1]) : null;

  return {
    raw_text: block,
    source: usedPath,
    found_entry: true,
    intent,
    gene_used,
    signals,
    score,
    block_header: lines[blockStart].trim()
  };
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
    },
    {
      label: 'submodule_invisible',
      record: {
        signals: ['tool_bypass', 'recurring_error', 'repair_loop_detected'],
        gene_used: 'gene_tool_integrity',
        intent: 'repair',
        gene_validation_passed: true,
        audit_outcome: 'constraint: hollow_commit: 22 file(s) changed but 0 are constraint-counted code',
        narrative: 'Solidify post-gate failed: validation passed, but the auditor is submodule-blind and cannot see skills/evolver/src/ changes from the parent repo.'
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
  } else if (args.includes('--recent')) {
    const fileIdx = args.indexOf('--recent');
    const provided = (fileIdx !== -1 && fileIdx !== args.length - 1) ? args[fileIdx + 1] : null;
    record = loadFromNarrative(provided);
    if (!record.found_entry) {
      process.stderr.write('no recent failed entry found in evolution narrative\n');
      process.exit(3);
    }
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
      process.stderr.write('usage: gep-failure-postmortem [--stdin | --file <path> | --recent [path] | --demo]\n');
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
  loadFromNarrative,
  FAILURE_MODES,
  buildDemoSamples
};

if (require.main === module) {
  main().catch(err => {
    process.stderr.write('error: ' + (err && err.message ? err.message : String(err)) + '\n');
    process.exit(1);
  });
}
