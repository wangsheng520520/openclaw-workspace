---
name: gep-failure-postmortem
description: Analyzes failed GEP (Genome Evolution Protocol) cycle outputs to produce a structured postmortem with failure mode classification, signal/gene correlation, and next-cycle adjustment suggestions. Use when an Evolver cycle fails or when consecutive failures / failure loops are detected in the evolution narrative so the next cycle can pick a different gene or strategy without repeating the same mistake.
---

# GEP Failure Postmortem

A read-only, dependency-free postmortem tool for the Evolver self-evolution engine. Given a failed GEP cycle record (narrative + signals + gene used + outcome), it produces a structured report that helps the next cycle recover quickly.

## When to Use

- A GEP evolution cycle has `outcome: failed`
- The evolution narrative shows `consecutive_failure_streak` or `failure_loop_detected`
- You see `recurring_error` signals and need to understand the failure pattern
- Before choosing a gene for the next cycle, to avoid repeating the same one

## What It Does

1. **Parses** a GEP failure record (or raw text dump of a failed cycle)
2. **Classifies** the failure mode (validation_blocked, blast_radius_exceeded, json_schema_invalid, repeated_gene, missing_knowledge, etc.)
3. **Correlates** signals → gene → outcome to detect "same gene, same signal, same failure" loops
4. **Recommends** a next-cycle action (switch_gene, switch_intent, narrow_scope, fetch_hub_capsule, etc.)

## Usage

```bash
# Analyze a GEP failure record from stdin (JSON)
cat failed_cycle.json | node skills/gep-failure-postmortem/index.js --stdin

# Analyze a raw GEP prompt dump
node skills/gep-failure-postmortem/index.js --file memory/evolution/gep_prompt_cycle_XXXX.json

# Demo with built-in samples
node skills/gep-failure-postmortem/index.js --demo
```

## Output Format

```json
{
  "summary": "One-line failure summary",
  "failure_mode": "validation_blocked | repeated_gene | blast_radius_exceeded | ...",
  "confidence": 0.0-1.0,
  "signals_correlated": ["signal1", "signal2"],
  "gene_used": "gene_xxx",
  "loop_detected": true|false,
  "recommendation": {
    "action": "switch_gene | switch_intent | narrow_scope | fetch_hub | retry_safe",
    "next_gene_hint": "gene_xxx (or null)",
    "next_intent_hint": "innovate | repair | optimize | explore",
    "rationale": "Why this action"
  }
}
```

## Constraints

- Read-only: never edits state, never calls Hub, never writes to memory
- No dependencies: pure Node.js stdlib (fs, path)
- Deterministic: same input → same output (no time/random dependencies in core logic)
- Local-only: no network access

## Failure Mode Taxonomy

| Mode | Trigger | Recommendation |
|------|---------|----------------|
| `validation_blocked` | Validations failed before solidify | `retry_safe` after fixing the specific validation error |
| `repeated_gene` | Same gene in last 3+ failed cycles | `switch_gene` to a fresh candidate |
| `blast_radius_exceeded` | Files modified > 80% of gene.max_files | `narrow_scope` for next cycle |
| `json_schema_invalid` | Output rejected for missing JSON object | `retry_safe` with stricter prompt review |
| `missing_knowledge` | Hub returned no match AND local has no similar gene | `fetch_hub` to populate local knowledge |
| `stagnation` | stable_success_plateau + repeated gene | `switch_intent` to innovate |
| `unknown` | Cannot classify | `switch_gene` to a different category |

## See Also

- `validation-command-linter` — lint validation commands before submitting
- `evolver-overseer` — verify blast-radius estimates before approval
- `systematic-debugging` — general debugging methodology
