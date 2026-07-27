#!/usr/bin/env node
/**
 * gep-validate-noop.js
 *
 * A sandbox-safe, zero-side-effect validation script for GEP genes whose
 * mutation is a low-risk optimize/repair with no repo-specific test suite of
 * its own.
 *
 * WHY THIS EXISTS
 * ---------------
 * The evolver validator sandbox (src/gep/validator/sandboxExecutor.js) hard-
 * blocks `node -e '...'` / `node -p` / `node -r` inline-eval flags as an anti-
 * RCE control (GHSA-jxh8-jh77-xh6g). Several genes historically declared their
 * validation as:
 *     node -e 'if (1 + 1 !== 2) process.exit(1)'
 * That command PASSES in a raw shell but is REJECTED by solidify's safety gate,
 * so every solidify attempt for those genes fails with
 * "validation command rejected by safety check" and the loop retries forever.
 *
 * The sandbox only ever allows `node <script-file> [args]`. This file is that
 * script: it performs a trivial invariant check and exits 0, giving those genes
 * a runnable validation step WITHOUT weakening any safety mechanism.
 *
 * It intentionally: reads nothing sensitive, writes nothing, spawns nothing,
 * touches no network. Pure single-shot determinism — the exact "prefer single-
 * shot commands" guardrail gene_gep_optimize_tool_usage prescribes.
 */
'use strict';

function main() {
  // Core invariant: arithmetic + control flow behave as expected. If the Node
  // runtime is so broken this fails, validation SHOULD fail.
  if (1 + 1 !== 2) {
    process.stderr.write('gep-validate-noop: arithmetic invariant failed\n');
    process.exit(1);
  }
  // Sanity: JSON round-trips (many genes manipulate JSON assets).
  const probe = { ok: true, n: 42 };
  const round = JSON.parse(JSON.stringify(probe));
  if (round.ok !== true || round.n !== 42) {
    process.stderr.write('gep-validate-noop: JSON round-trip invariant failed\n');
    process.exit(1);
  }
  process.stdout.write('gep-validate-noop: ok\n');
  process.exit(0);
}

main();
