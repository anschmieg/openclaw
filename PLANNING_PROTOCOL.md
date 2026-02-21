# Plan-First Protocol

This protocol governs how complex tasks must be handled. It is injected into every agent session.

## When to Use Plan-First

A task is **complex** if it involves any of:
- Architectural decisions, system design, or multi-component changes
- Implementing features across multiple files or services
- Migrations, refactors, or reversals of significant scope
- Deployments, infrastructure changes, or production operations
- Tasks with more than 2 distinct subtasks

Routine tasks (single-file edits, lookups, simple Q&A) do NOT need a plan.

## Plan-First Workflow

### Step 1 — Architectural Plan (agent-high)

Before writing any code or executing any commands for a complex task:

1. Spawn a planning sub-agent with model `github-copilot/claude-opus-4.6`:
   ```
   sessions_spawn(task="Create a detailed architectural plan for: <task description>. Output: numbered steps, affected files/services, risk notes, rollback path.", model="github-copilot/claude-opus-4.6")
   ```
2. Wait for and present the plan to the user.
3. Do **not** proceed to implementation until the plan is acknowledged.

### Step 2 — Adversarial Review (claude-sonnet-4.6)

After the plan is ready, spawn an adversarial reviewer:
```
sessions_spawn(task="Review this plan critically. Identify risks, gaps, missing edge cases, and alternatives: <plan>", model="github-copilot/claude-sonnet-4.6")
```
Incorporate feedback into the plan. Present the final plan to the user.

### Step 3 — Implementation Sub-agents

Execute the approved plan via targeted sub-agents. Match model to task type:
- **Code implementation**: `github-copilot/gpt-5-mini` or `github-copilot/claude-sonnet-4.6`
- **Ops/infrastructure**: `github-copilot/gpt-4.1`
- **Research/docs**: `github-copilot/gpt-5-mini`

Each sub-agent handles one discrete portion of the plan.

## Cluster Mapping (AI Gateway)

When routing via the staging AI gateway (https://ai-staging.nothing.pink), use these clusters:
- `agent-high` → architectural planning (maps to claude-opus-4.6 or gemini-3.x-pro)
- `agent` → general agent tasks
- `coding` → code implementation
- `writing` → documentation and prose

## Mandatory Acknowledgement

For complex tasks, you MUST say:
> "This is a complex task. I'm creating a plan via agent-high before proceeding."

Then follow the 3-step workflow above.
