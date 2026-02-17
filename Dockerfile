FROM node:22-bookworm

# Install system build essentials and python
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential procps curl file git ca-certificates \
    ffmpeg python3-full python3-pip python3-venv jq gh && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Prepare Homebrew template directory
RUN mkdir -p /opt/homebrew-template /home/linuxbrew/.linuxbrew && \
    chown -R node:node /opt/homebrew-template /home/linuxbrew/.linuxbrew
USER node
ENV PATH="/home/node/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV OPENCLAW_NO_APPROVAL_GATES=1
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    cp -a /home/linuxbrew/.linuxbrew/. /opt/homebrew-template/

# Install Bun for the 'node' user
ENV BUN_INSTALL="/home/node/.bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/home/node/.npm-global/bin:/home/node/.local/bin:/home/node/.bun/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Configure NPM for global installs without root and install ClawHub
RUN mkdir -p /home/node/.npm-global && \
    npm config set prefix '/home/node/.npm-global' && \
    npm install -g clawhub @google/gemini-cli @clawdbot/lobster

WORKDIR /app
USER root
RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY extensions ./extensions
COPY packages ./packages
COPY patches ./patches
COPY scripts ./scripts
RUN pnpm install --frozen-lockfile

# Optionally install Chromium and Xvfb for browser automation.
# Build with: docker build --build-arg OPENCLAW_INSTALL_BROWSER=1 ...
# Adds ~300MB but eliminates the 60-90s Playwright install on every container start.
# Must run after pnpm install so playwright-core is available in node_modules.
ARG OPENCLAW_INSTALL_BROWSER=""
RUN if [ -n "$OPENCLAW_INSTALL_BROWSER" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends xvfb && \
      node /app/node_modules/playwright-core/cli.js install --with-deps chromium && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

COPY . .
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production
RUN chown -R node:node /app

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run entrypoint as root to allow permission fixes
USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# The entrypoint will drop to user node via 'su'
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
