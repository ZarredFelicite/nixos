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
      "/var/db/sudo/lectured"
      "/etc/NetworkManager/system-connections"
      "/etc/coolercontrol"
    ];
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/nix/id_rsa"
      #"/var/lib/cups/printers.conf"
      #"/var/lib/logrotate.status"
    ];
  };
}
