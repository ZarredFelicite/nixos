{ config, pkgs, ... }:
let
  nfsMounts = [
    "/mnt/gargantua"
    "/mnt/ceres"
    "/mnt/eros"
    "/mnt/turing"
  ];

  nfsOptions = [
    "x-systemd.automount"
    "noauto"
    "nofail"
    "_netdev"
    "x-systemd.idle-timeout=600"
    "x-systemd.requires=tailscaled.service"
    "x-systemd.mount-timeout=15s"
    "x-systemd.device-timeout=5s"
    "timeo=100"
    "retrans=2"
  ];
in {
  services.rpcbind.enable = true;
  environment.systemPackages = [ pkgs.nfs-utils ];
  systemd.services.nfs-automounts-delayed = {
    description = "Start NFS automounts after boot settles";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemctl start mnt-gargantua.automount mnt-ceres.automount mnt-eros.automount mnt-turing.automount
    '';
  };

  systemd.timers.nfs-automounts-delayed = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      Unit = "nfs-automounts-delayed.service";
    };
  };

  systemd.services.nfs-client-cleanup = {
    description = "Stop local NFS users and detach NFS mounts before sleep/shutdown";
    wantedBy = [ "sleep.target" "shutdown.target" ];
    before = [
      "sleep.target"
      "shutdown.target"
      "umount.target"
      "mnt-gargantua.mount"
      "mnt-ceres.mount"
      "mnt-eros.mount"
      "mnt-turing.mount"
      "tailscaled.service"
      "network.target"
    ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "20s";
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl stop mpd.service 2>/dev/null || true
      ${pkgs.psmisc}/bin/fuser -km ${builtins.concatStringsSep " " nfsMounts} 2>/dev/null || true
      ${pkgs.util-linux}/bin/umount -f -l ${builtins.concatStringsSep " " nfsMounts} 2>/dev/null || true
    '';
  };

  # TODO: set correct permissions
  fileSystems = {
    "/mnt/gargantua" = {
      device = "sankara:/mnt/gargantua";
      fsType = "nfs";
      options = nfsOptions;
    };
    "/mnt/ceres" = {
      device = "sankara:/mnt/ceres";
      fsType = "nfs";
      options = nfsOptions;
    };
    "/mnt/eros" = {
      device = "sankara:/mnt/eros";
      fsType = "nfs";
      options = nfsOptions;
    };
    "/mnt/turing" = {
      device = "sankara:/mnt/turing";
      fsType = "nfs";
      options = nfsOptions;
    };
  };
}
