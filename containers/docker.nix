{ config, pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "btrfs";
    #rootless = {
    #  enable = true;
    #  setSocketVariable = true;
    #};
    #daemon.settings = {
    #  data-root = "/home/zarred/.local/share/docker";
    #};
  };
  environment.systemPackages = [ pkgs.docker-compose pkgs.docker-client ];
  hardware.nvidia-container-toolkit = {
    enable = if config.networking.hostName == "nano" then false else true;
  };
  users.users.zarred.extraGroups = [ "docker" ];
  # windows in docker https://github.com/dockur/windows
}
