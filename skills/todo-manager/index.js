#!/usr/bin/env node
const { scanTodos } = require('./scripts/scan-todos');
module.exports = { scanTodos };
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.includes('--help')) {
    console.log('Usage: node index.js <dir> [--max-files N] [--format json|markdown]');
    console.log('Scans a directory for TODO/FIXME/HACK/XXX comments');
    process.exit(0);
  }
  const dir = args[0] || '.';
  const maxFiles = parseInt(args[args.indexOf('--max-files') + 1] || '100');
  const format = args[args.indexOf('--format') + 1] || 'json';
  scanTodos(dir, { maxFiles, format }).then(r => console.log(format === 'json' ? JSON.stringify(r, null, 2) : r));
}
