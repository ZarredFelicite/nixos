#!/usr/bin/env bash
set -euo pipefail

readonly PRIMARY_FPR=1504329BCE4AE308C2218F2CD276AC444633E146
readonly PRIMARY_GRIP=13A4FEE773790871433DF46D116C7AE1C597FBDC
readonly AUTH_SUBKEY_FPR=5C628F1B3672EB69C75353184DB986A6D8C648AB
readonly AUTH_SUBKEY_GRIP=BEF3920E6B79FF4A4F817838844F26D1BCAE35C9

fail() {
  printf 'Titan GPG auth-subkey import refused: %s\n' "$1" >&2
  exit 1
}

[[ $# -eq 1 ]] || fail 'expected the SOPS runtime-secret path'
secret_file=$1
[[ -n ${GNUPGHOME:-} && -d $GNUPGHOME ]] || fail 'GNUPGHOME must name the intended user keyring'
[[ -r $secret_file ]] || fail 'SOPS runtime secret is unavailable'

# Parse only public fingerprints, keygrips, and capability metadata. The
# show-only/dry-run preflight reads the protected packet stream without import.
check_metadata() {
  local kind=$1 output

  case "$kind" in
    payload)
      output=$(gpg --homedir "$GNUPGHOME" --no-options --batch --no-tty \
        --pinentry-mode error --with-colons --with-keygrip \
        --import-options show-only --dry-run --import "$secret_file" 2>/dev/null) \
        || return 1
      ;;
    keyring)
      output=$(gpg --homedir "$GNUPGHOME" --no-options --batch --no-tty \
        --with-colons --with-keygrip --list-keys "$PRIMARY_FPR" 2>/dev/null) \
        || return 1
      ;;
    *) return 1 ;;
  esac

  printf '%s\n' "$output" | python3 -c '
import sys
mode, primary_fpr, primary_grip, auth_fpr, auth_grip = sys.argv[1:]
records = []
primary = None
current = None
for line in sys.stdin:
    fields = line.rstrip("\n").split(":")
    tag = fields[0]
    if tag in ("pub", "sec"):
        current = {"tag": tag, "fpr": "", "grip": "", "caps": "", "parent": ""}
        records.append(current)
        primary = current
    elif tag in ("sub", "ssb"):
        current = {"tag": tag, "fpr": "", "grip": "", "caps": "", "parent": primary["fpr"] if primary else ""}
        if len(fields) > 11:
            current["caps"] = fields[11]
        records.append(current)
    elif tag == "fpr" and current is not None and not current["fpr"] and len(fields) > 9:
        current["fpr"] = fields[9]
        if current["tag"] in ("pub", "sec"):
            primary = current
    elif tag == "grp" and current is not None and len(fields) > 9:
        current["grip"] = fields[9]

primaries = [r for r in records if r["tag"] in ("pub", "sec") and r["fpr"] == primary_fpr and r["grip"] == primary_grip]
auth = [r for r in records if r["tag"] in ("sub", "ssb") and r["parent"] == primary_fpr and r["fpr"] == auth_fpr and r["grip"] == auth_grip and "a" in r["caps"] and "s" in r["caps"]]
if len(primaries) != 1 or len(auth) != 1:
    raise SystemExit(1)
if mode == "payload":
    secret_subkeys = [r for r in records if r["tag"] == "ssb"]
    if primaries[0]["tag"] != "sec" or auth[0]["tag"] != "ssb":
        raise SystemExit(1)
    if len(secret_subkeys) != 1 or secret_subkeys[0] is not auth[0]:
        raise SystemExit(1)
elif mode == "keyring":
    if primaries[0]["tag"] != "pub" or auth[0]["tag"] != "sub":
        raise SystemExit(1)
else:
    raise SystemExit(1)
' "$kind" "$PRIMARY_FPR" "$PRIMARY_GRIP" "$AUTH_SUBKEY_FPR" "$AUTH_SUBKEY_GRIP"
}

# A secret packet for another key/subkey must not be imported accidentally.
check_metadata payload || fail 'SOPS payload does not match the one expected auth-capable subkey'

agent_key_state() {
  local grip=$1 response last_line rc=0
  response=$(gpg-connect-agent --homedir "$GNUPGHOME" "HAVEKEY $grip" /bye 2>/dev/null) || rc=$?
  last_line=${response##*$'\n'}
  case "$last_line" in
    'ERR 67108881 No secret key'*) printf absent ;;
    OK) [[ $rc -eq 0 ]] || return 2; printf present ;;
    *) return 2 ;;
  esac
}

primary_state=$(agent_key_state "$PRIMARY_GRIP") || fail 'could not safely query primary-key availability'
[[ $primary_state == absent ]] || fail 'primary private key is already available; parent review required'

auth_state=$(agent_key_state "$AUTH_SUBKEY_GRIP") || fail 'could not safely query auth-subkey availability'
if [[ $auth_state == present ]]; then
  check_metadata keyring || fail 'existing public key metadata does not match the expected auth subkey'
  printf 'Titan GPG auth subkey is already provisioned.\n'
  exit 0
fi

# Import is noninteractive by design. Pinentry is forbidden; a passphrase
# prompt here is an error, not something to surface during boot or login.
if ! gpg --homedir "$GNUPGHOME" --no-options --batch --no-tty \
  --pinentry-mode error --import "$secret_file" >/dev/null 2>&1; then
  fail 'GPG import failed (raw GPG output suppressed)'
fi

check_metadata keyring || fail 'imported public key metadata does not match the expected auth subkey'
auth_state=$(agent_key_state "$AUTH_SUBKEY_GRIP") || fail 'could not verify imported auth-subkey availability'
[[ $auth_state == present ]] || fail 'import completed but the expected auth subkey is unavailable'
primary_state=$(agent_key_state "$PRIMARY_GRIP") || fail 'could not verify primary-key availability after import'
[[ $primary_state == absent ]] || fail 'primary private key became available; parent review required'

printf 'Titan GPG auth subkey imported; passphrase unlock is deferred until explicit key use.\n'
