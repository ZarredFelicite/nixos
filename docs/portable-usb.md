# Portable NixOS USB — configuration decisions

Status: The installed Samsung Type-C USB still has **unsigned GRUB**; Titan rejected it in the firmware boot manager before GRUB appeared. Lanzaboote signed-boot configuration for the USB and Titan has been built on `web`; the new root-owned signing bundle is on Web's encrypted `/var/lib/sbctl` and was copied and checked on the USB's encrypted root. No firmware enrollment or USB bootloader replacement has been approved, and no signed image has been installed or boot-tested. The standalone host flake is in `portable/`, with a copy at `/home/zarred/portable-nixos` on the encrypted USB. Previous GRUB installations did not repartition or format the USB; it was unmounted and LUKS locked after verification.

## Purpose

- A normal, persistent NixOS installation on the Samsung Type-C USB, not a Ventoy ISO or live-overlay setup.
- Boot on the Framework and, where practical, other UEFI computers.
- Carry the tools for a **separate Titan host** in the full root `dots` flake. Its SSD target remains an intentional `throw` until Titan's hardware is identified and the user approves a layout; the internal SSD has not been touched.
- Keep this portable USB's smaller desktop profile separate from Titan's full Nano desktop and Home Manager profile.

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
- Give the Framework's internal SSD a **separate Titan host** in the root flake. It shares Nano's desktop role and Home Manager profile, but uses Framework hardware and a separate Disko layout. The standalone portable USB remains a smaller, independently updatable desktop.

## Installation record and remaining validation

- The Samsung serial and all partition UUIDs were checked before mounting the existing encrypted Btrfs root at `/mnt/portable-usb-install` and its USB EFI partition at `/mnt/portable-usb-install/boot`. With explicit approval, `nixos-install --system … --no-root-password --no-channel-copy` installed the prebuilt flake closure. No disk partitioning, formatting, Framework SSD write, or firmware boot-entry change was requested. The EFI fallback `EFI/BOOT/BOOTX64.EFI` and GRUB configuration were verified.
- The `zarred` account password was set through masked desktop prompts; its password status is `P` and root's is `L` (locked). Neither password nor hash is stored in this repo. The scripts and copied flake remain on the encrypted root, with roughly 41 GiB available after installation. The USB was safely unmounted and relocked.
- **Next:** review Titan's **Administer Secure Boot** firmware menu before deciding whether a custom signing certificate can be enrolled while retaining factory trust; do not clear, replace, or enroll keys without separate approval. The matching root-only PKI now has copies on encrypted `web` and USB roots; neither copy is on the ESP or in Git/Nix store. Separately approve staging the **public certificate** for the firmware picker, enrolling that certificate into `db` without deleting factory entries, and replacing the USB's GRUB fallback with signed Lanzaboote; verify signatures and physically boot the USB before testing LUKS unlock, desktop sessions, Wi-Fi, and `/data`. Preserve the existing MBR layout. No USB boot files or firmware keys have been changed yet.
- SSH has no authorized user key yet; enroll it, Tailscale/WireGuard, mail, GPG, Pi credentials, and the `web` cache identity only after first boot. Camera, calendar, remote Pi dashboard, TTS, and Ember integrations are passive in the portable Quickshell copy.
- Titan's host and guarded installer are prepared below, but a real disk target must only be chosen after booting this USB on Titan and reviewing its inventory. Never infer or partition the internal SSD from this desktop.

## Titan discovery (Framework laptop)

- The reported CPU is **Intel Core Ultra 5 325**, offered in the Framework Laptop 13 Pro (Intel Core Ultra Series 3). Confirm the DMI product on the laptop before selecting its hardware profile. The pinned `nixos-hardware` revision includes `nixosModules.framework-intel-core-ultra-series3`; do not import Nano's ThinkPad profile.
- Titan's root-flake host now shares Nano's **tmpfs root/home, full desktop role, and Home Manager profile**, but uses the Framework Series 3 hardware module, a separate Disko layout, and runtime login-hash provisioning. It deliberately has **no SSD target yet** (`hosts/titan/target-disk.nix` throws). Its disk identity, swap needs, and final layout require Titan-side inventory and approval.
- The committed read-only inventory command `portable/bin/titan-inventory` was copied to the encrypted USB as `/home/zarred/portable-nixos/bin/titan-inventory` and checksum-verified; the USB was relocked. After booting it on Titan, run this command locally to see CPU/DMI/BIOS and all disk/partition identifiers. It **never selects or modifies a disk**; its serials, WWNs, and UUIDs should be shared carefully.
- [Framework's Laptop 13 Pro NixOS guide](https://guides.frame.work/Guide/NixOS+on+the+Framework+Laptop+13+Pro/780) recommends a **non-LTS kernel**. The installed unsigned USB defaults to Linux **7.1.2**, with its original 6.12.93 generation still offered by GRUB until the signed fallback replaces it. Old profiles may remain after migration, but are **not** a bootable rollback without signed UKIs. Neither generation has booted on Titan.
- To update the USB later **from `web`**, run `portable/bin/update-os` from this worktree only after the approved PKI/recovery/enrollment plan. Its read-only `--check` verifies the Samsung USB before starting. A normal run refreshes portable inputs; `--locked` keeps `portable/flake.lock`. Both build on `web` and, after one Polkit authorization, install only to the verified USB, check runtime PKI ownership/key-certificate matching, and verify signed EFI fallback and UKIs. The older system profile remains on encrypted root but is not promised as a bootable rollback. There is no unattended timer or automatic reboot.

## Titan preparation and guarded install (not yet executed)

- The full root `dots` flake defines `nixosConfigurations.titan` in `hosts/titan.nix` and `hosts/titan/disko.nix`; do **not** install from the standalone `portable/` flake. Disko plans a 1 GiB ESP, LUKS2/Btrfs `/nix` and `/persist`, and tmpfs `/` and `/home/zarred`. A unique Titan SSH host key decrypts SOPS at boot from `/persist/etc/ssh/ssh_host_ed25519_key`. Its age recipient was added to `.sops.yaml` and the three encrypted files were rekeyed; their decrypted-content hashes matched before/after, and Titan-key-only decryption passed. The private key remains outside Git and the Nix store.
- The USB was updated using `portable/bin/update-os --locked`; its installed generation now includes `gh`, `jq`, `sops`, `ssh-to-age`, `whois`, `nixos-install-tools`, and polkit. The updater verified both the new and previous GRUB generations, kept `portable/flake.lock` unchanged, and relocked the USB. The **full root** `dots` Titan branch was staged at `/home/zarred/dots` on the encrypted USB, and the Titan SSH keypair was staged at `/home/zarred/.local/state/titan-provision/ssh_host_ed25519_key{,.pub}` (directory `0700`, private key `0600`). No personal GPG private key or Web token was copied. A fresh GitHub login was saved under the USB's encrypted `~/.config/gh`, and access to all five private repositories was verified. Titan's full system prebuild is still pending its hardware/disk inventory.
- On Titan, boot the USB, run `/home/zarred/portable-nixos/bin/titan-inventory`, review DMI, the internal SSD's stable `/dev/disk/by-id/` name, size, serial and contents, and obtain **explicit approval of that exact disk and layout**. Run `/home/zarred/portable-nixos/bin/install-titan --plan --disk /dev/disk/by-id/...` from the USB only after identifying the candidate. The plan and inventory are read-only. Do not run `--apply` on Web or before approval.
- After separate disk/layout approval and a successful **signed USB boot on Titan**, `/home/zarred/portable-nixos/bin/install-titan --apply --disk /dev/disk/by-id/...` requires Secure Boot enabled, verifies the booted USB fallback against the root-only signing certificate, checks Titan hardware, USB exclusion, no active mounts/holders/swap, SOPS decryption **using only Titan's SSH key**, and private input authentication. It asks for the serial, stages the tracked target module, prebuilds Titan and Disko, then asks for `WIPE <serial>` before Polkit rechecks identity and runs Disko. LUKS and the login password use masked prompts; the login hash, SSH host key, and signing PKI are persisted only under encrypted `/persist` (not the ESP). It verifies signed Titan EFI artifacts and leaves mounts in place for inspection. **No apply, partitioning, formatting or Titan boot test has occurred.**
