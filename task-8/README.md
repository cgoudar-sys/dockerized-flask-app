# Task 8: PostgreSQL database volume management

Run with Docker running:

```sh
bash persistence-demo.sh
```

The script uses the official `postgres:17-alpine` image. It sets
`POSTGRES_USER=demo`, `POSTGRES_DB=volume_demo`, and a generated
`POSTGRES_PASSWORD`. Credentials are created locally in a temporary file and
are not committed. No host database port is published.

It creates the requested named volume with `docker volume create postgres-data`
and mounts it at `/var/lib/postgresql/data`, the data path for PostgreSQL 17.
It inserts two rows, queries them, stops and removes the first container, then
creates another container with the same volume. It verifies identical rows
and different container IDs. Success prints `PASS`.

The replacement container and volume remain available for inspection:

```sh
docker volume inspect postgres-data
docker exec task8-postgres-recreated psql -U demo -d volume_demo -c 'SELECT * FROM messages;'
docker stop task8-postgres-recreated
```

Stopping or removing the container preserves the named volume. The script
refuses an existing volume to avoid changing existing data or reporting a false
success. Use unused volume/container names to repeat the demonstration.

See `verification.txt` for the test results.
