#!/usr/bin/env node

const fs = require('fs').promises;
const path = require('path');
const { exec } = require('child_process');
const util = require('util');

const execAsync = util.promisify(exec);

// Health data file path
const HEALTH_FILE = path.join(process.env.HOME || process.cwd(), '.openclaw', 'workspace', 'memory', 'feed-health.json');

/**
 * Parse blogwatcher scan output into structured data
 * @param {string} output - Raw blogwatcher scan output
 * @returns {Object} Parsed report
 */
function parseScanOutput(output) {
  const lines = output.split('\n');
  const sources = [];
  let currentSource = null;
  
  for (const line of lines) {
    // Match source line: "  Source Name"
    const sourceMatch = line.match(/^  (.+)$/);
    if (sourceMatch && !line.includes('Source:') && !line.includes('Error:') && !line.includes('Found:')) {
      if (currentSource) {
        sources.push(currentSource);
      }
      currentSource = { name: sourceMatch[1].trim(), status: 'healthy', found: 0, new: 0, error: null };
      continue;
    }
    
    // Match success line: "    Source: RSS | Found: X | New: Y"
    const successMatch = line.match(/Source: RSS \| Found: (\d+) \| New: (\d+)/);
    if (successMatch && currentSource) {
      currentSource.found = parseInt(successMatch[1], 10);
      currentSource.new = parseInt(successMatch[2], 10);
      continue;
    }
    
    // Match error line: "    Error: ..."
    const errorMatch = line.match(/Error: (.+)$/);
    if (errorMatch && currentSource) {
      currentSource.status = 'failed';
      currentSource.error = errorMatch[1].trim();
      continue;
    }
  }
  
  if (currentSource) {
    sources.push(currentSource);
  }
  
  return {
    timestamp: new Date().toISOString(),
    sources,
    healthy: sources.filter(s => s.status === 'healthy').length,
    degraded: 0, // Will be calculated from history
    failed: sources.filter(s => s.status === 'failed').length
  };
}

/**
 * Load health history from file
 */
async function loadHistory() {
  try {
    const data = await fs.readFile(HEALTH_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return { sources: {}, lastScan: null };
    }
    throw error;
  }
}

/**
 * Save health history to file
 */
async function saveHistory(history) {
  await fs.mkdir(path.dirname(HEALTH_FILE), { recursive: true });
  await fs.writeFile(HEALTH_FILE, JSON.stringify(history, null, 2));
}

/**
 * Update failure history based on current scan results
 */
function updateHistory(history, report) {
  const now = new Date().toISOString();
  
  // Initialize or update each source
  for (const source of report.sources) {
    const sourceName = source.name;
    
    if (!history.sources[sourceName]) {
      history.sources[sourceName] = {
        consecutiveFailures: 0,
        lastError: null,
        firstFailure: null,
        totalFailures: 0
      };
    }
    
    const sourceHistory = history.sources[sourceName];
    
    if (source.status === 'failed') {
      sourceHistory.consecutiveFailures++;
      sourceHistory.lastError = source.error;
      sourceHistory.totalFailures++;
      if (!sourceHistory.firstFailure) {
        sourceHistory.firstFailure = now;
      }
    } else {
      // Success - reset consecutive failures
      sourceHistory.consecutiveFailures = 0;
      sourceHistory.lastError = null;
    }
    
    // Set status based on consecutive failures
    if (sourceHistory.consecutiveFailures >= 3) {
      source.status = 'failed';
    } else if (sourceHistory.consecutiveFailures > 0) {
      source.status = 'degraded';
    }
  }
  
  history.lastScan = report;
  return history;
}

/**
 * Run blogwatcher scan and generate health report
 */
async function scan() {
  try {
    const { stdout, stderr } = await execAsync('blogwatcher scan', { 
      cwd: path.join(process.env.HOME || process.cwd(), '.openclaw', 'workspace')
    });
    
    const report = parseScanOutput(stdout);
    
    // Load history and update it
    const history = await loadHistory();
    const updatedHistory = updateHistory(history, report);
    await saveHistory(updatedHistory);
    
    // Update report with final statuses
    report.degraded = report.sources.filter(s => s.status === 'degraded').length;
    report.failed = report.sources.filter(s => s.status === 'failed').length;
    
    return report;
  } catch (error) {
    console.error('Error running blogwatcher scan:', error.message);
    throw error;
  }
}

/**
 * Get current health status
 */
async function getStatus() {
  const history = await loadHistory();
  return history.lastScan || null;
}

/**
 * Get failure history
 */
async function getHistory() {
  const history = await loadHistory();
  return history;
}

/**
 * Diagnose feed failures and provide remediation suggestions
 */
async function diagnose() {
  const history = await loadHistory();
  if (!history.lastScan) {
    throw new Error('No scan data available. Run "scan" first.');
  }

  const failedSources = history.lastScan.sources.filter(s => s.status !== 'healthy');
  const diagnosis = {
    timestamp: new Date().toISOString(),
    summary: {
      totalSources: history.lastScan.sources.length,
      healthy: history.lastScan.healthy,
      degraded: history.lastScan.degraded,
      failed: history.lastScan.failed,
      actionableIssues: 0
    },
    recommendations: []
  };

  for (const source of failedSources) {
    const rec = {
      source: source.name,
      error: source.error,
      status: source.status,
      consecutiveFailures: history.sources[source.name]?.consecutiveFailures || 0,
      type: 'unknown',
      action: 'investigate',
      details: ''
    };

    // Classify error types and provide specific remediation
    if (source.error && source.error.includes('status 503')) {
      rec.type = 'server_error';
      rec.action = 'retry_later';
      rec.details = 'Server temporarily unavailable. Try again in a few hours or check if the site is down.';
    } else if (source.error && source.error.includes('status 404')) {
      rec.type = 'not_found';
      rec.action = 'update_url';
      rec.details = 'Feed URL returns 404. The blog may have moved or discontinued its RSS feed.';
    } else if (source.error && (source.error.includes('XML') || source.error.includes('xml'))) {
      rec.type = 'xml_parse_error';
      rec.action = 'check_encoding';
      rec.details = 'XML parsing failed. Try fetching with different encoding or user-agent.';
    } else if (source.error && source.error.includes('Failed to detect feed type')) {
      rec.type = 'format_detection_failure';
      rec.action = 'manual_inspection';
      rec.details = 'Could not detect feed format. Manually inspect the URL for valid RSS/Atom structure.';
    } else if (source.error && source.error.includes('timeout') || source.error.includes('timed out')) {
      rec.type = 'timeout';
      rec.action = 'increase_timeout';
      rec.details = 'Request timed out. Consider increasing timeout or checking network connectivity.';
    }

    diagnosis.recommendations.push(rec);
  }

  diagnosis.summary.actionableIssues = diagnosis.recommendations.length;
  return diagnosis;
}

// CLI interface
if (require.main === module) {
  const command = process.argv[2] || 'scan';
  
  async function run() {
    try {
      switch (command) {
        case 'scan':
          const report = await scan();
          console.log(JSON.stringify(report, null, 2));
          break;
        case 'status':
          const status = await getStatus();
          console.log(JSON.stringify(status, null, 2));
          break;
        case 'history':
          const history = await getHistory();
          console.log(JSON.stringify(history, null, 2));
          break;
        case 'diagnose':
          const diagnosis = await diagnose();
          console.log(JSON.stringify(diagnosis, null, 2));
          break;
        default:
          console.error(`Unknown command: ${command}`);
          console.error('Available commands: scan, status, history, diagnose');
          process.exit(1);
      }
    } catch (error) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  }
  
  run();
}

module.exports = { scan, getStatus, getHistory };
module.exports = { scan, getStatus, getHistory, diagnose };
