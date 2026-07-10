# Pi 0.79.3 → 0.80.6: Extension/RPC Changes

## Extensions

- New lifecycle event: `agent_settled`
  - Fires after an agent run is fully settled/idle, not just ended.
  - Also exposed over RPC.

- New provider hook: `before_provider_headers`
  - Extensions can inject or modify provider request headers before requests.

- Entry renderers
  - Extensions can render persisted, display-only session entries in interactive mode.
  - These entries are not sent to model context.

- `session_info_changed` event
  - Extensions can observe session name/metadata changes.

- Inline extensions
  - Added `InlineExtension` type for named inline extension factories.

- Tool-change timing fix
  - Extension tool changes now apply before the next provider request in the same agent run.
  - Also preserves `before_agent_start` system-prompt overrides.

- Extension startup/crash UX
  - Extension-related startup failures now suggest restarting with `pi -ne`.

- Extension package commands fix
  - `pi list`, `pi install`, and `pi update` now terminate even if an extension leaves background handles open.

- Docs/example fixes
  - Clarified `pi.getActiveTools()` returns names, `pi.getAllTools()` returns metadata.
  - Question/questionnaire extension examples wrap long text better.
  - Question example handles multiple questions in one assistant turn sequentially.

## RPC

- New RPC commands
  - `get_entries`: read session entries.
  - `get_tree`: read session tree snapshots.

- `./rpc-entry` package export
  - Lets integrations launch Pi directly in RPC mode.

- `agent_settled` over RPC
  - RPC clients can wait for fully settled agent runs.

- `max` thinking support
  - RPC supports the new `max` thinking level.

## SDK / Provider-Facing Changes Relevant to Extensions

- Public SDK exports for model resolution
  - CLI-equivalent model/scoped-model resolution is now exported.

- `pi-ai` API migration
  - Old global API moved from `@earendil-works/pi-ai` to `@earendil-works/pi-ai/compat`.
  - Runtime extensions still work via loader alias, but typed extension source should migrate.

- Removed base entrypoints
  - Removed `@earendil-works/pi-ai/base` and `@earendil-works/pi-agent-core/base`.
  - Use root packages with explicit `Models` provider factories.

- Custom provider/model config fixes
  - `models.json` stored credentials can satisfy auth without duplicate `apiKey`.
  - `modelOverrides` now apply to extension-registered provider models.
  - Custom model costs support input-token pricing tiers.
  - Plain uppercase API keys/headers stay literals; env vars now need explicit `$ENV_VAR`.
