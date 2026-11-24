const http = require('node:http');

const port = Number(process.env.PORT || 3000);
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end('Hello, World!\n');
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Server listening on port ${port}`);
});

process.on('SIGTERM', () => server.close(() => process.exit(0)));
