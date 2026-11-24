#!/usr/bin/env bash
set -euo pipefail

DOCKER=${DOCKER:-docker}
volume=task9-shared-data
writer=task9-writer
reader=task9-reader

if "$DOCKER" volume inspect "$volume" >/dev/null 2>&1; then
    echo "Volume $volume already exists. Choose a new name before running again."
    exit 1
fi
for container in "$writer" "$reader"; do
    if "$DOCKER" container inspect "$container" >/dev/null 2>&1; then
        echo "Container $container already exists. Choose a new name."
        exit 1
    fi
done

"$DOCKER" volume create "$volume"
"$DOCKER" run -d --name "$writer" --mount "type=volume,source=$volume,target=/data" alpine:3.22 sleep infinity
"$DOCKER" run -d --name "$reader" --mount "type=volume,source=$volume,target=/data" alpine:3.22 sleep infinity

echo "Writing a file from $writer..."
"$DOCKER" exec "$writer" sh -c 'printf "%s\n" "Hello from the first container!" > /data/message.txt'

echo "Reading the same file from $reader:"
message=$("$DOCKER" exec "$reader" cat /data/message.txt)
printf '%s\n' "$message"
test "$message" = "Hello from the first container!"

echo "Adding a reply from $reader..."
"$DOCKER" exec "$reader" sh -c 'printf "%s\n" "Reply from the second container!" >> /data/message.txt'

echo "Reading the updated file from $writer:"
"$DOCKER" exec "$writer" cat /data/message.txt
"$DOCKER" exec "$writer" grep -Fx 'Reply from the second container!' /data/message.txt >/dev/null
echo "PASS: Both containers can read data written by the other."

"$DOCKER" inspect --format '{{.Name}}{{range .Mounts}}{{println}}{{.Type}} {{.Name}} -> {{.Destination}}{{end}}' "$writer" "$reader"
