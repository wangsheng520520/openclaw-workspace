'use strict';

// Runtime shim for Evolver Hub requests under WSL2 + Chameleon proxy.
// Evolver's src/gep/hubFetch uses the package undici.fetch with its own direct
// dispatcher, so Node's --use-env-proxy is bypassed. The exported test hook is
// intentionally narrow: it only replaces the fetch implementation with
// global.fetch and drops hubFetch's direct dispatcher, letting Node's
// EnvHttpProxyAgent handle HTTP_PROXY/HTTPS_PROXY.

try {
  const hubFetch = require('/home/wszmd520520/.openclaw/workspace/skills/evolver/src/gep/hubFetch');
  if (hubFetch && typeof hubFetch._setFetchImplForTest === 'function') {
    hubFetch._setFetchImplForTest((url, opts = {}) => {
      const { dispatcher, ...rest } = opts || {};
      return global.fetch(url, rest);
    });
    console.error('[evolver-proxy-preload] hubFetch now uses global.fetch/env proxy');
  } else {
    console.error('[evolver-proxy-preload] _setFetchImplForTest not available; hubFetch may bypass env proxy');
  }
} catch (err) {
  console.error('[evolver-proxy-preload] failed:', err && (err.stack || err.message || String(err)));
}
