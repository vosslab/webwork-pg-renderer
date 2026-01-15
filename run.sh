#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME=pg-renderer

# Ensure PG submodule is present (required for assets under lib/PG/htdocs).
if [[ ! -d "lib/PG/htdocs" ]]; then
  echo "Initializing PG submodule..."
  git submodule update --init --recursive lib/PG
fi

# On Ctrl-C or TERM, stop the compose stack.
cleanup() {
  echo
  echo "Stopping containers..."
  podman-compose down
}
trap cleanup INT TERM

echo "Building image (cached)..."
podman build -t "${IMAGE_NAME}" .

echo "Starting containers with podman-compose..."
podman-compose up -d --force-recreate

# Optional: open the UI in a browser.
open "http://localhost:3000/health/" || true
open "http://localhost:3000/" || true
echo "Sample problem path: private/myproblem.pg"

echo
echo "Tailing logs for pg-test. Press Ctrl-C to stop and clean up."
podman logs -f pg-test
