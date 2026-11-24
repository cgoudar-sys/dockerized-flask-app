# Dockerized Flask application

Prerequisite: Install and start Docker Desktop (or another Docker engine).

From this directory, build the image:

```sh
docker build -t welcome-flask .
```

Run the container on port 5000:

```sh
docker run --detach --name welcome-flask -p 5000:5000 welcome-flask
```

Open http://localhost:5000 in your browser. Expected response:

```text
Welcome to the Dockerized Flask Application!
```

You can also check it from the terminal:

```sh
curl --fail http://localhost:5000/
```

Stop and remove the container when finished:

```sh
docker stop welcome-flask
docker rm welcome-flask
```

This exercise uses Flask's development server for local testing.
