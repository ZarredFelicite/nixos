{ config, pkgs, ... }: {
  imports = [
    #./cvat.nix
  ];
  virtualisation.oci-containers.backend = "podman";
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
