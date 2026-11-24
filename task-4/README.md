# Task 4: Custom Docker bridge network

Run with Docker Desktop running:

```sh
bash run.sh
```

The script creates `task4-bridge` with the bridge driver, then starts the
official Redis image as container `redis` and the Flask app as `task4-flask`.
Both join the same custom network. `REDIS_HOST=redis` makes Flask connect through
Docker's container-name DNS on port 6379. Redis has no published host port.

Open http://localhost:5003 and refresh to increment the Redis-backed counter.
Host port 5003 avoids the existing exercises and macOS AirPlay on port 5000;
Flask listens on port 5000 inside its container.

Verification checks container-name DNS resolution, Redis PING from the Flask
container, and two HTTP requests whose counter values must increase by one.
The script also prints network membership. See `verification.txt` for results.

Inspect the network and stored counter:

```sh
docker network inspect task4-bridge
docker exec redis redis-cli GET visits
```

The script expects unused network and container names. Both containers remain
running for inspection. This exercise uses Flask's development server.
