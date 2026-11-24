# Task 3: Persistent MySQL storage with Docker volumes

Run the demonstration with Docker Desktop running:

```sh
bash persistence-demo.sh
```

The script uses the official `mysql:8.4` image and creates the named volume
`task3-mysql-data`. It starts MySQL with `MYSQL_DATABASE=volume_demo` and a
randomly generated `MYSQL_ROOT_PASSWORD`, mounting the volume at `/var/lib/mysql`.
Credentials are generated locally in a temporary file and are not committed.
MySQL is accessed through `docker exec`; no host database port is published.

The script inserts two rows, captures the query result, stops and removes the
first container, and creates a different container attached to the same volume.
It compares the rows before and after replacement and checks that the container
IDs differ. A successful run prints `PASS`.

The replacement container and volume are left available for inspection:

```sh
docker volume inspect task3-mysql-data
docker inspect task3-mysql-recreated
docker exec task3-mysql-recreated sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot volume_demo -e "SELECT * FROM messages;"'
```

Stop the replacement container when finished:

```sh
docker stop task3-mysql-recreated
```

The volume preserves data after container removal. The script refuses to reuse
an existing demo volume to ensure each demonstration starts with an empty database.
To repeat, choose unused volume and container names in the script.

See `verification.txt` for the captured execution results.
