# Task 5: Docker bridge network isolation

With Docker running, execute:

```sh
bash isolation-demo.sh
```

The script creates two custom bridge networks, `network-1` and `network-2`.
It starts `container-1` on the first and `container-2` on the second, using
the official `alpine:3.22` image. No host ports are published.

Tests:

1. Loopback pings succeed in both containers, confirming ping is functional.
2. `container-1` cannot ping `container-2` by name across separate networks.
3. Pinging container-2's actual IP also fails, checking isolation beyond DNS.
4. Temporarily connecting container-2 to network-1 allows ping by name.
5. After disconnecting it, cross-network IP ping fails again.

Both containers remain running on their separate networks for inspection.
See `verification.txt` for captured results. These tests demonstrate direct
container communication isolation under Docker's current bridge configuration.

Manual verification:

```sh
docker network inspect network-1 network-2
docker exec container-1 ping -c 2 -W 2 container-2
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container-2
# Replace CONTAINER_2_IP with the address printed above:
docker exec container-1 ping -c 2 -W 2 CONTAINER_2_IP
```

The two cross-network pings should exit with a nonzero status. The script
expects unused network and container names and refuses to overwrite existing resources.
