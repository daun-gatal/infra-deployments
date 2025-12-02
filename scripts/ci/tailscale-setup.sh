#!/usr/bin/env bash
set -e

echo "🟦 Starting Tailscale…"
mkdir -p /var/run/tailscale
curl -fsSL https://tailscale.com/install.sh | sh

tailscaled \
  --tun=userspace-networking \
  --state=mem: \
  --socket=/var/run/tailscale/tailscaled.sock &

sleep 5

TAIL_HOST="gitlab-runner-${MODULE_NAME}-$(head /dev/urandom | tr -dc a-z0-9 | head -c6)"

tailscale up \
  --auth-key="${TAILSCALE_AUTH_KEY}?preauthorized=true" \
  --accept-routes \
  --hostname="$TAIL_HOST" \
  --advertise-tags=tag:git