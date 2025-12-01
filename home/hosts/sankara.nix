{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied

    ../theme

    # Modules for a server/CLI focused experience (previously via home/core.nix's imports)
    ../cli # General CLI applications and tools
    ../menu
    ../mail      # For CLI mail clients or background sync
    ../finance
    ../media     # For CLI media tools or background services
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  # Placeholder for any home-manager settings absolutely specific to zarred on sankara
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-sankara-specific-tool ];
}
