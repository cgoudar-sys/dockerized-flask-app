#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
DOCKER=${DOCKER:-docker}

"$DOCKER" network create --driver bridge task4-bridge
"$DOCKER" run -d --name redis --network task4-bridge redis:7.4-alpine
"$DOCKER" build -t task4-flask .
"$DOCKER" run -d --name task4-flask --network task4-bridge -e REDIS_HOST=redis -p 5003:5000 task4-flask

# Check DNS resolution and a direct Redis operation from the Flask container.
"$DOCKER" exec task4-flask python -c 'import socket; from redis import Redis; print("redis resolves to", socket.gethostbyname("redis")); r=Redis(host="redis", socket_connect_timeout=5); assert r.ping(); print("Redis PING: PASS")'

# Verify that two requests to Flask increment the counter stored in Redis.
"$DOCKER" exec -i task4-flask python - <<'PY'
import re
import time
from urllib.request import urlopen

def fetch():
    for attempt in range(20):
        try:
            with urlopen("http://127.0.0.1:5000/", timeout=3) as response:
                return response.read().decode().strip()
        except OSError:
            if attempt == 19:
                raise
            time.sleep(1)

first, second = fetch(), fetch()
print(first)
print(second)
assert int(re.search(r"visited (\d+)", second)[1]) == int(re.search(r"visited (\d+)", first)[1]) + 1
print("Flask to Redis communication: PASS")
PY
"$DOCKER" network inspect --format '{{.Name}} driver={{.Driver}}{{range .Containers}}{{println}}{{.Name}} {{.IPv4Address}}{{end}}' task4-bridge
