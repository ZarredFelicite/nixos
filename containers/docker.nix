{ config, pkgs, ... }: {
  virtualisation.docker = {
    enable = false;
    enableOnBoot = true;
    enableNvidia = false; #TODO
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
    enable = false; #TODO
  };
  users.users.zarred.extraGroups = [ "docker" ];
  # windows in docker https://github.com/dockur/windows
}
