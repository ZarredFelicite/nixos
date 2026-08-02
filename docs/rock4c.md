# ROCK 4C+ build and deployment

This documents the repository's Radxa ROCK 4C+ NixOS SD-image workflow. The
build target is `nixosConfigurations.rock4c-image`; the running host target is
`nixosConfigurations.rock4c`.

## What the image contains

- A compressed, MBR-partitioned aarch64 SD image named
  `rock4c-plus-nixos.img.zst`.
- A 64 MiB FAT partition beginning at 32 MiB and an ext4 root partition
  labeled `NIXOS_SD`.
- Rockchip U-Boot written at sectors 64 and 16384. The image uses generic
  extlinux-compatible boot support, not GRUB or systemd-boot.
- The shared host configuration: hostname `rock4c`, NetworkManager, SSH,
  Avahi/mDNS, Tailscale, the `end0` Ethernet profile, and the AP6256 reset
  handling.
- A serial console kernel parameter of `console=ttyS2,1500000n8`.

The helper builds and copies images; it does **not** flash an SD card.

## Relevant files

| File | Purpose |
| --- | --- |
| [`build-rock4c-image.sh`](../build-rock4c-image.sh) | Builds the image and optionally injects Wi-Fi credentials. |
| [`flake.nix`](../flake.nix) | Defines the `rock4c` and `rock4c-image` targets. |
| [`hosts/rock4c.nix`](../hosts/rock4c.nix) | Shared host hardware, networking, services, users, and AP6256 setup. |
| [`images/rock4c-sd-image.nix`](../images/rock4c-sd-image.nix) | Adds the aarch64 SD-image module and Rockchip image layout/U-Boot writes. |
| [`home/hosts/rock4c.nix`](../home/hosts/rock4c.nix) | Headless user configuration, including the `rebuild` alias. |

## Prerequisites

Run the build from this checkout with:

- Nix with flakes and an aarch64 Linux build capability. The `web` host in
  this repository provides this with `nix.settings.extra-platforms = [
  "aarch64-linux" ]` and `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`.
  Use an equivalent native aarch64 builder or binfmt-enabled host elsewhere;
  this repository does not define a separate remote builder for this script.
- For `--plain`, the script checks for `nix`, `mkdir`, `realpath`, and `install`.
- The default Wi-Fi build additionally checks for `zstd`, `zstdcat`, `gpg`,
  `pkexec`, `losetup`, `findmnt`, `mount`, `umount`, `mktemp`, `shred`,
  `head`, `cat`, `mv`, `rm`, and `rmdir`.
- For flashing, also have `lsblk` and `dd`; use `pkexec` for the privileged
  write, never `sudo`.
- For the default build, a readable GPG-encrypted password file and access to
  its matching private key. GPG may prompt through the configured agent for a
  passphrase.

Check the script's own usage text before building:

```bash
./build-rock4c-image.sh --help
```

## Build an image

From the repository root:

```bash
# Reproducible image without a Wi-Fi profile or credentials.
./build-rock4c-image.sh --plain

# Image with a NetworkManager Wi-Fi profile injected.
./build-rock4c-image.sh
```

The script runs the following flake build internally:

```bash
nix build "$repo_dir#nixosConfigurations.rock4c-image.config.system.build.sdImage" \
  --no-link --print-out-paths
```

The outputs are written under `OUT_DIR` (default: `<repository>/build`). Unless
stated otherwise, commands below assume this default:

- `rock4c-plus-nixos.img.zst` for `--plain`
- `rock4c-plus-nixos-wifi.img.zst` for the default build

Supported environment variables:

| Variable | Default | Notes |
| --- | --- | --- |
| `WIFI_SSID` | `OpenWrt-AX3000T` | Must be non-empty and contain no newline or carriage return. |
| `WIFI_PASSWORD_FILE` | `/home/zarred/sync/password-store/wifi/AX3000T.gpg` | GPG-encrypted file; only its first decrypted line is used. |
| `OUT_DIR` | `<repository>/build` | Output directory. |

For example:

```bash
WIFI_SSID='my-network' \
WIFI_PASSWORD_FILE="$HOME/path/to/password.gpg" \
OUT_DIR="$PWD/build" \
  ./build-rock4c-image.sh
```

## Credential handling

The default build decrypts the password file and writes a WPA-PSK
NetworkManager profile to:

```text
etc/NetworkManager/system-connections/rock4c-wifi.nmconnection
```

That profile contains the password in plaintext. Temporary password and
profile files are shredded during cleanup, but the final
`rock4c-plus-nixos-wifi.img.zst` still contains the credential. The script uses
`umask 077`, and both final output variants are mode `0600`; with the default
output directory, verify with:

```bash
stat -c '%a %n' build/*.img.zst
```

Keep Wi-Fi images local, do not commit them, and remove them when no longer
needed. `build/` is ignored by this repository. Use `--plain` when credentials
are not required.

## Identify and flash the SD card

Flashing overwrites the selected device. Identify the whole microSD device,
not one of its partitions:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,MOUNTPOINTS
```

A safe approach is to run `lsblk` before and after inserting the card and
compare the newly appearing device. Confirm the model, serial, and size.
Replace `/dev/sdX` below only with that whole microSD device.

Inspect the selected device again. For every mounted partition shown, unmount
it individually—for example, `pkexec umount /dev/sdX1`—then rerun `lsblk` and
confirm the `MOUNTPOINTS` column is empty:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,SIZE,TYPE,MOUNTPOINTS /dev/sdX
```

The following command assumes the default `OUT_DIR=build` and permanently
overwrites `/dev/sdX`:

```bash
zstdcat build/rock4c-plus-nixos-wifi.img.zst \
  | pkexec dd of=/dev/sdX bs=4M status=progress conv=fsync
```

Use `build/rock4c-plus-nixos.img.zst` instead for a plain image, or substitute
the configured `OUT_DIR`. Do not use `sudo` for this operation. When the write
finishes, confirm the expected partitions are visible before removing the
card:

```bash
lsblk -f /dev/sdX
```

## First boot and access

The imported NixOS SD-image module has first-boot expansion enabled by default.
On the first boot it grows the root partition and then the ext4 filesystem to
fit the card. Check the result after the board is up:

```bash
findmnt -no SOURCE,FSTYPE /
df -h /
```

The repository does not specify a first-boot delay or a required HDMI/serial
setup. If serial access is needed, use the configured console
`ttyS2,1500000n8`.

SSH is enabled for user `zarred` with the configured authorized keys only:
root login, password authentication, and keyboard-interactive authentication
are disabled. You must possess a private key matching one of the public keys
in [`hosts/rock4c.nix`](../hosts/rock4c.nix); the image provides no fallback
password login.

The configured network paths are:

- Ethernet interface `end0`: static `192.168.86.151/24`, with IPv6 disabled.
- Wi-Fi: NetworkManager IPv4/IPv6 DHCP when using the Wi-Fi image.
- Avahi/mDNS is enabled, so `rock4c.local` may be available on an mDNS-aware
  LAN; otherwise use the reachable Ethernet address or Wi-Fi DHCP lease.

For a Wi-Fi image, find the board's address in the router's DHCP leases or try
mDNS. For direct Ethernet, configure the other endpoint on the
`192.168.86.0/24` network and use the static address. For example:

```bash
ssh zarred@rock4c.local
# or, over the configured direct Ethernet network
ssh zarred@192.168.86.151
```

Tailscale is enabled in the image, but this repository does not document an
enrollment/authentication procedure.

## Normal rebuild and deployment

The deployed system target is `rock4c`, not `rock4c-image`. The image installs a
`rebuild` shell alias configured as:

```text
sudo nixos-rebuild switch --flake /home/zarred/dots#rock4c
```

Use `rebuild` only when the intended checkout exists at exactly
`/home/zarred/dots`; the alias does not discover the current clone or worktree.
If the checkout lives elsewhere, update the alias in
[`home/hosts/rock4c.nix`](../home/hosts/rock4c.nix) or invoke the same flake
target with the correct absolute path. The alias currently uses `sudo` because
that is what the repository config defines; the SD flashing workflow above
deliberately uses `pkexec` instead. There is no separate remote-deploy helper
in this repository.

After changing the host or image configuration, rebuild the SD image with the
script and flash a newly built image. Avoid cloning the same image unchanged
onto multiple boards; see the caveat below.

## Validation and troubleshooting

Before a full build, perform the cheap checks:

```bash
bash -n build-rock4c-image.sh
./build-rock4c-image.sh --help
```

After a build, verify the expected file and permissions. These commands assume
the default `OUT_DIR=build`:

```bash
ls -lh build/rock4c-plus-nixos*.img.zst
stat -c '%a %n' build/rock4c-plus-nixos*.img.zst
```

On the board, check the configured services and networking:

```bash
systemctl is-active sshd NetworkManager rock4c-wifi-reset
ip -4 addr show dev end0
findmnt -no SOURCE,FSTYPE /
```

### AP6256 Wi-Fi reset

The AP6256 needs an early reset provider, the board calibration firmware, and
a 200 ms SDIO post-power-on delay. Warm-boot initialization is intermittent,
so `rock4c-wifi-reset.service` runs before NetworkManager and performs the
configured recovery sequence: unload the Broadcom modules, unbind
`fe310000.mmc`, wait two seconds, rebind it, wait one second, and reload
`brcmfmac`. If the SDIO device is absent, the service exits successfully
without resetting it.

Inspect the service and related kernel messages with:

```bash
systemctl status rock4c-wifi-reset
journalctl -b -u rock4c-wifi-reset
journalctl -k -b | grep -Ei 'brcmfmac|mmc|sdio'
nmcli device status
```

If Wi-Fi is missing after a warm boot, first check that the reset service ran
before NetworkManager and that the `brcmfmac`/SDIO messages are present. The
image's reset provider, calibration firmware, device-tree delay, and service
are intentional parts of the fix; do not remove them while debugging.

## Current multi-board caveat

Every image currently sets both:

- hostname `rock4c`; and
- static Ethernet address `192.168.86.151/24` on `end0`.

Therefore, multiple boards booted from the same configuration will conflict
on hostname and wired IP. This is a current configuration limitation, not a
per-image identity mechanism. Before connecting multiple boards to the same
wired network, give each one a unique `networking.hostName` and `end0` static
address through separate per-board host configurations/images. The repository
currently provides only the single shared `rock4c` target, so that host split
must be added before producing distinct images.
