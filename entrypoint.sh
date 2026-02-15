#!/bin/bash
set -e

# If the persistent brew volume is empty, copy the template
if [ ! -d "/home/linuxbrew/.linuxbrew/bin" ]; then
    echo "Initializing persistent Homebrew volume from template..."
    # Ensure destination is owned by node so cp can write to it
    mkdir -p /home/linuxbrew/.linuxbrew
    chown -R node:node /home/linuxbrew
    # Copy as node user
    su node -c "cp -a /opt/homebrew-template/. /home/linuxbrew/.linuxbrew/"
fi

# Fix ownership on config and workspace
echo "Ensuring permissions for /home/node/.openclaw..."
mkdir -p /home/node/.openclaw/workspace
chown -R node:node /home/node/.openclaw

# Execute the command as the node user
# (CMD in Dockerfile is node openclaw.mjs gateway ...)
echo "Starting OpenClaw..."
exec su node -c "$*"
