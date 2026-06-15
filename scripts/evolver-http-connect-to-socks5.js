#!/usr/bin/env node
'use strict';

// Local bridge for Evolver/Node env-proxy support.
// Node v24 --use-env-proxy accepts http(s) proxy URLs, while Chameleon exposes
// a local SOCKS endpoint. This tiny HTTP CONNECT proxy forwards CONNECT tunnels
// to the configured SOCKS5 server.

const http = require('node:http');
const net = require('node:net');

const LISTEN_HOST = process.env.EVOLVER_PROXY_BRIDGE_HOST || '127.0.0.1';
const LISTEN_PORT = Number(process.env.EVOLVER_PROXY_BRIDGE_PORT || 18080);
const SOCKS_HOST = process.env.CHAMELEON_PROXY_HOST || '127.0.0.1';
const SOCKS_PORT = Number(process.env.CHAMELEON_PROXY_PORT || 1234);

function socksConnect(targetHost, targetPort, cb) {
  const socket = net.connect(SOCKS_PORT, SOCKS_HOST);
  let stage = 0;
  let chunks = [];
  const fail = (err) => {
    try { socket.destroy(); } catch {}
    cb(err);
  };

  socket.setTimeout(15000, () => fail(new Error('socks timeout')));
  socket.once('error', fail);
  socket.once('connect', () => socket.write(Buffer.from([0x05, 0x01, 0x00])));
  socket.on('data', (buf) => {
    chunks.push(buf);
    const data = Buffer.concat(chunks);

    if (stage === 0) {
      if (data.length < 2) return;
      if (data[0] !== 0x05 || data[1] !== 0x00) return fail(new Error('socks auth failed'));
      chunks = [];
      stage = 1;

      const host = Buffer.from(targetHost);
      if (host.length > 255) return fail(new Error('host too long'));
      const req = Buffer.alloc(7 + host.length);
      req[0] = 0x05; // SOCKS version
      req[1] = 0x01; // CONNECT
      req[2] = 0x00; // reserved
      req[3] = 0x03; // domain name
      req[4] = host.length;
      host.copy(req, 5);
      req.writeUInt16BE(targetPort, 5 + host.length);
      socket.write(req);
      return;
    }

    if (stage === 1) {
      if (data.length < 5) return;
      if (data[0] !== 0x05 || data[1] !== 0x00) return fail(new Error(`socks connect failed ${data[1]}`));
      let need = 0;
      if (data[3] === 0x01) need = 10;
      else if (data[3] === 0x03) need = 7 + data[4];
      else if (data[3] === 0x04) need = 22;
      else return fail(new Error('bad socks address type'));
      if (data.length < need) return;
      socket.removeAllListeners('data');
      socket.removeAllListeners('error');
      socket.setTimeout(0);
      cb(null, socket);
    }
  });
}

const server = http.createServer((req, res) => {
  res.writeHead(405, { 'content-type': 'text/plain' });
  res.end('CONNECT only\n');
});

server.on('connect', (req, client, head) => {
  const [host, portStr] = req.url.split(':');
  const port = Number(portStr || 443);
  socksConnect(host, port, (err, upstream) => {
    if (err) {
      client.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
      client.destroy();
      return;
    }
    client.write('HTTP/1.1 200 Connection Established\r\n\r\n');
    if (head && head.length) upstream.write(head);
    upstream.pipe(client);
    client.pipe(upstream);
  });
});

server.listen(LISTEN_PORT, LISTEN_HOST, () => {
  console.log(`[evolver-proxy-bridge] listening http://${LISTEN_HOST}:${LISTEN_PORT} -> socks5://${SOCKS_HOST}:${SOCKS_PORT}`);
});
