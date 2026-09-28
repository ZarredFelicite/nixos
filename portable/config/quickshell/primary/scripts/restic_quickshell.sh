#!/usr/bin/env bash
# Helper script for Quickshell Restic widget
set -u

# SSH Agent fix for Quickshell
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    for sock in "/run/user/$(id -u)/gnupg/S.gpg-agent.ssh" "/run/user/$(id -u)/ssh-agent.socket"; do
        if [ -S "$sock" ]; then
            export SSH_AUTH_SOCK="$sock"
            break
        fi
    done
fi

RESTIC_BIN=$(command -v restic || echo "/run/current-system/sw/bin/restic")

# Detect backup activity (prefer systemd state, fallback to process match)
ACTIVE_STATE=$(systemctl show -p ActiveState --value restic-backups-home.service 2>/dev/null || true)
if [ "$ACTIVE_STATE" = "active" ] || [ "$ACTIVE_STATE" = "activating" ] || pgrep -f "restic.*backup" >/dev/null; then
    BACKING_UP=true
else
    BACKING_UP=false
fi

LAST_STATUS="success"
ERROR_MSG=""
SNAPSHOTS_JSON="[]"
STATS_JSON="{}"

# Read snapshots without taking a lock so this works while backup is running
SNAPSHOTS_OUT=$($RESTIC_BIN --no-lock snapshots --json --latest 5 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ] || [ -z "$SNAPSHOTS_OUT" ]; then
    SNAPSHOTS_JSON="[]"
    ERROR_MSG="$SNAPSHOTS_OUT"
    if [ "$BACKING_UP" = true ]; then
        LAST_STATUS="running"
    else
        LAST_STATUS="error"
    fi
else
    SNAPSHOTS_JSON="$SNAPSHOTS_OUT"
    STATS_JSON=$(echo "$SNAPSHOTS_JSON" | jq '.[-1].summary | {total_size: .total_bytes_processed, total_file_count: .total_files_processed}' 2>/dev/null || echo "{}")
    if [ "$BACKING_UP" = true ]; then
        LAST_STATUS="running"
    fi
fi

jq -n \
  --argjson backingUp "$BACKING_UP" \
  --argjson snapshots "$SNAPSHOTS_JSON" \
  --argjson stats "$STATS_JSON" \
  --arg lastStatus "$LAST_STATUS" \
  --arg error "$ERROR_MSG" \
  '{
    backingUp: $backingUp,
    snapshots: $snapshots,
    stats: $stats,
    lastStatus: $lastStatus,
    error: $error
  }'
