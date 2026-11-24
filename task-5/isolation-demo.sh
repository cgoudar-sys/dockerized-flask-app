#!/usr/bin/env bash
set -euo pipefail
DOCKER=${DOCKER:-docker}
for net in network-1 network-2; do
  if "$DOCKER" network inspect "$net" >/dev/null 2>&1; then
    echo "$net already exists; choose unused network names." >&2
    exit 1
  fi
done
for name in container-1 container-2; do
  if "$DOCKER" container inspect "$name" >/dev/null 2>&1; then
    echo "$name already exists; choose unused container names." >&2
    exit 1
  fi
done

"$DOCKER" pull alpine:3.22
"$DOCKER" network create --driver bridge network-1
"$DOCKER" network create --driver bridge network-2
"$DOCKER" run -d --name container-1 --network network-1 alpine:3.22 sleep infinity
"$DOCKER" run -d --name container-2 --network network-2 alpine:3.22 sleep infinity
ip2=$("$DOCKER" inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container-2)
echo "container-2 IP: $ip2"

# Positive controls: ping exists and works inside each container.
"$DOCKER" exec container-1 ping -c 1 -W 2 127.0.0.1
"$DOCKER" exec container-2 ping -c 1 -W 2 127.0.0.1

echo "Test 1: Ping by name across separate networks (expected failure)."
if "$DOCKER" exec container-1 ping -c 2 -W 2 -w 5 container-2; then
  echo "FAIL: Cross-network name ping unexpectedly succeeded." >&2
  exit 1
fi
echo "PASS: Cross-network name ping failed."

echo "Test 2: Ping by IP across separate networks (expected failure)."
if "$DOCKER" exec container-1 ping -c 2 -W 2 -w 5 "$ip2"; then
  echo "FAIL: Cross-network IP ping unexpectedly succeeded." >&2
  exit 1
fi
echo "PASS: Cross-network IP ping failed."

# Temporarily join the same network to prove the peer is reachable when allowed.
"$DOCKER" network connect network-1 container-2
trap '"$DOCKER" network disconnect network-1 container-2 >/dev/null 2>&1 || true' EXIT
echo "Positive control: Ping succeeds after temporarily sharing network-1."
"$DOCKER" exec container-1 ping -c 2 -W 2 -w 5 container-2
"$DOCKER" network disconnect network-1 container-2
trap - EXIT

echo "Final check: IP ping fails again after restoring isolation."
if "$DOCKER" exec container-1 ping -c 2 -W 2 -w 5 "$ip2"; then
  echo "FAIL: Cross-network IP ping unexpectedly succeeded." >&2
  exit 1
fi
echo "PASS: Isolation restored."
"$DOCKER" network inspect --format '{{.Name}} driver={{.Driver}}{{range .Containers}}{{println}}{{.Name}} {{.IPv4Address}}{{end}}' network-1 network-2
