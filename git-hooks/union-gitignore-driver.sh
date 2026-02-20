#!/usr/bin/env bash
# union-gitignore-driver.sh — Custom merge driver for .gitignore
#
# Called by git with: %O (ancestor) %A (ours/current) %B (theirs/upstream)
# Result must be written to %A.
#
# Policy: Keep ALL lines present in either side. Only remove a line if
# it was present in the ancestor AND removed by BOTH sides.

set -euo pipefail

ANCESTOR="$1"  # %O — common ancestor
OURS="$2"      # %A — current branch (fork)
THEIRS="$3"    # %B — incoming branch (upstream)

# Normalize: strip trailing whitespace, remove blank lines for comparison
normalize() { sed 's/[[:space:]]*$//' "$1" | grep -v '^$' | sort -u; }

# Get normalized sets
ancestor_lines=$(normalize "$ANCESTOR" 2>/dev/null || true)
ours_lines=$(normalize "$OURS")
theirs_lines=$(normalize "$THEIRS")

# Union: all lines from both sides
union_lines=$(printf '%s\n%s\n' "$ours_lines" "$theirs_lines" | sort -u)

# Lines removed by BOTH sides (present in ancestor, absent from both ours and theirs)
# Only these get actually removed from the union.
if [ -n "$ancestor_lines" ]; then
  # Lines in ancestor but not in ours
  removed_by_ours=$(comm -23 <(echo "$ancestor_lines") <(echo "$ours_lines") 2>/dev/null || true)
  # Lines in ancestor but not in theirs
  removed_by_theirs=$(comm -23 <(echo "$ancestor_lines") <(echo "$theirs_lines") 2>/dev/null || true)
  # Lines removed by BOTH
  removed_by_both=$(comm -12 <(echo "$removed_by_ours" | sort) <(echo "$removed_by_theirs" | sort) 2>/dev/null || true)
else
  removed_by_both=""
fi

# Final result: union minus lines removed by both
if [ -n "$removed_by_both" ]; then
  result=$(comm -23 <(echo "$union_lines") <(echo "$removed_by_both" | sort -u))
else
  result="$union_lines"
fi

# Reconstruct with original structure: keep ours as base, append new lines from theirs
# This preserves comments and section grouping from the fork's .gitignore
{
  # Start with our version (preserves structure/comments)
  cat "$OURS"
  echo ""
  # Add any lines from theirs that aren't already in ours
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! grep -qxF "$line" "$OURS" 2>/dev/null; then
      echo "$line"
    fi
  done <<< "$theirs_lines"
} > "${OURS}.merged"

# Remove lines that were deleted by both sides
if [ -n "$removed_by_both" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Remove exact line matches
    grep -vxF "$line" "${OURS}.merged" > "${OURS}.tmp" || true
    mv "${OURS}.tmp" "${OURS}.merged"
  done <<< "$removed_by_both"
fi

# Write result back to %A (ours) — this is what git expects
mv "${OURS}.merged" "$OURS"

exit 0
