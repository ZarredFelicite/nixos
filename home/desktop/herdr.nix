{ inputs, pkgs, lib, config, ... }:
let
  herdrPackage = inputs.herdr.packages.${pkgs.system}.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../../pkgs/herdr-status-dot-spacing.patch ];
  });
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
in
{
  home.packages = [ herdrPackage ];

  # Herdr's registry is mutable user state. Register the immutable packaged
  # plugin through Herdr's supported command; this preserves other entries and
  # leaves existing config, state, and manual checkout files untouched.
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
        "HERDR_WEB_HOST=127.0.0.1"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
