{ osConfig, pkgs, inputs, lib, ... }:
let
  # Create a wrapper script that sets OPENROUTER_API_KEY from the secret file
  openclawWrapper = pkgs.writeShellScript "openclaw-gateway-wrapper" ''
    export OPENROUTER_API_KEY=$(cat ${osConfig.sops.secrets.openrouter-api.path})
    export PATH="$HOME/.nix-profile/bin:$HOME/.bun/bin:${pkgs.openssl.bin}/bin:/run/current-system/sw/bin:$PATH"
    exec ${pkgs.openclaw-gateway}/bin/openclaw gateway --port 18789
  '';
in {
  home.packages = [ pkgs.openclaw-gateway pkgs.bun ];

  # Manually defined service (bypasses the module's config generation)
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "Openclaw Gateway";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${openclawWrapper}";
      WorkingDirectory = "%h/.openclaw";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "MOLTBOT_NIX_MODE=1"
        "CLAWDBOT_NIX_MODE=1"
        "HOME=%h"
        "PATH=${pkgs.openssl.bin}/bin:/run/current-system/sw/bin"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
