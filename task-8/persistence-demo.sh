#!/usr/bin/env bash
set -euo pipefail
DOCKER=${DOCKER:-docker}
VOLUME=postgres-data
FIRST=task8-postgres-first
SECOND=task8-postgres-recreated
IMAGE=postgres:17-alpine
if "$DOCKER" volume inspect "$VOLUME" >/dev/null 2>&1; then
  echo "$VOLUME already exists; use an unused volume name to avoid modifying existing data." >&2
  exit 1
fi
for name in "$FIRST" "$SECOND"; do
  if "$DOCKER" container inspect "$name" >/dev/null 2>&1; then
    echo "$name already exists; choose unused container names." >&2
    exit 1
  fi
done
credentials=$(mktemp)
chmod 600 "$credentials"
trap 'rm -f "$credentials"' EXIT
printf 'POSTGRES_USER=demo\nPOSTGRES_DB=volume_demo\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)" > "$credentials"

wait_ready() {
  for ((attempt=1; attempt<=90; attempt++)); do
    if "$DOCKER" exec "$1" pg_isready -h 127.0.0.1 -U demo -d volume_demo >/dev/null 2>&1; then
      return
    fi
    sleep 2
  done
  echo "PostgreSQL readiness timed out." >&2
  return 1
}
query() {
  "$DOCKER" exec -i "$1" psql -U demo -d volume_demo -v ON_ERROR_STOP=1 -At
}

"$DOCKER" pull "$IMAGE"
"$DOCKER" volume create "$VOLUME"
"$DOCKER" run -d --name "$FIRST" --env-file "$credentials" --mount "type=volume,source=$VOLUME,target=/var/lib/postgresql/data" "$IMAGE"
wait_ready "$FIRST"
query "$FIRST" <<'SQL'
CREATE TABLE messages (id INTEGER PRIMARY KEY, message TEXT NOT NULL);
INSERT INTO messages VALUES (1, 'PostgreSQL data persists'), (2, 'Stored in postgres-data');
SQL
before=$(query "$FIRST" <<<'SELECT id, message FROM messages ORDER BY id;')
echo "Before container replacement:"
printf '%s\n' "$before"
first_id=$("$DOCKER" inspect --format '{{.Id}}' "$FIRST")
"$DOCKER" stop "$FIRST"
"$DOCKER" rm "$FIRST"
"$DOCKER" run -d --name "$SECOND" --env-file "$credentials" --mount "type=volume,source=$VOLUME,target=/var/lib/postgresql/data" "$IMAGE"
wait_ready "$SECOND"
after=$(query "$SECOND" <<<'SELECT id, message FROM messages ORDER BY id;')
second_id=$("$DOCKER" inspect --format '{{.Id}}' "$SECOND")
echo "After container replacement:"
printf '%s\n' "$after"
test "$first_id" != "$second_id"
test "$before" = "$after"
echo "PASS: Both rows survived replacement with a different container using postgres-data."
echo "Original container: $first_id"
echo "Replacement container: $second_id"
"$DOCKER" inspect --format '{{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{println}}{{end}}' "$SECOND"
