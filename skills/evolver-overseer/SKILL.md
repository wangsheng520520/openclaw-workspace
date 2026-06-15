---
name: evolver-overseer
description: Before approving evolver mutations, verify blast radius estimate accuracy. Evoler's max_files constraint is 15; estimate drift >2x predicts certain failure. Use this when supervising evolver review/approve cycles.
---

CRITICAL: Check estimate vs actual before approving

## Pre-Approve Checklist

1. **Parse mutation diff header** — look for `Files changed: N` / `Lines changed: M`
2. **Compare to gene's `constraints.max_files`** (default 15)
3. **If actual files > 2x estimate** → likely solidify failure incoming
4. **If actual files > 30** (2x limit) → approval will waste a cycle

## Anti-Pattern

Approving mutations with large file counts (READMEs, generated docs, bulk refactors) because the gene's own estimate is wrong. The constrain

## When Rejecting Is Correct

`constraint_destructive` rejection is evolver working as designed. Do not override.

## After Failed Run

- Check `memory/evolution/evolution_narrative.md` for failure case logged
- Epigenetic mark (-0.1) auto-applied; no manual repair needed
- Next run will decay boost automatically
- If same gene fails 2x, remove it from active pool manually
