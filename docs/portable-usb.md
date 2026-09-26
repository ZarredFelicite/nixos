# Portable NixOS USB — configuration decisions

Status: MVP installed on the Samsung Type-C USB (2026-09-25); **physical boot on the Framework has not been tested yet**. The standalone host flake is in `portable/`, with a copy at `/home/zarred/portable-nixos` on the encrypted USB. The prebuilt system was installed without repartitioning or formatting; GRUB's removable UEFI fallback is present. After verification, the USB was unmounted and LUKS locked.

## Purpose

- A normal, persistent NixOS installation on the Samsung Type-C USB, not a Ventoy ISO or live-overlay setup.
- Boot on the Framework and, where practical, other UEFI computers.
- Include the tools to install a **future separate flake host configuration** onto the Framework's empty internal SSD after its hardware is identified. That host configuration is not yet written; the internal SSD has not been touched.
- Adapt chosen Nano features without importing Nano-specific disk, hardware, network, or impermanence assumptions wholesale.

## Prepared USB layout

| Partition | Size | Current state | Intended use |
| --- | ---: | --- | --- |
| 1 | 1 GiB | FAT32, `NIXOS_BOOT` | EFI system partition |
| 2 | 54.4 GiB | LUKS2 with Btrfs `NIXOS_ROOT`; locked | Persistent OS and home |
| 3 | 183.6 GiB | ext4, `samsung_c`; empty except `lost+found` | Mount at `/data`; **not encrypted** |

The USB uses an MBR partition table. Ventoy and its three ISOs were removed. The previous files on `samsung_c` were deleted at the user's explicit request. An **incomplete, unverified** copy remains at `~/misc/backups/samsung_c-2026-09-25/`; it must not be treated as a full backup. No swap partition or swap file is requested; hibernation is therefore out of scope.

After cleanup, the **entire** `~/scripts` tree (including hidden files) was copied into the encrypted Btrfs filesystem at `/home/zarred/scripts`: 35,229 entries, about 1.24 GB of file data. A checksum-based `rsync` dry run found no differences, and the scripts were present after installation. Private files there must not be copied into the Nix store or a public repo.

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

## Installation record and remaining validation

- The Samsung serial and all partition UUIDs were checked before mounting the existing encrypted Btrfs root at `/mnt/portable-usb-install` and its USB EFI partition at `/mnt/portable-usb-install/boot`. With explicit approval, `nixos-install --system … --no-root-password --no-channel-copy` installed the prebuilt flake closure. No disk partitioning, formatting, Framework SSD write, or firmware boot-entry change was requested. The EFI fallback `EFI/BOOT/BOOTX64.EFI` and GRUB configuration were verified.
- The `zarred` account password was set through masked desktop prompts; its password status is `P` and root's is `L` (locked). Neither password nor hash is stored in this repo. The scripts and copied flake remain on the encrypted root, with roughly 41 GiB available after installation. The USB was safely unmounted and relocked.
- **Next:** boot the USB on the Framework and test LUKS unlock, SDDM's three sessions, Wi-Fi, `/data`, and Hyprland/Quickshell. Do not claim boot success until that test. If Secure Boot rejects unsigned GRUB, pause and decide how to handle that policy rather than silently changing firmware settings.
- SSH has no authorized user key yet; enroll it, Tailscale/WireGuard, mail, GPG, Pi credentials, and the `web` cache identity only after first boot. Camera, calendar, remote Pi dashboard, TTS, and Ember integrations are passive in the portable Quickshell copy.
- Add the Framework's own flake host/disk workflow after verifying its internal SSD identity on that machine. Never infer or partition the internal SSD from this desktop.

## Titan discovery (Framework laptop)

- The reported CPU is **Intel Core Ultra 5 325**, offered in the Framework Laptop 13 Pro (Intel Core Ultra Series 3). Confirm the DMI product on the laptop before selecting its hardware profile. The pinned `nixos-hardware` revision includes `nixosModules.framework-intel-core-ultra-series3`; do not import Nano's ThinkPad profile.
- The desired Titan layout follows Nano's **tmpfs root/home with selected persistence**. Nano's fixed `/dev/nvme0n1p*` paths, Btrfs subvolumes, swap size, SOPS-derived passwords, and hardware-specific services must not be copied blindly. The internal SSD identity and approved layout are still unknown; no Titan installable host, target-specific disk plan, or installer has been created.
- The committed read-only inventory command `portable/bin/titan-inventory` was copied to the encrypted USB as `/home/zarred/portable-nixos/bin/titan-inventory` and checksum-verified; the USB was relocked. After booting it on Titan, run this command locally to see CPU/DMI/BIOS and all disk/partition identifiers. It **never selects or modifies a disk**; its serials, WWNs, and UUIDs should be shared carefully.
- [Framework's Laptop 13 Pro NixOS guide](https://guides.frame.work/Guide/NixOS+on+the+Framework+Laptop+13+Pro/780) recommends a **non-LTS kernel**. The installed USB image contains Linux 6.12.93 (LTS), and Framework boot has not been tested. Do not silently change the kernel or Secure Boot policy; report any boot failure and decide on the smallest compatible change.
