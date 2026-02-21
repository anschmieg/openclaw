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

If you want, I can add a template pre-commit hook that runs detect-secrets and prevents commits containing common API key patterns. Ask and I'll create it and wire it into the repo.
