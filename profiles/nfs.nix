{ config, pkgs, ... }: {
  services.rpcbind.enable = true;
  environment.systemPackages = [ pkgs.nfs-utils ];
  boot.initrd = {
    supportedFilesystems = [ "nfs" ];
    kernelModules = [ "nfs" ];
  };
  # TODO: set correct permissions
  fileSystems = {
    "/mnt/gargantua" = {
      device = "sankara:/mnt/gargantua";
      fsType = "nfs";
      options = [ "x-systemd.automount" "nofail" "_netdev" "x-systemd.idle-timeout=600" "x-systemd.requires=tailscaled.service" ];
    };
    "/mnt/ceres" = {
      device = "sankara:/mnt/ceres";
      fsType = "nfs";
      options = [ "x-systemd.automount" "nofail" "_netdev" "x-systemd.idle-timeout=600" "x-systemd.requires=tailscaled.service" ];
    };
    "/mnt/eros" = {
      device = "sankara:/mnt/eros";
      fsType = "nfs";
      options = [ "x-systemd.automount" "nofail" "_netdev" "x-systemd.idle-timeout=600" "x-systemd.requires=tailscaled.service" ];
    };
    "/mnt/turing" = {
      device = "sankara:/mnt/turing";
      fsType = "nfs";
      options = [ "x-systemd.automount" "nofail" "_netdev" "x-systemd.idle-timeout=600" "x-systemd.requires=tailscaled.service" ];
    };
  };
}
