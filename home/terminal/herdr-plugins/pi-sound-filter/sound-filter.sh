#!/usr/bin/env bash
set -euo pipefail

plugin_root=${HERDR_PLUGIN_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}
event_json=${HERDR_PLUGIN_EVENT_JSON:-}
herdr_bin=${HERDR_BIN_PATH:-herdr}

[[ -n "$event_json" ]] || exit 0

read -r pane_id agent status < <(
  jq -r '
    if .event == "pane_agent_status_changed" then
      [.data.pane_id, (.data.agent // ""), .data.agent_status] | @tsv
    else
      empty
    end
  ' <<<"$event_json"
)

[[ -n "${pane_id:-}" && "$agent" == "pi" ]] || exit 0
[[ "$status" == "done" || "$status" == "blocked" ]] || exit 0

agent_name=$(
  "$herdr_bin" agent list 2>/dev/null |
    jq -r --arg pane "$pane_id" 'first(.result.agents[] | select(.pane_id == $pane) | (.name // "")) // ""'
)

[[ "$agent_name" != subagent-* ]] || exit 0

sound=$([[ "$status" == "blocked" ]] && printf request || printf done)
sound_path="$plugin_root/sounds/$sound.mp3"

if [[ "${HERDR_SOUND_FILTER_DRY_RUN:-0}" == "1" ]]; then
  printf '%s\n' "$sound"
  exit 0
fi

if command -v pw-play >/dev/null 2>&1; then
  timeout 15s pw-play "$sound_path" >/dev/null 2>&1 && exit 0
fi
if command -v mpv >/dev/null 2>&1; then
  timeout 15s mpv --no-video --really-quiet "$sound_path" >/dev/null 2>&1 && exit 0
fi

exit 0
