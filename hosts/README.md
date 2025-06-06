# Hosts

This directory contains the NixOS configurations for each individual machine. Each file in this directory corresponds to a specific host (e.g., `web.nix`, `sankara.nix`).

Each host configuration file imports the necessary roles and profiles from the `roles/` and `profiles/` directories to define the system's functionality and characteristics. Host-specific settings that are unique to that machine are also defined here.
