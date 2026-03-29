#!/usr/bin/env node
/**
 * Servidor mínimo para pré-visualização Mermaid em tempo quase real.
 *
 * - GET  /mermaid-live  → SSE: envia o ficheiro observado ao ligar e sempre que mudar
 * - POST /mermaid-push → corpo text/plain = código Mermaid; grava no ficheiro e notifica clientes
 * - GET  /*             → ficheiros estáticos a partir de --static
 *
 * Uso:
 *   node mermaid-live-server.mjs --file ./diagram.mmd --static . --port 9876
 *
 * No browser (mesmo origin que este servidor):
 *   abrir base.html → liga a /mermaid-live por defeito (?nolive=1 desliga); redesenha ao receber texto
 *
 * O agente (ou tu) pode atualizar o gráfico sem refresh manual:
 *   curl -sS -X POST http://127.0.0.1:9876/mermaid-push --data-binary @diagram.mmd
 *   # ou editar diagram.mmd no disco → fs.watch notifica
 */
import http from 'http';
import fs from 'fs';
import path from 'path';

let watchFile = path.join(process.cwd(), 'diagram.mmd');
let port = 9876;
let staticRoot = process.cwd();

for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  if (a === '--file' && process.argv[i + 1]) {
    watchFile = path.resolve(process.argv[++i]);
    continue;
  }
  if (a === '--port' && process.argv[i + 1]) {
    port = parseInt(process.argv[++i], 10);
    continue;
  }
  if (a === '--static' && process.argv[i + 1]) {
    staticRoot = path.resolve(process.argv[++i]);
    continue;
  }
  if (a === '-h' || a === '--help') {
    console.log(`Usage: node mermaid-live-server.mjs [--file PATH] [--port N] [--static DIR]`);
    process.exit(0);
  }
}

const clients = new Set();
let watchTimer = null;

function broadcast(text) {
  const payload = JSON.stringify({ text: text || '' });
  const chunk = 'data: ' + payload.replace(/\r\n/g, '\n').split('\n').join('\ndata: ') + '\n\n';
  for (const res of clients) {
    try {
      res.write(chunk);
    } catch {
      clients.delete(res);
    }
  }
}

function readAndBroadcast() {
  fs.readFile(watchFile, 'utf8', (err, text) => {
    if (err && err.code !== 'ENOENT') console.error('read', watchFile, err.message);
    broadcast(err ? '' : text);
  });
}

function scheduleBroadcast() {
  if (watchTimer) clearTimeout(watchTimer);
  watchTimer = setTimeout(() => {
    watchTimer = null;
    readAndBroadcast();
  }, 120);
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.mmd': 'text/plain; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.json': 'application/json; charset=utf-8',
};

function safeJoin(root, reqPath) {
  const rel = String(reqPath || '').replace(/^\/+/, '');
  if (rel.includes('\0')) return null;
  const resolved = path.resolve(root, rel);
  if (!resolved.startsWith(path.resolve(root))) return null;
  return resolved;
}

const server = http.createServer((req, res) => {
  const u = new URL(req.url || '/', `http://127.0.0.1:${port}`);

  if (u.pathname === '/mermaid-live' && req.method === 'GET') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });
    clients.add(res);
    readAndBroadcast();
    req.on('close', () => {
      clients.delete(res);
    });
    return;
  }

  if (u.pathname === '/mermaid-push' && req.method === 'POST') {
    let body = '';
    req.on('data', (c) => {
      body += c;
      if (body.length > 2_000_000) req.destroy();
    });
    req.on('end', () => {
      fs.mkdir(path.dirname(watchFile), { recursive: true }, (mkErr) => {
        if (mkErr) {
          res.writeHead(500);
          res.end(mkErr.message);
          return;
        }
        fs.writeFile(watchFile, body, 'utf8', (err) => {
          if (err) {
            res.writeHead(500);
            res.end(err.message);
            return;
          }
          broadcast(body);
          res.writeHead(204, { 'Access-Control-Allow-Origin': '*' });
          res.end();
        });
      });
    });
    return;
  }

  if (req.method !== 'GET' && req.method !== 'HEAD') {
    res.writeHead(405);
    res.end();
    return;
  }

  let rel = u.pathname === '/' ? '/index.html' : u.pathname;
  const filePath = safeJoin(staticRoot, decodeURIComponent(rel));
  if (!filePath) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, st) => {
    if (err || !st.isFile()) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
    if (req.method === 'HEAD') {
      res.end();
      return;
    }
    fs.createReadStream(filePath).pipe(res);
  });
});

function ensureWatch() {
  fs.mkdir(path.dirname(watchFile), { recursive: true }, () => {
    fs.access(watchFile, fs.constants.F_OK, (err) => {
      if (err) {
        fs.writeFile(
          watchFile,
          "%%{init: {'theme': 'dark'}}%%\nflowchart TD\n  A[Live] --> B[OK]\n",
          'utf8',
          () => tryWatch()
        );
      } else {
        tryWatch();
      }
    });
  });
}

function tryWatch() {
  try {
    fs.watch(watchFile, { persistent: true }, () => scheduleBroadcast());
  } catch (e) {
    console.error('watch', watchFile, e.message);
  }
}

ensureWatch();

server.listen(port, '127.0.0.1', () => {
  console.log(`mermaid-live http://127.0.0.1:${port}/  file=${watchFile}  static=${staticRoot}`);
  console.log(`  SSE GET /mermaid-live   POST /mermaid-push   abrir base.html (?nolive=1 desliga SSE)`);
});
