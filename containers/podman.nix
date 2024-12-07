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
  users.users.zarred.extraGroups = [ "podman" ];
}
