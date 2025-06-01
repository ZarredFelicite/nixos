{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied
    ../cli-apps.nix # General CLI applications and tools
    ../python.nix # All python packages

    # Modules for a server/CLI focused experience (previously via home/core.nix's imports)
    ../cli/default.nix
    ../mail/default.nix      # For CLI mail clients or background sync
    ../terminal/default.nix
    ../security.nix
    ../impermanence.nix
    # Optional: depending on server use for user zarred
    ../finance/default.nix
    ../media/default.nix     # For CLI media tools or background services
  ];

  # Placeholder for any home-manager settings absolutely specific to zarred on sankara
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-sankara-specific-tool ];
}
