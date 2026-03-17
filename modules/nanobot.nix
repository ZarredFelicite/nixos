# NixOS systemd user service for nanobot AI gateway
# Runs as your user account via the local checkout wrapper package
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nanobot;
in
{
  options.services.nanobot = {
    enable = mkEnableOption "nanobot AI gateway service";

    port = mkOption {
      type = types.port;
      default = 18790;
      description = "Port for the nanobot gateway";
    };

    projectDir = mkOption {
      type = types.str;
      default = "/home/zarred/dev/nanobot";
      description = "Path to the nanobot source checkout";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
      description = "Enable verbose/debug logging";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.nanobot = let
      nanobotPackage = pkgs.callPackage ../pkgs/nanobot.nix {
        projectDir = cfg.projectDir;
      };
    in {
      description = "Nanobot AI Gateway";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${lib.getExe nanobotPackage} gateway --port ${toString cfg.port}${optionalString cfg.verbose " --verbose"}";
        Restart = "on-failure";
        RestartSec = "10s";
      };

      path = [ "/run/current-system/sw" ];
    };
  };
}
