#!/usr/bin/env bash
set -euo pipefail

# Rebuild image from scratch so code changes are picked up.
podman build --no-cache --pull -t pg-renderer .

# Restart the container with the fresh image.
podman-compose down
podman-compose up -d

open "http://localhost:3000/"
echo "private/myproblem.pg"
podman logs pg-test
podman image prune -f
