{ config, pkgs, ... }: {
  #virtualisation.oci-containers.backend = "docker";
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
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
