# NixOS systemd user service for Ember web server
# Runs as your user account via the local checkout wrapper package
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ember;
in
{
  options.services.ember = {
    enable = mkEnableOption "Ember web server service";

    port = mkOption {
      type = types.port;
      default = 4311;
      description = "Port for the Ember web server";
    };

    projectDir = mkOption {
      type = types.str;
      default = "/home/zarred/dev/ember";
      description = "Path to the Ember source checkout";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services = let
      qmdPkg = pkgs.callPackage ../pkgs/qmd/package.nix {};
    in {
      qmd-mcp = {
        description = "Persistent qmd MCP server";
        partOf = [ "ember.service" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "simple";
          Environment = [ "HOME=%h" ];
          ExecStart = "${lib.getExe qmdPkg} mcp --http --port 8181";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      ember = let
        emberPackage = pkgs.callPackage ../pkgs/ember.nix {
          projectDir = cfg.projectDir;
        };
        emberStart = pkgs.writeShellScript "ember-start" ''
          export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter-api.path})"
          exec ${lib.getExe emberPackage} --daemon --web-port=${toString cfg.port}
        '';
      in {
        description = "Ember Web Server";
        after = [ "network-online.target" "qmd-mcp.service" ];
        wants = [ "network-online.target" "qmd-mcp.service" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "simple";
          WorkingDirectory = cfg.projectDir;
          Environment = [
            "HOME=%h"
            "QMD_MCP_URL=http://localhost:8181/mcp"
            "PATH=${qmdPkg}/bin:%h/.nix-profile/bin:%h/.local/state/nix/profile/bin:/etc/profiles/per-user/%u/bin:/nix/profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
          ];
          ExecStart = "${emberStart}";
          Restart = "on-failure";
          RestartSec = "10s";
        };

        path = [ qmdPkg "/run/current-system/sw" ];
      };
    };
  };
}
