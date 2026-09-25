#!/usr/bin/env bash
# Keep one audio-state watcher per lock, but only for the Quickshell process
# identity that launched it.
set -eu -o pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 MODE OWNER_PID OWNER_STARTTIME" >&2
  exit 2
fi

mode=$1
owner_pid=$2
owner_start=$3
proc_root=${QUICKSHELL_WATCHER_PROC_ROOT:-/proc}
lock_dir=${QUICKSHELL_WATCHER_LOCK_DIR:-/tmp}
helper=${QUICKSHELL_AUDIO_STATE_HELPER:-/home/zarred/.config/quickshell/primary/scripts/audio-indicator-state.py}
retry_seconds=${QUICKSHELL_WATCHER_RETRY_SECONDS:-0.25}

case "$mode" in
  tts-active) lock_name=quickshell-tts-watcher.lock ;;
  tts-playing) lock_name=quickshell-tts-playing-watcher.lock ;;
  recording) lock_name=quickshell-recording-watcher.lock ;;
  *) echo "unknown watcher mode: $mode" >&2; exit 2 ;;
esac

[[ $owner_pid =~ ^[0-9]+$ && $owner_start =~ ^[0-9]+$ ]] || exit 2

owner_is_live() {
  local stat tail state start
  [[ -r "$proc_root/$owner_pid/stat" ]] || return 1
  IFS= read -r stat < "$proc_root/$owner_pid/stat" || return 1
  tail=${stat##*) }
  read -r state _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ start _ <<< "$tail" || return 1
  [[ $state != Z && $state != X && $start == "$owner_start" ]]
}

exec 9>"$lock_dir/$lock_name"
while owner_is_live; do
  if flock -n 9; then
    break
  fi
  sleep "$retry_seconds"
done
owner_is_live || exit 0

prev=
while owner_is_live; do
  state=$($helper "$mode") || state=inactive
  if [[ $mode == recording || $state != "$prev" ]]; then
    printf '%s\n' "$state"
    prev=$state
  fi

  if [[ $mode == tts-active ]]; then
    sleep "$retry_seconds"
  else
    marker=quickshell-tts-playing
    [[ $mode == recording ]] && marker=audio_recording_running.tmp
    # A timeout bounds how long an inotify child can outlive its Quickshell owner.
    timeout 1s inotifywait -q -e create,delete,modify "$lock_dir/" \
      --include "$marker" 9>&- >/dev/null 2>&1 || sleep "$retry_seconds"
  fi
done
