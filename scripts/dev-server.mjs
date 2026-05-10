import { createServer } from 'node:http';
import { createReadStream, existsSync } from 'node:fs';
import { extname, join, normalize } from 'node:path';

const root = process.cwd();
const port = Number(process.env.PORT ?? 5173);
const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
};

function resolveFile(urlPath) {
  const safePath = normalize(decodeURIComponent(urlPath)).replace(/^([/\\])+/, '');
  const candidate = join(root, safePath || 'index.html');
  if (existsSync(candidate) && !candidate.endsWith('/')) return candidate;
  return join(root, 'index.html');
}

createServer((request, response) => {
  const filePath = resolveFile(new URL(request.url ?? '/', `http://${request.headers.host}`).pathname);
  response.setHeader('Content-Type', contentTypes[extname(filePath)] ?? 'application/octet-stream');
  createReadStream(filePath).pipe(response);
}).listen(port, '0.0.0.0', () => {
  console.log(`Chameleon MVP running at http://127.0.0.1:${port}`);
});
