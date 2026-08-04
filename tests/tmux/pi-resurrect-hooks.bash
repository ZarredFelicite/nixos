#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
enrich="$root/home/cli/tmux/pi-resurrect-enrich-save"
restore="$root/home/cli/tmux/pi-resurrect-post-restore"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_eq() { [[ "$1" == "$2" ]] || fail "expected <$2>, got <$1>"; }
assert_file_contains() { grep -Fq -- "$2" "$1" || { printf '%s\n' "--- $1 ---" >&2; cat "$1" >&2; fail "<$2> not found in $1"; }; }

setup() {
  test_root="$(mktemp -d "${TMPDIR:-/tmp}/pi-resurrect-test.XXXXXX")"
  export HOME="$test_root/home"
  export XDG_STATE_HOME="$HOME/.local/state"
  export PATH="$test_root/bin:$PATH"
  mkdir -p "$HOME/.config/pi/agent/sessions" "$XDG_STATE_HOME/pi-tmux-sessions" "$test_root/bin"
  cat > "$test_root/bin/tmux" <<'FAKE_TMUX'
#!/usr/bin/env bash
set -euo pipefail
state="${FAKE_TMUX_STATE:?}"
log="${FAKE_TMUX_LOG:?}"
args=()
while (($#)); do
  case "$1" in
    -S) shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
key_for_target() {
  local target="$1"
  awk -F'|' -v target="$target" '$1 == target { print; exit }' "$state"
}
if [[ "${args[0]:-}" == "display-message" ]]; then
  target=""; format=""
  while ((${#args[@]})); do
    case "${args[0]}" in
      -t) target="${args[1]}"; args=("${args[@]:2}") ;;
      -p) args=("${args[@]:1}") ;;
      display-message) args=("${args[@]:1}") ;;
      *) format="${args[0]}"; args=("${args[@]:1}") ;;
    esac
  done
  row="$(key_for_target "$target")"
  IFS='|' read -r _ current pane_id cwd <<< "$row"
  printf 'display|%s|%s\n' "$target" "$format" >> "$log"
  case "$format" in
    '#{pane_current_command}') printf '%s\n' "$current" ;;
    '#{pane_id}') printf '%s\n' "$pane_id" ;;
    '#{pane_current_path}') printf '%s\n' "$cwd" ;;
  esac
  exit 0
fi
if [[ "${args[0]:-}" == "respawn-pane" ]]; then
  target=""; command=""
  while ((${#args[@]})); do
    case "${args[0]}" in
      -t) target="${args[1]}"; args=("${args[@]:2}") ;;
      -c) args=("${args[@]:2}") ;;
      -k) args=("${args[@]:1}") ;;
      *) command="${args[0]}"; args=("${args[@]:1}") ;;
    esac
  done
  printf 'respawn|%s|%s\n' "$target" "$command" >> "$log"
  awk -F'|' -v target="$target" 'BEGIN { OFS="|" } $1 == target {$2="pi"} { print }' "$state" > "$state.tmp"
  mv "$state.tmp" "$state"
  exit 0
fi
exit 1
FAKE_TMUX
  chmod +x "$test_root/bin/tmux"
  trap 'rm -rf "$test_root"' EXIT
}

session_file() {
  local name="$1"
  printf '%s\n' '{"type":"session_info","name":"'$name'"}' > "$HOME/.config/pi/agent/sessions/$name.jsonl"
  printf '%s/.config/pi/agent/sessions/%s.jsonl\n' "$HOME" "$name"
}

meta() {
  local pane_id="$1" session_file_path="$2" cwd="$3"
  python3 - "$pane_id" "$session_file_path" "$cwd" <<'PY'
import base64, json, os, sys
pane, session, cwd = sys.argv[1:]
key = base64.urlsafe_b64encode(pane.encode()).decode().rstrip('=')
path = os.path.join(os.environ['XDG_STATE_HOME'], 'pi-tmux-sessions', key + '.json')
with open(path, 'w') as f:
    json.dump({'tmuxPane': pane, 'sessionFile': session, 'cwd': cwd,
               'restartCommand': f'cd {cwd} && pi --session {session}'}, f)
PY
}

make_row() {
  local session="$1" window="$2" index="$3" cwd="$4" pane_command="$5" full="$6"
  printf 'pane\t%s\t%s\t1\t:\t%s\ttransient\t:%s\t1\t%s\t:%s\n' \
    "$session" "$window" "$index" "$cwd" "$pane_command" "$full"
}

run_restore() {
  FAKE_TMUX_STATE="$test_root/state" FAKE_TMUX_LOG="$test_root/log" "$restore" "$test_root/save"
}

test_wrong_running_pi_respawns_exact_command() {
  setup
  cwd="$test_root/work"; mkdir -p "$cwd"
  session="$(session_file exact)"
  printf 'work:1.0|pi|%%1|%s\n' "$cwd" > "$test_root/state"
  meta '%1' "$(session_file old)" "$cwd"
  make_row work 1 0 "$cwd" pi "pi --session $session" > "$test_root/save"
  : > "$test_root/log"
  run_restore
  assert_file_contains "$test_root/log" "respawn|work:1.0|pi --session $session"
}

test_correct_pi_is_skipped() {
  setup
  cwd="$test_root/work"; mkdir -p "$cwd"
  session="$(session_file exact)"
  printf 'work:1.0|pi|%%1|%s\n' "$cwd" > "$test_root/state"
  meta '%1' "$session" "$cwd"
  make_row work 1 0 "$cwd" pi "pi --session $session" > "$test_root/save"
  : > "$test_root/log"
  run_restore
  run_restore
  ! grep -q '^respawn|' "$test_root/log" || fail 'correct Pi was respawned'
}

test_no_pane_index_fallback() {
  setup
  cwd="$test_root/work"; mkdir -p "$cwd"
  printf 'work:1.0|zsh|%%0|%s\nwork:1.1|pi|%%1|%s\n' "$cwd" "$cwd" > "$test_root/state"
  make_row work 1 0 "$cwd" pi "" > "$test_root/save"
  : > "$test_root/log"
  run_restore
  ! grep -q '^respawn|' "$test_root/log" || fail 'unexpected pane-index fallback respawn'
  ! grep -q 'work:1.1' "$test_root/log" || fail 'inspected fallback pane'
}

test_zsh_colon_pi_enriches_without_corruption() {
  setup
  cwd="$test_root/work"; mkdir -p "$cwd"
  session="$(session_file exact)"
  printf 'work:1.0|zsh|%%9|%s\n' "$cwd" > "$test_root/state"
  meta '%9' "$session" "$cwd"
  printf 'window\twork\t1\t:name\n' > "$test_root/save"
  make_row work 1 0 "$cwd" zsh "pi --session $session" >> "$test_root/save"
  cp "$test_root/save" "$test_root/original"
  FAKE_TMUX_STATE="$test_root/state" FAKE_TMUX_LOG="$test_root/log" "$enrich" "$test_root/save"
  assert_file_contains "$test_root/save" "$cwd && pi --session $session"
  assert_file_contains "$test_root/save" $'window\twork\t1\t:name'
  [[ "$(wc -l < "$test_root/save")" -eq 2 ]] || fail 'row count changed'
}

test_wrong_running_pi_respawns_exact_command
test_correct_pi_is_skipped
test_no_pane_index_fallback
test_zsh_colon_pi_enriches_without_corruption
printf '%s\n' 'tmux Pi resurrect regression tests: PASS'
