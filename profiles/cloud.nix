{ pkgs, config, ... }: {
  services.nextcloud = {
    package = pkgs.nextcloud30;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = "/mnt/gargantua/nextcloud";
    settings = {
      trusted_domains = [ "localhost" ];
    };
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
      dbtype = "sqlite";
    };
    database.createLocally = true;
  };
  virtualisation.oci-containers.containers."stirling-pdf" = {
    image = "docker.io/frooodle/s-pdf:latest";
    ports = [ "8088:8080" ];
    environment = {
      DOCKER_ENABLE_SECURITY = "false";
    };
    volumes = [
      "/var/lib/stirling-pdf/customFiles:/customFiles/"
      "/var/lib/stirling-pdf/extraConfigs:/configs"
      "/var/lib/stirling-pdf/trainingData:/usr/share/tesseract-ocr/4.00/tessdata"
    ];
  };
  services.immich = {
    enable = true;
    secretsFile = config.sops.secrets.immich-secrets.path;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/mnt/gargantua/immich";
  };
}
