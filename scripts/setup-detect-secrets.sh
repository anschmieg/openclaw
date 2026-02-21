#!/usr/bin/env bash
# helper: create baseline if missing
if [ ! -f .secrets.baseline ]; then
  if command -v detect-secrets >/dev/null 2>&1; then
    detect-secrets scan > .secrets.baseline
    git add .secrets.baseline
  fi
fi
