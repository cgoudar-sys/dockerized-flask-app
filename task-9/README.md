# Task 9: Sharing a Docker volume

This example uses two small Alpine containers to show file sharing directly.
Both mount the named volume `task9-shared-data` at `/data`.

Run with Docker running:

```sh
bash shared-volume.sh
```

The first container writes `/data/message.txt`. The second reads the message
and adds a reply. The first reads the updated file. The script checks both
messages and prints `PASS` when sharing works in both directions.

You can check the file yourself:

```sh
docker exec task9-writer cat /data/message.txt
docker exec task9-reader cat /data/message.txt
docker volume inspect task9-shared-data
```

Both containers stay running for inspection. Stop them when finished:

```sh
docker stop task9-writer task9-reader
```

The volume keeps the file after containers stop. The script expects unused
resource names and won't overwrite an existing demo volume. See
`verification.txt` for the results from the local run.
