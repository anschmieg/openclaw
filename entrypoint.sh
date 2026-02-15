#!/bin/bash
set -e

# If the persistent brew volume is empty, copy the template
if [ ! -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    echo "Initializing persistent Homebrew volume from template..."
    mkdir -p /home/linuxbrew/.linuxbrew
    cp -a /opt/homebrew-template/. /home/linuxbrew/.linuxbrew/
fi

# Ensure permissions on ALL critical paths
echo "Fixing permissions for node user..."
chown -R node:node /home/linuxbrew
chown -R node:node /home/node/.openclaw
chown -R node:node /app

# Execute the command as the node user
echo "Starting OpenClaw..."
# We use 'runuser' or 'su' to drop privileges
exec su node -c "$*"
