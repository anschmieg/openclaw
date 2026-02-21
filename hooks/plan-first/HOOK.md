---
name: plan-first
description: "Injects the plan-first protocol into every agent bootstrap so complex tasks always go through agent-high planning before execution."
homepage: https://docs.openclaw.ai/automation/hooks
metadata:
  {
    "openclaw": {
      "emoji": "🗺️",
      "events": ["agent:bootstrap"],
      "requires": {}
    }
  }
---

# Plan-First Hook

Injects `PLANNING_PROTOCOL.md` from the workspace root into every agent's bootstrap files.

This ensures all agents receive the plan-first mandate at session start:
- Complex tasks → plan via agent-high (claude-opus-4.6) first
- Adversarial review via claude-sonnet-4.6
- Implementation via targeted sub-agents per task type

## What It Does

- Listens for `agent:bootstrap` events
- Pushes `PLANNING_PROTOCOL.md` into `context.bootstrapFiles`
- No-op if the file is already included

## Requirements

None — works with any OpenClaw workspace that has a `PLANNING_PROTOCOL.md` at root.
