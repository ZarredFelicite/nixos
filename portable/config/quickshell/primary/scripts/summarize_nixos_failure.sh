#!/usr/bin/env bash
# Summarize a nixos-upgrade.service failure into one short sentence.
# Reads the systemd error text from stdin, prints the summary to stdout.
# Diagnostic info goes to stderr.

set -u
LOG=/tmp/qs-nixos-summary.log
{
  printf -- '--- %s pid=%d ---\n' "$(date -Iseconds)" "$$"
  printf 'PATH=%s\n' "$PATH"
} >> "$LOG"

OPENAI_API_KEY="$(cat /run/secrets/openai-api 2>/dev/null || true)"
export OPENAI_API_KEY
printf 'key_len=%d\n' "${#OPENAI_API_KEY}" >> "$LOG"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "no openai api key available" >&2
  exit 2
fi

tmp="$(mktemp --suffix=.txt /tmp/qs-nixos-upgrade-err.XXXXXX)"
trap 'rm -f "$tmp"' EXIT

# 1) Last 250 lines of the nixos-upgrade.service journal — contains the
#    real nix build output, not just the systemd wrapper.
{
  echo "=== nixos-upgrade.service journal (tail) ==="
  journalctl -u nixos-upgrade.service --no-pager -o cat -n 250 2>/dev/null
} > "$tmp"

# 2) Find the FIRST derivation that actually failed (builder error, not a
#    cascade "dependency failed") and append its build log.
fail_drv="$(awk '
  /^error: Cannot build / {
    match($0, /\/nix\/store\/[a-z0-9]+-[^ '\'']+\.drv/)
    if (RSTART) drv = substr($0, RSTART, RLENGTH)
    next
  }
  /Reason: builder failed/ {
    if (drv) { print drv; exit }
  }
' "$tmp")"
# Fallback: any .drv mentioned, last one wins.
if [ -z "$fail_drv" ]; then
  fail_drv="$(grep -oE "/nix/store/[a-z0-9]+-[^ ']+\.drv" "$tmp" | head -1)"
fi
if [ -n "$fail_drv" ] && command -v nix >/dev/null 2>&1; then
  {
    echo
    echo "=== nix log $fail_drv (tail) ==="
    nix log "$fail_drv" 2>/dev/null | tail -120
  } >> "$tmp"
fi

# 3) Fallback: if journal was empty (e.g. no permission), use whatever the
#    caller passed in (argv or stdin) so we still produce something.
if [ ! -s "$tmp" ]; then
  if [ "$#" -ge 1 ]; then
    printf '%s' "$1" > "$tmp"
  else
    cat > "$tmp"
  fi
fi
printf 'wrote err size=%d to %s fail_drv=%s\n' \
  "$(stat -c %s "$tmp")" "$tmp" "${fail_drv:-none}" >> "$LOG"

out="$(python3 /home/zarred/scripts/ai/summarizer.py "$tmp" \
  --content-only --length short --timeout 30 --retries 0 \
  --prompt "This is the systemd journal for a failed nixos-upgrade.service run. Find the SPECIFIC underlying failure from the nix/nixos-rebuild output and report it in ONE short sentence (under 110 chars). Cite the actual cause: the failing builder/derivation name, the HTTP error and URL, the syntax/eval error and file, the missing file, the git/flake fetch error, etc. Do NOT say generic things like 'a dependency failed', 'build failed', 'service failed', or 'exit code 1' — those are the wrapper, not the cause. If you literally cannot find a concrete cause, output the most specific error line verbatim. No preamble, no quotes." \
  </dev/null 2>&1)"
rc=$?

printf 'summarizer rc=%d out_len=%d\n' "$rc" "${#out}" >> "$LOG"
printf 'out=%s\n' "$out" >> "$LOG"

if [ $rc -ne 0 ]; then
  echo "$out" >&2
  exit $rc
fi

printf '%s\n' "$out"
