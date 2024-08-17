{ ... }: {
  services.gotify = {
    environment.GOTIFY_SERVER_PORT = 8081;
    stateDirectoryName = "gotify";
  };
  virtualisation.oci-containers.containers."homarr" = {
    image = "ghcr.io/ajnart/homarr";
    ports = [ "7575:7575" ];
    extraOptions = ["--network=host"];
    volumes = [
      "/var/lib/homarr/configs:/app/data/configs"
      "/var/lib/homarr/icons:/app/public/icons"
      "/var/lib/homarr/data:/data"
    ];
  };
  virtualisation.oci-containers.containers."dashdot" = {
    image = "mauricenino/dashdot:latest";
    ports = [ "80:3001" ];
    environment = {
      DASHDOT_ENABLE_CPU_TEMPS = "true";
      DASHDOT_ALWAYS_SHOW_PERCENTAGES = "true";
      #DASHDOT_WIDGET_LIST = "os,cpu,storage,ram,network,gpu";
    };
    extraOptions = ["--network=host" "--privileged"];
    volumes = [
      "/:/mnt/host:ro"
    ];
  };
  #virtualisation.oci-containers.containers."homepage" = {
  #  autoStart = true;
  #  image = "ghcr.io/benphelps/homepage:latest";
  #  #user = "zarred:users";
  #  environment = {
  #    PUID = "1000";
  #    PGID = "1000";
  #    LOG_LEVEL = "debug";
  #  };
  #  ports = [ "3000:3000" ];
  #  #workdir = "/var/lib/homepage";
  #  volumes = [
  #    "/var/lib/homepage:/app/config"
  #    "/mnt/mass:/mnt/mass"
  #    "/mnt/linus:/mnt/linus"
  #  ];
  #  extraOptions = ["--network=host"];
  #};
}
