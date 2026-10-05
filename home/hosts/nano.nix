{ inputs, self, pkgs, pkgs-unstable, lib, config, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied

    # Desktop specific modules (previously via home/desktop.nix)
    ../browser
    ../desktop
    ../theme
    ../gaming

    # Modules for a full desktop experience (previously via home/core.nix's imports)
    ../cli # General CLI applications and tools
    ../mail
    ../finance
    ../media
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  # 0.11+ provides encrypted, fingerprint-authorized input sharing.
  home.packages = [ pkgs-unstable.lan-mouse ];

  #systemd.user.services.airpods_battery.Install.WantedBy = lib.mkForce [];
  #systemd.user.services.zmk_battery.Install.WantedBy = lib.mkForce [];

  systemd.user.services.quickshell.Service.Environment = [
    "QUICKSHELL_DISABLE_AI_VISUALIZER=1"
  ];

  xdg.configFile."home-assistant/config.json".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."home-assistant-config.json".path;

  # Placeholder for any home-manager settings absolutely specific to zarred on nano
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-nano-specific-tool ];
}
