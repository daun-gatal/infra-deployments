#!/usr/bin/env bash
set -e

echo "📦 Installing required packages…"
apt-get update
apt-get install -y curl openssh-client gettext-base gnupg software-properties-common wget

echo "🔐 Setting up SSH for Git cloning…"
mkdir -p ~/.ssh
echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

echo "📌 Installing Terraform…"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
> /etc/apt/sources.list.d/hashicorp.list

apt-get update
apt-get install -y terraform

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

echo "✔ Environment ready."
