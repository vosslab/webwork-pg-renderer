podman build -t pg-renderer .
podman-compose down
podman-compose build --no-cache
podman-compose up -d
open "http://localhost:3000/"
echo "private/myproblem.pg"
podman logs pg-test
podman image prune
