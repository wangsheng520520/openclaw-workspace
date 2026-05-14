const fs = require('fs');
const path = require('path');

const PATTERNS = {
  TODO: /\/\/\s*TODO[:\s]+(.+)/gi,
  FIXME: /\/\/\s*FIXME[:\s]+(.+)/gi,
  HACK: /\/\/\s*HACK[:\s]+(.+)/gi,
  XXX: /\/\/\s*XXX[:\s]+(.+)/gi
};

const EXCLUDED = ['node_modules', '.git', 'dist', 'build', '.next'];

function shouldScan(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return ['.js', '.ts', '.jsx', '.tsx', '.py', '.java', '.go', '.rs', '.cpp', '.c', '.h', '.rb', '.php', '.swift', '.css', '.scss', '.html', '.vue', '.svelte', '.sh', '.bash', '.yaml', '.yml', '.md', '.json', '.toml'].includes(ext);
}

function scanFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    const findings = [];
    lines.forEach((line, idx) => {
      for (const [type, pattern] of Object.entries(PATTERNS)) {
        pattern.lastIndex = 0;
        let match;
        while ((match = pattern.exec(line)) !== null) {
          findings.push({ file: filePath, line: idx + 1, type, message: match[1].trim(), context: line.trim() });
        }
      }
    });
    return findings;
  } catch (e) {
    return [];
  }
}

function scanTodos(dir, opts = {}) {
  return new Promise((resolve) => {
    const allFindings = [];
    let filesScanned = 0;
    const maxFiles = opts.maxFiles || 100;
    
    function walk(currentDir) {
      if (filesScanned >= maxFiles) return;
      try {
        const entries = fs.readdirSync(currentDir, { withFileTypes: true });
        for (const entry of entries) {
          if (filesScanned >= maxFiles) return;
          const fullPath = path.join(currentDir, entry.name);
          if (entry.isDirectory()) {
            if (!EXCLUDED.includes(entry.name) && !entry.name.startsWith('.')) {
              walk(fullPath);
            }
          } else if (shouldScan(fullPath)) {
            filesScanned++;
            const findings = scanFile(fullPath);
            allFindings.push(...findings);
          }
        }
      } catch (e) {}
    }
    
    walk(dir);
    
    const summary = {};
    allFindings.forEach(f => { summary[f.type] = (summary[f.type] || 0) + 1; });
    
    if (opts.format === 'markdown') {
      let md = '# TODO Scanner Report\n\n';
      md += `Scanned ${filesScanned} files, found ${allFindings.length} items.\n\n`;
      md += '## Summary\n\n';
      for (const [type, count] of Object.entries(summary).sort()) {
        md += `- **${type}**: ${count}\n`;
      }
      md += '\n## Findings\n\n';
      const byFile = {};
      allFindings.forEach(f => {
        if (!byFile[f.file]) byFile[f.file] = [];
        byFile[f.file].push(f);
      });
      for (const [file, items] of Object.entries(byFile).slice(0, 50)) {
        md += `### ${file}\n\n`;
        items.forEach(item => {
          md += `- L${item.line} [${item.type}] ${item.message}\n`;
        });
        md += '\n';
      }
      resolve(md);
    } else {
      resolve({ summary, total: allFindings.length, filesScanned, findings: allFindings.slice(0, 200) });
    }
  });
}

module.exports = { scanTodos, scanFile };
