#!/usr/bin/env bash
set -euo pipefail

DOCKER=${DOCKER:-docker}
IMAGE=mysql:8.4
VOLUME=task3-mysql-data
FIRST=task3-mysql-first
SECOND=task3-mysql-recreated

# Refuse existing resources so a previous run cannot produce a false success.
if "$DOCKER" volume inspect "$VOLUME" >/dev/null 2>&1; then
  echo "Volume $VOLUME already exists. Use a fresh volume name before rerunning." >&2
  exit 1
fi
for name in "$FIRST" "$SECOND"; do
  if "$DOCKER" container inspect "$name" >/dev/null 2>&1; then
    echo "Container $name already exists. Choose unused names before rerunning." >&2
    exit 1
  fi
done

# Generate credentials locally; never print or commit them.
credentials=$(mktemp)
chmod 600 "$credentials"
trap 'rm -f "$credentials"' EXIT
printf 'MYSQL_ROOT_PASSWORD=%s\nMYSQL_DATABASE=volume_demo\n' "$(openssl rand -hex 24)" > "$credentials"

wait_for_mysql() {
  local name=$1
  for ((attempt=1; attempt<=90; attempt++)); do
    if "$DOCKER" exec "$name" sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -Nse "SELECT 1"' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done
  echo "MySQL did not become ready in $name." >&2
  return 1
}

query() {
  "$DOCKER" exec -i "$1" sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot --batch --skip-column-names volume_demo'
}

"$DOCKER" pull "$IMAGE"
"$DOCKER" volume create "$VOLUME"
echo "Starting the first MySQL container with the named volume."
"$DOCKER" run -d --name "$FIRST" --env-file "$credentials" --mount "type=volume,source=$VOLUME,target=/var/lib/mysql" "$IMAGE"
wait_for_mysql "$FIRST"
query "$FIRST" <<'SQL'
CREATE TABLE messages (id INT PRIMARY KEY, message VARCHAR(100) NOT NULL);
INSERT INTO messages VALUES (1, 'Data survives container replacement'), (2, 'Stored in a Docker named volume');
SQL
before=$(query "$FIRST" <<<'SELECT id, message FROM messages ORDER BY id;')
echo "Rows before replacement:"
printf '%s\n' "$before"
first_id=$("$DOCKER" inspect --format '{{.Id}}' "$FIRST")
"$DOCKER" stop --time 30 "$FIRST"
"$DOCKER" rm "$FIRST"
echo "Starting a new MySQL container with the same volume."
"$DOCKER" run -d --name "$SECOND" --env-file "$credentials" --mount "type=volume,source=$VOLUME,target=/var/lib/mysql" "$IMAGE"
wait_for_mysql "$SECOND"
after=$(query "$SECOND" <<<'SELECT id, message FROM messages ORDER BY id;')
second_id=$("$DOCKER" inspect --format '{{.Id}}' "$SECOND")
echo "Rows after replacement:"
printf '%s\n' "$after"
test "$first_id" != "$second_id"
test "$before" = "$after"
echo "PASS: Different container IDs; both rows persisted in $VOLUME."
echo "Original container: $first_id"
echo "Replacement container: $second_id"
"$DOCKER" inspect --format '{{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{println}}{{end}}' "$SECOND"
