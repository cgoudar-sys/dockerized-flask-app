# Task 6: Multi-stage Node.js build

Build and run from this directory:

```sh
docker build -t task6-node .
docker run -d --name task6-node -p 3000:3000 task6-node
```

Open http://localhost:3000. Expected response: `Hello, World!`

The first stage uses `node:24-bookworm` to validate the JavaScript and prepare
`dist/server.js` with `npm run build`. This small app uses Node's built-in HTTP
module and needs no third-party dependencies or transpiler.

The second stage uses the smaller `node:24-alpine` runtime base and copies only
the prepared server file from the build stage. The app runs as the non-root
`node` user. Build-stage files and tools are not copied into the final image.

Verify and stop:

```sh
curl --fail http://localhost:3000/
docker logs task6-node
docker stop task6-node
```
