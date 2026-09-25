# Portable NixOS USB — configuration decisions

Status: planning snapshot (2026-09-25). **No NixOS system or bootloader has been installed on the USB yet.** This is not an executable host configuration.

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

## Confirmed features

- Persistent `/` and home on the encrypted Btrfs partition; no tmpfs-root impermanence like Nano.
- A login screen offering **Hyprland, COSMIC, and GNOME**. For Hyprland, carry over Nano's custom keybindings, Quickshell, lock screen, and styling where portable. Display manager not chosen yet.
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
- No NFS mounts, Sankara backups, or SSH distributed builder. Prefer the signed Nix store cache served by host `web` when reachable; use public caches and local builds as fallback. Authorize a separate portable-device SSH identity for the web cache after installation.
- Mount the existing ext4 partition at `/data` for optional bulk storage. It is **unencrypted**; keep home and private state on the encrypted root by default.
- Enroll Tailscale, WireGuard, mail, GPG, Pi, and other credentials after first boot; do not embed private keys or tokens in the Nix store or USB image.
- Give the Framework's internal SSD a **separate host configuration**, reusing selected Nano/portable modules where suitable. Do not install Nano's host file unchanged: it hardcodes ThinkPad hardware and disk paths. Build that host after inspecting Framework hardware; the portable USB needs only the tools to install a flake safely.

## Still to decide

1. **Script scope:** `~/scripts` totals roughly 59 GiB and contains large TTS/AI/MCP data and sensitive files; it cannot be copied wholesale to the 54.4 GiB encrypted root. Choose between a small Hyprland-only script subset and a broader Quickshell-related **code-only** subset under `/home/zarred/scripts` (recommended). Exclude models, caches, downloads, credentials, and the camera script containing embedded credentials. Shortcuts for excluded applications must be removed or disabled.
2. Implementation details: multi-session display manager, removable UEFI bootloader, portable hostname, and adapting custom Hyprland/Quickshell scripts and assets. Unless changed, use a password-protected `zarred` account without autologin and Nano's locale/keyboard preferences. Set its password interactively; never commit a plaintext password or private key.
3. Framework host disk layout and install workflow later. Never infer the internal SSD device name or partition it without verifying it on the Framework.
4. Validation depth: MVP configuration evaluation/build and boot test versus a more thorough portability and hardening pass.

**Do not run `nixos-install` or assume the USB is bootable until these choices are resolved and the installation is validated.**
