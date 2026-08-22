# NixOS Configuration

This repository contains the NixOS configurations for my various systems, managed using Nix flakes.

## Setup Overview

### Host roles

- **web** — primary desktop, SSH remote builder, and `ssh-ng` binary-cache host.
- **nano** — laptop client; prefers web for cache hits and cache-miss builds.
- **sankara** — server/storage host.
- **surface** — additional laptop configuration.

### Nano ↔ web routing

The dedicated Ethernet link uses `web = 192.168.86.150` and `nano = 192.168.86.125`. SSH has two route-aware aliases:

- `nixremote-web` — remote builder; probes `192.168.86.150:22` first, then falls back to `100.64.1.150` through Tailscale. This alias remains usable off the home LAN; Tailscale chooses its direct-LAN or DERP path.
- `nixremote-web-cache` — web binary cache; probes the dedicated endpoint first, then checks home Wi-Fi via `192.168.8.150`. On home Wi-Fi the SSH payload still connects to `100.64.1.150` through Tailscale. It fails fast off the home LAN.

The effective order is local store first, followed by these stages:

| Network state | Cache lookup order | Build fallback order |
| --- | --- | --- |
| Docked / dedicated Ethernet | web cache over `192.168.86.150` (priority 30), public caches | web builder over wired SSH, then Nano local |
| Home Wi-Fi, no dock | web cache over Tailscale, public caches | web builder over Tailscale, then Nano local |
| Other network | public caches | web builder over Tailscale direct/DERP, then Nano local |

Public substituters are `cache.nixos.org`, `cuda-maintainers.cachix.org`, `nix-community.cachix.org`, and `hyprland.cachix.org`. The web cache's `web-binary-cache` key is trusted locally; its priority 30 precedes the public caches' default priority 40 when the home-LAN route is available.

`system.autoUpgrade` evaluates the live checkout at `path:/home/zarred/dots` around 02:00 (with a 45-minute randomized delay), refreshes/recreates flake inputs, and keeps the configured cache and remote-builder policy. It does not reboot automatically. The source checkout is evaluated into the selected host configuration, paths are fetched from the cache chain or built on web, and resulting store paths are copied into Nano's local store before activation. Existing SSH connections do not migrate mid-build: if the selected route disappears, that build fails and must be retried.

For local inspection, use commands such as `nix eval --json .#nixosConfigurations.nano.config.nix.buildMachines` and `nix eval --json .#nixosConfigurations.nano.config.nix.settings.substituters`; the generated builder entry is written to `/etc/nix/machines`. The main routing files are `profiles/nix.nix` (substituters/build machine), `profiles/common.nix` (network addresses and SSH aliases), `roles/desktop.nix` (automatic upgrades), `hosts/nano.nix`, and `hosts/web.nix`.

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

The flake exposes these host configurations under `nixosConfigurations`; host-specific hardware and Home Manager entry points live under `hosts/` and `home/hosts/`.

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
