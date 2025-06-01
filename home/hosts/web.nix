{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied
    ../cli-apps.nix # General CLI applications and tools
    ../python.nix # All python packages

    # Desktop specific modules (previously via home/desktop.nix)
    ../browser/default.nix
    ../desktop/default.nix # This is home/desktop/default.nix
    ../theme/default.nix
    ../gaming/default.nix

    # Modules for a full desktop experience (previously via home/core.nix's imports)
    ../menu/default.nix
    ../cli/default.nix
    ../mail/default.nix
    ../finance/default.nix
    ../media/default.nix
    ../terminal/default.nix
    ../security.nix
    ../impermanence.nix
  ];

  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
