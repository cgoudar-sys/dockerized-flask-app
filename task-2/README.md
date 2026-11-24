# Task 2: Flask and Redis visit counter
Start both services from this directory:
```sh
docker compose up --build -d
```
Open http://localhost:5000 and refresh to increment the Redis counter.
Redis data persists in a named volume.
If port 5000 is occupied by macOS AirPlay Receiver:
```sh
APP_PORT=5002 docker compose up --build -d
```
Open http://localhost:5002 and refresh. Verified locally: counter increased from 1 to 2 and Redis stored 2. Both containers were running and Redis was healthy.
```sh
docker compose ps
docker compose down
```
Stopping preserves the counter volume. This exercise uses the Flask development server.
