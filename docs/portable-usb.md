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
| 3 | 183.6 GiB | ext4, `samsung_c`; empty except `lost+found` | Undecided; **not encrypted** |

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
- Terminal mail tools and Signal; no Thunderbird, Discord, or Zoom requested.
- mpv only from Nano's media applications; no Spotify, MPD/Twitch tools, or OBS requested.
- `pass` and GPG; credentials and personal data are not part of this document.
- No automatic NixOS upgrades. Manual updates remain possible.

## Still to decide

1. Whether to mount the empty, **unencrypted** `samsung_c` partition as `/data`, leave it unused, or explicitly approve a separate encryption/reformat plan. The encrypted root/home has only 54.4 GiB.
2. Round 3 Nano features: development languages/toolchain; Docker/Podman; QEMU/libvirt; local AI; FreeCAD/OrcaSlicer; Android SDK; gaming; NFS/Sankara backups/remote builders.
3. Display manager, portable UEFI bootloader details, portable host name, and how to adapt host-bound scripts, secrets, and Quickshell dependencies.
4. Framework-specific flake host and safe target-disk installation workflow. Never infer the internal SSD device name or partition it without verifying it on the Framework.
5. Login credential setup and deployment of SSH, Tailscale, WireGuard, mail, and GPG material without committing secrets.
6. Validation depth: MVP configuration evaluation/build and boot test versus a more thorough portability and hardening pass.

**Do not run `nixos-install` or assume the USB is bootable until these choices are resolved and the installation is validated.**
