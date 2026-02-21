import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";
import { isAgentBootstrapEvent, type HookHandler } from "../../src/hooks/hooks.js";

const PROTOCOL_FILENAME = "PLANNING_PROTOCOL.md";

/** Candidate paths to look for PLANNING_PROTOCOL.md */
function protocolCandidates(workspaceDir?: string): string[] {
  const candidates: string[] = [];
  if (workspaceDir) {
    candidates.push(path.join(workspaceDir, PROTOCOL_FILENAME));
  }
  // Always also check the canonical main workspace
  candidates.push(path.join(os.homedir(), ".openclaw", "workspace", PROTOCOL_FILENAME));
  return [...new Set(candidates)];
}

const planFirstHook: HookHandler = async (event) => {
  if (!isAgentBootstrapEvent(event)) {
    return;
  }

  const context = event.context;

  // Load planning protocol from first available candidate path
  let protocol: string | undefined;
  for (const candidate of protocolCandidates(context.workspaceDir)) {
    try {
      protocol = await fs.readFile(candidate, "utf-8");
      break;
    } catch {
      // try next
    }
  }

  if (!protocol) {
    return;
  }

  const protocolSection = `\n\n---\n\n${protocol.trim()}\n`;

  // Append to SOUL.md if present and protocol not already injected
  const soulEntry = context.bootstrapFiles.find((f) => f.name === "SOUL.md");
  if (soulEntry) {
    if (!soulEntry.content?.includes("Plan-First Protocol")) {
      soulEntry.content = (soulEntry.content ?? "") + protocolSection;
    }
    return;
  }

  // Fallback: append to AGENTS.md
  const agentsEntry = context.bootstrapFiles.find((f) => f.name === "AGENTS.md");
  if (agentsEntry && !agentsEntry.content?.includes("Plan-First Protocol")) {
    agentsEntry.content = (agentsEntry.content ?? "") + protocolSection;
  }
};

export default planFirstHook;
