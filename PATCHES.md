# PATCHES.md

This repository uses a patches-based overlay system for OpenClaw configuration.

- Keep local, persistent customizations in `patches/*.json`.
- The CI and local script `scripts/apply-overlays.sh` compose the final
  `openclaw.json` by merging the upstream `~/.openclaw/openclaw.json` with the
  patches. Patches win on conflict.
- For complex changes that must modify upstream files, add a numbered patch
  file `patches/0001-some-change.json` describing the minimal changes needed.
- Do not edit the vendored upstream `openclaw.json` directly in the repo. Always
  place local changes as patches.

Applying patches locally

1. Run `scripts/apply-overlays.sh` to create `openclaw.json` at the repo root.
2. Run `openclaw doctor --check` to validate the composed config.

If you need to migrate an existing customization into a patch, create a new
file under `patches/` with only the keys that change and run the compose script.
