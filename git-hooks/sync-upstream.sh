#!/usr/bin/env bash
# sync-upstream.sh — Fully automated upstream merge for this fork.
#
# Usage: git-hooks/sync-upstream.sh [upstream-ref]
#   upstream-ref: defaults to upstream/main
#
# This script:
#   1. Ensures merge drivers are registered
#   2. Fetches upstream
#   3. Merges upstream into the current branch
#   4. Auto-resolves any residual conflicts using fork policy
#   5. Commits the result
#
# Exit codes:
#   0 = success (clean merge or auto-resolved)
#   1 = unresolvable conflict (should never happen with correct .gitattributes)

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel)"
UPSTREAM_REF="${1:-upstream/main}"

echo "============================================"
echo " Fork Upstream Sync"
echo " Merging: $UPSTREAM_REF → $(git branch --show-current)"
echo "============================================"

# --- Step 1: Ensure merge drivers are registered ---
echo ""
echo "[1/5] Registering merge drivers..."
bash "$ROOT_DIR/git-hooks/setup-merge-drivers.sh"

# --- Step 2: Fetch upstream ---
echo ""
echo "[2/5] Fetching upstream..."
git fetch upstream --prune 2>&1 || { echo "WARN: Could not fetch upstream"; }

# --- Step 3: Check for uncommitted changes ---
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: You have uncommitted changes. Commit or stash them first."
  exit 1
fi

# --- Step 4: Merge ---
echo ""
echo "[3/5] Merging $UPSTREAM_REF..."
MERGE_SUCCESS=true
git merge "$UPSTREAM_REF" --no-edit -m "chore: merge upstream $(date +%Y-%m-%d)" 2>&1 || MERGE_SUCCESS=false

if [ "$MERGE_SUCCESS" = true ]; then
  echo ""
  echo "[4/5] Merge completed cleanly — no conflicts."
  echo "[5/5] Done!"
  exit 0
fi

# --- Step 5: Auto-resolve any remaining conflicts ---
echo ""
echo "[4/5] Merge had conflicts — auto-resolving..."

CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || true)

if [ -z "$CONFLICTED_FILES" ]; then
  echo "  No conflicted files found (merge driver resolved them)."
  git commit --no-edit 2>/dev/null || true
  echo "[5/5] Done!"
  exit 0
fi

echo "  Conflicted files:"
echo "$CONFLICTED_FILES" | sed 's/^/    /'

# Overlay files declared in .gitattributes
OVERLAY_PATTERNS=(
  "docker-compose.local.yml"
  "Dockerfile.local"
  "data/config/openclaw.json"
  "entrypoint.sh"
  "git-hooks/"
  "extensions/openai-codex-auth/"
  ".claude/settings.local.json"
)

UNRESOLVED=""

while IFS= read -r file; do
  [ -z "$file" ] && continue

  IS_OVERLAY=false
  for pattern in "${OVERLAY_PATTERNS[@]}"; do
    if [[ "$file" == $pattern* ]]; then
      IS_OVERLAY=true
      break
    fi
  done

  if [ "$IS_OVERLAY" = true ]; then
    echo "  → $file: overlay — keeping ours"
    git checkout --ours -- "$file" 2>/dev/null || true
    git add "$file"
  elif [ "$file" = ".gitignore" ]; then
    echo "  → $file: union-merging..."
    # Get both versions
    git show :2:.gitignore > "$ROOT_DIR/.gitignore-ours" 2>/dev/null || true
    git show :3:.gitignore > "$ROOT_DIR/.gitignore-theirs" 2>/dev/null || true
    if [ -f "$ROOT_DIR/.gitignore-ours" ] && [ -f "$ROOT_DIR/.gitignore-theirs" ]; then
      # Union: start with ours, add missing lines from theirs
      cp "$ROOT_DIR/.gitignore-ours" "$ROOT_DIR/.gitignore"
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^# ]] && continue  # skip comments from theirs
        if ! grep -qxF "$line" "$ROOT_DIR/.gitignore" 2>/dev/null; then
          echo "$line" >> "$ROOT_DIR/.gitignore"
        fi
      done < "$ROOT_DIR/.gitignore-theirs"
      rm -f "$ROOT_DIR/.gitignore-ours" "$ROOT_DIR/.gitignore-theirs"
      git add "$ROOT_DIR/.gitignore"
      echo "    .gitignore union-merged"
    else
      echo "    WARN: Could not extract merge stages for .gitignore"
      UNRESOLVED="$UNRESOLVED $file"
    fi
  elif [ "$file" = ".gitattributes" ]; then
    echo "  → $file: overlay (keeping fork's merge strategy file)"
    git checkout --ours -- "$file" 2>/dev/null || true
    git add "$file"
  else
    echo "  → $file: non-overlay — taking theirs (upstream)"
    git checkout --theirs -- "$file" 2>/dev/null || true
    git add "$file"
  fi
done <<< "$CONFLICTED_FILES"

# Clean up any temp files
rm -f "$ROOT_DIR/.gitignore-ours" "$ROOT_DIR/.gitignore-theirs" "$ROOT_DIR/.gitignore.tmp"

if [ -n "$UNRESOLVED" ]; then
  echo ""
  echo "ERROR: Could not auto-resolve these files:"
  echo "$UNRESOLVED" | tr ' ' '\n' | sed 's/^/    /'
  echo "Please resolve manually and run: git add <file> && git commit"
  exit 1
fi

# Commit the merge
echo ""
echo "[5/5] Committing merge resolution..."
git commit --no-edit 2>/dev/null || git commit -m "chore: merge upstream $(date +%Y-%m-%d)"
echo ""
echo "=== Upstream sync complete ==="
git log --oneline -1
exit 0
