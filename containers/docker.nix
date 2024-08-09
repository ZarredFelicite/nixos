{ config, pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    enableNvidia = false;
    storageDriver = "btrfs";
    #rootless = {
    #  enable = true;
    #  setSocketVariable = true;
    #};
    #daemon.settings = {
    #  data-root = "/home/zarred/.local/share/docker";
    #};
  };
  environment.systemPackages = [ pkgs.docker-compose ];
  virtualisation.containers.cdi.dynamic.nvidia.enable = false;
  users.users.zarred.extraGroups = [ "docker" ];
  # windows in docker https://github.com/dockur/windows
}
