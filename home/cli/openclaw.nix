{ osConfig, config, pkgs, pkgs-unstable, inputs, lib, ... }:
let
  qmdPkg = pkgs.callPackage ../../pkgs/qmd/package.nix {};
  openclawPkg = pkgs-unstable.openclaw;

  hostName = osConfig.networking.hostName or "";
  isWeb = hostName == "web";
  isNodeHost = builtins.elem hostName [ "nano" "sankara" ];

  # Create a wrapper script that sets OPENROUTER_API_KEY from the secret file
  openclawWrapper = pkgs.writeShellScript "openclaw-gateway-wrapper" ''
    export OPENROUTER_API_KEY=$(cat ${osConfig.sops.secrets.openrouter-api.path})
    exec ${openclawPkg}/bin/openclaw gateway --port 18789
  '';
in {
  home.packages = [ openclawPkg qmdPkg ];

  systemd.user.services = lib.mkMerge [
    (lib.mkIf isWeb {
      # Gateway host (web): run gateway + tailscale serve; disable node clients.
      openclaw-gateway = {
        Unit = {
          Description = "Openclaw Gateway";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${openclawWrapper}";
          WorkingDirectory = "${config.home.homeDirectory}/.openclaw";
          Restart = "always";
          RestartSec = "5s";
          Environment = [
            "MOLTBOT_NIX_MODE=1"
            "CLAWDBOT_NIX_MODE=1"
            "HOME=${config.home.homeDirectory}"
            "OPENCLAW_STATE_DIR=${config.home.homeDirectory}/.openclaw"
            "PATH=${qmdPkg}/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      # Expose loopback-bound OpenClaw gateway over Tailscale Serve (HTTPS).
      openclaw-tailnet-serve = {
        Unit = {
          Description = "OpenClaw gateway via Tailscale Serve (HTTPS 18789)";
          After = [ "network-online.target" "openclaw-gateway.service" ];
          Wants = [ "network-online.target" "openclaw-gateway.service" ];
          PartOf = [ "openclaw-gateway.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https 18789 http://127.0.0.1:18789";
          ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=18789 off";
        };
        Install.WantedBy = [ "default.target" ];
      };

      openclaw-node-host.Install.WantedBy = lib.mkForce [ ];
    })

    (lib.mkIf isNodeHost {
      # Node hosts (nano/sankara): do not run gateway/node client; run node-host only.
      openclaw-gateway.Install.WantedBy = lib.mkForce [ ];

      openclaw-node-host = {
        Unit = {
          Description = "OpenClaw node host (${hostName})";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          EnvironmentFile = "%h/.config/openclaw/node-host.env";
          ExecStart = "${openclawPkg}/bin/openclaw node run --host web.manticore-lenok.ts.net --port 18789 --tls --display-name ${hostName}";
          Restart = "always";
          RestartSec = "2s";
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
