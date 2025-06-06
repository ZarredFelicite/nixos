{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied
    ../python.nix # All python packages

    # Desktop specific modules (previously via home/desktop.nix)
    ../browser
    ../desktop
    ../theme
    ../gaming

    # Modules for a full desktop experience (previously via home/core.nix's imports)
    ../cli # General CLI applications and tools
    ../menu
    ../mail
    ../finance
    ../media
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  systemd.user.services.airpods_battery.Install.WantedBy = lib.mkForce [];
  systemd.user.services.zmk_battery.Install.WantedBy = lib.mkForce [];
  # Placeholder for any home-manager settings absolutely specific to zarred on nano
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-nano-specific-tool ];
}
