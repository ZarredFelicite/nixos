{ pkgs, config, ... }: {
  services.nextcloud = {
    package = pkgs.nextcloud29;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = "/mnt/gargantua/nextcloud";
    settings = {
      trusted_domains = [ "localhost" ];
    };
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
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
}
