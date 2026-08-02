# NixOS Configuration

This repository contains the NixOS configurations for my various systems, managed using Nix flakes.

## Directory Structure

-   `containers/`: Configurations for various containers (e.g., Docker, Podman, Nextcloud).
-   `home/`: Home-manager configurations, organized by category (e.g., browser, cli, desktop).
-   `hosts/`: Specific configurations for each host system (web, sankara, nano, surface).
-   `modules/`: Reusable NixOS modules that can be imported into host configurations.
-   `overlays/`: Nixpkgs overlays for custom package versions or modifications.
-   `pkgs/`: Custom packages defined for use within the configurations.
-   `profiles/`: System profiles that group related configurations and can be applied to hosts.
-   `roles/`: Role-based configurations (e.g., desktop, server) that define a base set of configurations for a type of system.
-   `secrets/`: Encrypted secrets managed with sops-nix.

## Systems

-   **web**: Desktop system
-   **sankara**: Server system
-   **nano**: Laptop system
-   **surface**: Laptop system
-   **rock4c**: Radxa ROCK 4C+ headless system

## ROCK 4C+ SD image

The deployed host and SD image share `hosts/rock4c.nix`; image-only partitioning
and U-Boot installation live in `images/rock4c-sd-image.nix`.

```bash
# Reproducible image without credentials
./build-rock4c-image.sh --plain

# Inject the existing encrypted Wi-Fi password into a local, ignored image
./build-rock4c-image.sh
```

The helper only builds images; it never flashes a device. Outputs are written
under `build/` with mode `0600`:

- `build/rock4c-plus-nixos.img.zst` (`--plain`)
- `build/rock4c-plus-nixos-wifi.img.zst` (default)

Confirm the target device with `lsblk` before running this destructive command;
replace `/dev/sdX` only with the whole microSD device, never a partition:

```bash
zstdcat build/rock4c-plus-nixos-wifi.img.zst \
  | pkexec dd of=/dev/sdX bs=4M status=progress conv=fsync
```

The image uses MBR, a 64 MiB FAT partition beginning at 32 MiB, an ext4 root
partition labeled `NIXOS_SD`, and raw Rockchip U-Boot writes at sectors 64 and
16384. Wi-Fi credentials in generated images are plaintext; do not commit or
retain those images unnecessarily.
