#!/usr/bin/env bash
set -eu -o pipefail

config_path="${HOME:-}/.ember/config.json"
if [ -z "${HOME:-}" ] || [ ! -r "$config_path" ]; then
  printf '%s\n' 'Ember credentials unavailable' >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'Ember credentials parser unavailable' >&2
  exit 1
fi

token="$(jq -er '.webApiToken | strings | select(length > 0)' "$config_path" 2>/dev/null)" || {
  printf '%s\n' 'Ember token unavailable' >&2
  exit 1
}

case "$token" in
  *[!A-Za-z0-9._~+/=-]*)
    printf '%s\n' 'Ember token has unsafe characters' >&2
    exit 1
    ;;
esac

printf 'header = "Authorization: Bearer %s"\n' "$token" | exec curl --config - "$@"
