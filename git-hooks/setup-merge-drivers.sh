#!/usr/bin/env bash
# setup-merge-drivers.sh — Register all custom merge drivers for this fork.
# Run once after cloning, or any time drivers are added/changed.
# Safe to re-run (idempotent).

set -euo pipefail

echo "=== Registering fork merge drivers ==="

# 1. merge=ours — built-in, just needs to be declared.
#    Keeps the current branch's version of the file unconditionally.
git config merge.ours.name   "always keep ours (fork overlay files)"
git config merge.ours.driver "true"

# 2. merge=prefer-theirs — for all non-overlay files, accept upstream.
#    %O = ancestor, %A = ours, %B = theirs
git config merge.prefer-theirs.name   "prefer upstream/theirs for non-overlay files"
git config merge.prefer-theirs.driver "cp %B %A"

# 3. merge=union-gitignore — union merge for .gitignore.
#    Keeps all lines from both sides; only removes a line if BOTH sides removed it.
git config merge.union-gitignore.name   "union merge for .gitignore"
git config merge.union-gitignore.driver "git-hooks/union-gitignore-driver.sh %O %A %B"

echo "=== Installing hooks ==="

# Install post-merge hook
cp git-hooks/post-merge .git/hooks/post-merge 2>/dev/null || true
chmod +x .git/hooks/post-merge 2>/dev/null || true

echo "=== Done. Merge drivers registered: ==="
git config --local --get-regexp '^merge\.' || true
