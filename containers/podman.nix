{ config, pkgs, ... }: {
  imports = [
    #./cvat.nix
  ];
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = false;
  };
  users.extraUsers.zarred.extraGroups = [ "podman" ];
  #virtualisation.oci-containers.containers."stirling-pdf" = {
  #  image = "docker.io/frooodle/s-pdf:latest";
  #  ports = [ "8088:8080" ];
  #  environment = {
  #    DOCKER_ENABLE_SECURITY = "false";
  #  };
  #  volumes = [
  #    "/var/lib/stirling-pdf/customFiles:/customFiles/"
  #    "/var/lib/stirling-pdf/extraConfigs:/configs"
  #    "/var/lib/stirling-pdf/trainingData:/usr/share/tesseract-ocr/4.00/tessdata"
  #  ];
  #};
  users.users.zarred.extraGroups = [ "podman" ];
}
