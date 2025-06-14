{ pkgs, lib, config, ... }: {
  environment.systemPackages = [ pkgs.restic ];
  environment.sessionVariables = {
    RESTIC_REPOSITORY = config.services.restic.backups.home.repository;
    RESTIC_PASSWORD_FILE = config.sops.secrets.restic-home.path;
  };
  systemd.services.restic-backups-home.environment.SSH_AUTH_SOCK = "/run/user/1002/gnupg/S.gpg-agent.ssh";
  services.restic.backups = {
    home = {
      repository = "sftp:zarred@sankara:/mnt/gargantua/backups/restic/${config.networking.hostName}-home";
      initialize = true;
      user = "zarred";
      extraOptions = [
        "sftp.command='ssh zarred@sankara -s sftp'"
      ];
      #extraBackupArgs = [
      #  "--dry-run"
      #];
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
        OnCalendar = "daily";
        #OnCalendar = "23:04";
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
      backupPrepareCommand = "export SSH_AUTH_SOCK=/run/user/1002/gnupg/S.gpg-agent.ssh; ssh-add -L; export DISPLAY=:0; export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1002/bus'; ${pkgs.libnotify}/bin/notify-send 'Restic' 'Backup starting'";
      backupCleanupCommand = "touch /run/restic-backups-home/includes; export DISPLAY=:0; export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1002/bus'; ${pkgs.libnotify}/bin/notify-send 'Restic' 'Backup complete'";
    };
  };
}
