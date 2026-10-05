{ inputs, pkgs, config, osConfig, ... }:
let
  herdrPackage = inputs.herdr.packages.${pkgs.system}.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../../pkgs/herdr-status-dot-spacing.patch ];
  });
  helmRuntimeDir = "${config.xdg.dataHome}/helm";
  helmStateDir = "${config.xdg.stateHome}/herdr-agent-workbench-canary";
in {
  # Host-specific Herdr integrations use the shared CLI package.
  _module.args.herdrPackage = herdrPackage;
  home.packages = [ herdrPackage ];

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
