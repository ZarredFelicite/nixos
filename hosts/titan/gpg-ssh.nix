{ config, ... }:
let
  secretPath = config.sops.secrets.titan-gpg-key.path;
in
{
  sops.secrets.titan-gpg-key = {
    sopsFile = ../../secrets/titan/gpg-key.bin;
    format = "binary";
    owner = "zarred";
    mode = "0400";
  };

  # Keep the runtime importer Titan-only even though Titan reuses Nano's HM
  # profile. It waits for the SOPS runtime secret and never unlocks/signs keys.
  home-manager.users.zarred = { lib, pkgs, ... }: {
    home.file.".pam-gnupg".text = lib.mkForce ''
      13A4FEE773790871433DF46D116C7AE1C597FBDC
      5B32AFE33A293758C727F532FA9BD2E43A44237E
      BEF3920E6B79FF4A4F817838844F26D1BCAE35C9
    '';

    systemd.user.paths.titan-gpg-key = {
      Unit.Description = "Wait for Titan's SOPS-provisioned full GPG key";
      Path = {
        PathExists = secretPath;
        Unit = "titan-gpg-key-import.service";
        # A successful oneshot remains active. The path trigger limit prevents
        # failure retries from looping; retry/rotation needs explicit user action.
        TriggerLimitIntervalSec = "1h";
        TriggerLimitBurst = 1;
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.titan-gpg-key-import = {
      Unit = {
        Description = "Import Titan's SOPS-provisioned full GPG key";
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
