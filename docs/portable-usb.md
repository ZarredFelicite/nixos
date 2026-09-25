# Portable NixOS USB — configuration decisions

Status: MVP built (2026-09-25). **No NixOS system or bootloader has been installed on the USB yet.** The standalone host flake is in `portable/`; `nix build --no-link ./portable#nixosConfigurations.portable-usb.config.system.build.toplevel` succeeds (about 10.9 GiB closure). The USB remains locked pending a verified, approved installation.

## Purpose

- A normal, persistent NixOS installation on the Samsung Type-C USB, not a Ventoy ISO or live-overlay setup.
- Boot on the Framework and, where practical, other UEFI computers.
- Include the tools and a separate flake host configuration needed to install NixOS onto the Framework's empty internal SSD. The internal SSD has not been touched.
- Adapt chosen Nano features without importing Nano-specific disk, hardware, network, or impermanence assumptions wholesale.

## Prepared USB layout

| Partition | Size | Current state | Intended use |
| --- | ---: | --- | --- |
| 1 | 1 GiB | FAT32, `NIXOS_BOOT` | EFI system partition |
| 2 | 54.4 GiB | LUKS2 with Btrfs `NIXOS_ROOT`; locked | Persistent OS and home |
| 3 | 183.6 GiB | ext4, `samsung_c`; empty except `lost+found` | Mount at `/data`; **not encrypted** |

The USB uses an MBR partition table. Ventoy and its three ISOs were removed. The previous files on `samsung_c` were deleted at the user's explicit request. An **incomplete, unverified** copy remains at `~/misc/backups/samsung_c-2026-09-25/`; it must not be treated as a full backup. No swap partition or swap file is requested; hibernation is therefore out of scope.

After cleanup, the **entire** `~/scripts` tree (including hidden files) was copied into the encrypted Btrfs filesystem at `/home/zarred/scripts`: 35,229 entries, about 1.24 GB of file data. A checksum-based `rsync` dry run found no differences; the filesystem was then unmounted and LUKS locked. This staged copy is not a NixOS installation, and private files in it must not be copied into the Nix store or a public repo.

## Confirmed features

- Persistent `/` and home on the encrypted Btrfs partition; no tmpfs-root impermanence like Nano.
- **SDDM** login screen offering Hyprland, COSMIC, and GNOME without autologin. Hyprland has adapted Nano-style navigation, selected script-driven shortcuts, Quickshell, Hyprlock, and a generic wallpaper; shortcuts for excluded apps are omitted.
- NetworkManager for Wi-Fi; no Nano-specific static addresses or interface-name assumptions.
- SSH with key-only user login and firewall enabled; no password or root SSH login by default.
- Tailscale and WireGuard, with device credentials provisioned securely after installation rather than embedded in an image or the Nix store. No Syncthing requested.
- Bluetooth, PipeWire audio, firmware updates, and generic laptop power management; omit ThinkPad-specific tuning.
- Firefox and Tor Browser; no Brave or Zen Browser.
- Kitty as the only terminal emulator, plus Zsh, tmux, Starship, Neovim/Nixvim, and Git.
- Zathura as Nano's minimal PDF viewer; no Obsidian or LibreOffice requested.
- Terminal mail tools and Signal; install the mail applications now, but configure accounts, sync, and notifications after first boot. No Thunderbird, Discord, or Zoom requested.
- mpv only from Nano's media applications; no Spotify, MPD/Twitch tools, or OBS requested.
- `pass` and GPG; credentials and personal data are not part of this document.
- No automatic NixOS upgrades. Manual updates remain possible.
- From Nano's development tools: Git, Python and GCC only. Include the Pi coding agent, but no other local AI tools. No Docker/Podman, QEMU/libvirt, CAD/3D-printing tools, Android SDK, or gaming stack.
- No NFS mounts, Sankara backups, or SSH distributed builder. Public Nix caches and local builds work before enrollment; authorize a portable-device SSH identity and enable the signed `web` cache after first boot. The web cache is not yet active in the MVP configuration.
- Mount the existing ext4 partition at `/data` for optional bulk storage. It is **unencrypted**; keep home and private state on the encrypted root by default.
- Enroll Tailscale, WireGuard, mail, GPG, Pi, and other credentials after first boot; do not embed private keys or tokens in the Nix store or USB image.
- Give the Framework's internal SSD a **separate host configuration**, reusing selected Nano/portable modules where suitable. Do not install Nano's host file unchanged: it hardcodes ThinkPad hardware and disk paths. Build that host after inspecting Framework hardware; the portable USB needs only the tools to install a flake safely.

## Installation and validation remaining

1. Verify the Samsung USB serial, partition UUIDs, mount table, and staged `/home/zarred/scripts` once more. Preserve all three existing filesystems; never invoke Disko or reformat. Explicit approval is required before `nixos-install` writes to the prepared USB. The flake uses removable-media GRUB without firmware-variable changes; it does not target the Framework internal SSD.
2. During installation set a password for the `zarred` account **interactively**, not through Nix or chat. SSH is key-only but has no authorized key until provisioned after first boot. After installation, boot-test on the Framework and check LUKS unlock, login/session selection, Wi-Fi, `/data`, and the Hyprland/Quickshell desktop. Camera, calendar, remote Pi dashboard, TTS, and Ember integrations are passive in the portable Quickshell copy.
3. Add a separately hardware-verified Framework host and disk workflow later. Never infer the internal SSD device name or partition it without verifying it on the Framework.

**Do not run `nixos-install` before the mount/target review and explicit approval; do not claim boot success before a physical boot test.**
