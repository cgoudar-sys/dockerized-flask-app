import os

from flask import Flask
from redis import Redis
from redis.exceptions import RedisError

app = Flask(__name__)
redis = Redis(host=os.getenv("REDIS_HOST", "redis"), port=6379,
              socket_connect_timeout=2, socket_timeout=2)


@app.get("/")
def counter():
    try:
        visits = redis.incr("visits")
    except RedisError:
        return "Counter storage is temporarily unavailable. Please try again.\n", 503
    return f"Welcome! This page has been visited {visits} times.\n", 200, {"Cache-Control": "no-store"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
