#!/usr/bin/env bash
set -e

# NOTE: Packages (terraform, tailscale, jq, etc.) are pre-installed in the Docker image.

echo "🔐 Setting up SSH for Git cloning..."
mkdir -p ~/.ssh
echo "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
ssh-keyscan gitlab.com >> ~/.ssh/known_hosts

echo "✔ Environment ready."
