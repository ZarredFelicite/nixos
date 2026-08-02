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
  OUT_DIR            Output directory (default: ./build)
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

need nix
need zstd
need zstdcat
need install

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
out_dir="${OUT_DIR:-$repo_dir/build}"
mkdir -p "$out_dir"
out_dir=$(realpath "$out_dir")
umask 077

store_path=$(nix build "$repo_dir#nixosConfigurations.rock4c-image.config.system.build.sdImage" \
  --no-link --print-out-paths)

src_img=""
for candidate in "$store_path"/sd-image/*.img.zst; do
  if [[ -f "$candidate" ]]; then
    src_img="$candidate"
    break
  fi
done
if [[ -z "$src_img" ]]; then
  printf 'Could not find a built .img.zst under %s/sd-image\n' "$store_path" >&2
  exit 1
fi

plain_img="$out_dir/rock4c-plus-nixos.img.zst"
if [[ "$inject_wifi" == false ]]; then
  install -m 0600 "$src_img" "$plain_img"
  printf 'Built image:\n  %s\n' "$plain_img"
  exit 0
fi

need gpg
need pkexec
need losetup
need findmnt
need mount

ssid="${WIFI_SSID:-OpenWrt-AX3000T}"
password_file="${WIFI_PASSWORD_FILE:-/home/zarred/sync/password-store/wifi/AX3000T.gpg}"
if [[ ! -f "$password_file" ]]; then
  printf 'Missing Wi-Fi password file: %s\n' "$password_file" >&2
  exit 1
fi

raw_img=$(mktemp --tmpdir="$out_dir" rock4c-plus-nixos-wifi.XXXXXX.img)
compressed_tmp=$(mktemp --tmpdir="$out_dir" rock4c-plus-nixos-wifi.XXXXXX.img.zst)
password_tmp=$(mktemp)
profile_tmp=$(mktemp)
mountpoint=$(mktemp -d)
loopdev=""

cleanup() {
  if findmnt -rn "$mountpoint" >/dev/null 2>&1; then
    pkexec umount "$mountpoint" || true
  fi
  if [[ -n "$loopdev" ]]; then
    pkexec losetup -d "$loopdev" || true
  fi
  shred -u "$password_tmp" "$profile_tmp" 2>/dev/null || true
  unlink "$raw_img" 2>/dev/null || true
  unlink "$compressed_tmp" 2>/dev/null || true
  rmdir "$mountpoint" 2>/dev/null || true
}
trap cleanup EXIT

zstdcat "$src_img" > "$raw_img"
gpg --quiet --decrypt "$password_file" > "$password_tmp"
password=$(head -n 1 "$password_tmp")

cat > "$profile_tmp" <<EOF_PROFILE
[connection]
id=$ssid
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=$ssid

[wifi-security]
key-mgmt=wpa-psk
psk=$password

[ipv4]
method=auto

[ipv6]
method=auto
EOF_PROFILE

loopdev=$(pkexec losetup --find --show --partscan "$raw_img")
pkexec mount "${loopdev}p2" "$mountpoint"
pkexec mkdir -p "$mountpoint/etc/NetworkManager/system-connections"
pkexec install -m 0600 -o root -g root "$profile_tmp" \
  "$mountpoint/etc/NetworkManager/system-connections/${ssid}.nmconnection"
pkexec umount "$mountpoint"
pkexec losetup -d "$loopdev"
loopdev=""

zstd -f -T0 "$raw_img" -o "$compressed_tmp"
output="$out_dir/rock4c-plus-nixos-wifi.img.zst"
mv -f "$compressed_tmp" "$output"
printf 'Built Wi-Fi image:\n  %s\n' "$output"
