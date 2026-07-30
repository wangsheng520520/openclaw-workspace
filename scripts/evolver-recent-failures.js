#!/usr/bin/env node
// evolver-recent-failures.js — diagnostic helper for evolver cycles.
//
// Summarizes recent EvolutionEvents from .evolver/gep/events.jsonl so the
// next agent (and the GEP selector) can pick a Gene that avoids repeating
// the same failure mode. This addresses the recurring signal:
// `high_failure_ratio` + `force_innovation_after_repair_loop`.
//
// Output: JSON to stdout. Exit 0 on success, 1 on internal error.
//
// Usage:
//   node scripts/evolver-recent-failures.js            # last 5 of each
//   node scripts/evolver-recent-failures.js --limit=10 # custom limit
//
// Read-only. Touches no files outside the evolver GEP store. Safe to run
// at any time during a cycle.

'use strict';

const fs = require('fs');
const path = require('path');

const EVENTS_PATH = path.join(
  process.env.WORKSPACE_ROOT || process.cwd(),
  '.evolver', 'gep', 'events.jsonl'
);

function parseLimit() {
  const arg = process.argv.find(function (a) { return a.startsWith('--limit='); });
  if (!arg) return 5;
  const n = parseInt(arg.slice('--limit='.length), 10);
  return Number.isFinite(n) && n > 0 ? n : 5;
}

function readEvents() {
  if (!fs.existsSync(EVENTS_PATH)) {
    return null;
  }
  const raw = fs.readFileSync(EVENTS_PATH, 'utf8');
  const lines = raw.split('\n').filter(function (l) { return l.trim(); });
  const out = [];
  for (const line of lines) {
    try {
      out.push(JSON.parse(line));
    } catch (e) {
      // Skip malformed lines; do not throw
    }
  }
  return out;
}

function summarizeFailure(ev) {
  const meta = ev.meta || {};
  const selector = meta.selector || {};
  const softFailure = meta.soft_failure || {};
  return {
    id: ev.id,
    intent: ev.intent,
    genes_used: ev.genes_used || [],
    constraint_violations: meta.constraint_violations || [],
    soft_failure_class: softFailure.class || '',
    soft_failure_reason: softFailure.reason || '',
    selection_reason: selector.reason || [],
    score: ev.outcome && typeof ev.outcome.score === 'number' ? ev.outcome.score : null,
    created_at: ev.created_at || meta.at || null,
  };
}

function main() {
  const limit = parseLimit();
  const events = readEvents();
  if (events === null) {
    console.error(JSON.stringify({
      ok: false,
      error: 'events_file_missing',
      path: EVENTS_PATH,
      hint: 'Run evolver at least once to create events.jsonl',
    }));
    process.exit(1);
  }

  const sorted = events.slice().sort(function (a, b) {
    const aId = parseInt(String(a.id || '').replace(/[^0-9]/g, ''), 10) || 0;
    const bId = parseInt(String(b.id || '').replace(/[^0-9]/g, ''), 10) || 0;
    return bId - aId;
  });

  const failed = sorted.filter(function (e) {
    return e.outcome && e.outcome.status === 'failed';
  });
  const succeeded = sorted.filter(function (e) {
    return e.outcome && e.outcome.status === 'success';
  });

  const summary = {
    ok: true,
    events_file: EVENTS_PATH,
    total_events: events.length,
    total_failed: failed.length,
    total_succeeded: succeeded.length,
    last_n_failed: failed.slice(0, limit).map(summarizeFailure),
    last_n_succeeded: succeeded.slice(0, limit).map(function (ev) {
      return {
        id: ev.id,
        intent: ev.intent,
        genes_used: ev.genes_used || [],
        score: ev.outcome && typeof ev.outcome.score === 'number' ? ev.outcome.score : null,
        created_at: ev.created_at || (ev.meta && ev.meta.at) || null,
      };
    }),
    failure_class_distribution: failed.reduce(function (acc, ev) {
      const k = (ev.meta && ev.meta.soft_failure && ev.meta.soft_failure.class) || 'unknown';
      acc[k] = (acc[k] || 0) + 1;
      return acc;
    }, {}),
  };

  process.stdout.write(JSON.stringify(summary, null, 2) + '\n');
  process.exit(0);
}

main();
