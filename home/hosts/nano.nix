{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

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
    ../menu
    ../mail
    ../finance
    ../media
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  #systemd.user.services.airpods_battery.Install.WantedBy = lib.mkForce [];
  #systemd.user.services.zmk_battery.Install.WantedBy = lib.mkForce [];

  # Nano should act as a node host, not run its own gateway service.
  systemd.user.services.openclaw-gateway.Install.WantedBy = lib.mkForce [ ];

  # OpenClaw node host for connecting nano to the main gateway over Tailscale.
  # Token/config stays imperative in ~/.config/openclaw/node-host.env (persisted).
  systemd.user.services.openclaw-node-host = {
    Unit = {
      Description = "OpenClaw node host (nano)";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      EnvironmentFile = "%h/.config/openclaw/node-host.env";
      ExecStart = "${pkgs.openclaw-gateway}/bin/openclaw node run --host web.manticore-lenok.ts.net --port 18789 --display-name nano";
      Restart = "always";
      RestartSec = "2s";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Placeholder for any home-manager settings absolutely specific to zarred on nano
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-nano-specific-tool ];
}
