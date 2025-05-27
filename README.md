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
