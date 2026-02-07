{ pkgs, inputs, lib, ... }: {
  home.packages = [ pkgs.openclaw-gateway ];

  # Manually defined service (bypasses the module's config generation)
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "Openclaw Gateway";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${pkgs.openclaw-gateway}/bin/openclaw gateway --port 18789";
      WorkingDirectory = "%h/.openclaw";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "MOLTBOT_NIX_MODE=1"
        "CLAWDBOT_NIX_MODE=1"
        "HOME=%h"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
