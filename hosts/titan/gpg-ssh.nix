{ config, ... }:
let
  secretPath = config.sops.secrets.titan-gpg-auth-subkey.path;
in
{
  sops.secrets.titan-gpg-auth-subkey = {
    sopsFile = ../../secrets/titan/gpg-auth-subkey.bin;
    format = "binary";
    owner = "zarred";
    mode = "0400";
  };

  # Keep the runtime importer Titan-only even though Titan reuses Nano's HM
  # profile. It waits for the SOPS runtime secret and never unlocks/signs keys.
  home-manager.users.zarred = { lib, pkgs, ... }: {
    systemd.user.paths.titan-gpg-auth-subkey = {
      Unit.Description = "Wait for Titan's SOPS-provisioned GPG auth subkey";
      Path = {
        PathExists = secretPath;
        Unit = "titan-gpg-auth-subkey-import.service";
        # A successful oneshot remains active. The path trigger limit prevents
        # failure retries from looping; retry/rotation needs explicit user action.
        TriggerLimitIntervalSec = "1h";
        TriggerLimitBurst = 1;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.titan-gpg-auth-subkey-import = {
      Unit = {
        Description = "Import Titan's SOPS-provisioned GPG auth subkey";
        ConditionPathExists = secretPath;
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        Environment = [
          "GNUPGHOME=%h/.gnupg"
          "LC_ALL=C"
          "PATH=${lib.makeBinPath [ pkgs.gnupg pkgs.python3 ]}"
        ];
        ExecStart = "${pkgs.bash}/bin/bash ${./gpg-import.sh} ${secretPath}";
      };
    };
  };
}
