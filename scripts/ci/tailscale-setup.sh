#!/usr/bin/env bash
set -e

echo "🟦 Starting Tailscale…"
mkdir -p /var/run/tailscale
# NOTE: Tailscale is pre-installed in the Docker image.

tailscaled \
  --tun=userspace-networking \
  --state=mem: \
  --socket=/var/run/tailscale/tailscaled.sock &

sleep 5
STATE_NAME=$(basename ${MODULE_NAME})
TAIL_HOST="gitlab-runner-${STATE_NAME}-$(head /dev/urandom | tr -dc a-z0-9 | head -c6)"

tailscale up \
  --auth-key="${TAILSCALE_AUTH_KEY}?preauthorized=true" \
  --accept-routes \
  --hostname="$TAIL_HOST" \
  --advertise-tags=tag:git