#!/bin/bash
set -e

# If the persistent brew volume is empty, copy the template
if [ ! -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    echo "Initializing persistent Homebrew volume from template..."
    mkdir -p /home/linuxbrew/.linuxbrew
    cp -a /opt/homebrew-template/. /home/linuxbrew/.linuxbrew/
fi

# Ensure permissions on critical writable paths
echo "Fixing permissions for node user..."
chown -R node:node /home/linuxbrew
chown -R node:node /home/node/.openclaw
chown -R node:node /home/node/.local
chown -R node:node /home/node/.npm-global
chown -R node:node /app

# Skip /app/repo as it is a read-only mount and will cause chown to fail
# (The loop was caused by chown failing on the RO mount)

# Ensure local bin is in PATH for the whole session
export PATH="/home/node/.npm-global/bin:/home/node/.local/bin:/home/node/.bun/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

# Execute the command as the node user, preserving the environment
echo "Starting OpenClaw..."
exec su -m node -c "$*"
