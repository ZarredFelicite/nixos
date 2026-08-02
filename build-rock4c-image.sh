#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./build-rock4c-image.sh [--plain]

Build the ROCK 4C+ SD image from this flake. By default, inject the configured
Wi-Fi profile. Use --plain to copy the reproducible image without credentials.

Environment:
  WIFI_SSID          Wi-Fi SSID (default: OpenWrt-AX3000T)
  WIFI_PASSWORD_FILE GPG-encrypted password file
  OUT_DIR            Output directory (default: <repository>/build)
EOF
}

inject_wifi=true
case "${1:-}" in
  "") ;;
  --plain) inject_wifi=false ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

need() {
  command -v "$1" >/dev/null || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

# Escape values for the GLib key-file format used by NetworkManager.
keyfile_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  value=${value// /\\s}
  printf '%s' "$value"
}

need nix
need mkdir
need realpath
need install

if [[ "$inject_wifi" == true ]]; then
  need zstd
  need zstdcat
  need gpg
  need pkexec
  need losetup
  need findmnt
  need mount
  need umount
  need mktemp
  need shred
  need head
  need cat
  need mv
  need rm
  need rmdir
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
out_dir="${OUT_DIR:-$repo_dir/build}"
umask 077
mkdir -p "$out_dir"
out_dir=$(realpath "$out_dir")

ssid="${WIFI_SSID:-OpenWrt-AX3000T}"
password_file="${WIFI_PASSWORD_FILE:-/home/zarred/sync/password-store/wifi/AX3000T.gpg}"
if [[ "$inject_wifi" == true ]]; then
  if [[ ! -f "$password_file" ]]; then
    printf 'Missing Wi-Fi password file: %s\n' "$password_file" >&2
    exit 1
  fi
  if [[ -z "$ssid" || "$ssid" == *$'\n'* || "$ssid" == *$'\r'* ]]; then
    printf 'WIFI_SSID must be non-empty and must not contain newlines\n' >&2
    exit 1
  fi
fi

store_path=$(nix build "$repo_dir#nixosConfigurations.rock4c-image.config.system.build.sdImage" \
  --no-link --print-out-paths)

src_img="$store_path/sd-image/rock4c-plus-nixos.img.zst"
if [[ ! -f "$src_img" ]]; then
  printf 'Could not find the expected built image: %s\n' "$src_img" >&2
  exit 1
fi

plain_img="$out_dir/rock4c-plus-nixos.img.zst"
if [[ "$inject_wifi" == false ]]; then
  install -m 0600 "$src_img" "$plain_img"
  printf 'Built image:\n  %s\n' "$plain_img"
  exit 0
fi

tmp_dir=$(mktemp --tmpdir="$out_dir" -d rock4c-plus-nixos-wifi.XXXXXX)
raw_img="$tmp_dir/raw.img"
compressed_tmp="$tmp_dir/compressed.img.zst"
password_tmp="$tmp_dir/password"
profile_tmp="$tmp_dir/profile"
mountpoint=""
loopdev=""

cleanup() {
  if [[ -n "$mountpoint" ]] && findmnt -rn "$mountpoint" >/dev/null 2>&1; then
    pkexec umount "$mountpoint" || true
  fi
  if [[ -n "$loopdev" ]]; then
    pkexec losetup -d "$loopdev" || true
  fi
  if [[ -f "$password_tmp" || -f "$profile_tmp" ]]; then
    shred -u "$password_tmp" "$profile_tmp" 2>/dev/null || true
  fi
  rm -f -- "$raw_img" "$compressed_tmp"
  if [[ -n "$mountpoint" ]]; then
    rmdir "$mountpoint" 2>/dev/null || true
  fi
  rmdir "$tmp_dir" 2>/dev/null || true
}
trap cleanup EXIT

: > "$raw_img"
: > "$compressed_tmp"
: > "$password_tmp"
: > "$profile_tmp"
mountpoint=$(mktemp -d)

zstdcat "$src_img" > "$raw_img"
gpg --quiet --decrypt "$password_file" > "$password_tmp"
password=$(head -n 1 "$password_tmp")
if [[ -z "$password" ]]; then
  printf 'The decrypted Wi-Fi password is empty\n' >&2
  exit 1
fi
ssid_keyfile=$(keyfile_escape "$ssid")
password_keyfile=$(keyfile_escape "$password")

cat > "$profile_tmp" <<EOF_PROFILE
[connection]
id=$ssid_keyfile
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=$ssid_keyfile

[wifi-security]
key-mgmt=wpa-psk
psk=$password_keyfile

[ipv4]
method=auto

[ipv6]
method=auto
EOF_PROFILE

loopdev=$(pkexec losetup --find --show --partscan "$raw_img")
if [[ -z "$loopdev" ]]; then
  printf 'losetup did not return a loop device\n' >&2
  exit 1
fi
pkexec mount "${loopdev}p2" "$mountpoint"
pkexec mkdir -p "$mountpoint/etc/NetworkManager/system-connections"
pkexec install -m 0600 -o root -g root "$profile_tmp" \
  "$mountpoint/etc/NetworkManager/system-connections/rock4c-wifi.nmconnection"
pkexec umount "$mountpoint"
pkexec losetup -d "$loopdev"
loopdev=""

zstd -f -T0 "$raw_img" -o "$compressed_tmp"
output="$out_dir/rock4c-plus-nixos-wifi.img.zst"
mv -f "$compressed_tmp" "$output"
printf 'Built Wi-Fi image:\n  %s\n' "$output"
