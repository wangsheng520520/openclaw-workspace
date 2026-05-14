---
name: feed-health-checker
description: Monitor RSS/Atom feed health by parsing blogwatcher scan output, tracking recurring failures over time, and generating structured health reports. Use when feeds fail repeatedly, when you need a feed reliability summary, or during heartbeat checks to detect degraded blog sources.
---

# feed-health-checker

Tracks the health and reliability of RSS/Atom feeds monitored by `blogwatcher`.

## When to Use

- During heartbeat checks to detect degraded feeds
- When `blogwatcher scan` output contains errors
- To generate a feed reliability report
- To identify feeds that need URL updates or removal

## Usage

### Generate Health Report

```bash
# Run scan and capture health data
node skills/feed-health-checker/index.js scan

# View current health status
node skills/feed-health-checker/index.js status

# View failure history
node skills/feed-health-checker/index.js history

# Diagnose failures and get remediation suggestions
node skills/feed-health-checker/index.js diagnose
```

### Programmatic API

```js
const { scan, getStatus, getHistory, diagnose } = require('./skills/feed-health-checker');

// Run blogwatcher scan and parse results
const report = await scan();
// => { timestamp, sources: [{ name, status, found, new, error }], healthy, degraded, failed }

// Get current health status from last scan
const status = getStatus();

// Get failure history
const history = getHistory();
// => { sources: { "机器之心": { consecutiveFailures: 5, lastError: "...", firstFailure: "..." } } }
```

## Health States

| State | Meaning |
|-------|---------|
| `healthy` | Feed parsed successfully |
| `degraded` | Feed failed 1-2 times consecutively |
| `failed` | Feed failed 3+ times consecutively |

## Output

Health data is stored in `memory/feed-health.json` for persistence across sessions.

## Diagnosis Capabilities

The `diagnose` command analyzes feed failures and provides actionable remediation:

| Error Type | Detection Pattern | Recommended Action |
|------------|------------------|-------------------|
| Server Error (503) | `status 503` | Retry later, check site status |
| Not Found (404) | `status 404` | Update feed URL |
| XML Parse Error | `XML` or `xml` in error | Check encoding/user-agent |
| Format Detection Failure | `Failed to detect feed type` | Manual URL inspection |
| Timeout | `timeout` or `timed out` | Increase timeout settings |

## Dependencies

- `blogwatcher` CLI must be installed and configured
