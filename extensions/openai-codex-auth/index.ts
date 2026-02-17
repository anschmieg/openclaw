import {
  buildOauthProviderAuthResult,
  emptyPluginConfigSchema,
  type OpenClawPluginApi,
  type ProviderAuthContext,
} from "openclaw/plugin-sdk";
import { loginOpenAICodexOAuth } from "../../src/commands/openai-codex-oauth.js";

const PROVIDER_ID = "openai-codex";
const PROVIDER_LABEL = "OpenAI Codex (ChatGPT OAuth)";
const DEFAULT_MODEL = "openai-codex/gpt-5.3-codex";

const openaiCodexPlugin = {
  id: "openai-codex-auth",
  name: "OpenAI Codex Auth",
  description: "OAuth flow for OpenAI Codex (ChatGPT subscription)",
  configSchema: emptyPluginConfigSchema(),
  register(api: OpenClawPluginApi) {
    api.registerProvider({
      id: PROVIDER_ID,
      label: PROVIDER_LABEL,
      docsPath: "/providers/openai",
      auth: [
        {
          id: "oauth",
          label: "ChatGPT OAuth",
          hint: "Subscription-based access",
          kind: "oauth",
          run: async (ctx: ProviderAuthContext) => {
            const creds = await loginOpenAICodexOAuth({
              prompter: ctx.prompter,
              runtime: ctx.runtime,
              isRemote: ctx.isRemote,
              openUrl: ctx.openUrl,
            });

            if (!creds) {
              throw new Error("OpenAI OAuth cancelled or failed.");
            }

            return buildOauthProviderAuthResult({
              providerId: PROVIDER_ID,
              defaultModel: DEFAULT_MODEL,
              access: creds.access,
              refresh: creds.refresh,
              expires: creds.expires,
              email: creds.email,
            });
          },
        },
      ],
    });
  },
};

export default openaiCodexPlugin;
