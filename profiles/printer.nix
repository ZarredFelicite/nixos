{ pkgs, config, lib, ... }: {
  #  lib.mkIf config.services.klipper.enable
  virtualisation.oci-containers.containers."mainsail" = {
    image = "ghcr.io/mainsail-crew/mainsail";
    ports = [ "8001:80" ];
    #extraOptions = ["--network=host"];
    volumes = [
      "/var/lib/mainsail/config.json:/usr/share/nginx/html/config.json"
    ];
  };
  networking.firewall.allowedTCPPorts = [ 7125 ];
  #lib.mkIf config.services.klipper.enable
  #virtualisation.oci-containers.containers."mainsail" = {
  #  image = "ghcr.io/mainsail-crew/mainsail";
  #  ports = [ "80:8001" ];
  #  extraOptions = ["--network=host"];
  #  volumes = [
  #    "/var/mainsail/config.json:/usr/share/nginx/html/config.json"
  #  ];
  #};
  #services.mainsail = {
  #  enable = lib.mkIf config.services.klipper.enable true;
  #  hostName = "mainsail.zar.red";
  #};
  #services.fluidd = {
  #  enable = true;
  #  hostName = "fluidd.zar.red";
  #  nginx.acmeRoot = null;
  #};
  services.moonraker = {
    enable = lib.mkIf config.services.klipper.enable true;
    user = "zarred";
    group = "users";
    stateDir = "/var/lib/moonraker";
    port = 7125;
    address = "0.0.0.0";
    klipperSocket = config.services.klipper.apiSocket;
    allowSystemControl = true;
    settings = {
      authorization = {
        cors_domains = [
          "https://mainsail.zar.red"
          "http://192.168.86.200:8001"
        ];
        trusted_clients = [
          "192.168.86.0/24"
        ];
      };
      file_manager.enable_object_processing = true;
      announcements.subscriptions = [ "mainsail" ];
    };
  };
  services.klipper = {
    user = "zarred";
    group = "users";
    mutableConfig = true;
    mutableConfigFolder = "/var/lib/moonraker/config";
    logFile = "/var/lib/moonraker/logs/klipper.log";
    inputTTY = "/run/klipper/tty";
    apiSocket = "/run/klipper/api";
    configFile = "/var/lib/moonraker/config/printer.cfg";
  };
}
