{ config, pkgs, ... }: {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.KbdInteractiveAuthentication = true;
    settings.PermitRootLogin = "yes";
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2kS4ceJ24y6rLbPakB5b38Q46K2jZ/gABaYwfZx1GC zarred@archdesktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII0cpNhpg5cr0WAQXlPkOjoSu7iyeC5+pIIR2bGnNHqU zarred.f@gmail.com"
  ];
  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
    useDHCP = false;
    wireless.enable = false;
    #usePredictableInterfaceNames = false;
    #interfaces.eth0.ip4 = [{
    #  address = "192.168.86.110";
    #  prefixLength = 24;
    #}];
    #defaultGateway = "192.168.86.110";
    #nameservers = [ "8.8.8.8" ];
    hostName = "nixos-iso";
  };
}
