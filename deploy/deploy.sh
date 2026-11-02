#!/bin/sh
# Runs on the server. Starts the given backend image and goes back to the previous one if it isn't healthy.
# Usage: deploy.sh <image@digest> <api-domain>
set -eu
image=$1
domain=$2
cd "$(dirname "$0")"

previous=$(sed -n 's/^BACKEND_IMAGE=//p' release.env 2>/dev/null || true)

start() {
  printf 'BACKEND_IMAGE=%s\nAPI_DOMAIN=%s\n' "$1" "$domain" > release.env
  docker compose --env-file release.env pull
  docker compose --env-file release.env up -d --remove-orphans
}

healthy() {
  tries=0
  while [ "$tries" -lt 30 ]; do
    if docker compose --env-file release.env exec -T caddy wget -q -O /dev/null http://api:8080/api/v1/system/ping; then
      return 0
    fi
    tries=$((tries + 1))
    sleep 2
  done
  return 1
}

start "$image"
if healthy; then
  docker image prune -f > /dev/null
  echo "Backend is healthy: $image"
  exit 0
fi

echo "Backend failed its health check. Last logs:" >&2
docker compose --env-file release.env logs --tail 30 api >&2
if [ -n "$previous" ]; then
  echo "Going back to $previous" >&2
  start "$previous"
  healthy || echo "The previous version isn't healthy either." >&2
fi
exit 1
