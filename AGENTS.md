# AGENTS.md - Your Workspace

This folder is home. Treat it that way.

... (existing content)

## Overlay strategy for OpenClaw configuration (new process)

To minimize merge conflicts with upstream OpenClaw updates and keep local customizations
manageable, follow this overlay pattern:

1. Keep upstream OpenClaw config canonical. Do not edit `openclaw.json` vendored from upstream.
2. Put local customizations in `ops/overlays/openclaw.json`. This file contains only the keys
   you need to override or extend. Use environment variables for secrets (e.g., `${MODAL_API_KEY}`).
3. Use `scripts/apply-overlays.sh` in CI or locally to compose the final `openclaw.json` by merging
   upstream + overlays (overlay wins on conflicts).
4. For critical or complex changes that must modify upstream files, create a patch under `patches/`.
   The update workflow applies patches after merging to keep changes explicit and versioned.
5. Always run `openclaw doctor --check` and smoke tests after composing config. The auto-update CI job
   will perform these checks; run them locally before pushing.

Why this works:
- Upstream updates become simple merges (no drift) because local changes live in a separate file.
- Conflicts are reduced to overlay/patch application, which is handled in a controlled script and CI.

Updating overlays
- Modify `ops/overlays/openclaw.json` and open a PR. The CI will compose & validate.

Rollbacks and safety
- The update workflow creates PRs and runs validations; auto-merging is optional and gated by CI.
- If an automated update fails in production, the deployment should rollback to the previous tagged image.

