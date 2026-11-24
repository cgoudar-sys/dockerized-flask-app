# Task 7: Multi-stage Python Flask build

Build and run from this directory:

```sh
docker build -t task7-flask .
docker run -d --name task7-flask -p 5000:5000 task7-flask
```

Open http://localhost:5000. The home route returns `Hello, Docker`.

If macOS AirPlay Receiver or another service occupies port 5000, use:

```sh
docker run -d --name task7-flask -p 5004:5000 task7-flask
```

Then open http://localhost:5004. Flask still listens on port 5000 inside the container.

The build stage installs pinned Flask and Gunicorn dependencies into `/opt/venv`
and compiles the application to check Python syntax. The runtime stage starts
from a fresh Python slim image and copies only the virtual environment and
`app.py`. It serves the application with Gunicorn using two workers and runs
as a non-root user. Build working files are not copied into the runtime stage.

```sh
curl --fail http://localhost:5004/
docker logs task7-flask
docker stop task7-flask
```

See `verification.txt` and `verification.jpg` for local validation.
