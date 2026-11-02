#!/bin/sh
# Every check, run by CI and by the pre-push hook. Needs OpenTofu and Docker; touches no cloud account.
set -eu
cd "$(git rev-parse --show-toplevel)"

step() { printf '\n\033[1mcheck: %s\033[0m\n' "$1"; }

step "versions.yaml names a release for each app"
for app in backend frontend; do
  grep -Eq "^$app: v[0-9]+\.[0-9]+\.[0-9]+( |$)" versions.yaml || { echo "$app needs a version such as v1.2.0" >&2; exit 1; }
done

step "OpenTofu formatting"
tofu fmt -check -recursive infra

for root in infra/*/; do
  step "OpenTofu validation: $root"
  tofu -chdir="$root" init -backend=false -input=false > /dev/null
  tofu -chdir="$root" validate
done

step "Docker Compose file"
BACKEND_IMAGE=example API_DOMAIN=example.com docker compose -f deploy/docker-compose.yml config -q --no-env-resolution

step "Caddyfile"
docker run --rm -i -e API_DOMAIN=example.com caddy:2.10-alpine \
  sh -c 'cat > /tmp/Caddyfile && caddy validate --adapter caddyfile --config /tmp/Caddyfile' < deploy/Caddyfile

step "Shell scripts"
for script in deploy/deploy.sh scripts/*.sh .githooks/pre-push; do
  sh -n "$script"
done

printf '\n\033[32mcheck: all passed.\033[0m\n'
