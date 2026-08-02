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
./build-rock4c-image.sh --plain # Image without a Wi-Fi profile
./build-rock4c-image.sh         # Image with injected Wi-Fi credentials
```

The helper builds but never flashes the SD card. Injected Wi-Fi credentials are
plaintext inside the generated Wi-Fi image. See the
[ROCK 4C+ build and deployment guide](docs/rock4c.md) for prerequisites,
credential handling, safe flashing, first boot, updates, and troubleshooting.
