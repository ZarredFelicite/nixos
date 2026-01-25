{ inputs, lib, config, ... }: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];
  programs.fuse.userAllowOther = true;
  environment.persistence."/persist" = {
    directories = [
      "/root/.ssh"
      "/var/log"
      "/var/lib"
      "/var/cache"
      "/var/db/sudo/lectured"
      "/etc/NetworkManager/system-connections"
      "/etc/coolercontrol"
      "/nixos" # for nixos github repo
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/nix/id_rsa"
      "/etc/lact/config.yaml" # LACT GPU overclocking config
    ];
  };
}
