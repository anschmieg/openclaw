# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## Security guidance (added)

Do NOT store secrets (API keys, tokens, passwords) in workspace files, memory dumps, or notes that are tracked by Git. Follow these rules to avoid accidental leaks:

- Keep secrets in environment variables (example: MISTRAL_API_KEY) or a secrets manager (1Password, Vault).
- Never paste live tokens into memory/*.md, BOOTSTRAP.md, HEARTBEAT.md, or other workspace notes.
- Add any local-only files that might contain secrets to .gitignore (for example, memory/*.md if you intentionally keep private notes).
- Use secret-scanning tools in CI or pre-commit hooks to block commits with secrets. Examples: GitHub Secret Scanning, pre-commit hooks using detect-secrets or truffleHog.
- When a secret is exposed, rotate/revoke it immediately and scrub the repository history (git filter-repo / BFG / git filter-branch) before pushing.

Quick checklist before committing:
- Did I copy/paste an API key or token into a file? If yes — remove it and put it into an environment variable.
- Is the file I changed intended to be public or pushed upstream? If yes — double-check for secrets.
- If unsure, run a local secret scan (detect-secrets) before commit.

## GitHub CLI & GH_TOKEN (how to use safely)

- Do NOT store GH_TOKEN or any PAT in repository files. Store it in an environment variable on the machine or CI where it will be used:
  - export GH_TOKEN="<your_token_here>"
- To authenticate the GitHub CLI locally use:
  - echo "$GH_TOKEN" | gh auth login --with-token
  - Or: gh auth login --with-token < ~/.gh_token (if you keep it on a secure local file, ensure it's in .gitignore)
- For non-interactive pushes from CI, provide the token as an environment secret (do not hardcode it into scripts or files).

If you want, run the detect-secrets setup script and pre-commit install to prevent accidental commits.

If you want a short example of a safe push using GH_TOKEN (local machine), I can add it below — but I will never embed a real token into repository files.

If you want, I can also add CONTRIBUTING.md with a short section about secrets and GH_TOKEN usage.
