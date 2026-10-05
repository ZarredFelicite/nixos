{ inputs, pkgs, lib, config, osConfig, ... }:
let
  herdrPackage = inputs.herdr.packages.${pkgs.system}.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../../pkgs/herdr-status-dot-spacing.patch ];
  });
  helmRuntimeDir = "${config.xdg.dataHome}/helm";
  helmStateDir = "${config.xdg.stateHome}/herdr-agent-workbench-canary";
  herdrWebPlugin = "${pkgs.callPackage ../../pkgs/herdr-web.nix { }}/lib/node_modules/herdr-web";
  piPackage = pkgs.callPackage ../../pkgs/pi.nix { };
  herdrWebConfigDir = "${config.xdg.configHome}/herdr/plugins/config/barnuri.herdr-web";
  herdrWebStateDir = "${config.xdg.stateHome}/herdr-web";
  herdrWebPath = lib.makeBinPath [
    pkgs.nodejs
    herdrPackage
    piPackage
    pkgs.bash
    pkgs.coreutils
    pkgs.openssl
  ] + ":/run/current-system/sw/bin:/home/zarred/.nix-profile/bin";
in {
  # Host-specific Herdr integrations use the shared CLI package.
  _module.args.herdrPackage = herdrPackage;
  home.packages = [ herdrPackage ];

  # Keep plugin registration in Herdr's mutable registry, preserving existing
  # config, state, and other plugin entries.
  home.activation.herdrWebPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${herdrWebConfigDir}" "${herdrWebStateDir}"
    $DRY_RUN_CMD chmod 700 "${herdrWebConfigDir}" "${herdrWebStateDir}"
    $DRY_RUN_CMD ${herdrPackage}/bin/herdr plugin link "${herdrWebPlugin}"
  '';

  systemd.user.services.herdr-web = {
    Unit = {
      Description = "Herdr Web browser UI";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "${herdrWebPlugin}";
      ExecStart = "${pkgs.nodejs}/bin/node ${herdrWebPlugin}/server.js";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "PATH=${herdrWebPath}"
        "HERDR_PLUGIN_CONFIG_DIR=${herdrWebConfigDir}"
        "HERDR_PLUGIN_STATE_DIR=${herdrWebStateDir}"
        "HERDR_BIN_PATH=${herdrPackage}/bin/herdr"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  # The runtime and private configuration are provisioned separately under
  # persistent user directories. Skip startup on hosts not yet provisioned.
  systemd.user.services.helm = {
    Unit = {
      Description = "Helm agent workspace";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" "helm-proxy.service" ];
      Before = [ "helm-proxy.service" ];
      ConditionPathExists = [
        "${helmRuntimeDir}/bin/helm"
        "${helmStateDir}/remote-security.json"
      ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${helmRuntimeDir}/bin/helm --host 127.0.0.1 --port 8789 --remote-security-config ${helmStateDir}/remote-security.json";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "HERDR_SOCKET_PATH=${config.xdg.configHome}/herdr/herdr.sock"
        "HERDR_WEB_HOST_ID=${if osConfig.networking.hostName == "web" then "agent-workbench-canary" else osConfig.networking.hostName}"
        "HERDR_WEB_SEMANTIC_DIR=${config.xdg.stateHome}/herdr-web-canary/semantic"
        "HERDR_WEB_PI_EXTENSION_ENTRY=${helmRuntimeDir}/share/helm/pi-extension/dist/index.ts"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.helm-proxy = {
    Unit = {
      Description = "Helm local nginx relay";
      After = [ "helm.service" ];
      PartOf = [ "helm.service" ];
      ConditionPathExists = [ "${helmStateDir}/nginx.conf" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nginx}/bin/nginx -e ${helmStateDir}/nginx-error.log -c ${helmStateDir}/nginx.conf -g 'daemon off;'";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
