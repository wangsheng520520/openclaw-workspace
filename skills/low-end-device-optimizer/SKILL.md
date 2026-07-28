---
name: low-end-device-optimizer
description: Profiles host CPU/RAM and recommends CPU-only, low-memory agent optimizations (quantized model tier, heartbeat cadence, swap/zram, context size). Use when running an agent on constrained hardware or diagnosing OOM / high CPU on weak devices.
---

# low-end-device-optimizer

Report-only advisor for running an AI agent on constrained hardware
(CPU-only inference, low RAM). It reads OS metrics and returns an
actionable plan. It never edits config, installs runtimes, or executes
untrusted commands.

## When to use

- Deploying an agent on a small VPS, Raspberry Pi, or old laptop.
- Diagnosing OOM kills, swap thrash, or high CPU on a weak host.
- Deciding which quantized model tier fits available RAM.

## Usage

```bash
node skills/low-end-device-optimizer          # prints JSON plan for this host
```

Programmatic:

```js
const opt = require('./skills/low-end-device-optimizer');
const profile = opt.profileHost();
const plan = opt.buildPlan(profile);
console.log(plan.recommendations);
```

## What it recommends

1. **Runtime** — prefer a lightweight CPU runtime (llama.cpp / ollama).
2. **Model quant** — pick a quant tier (Q2_K … Q6_K) sized to RAM.
3. **Heartbeat** — widen cadence on weak hosts; disable non-essentials.
4. **Swap/zram** — enable under ~1GB RAM to avoid OOM.
5. **Context** — cap context window; halve it under memory pressure.

## API

- `profileHost()` → `{ platform, arch, cpuCount, cpuModel, totalMemGiB, freeMemGiB, memPressure, load1 }`
- `recommendQuant(totalMemGiB)` → `{ tier, maxParamsB, note }`
- `recommendHeartbeatSeconds(profile)` → number (seconds)
- `recommendContextTokens(profile)` → number (tokens)
- `buildPlan(profile)` → `{ profile, lowEndDetected, quant, heartbeatSeconds, contextTokens, recommendations }`
- `main()` → prints the plan and returns it

## Safety

Read-only: touches only `os` metrics. No filesystem writes, no network,
no shell. Recommendations are advisory; a human applies them.
