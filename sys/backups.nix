{ pkgs, lib, config, ... }: {
  environment.systemPackages = [ pkgs.restic ];
  services.restic.backups = {
    sankara-home = {
      repository = "sftp:zarred@sankara:/mnt/gargantua/backups/restic";
      user = "zarred";
      extraOptions = [
        "sftp.command='ssh sankara -i /home/zarred/.ssh/id_ed25519 -s sftp'"
      ];
      passwordFile = "${config.sops.secrets.restic-home.path}";
      paths = [
        "/home/zarred"
      ];
      exclude = [
        "/home/zarred/.cache"
        "/home/zarred/games"
        "/home/zarred/downloads/games"
      ];
      timerConfig = {
        #OnCalendar = "daily";
        OnCalendar = "18:35";
        Persistent = true;
        #RandomizedDelaySec = "5h";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 75"
      ];
      inhibitsSleep = false; # TODO: systemd-inhibit[388820]: Failed to inhibit: Access denied
      backupPrepareCommand = "export DISPLAY=:0; export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1002/bus'; ${pkgs.libnotify}/bin/notify-send 'Restic' 'Backup starting'";
      backupCleanupCommand = "export DISPLAY=:0; export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1002/bus'; ${pkgs.libnotify}/bin/notify-send 'Restic' 'Backup complete'";
    };
  };
}
