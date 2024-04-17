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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.substituters = [ "https://cache.nixos.org" ];
  nix.settings.trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  environment = {
    systemPackages = with pkgs; [
      git
      jq
      iotop
      wget
      curl
      neovim
      cmake
      gnumake
      ninja
      direnv
      memtest86plus
      btrfs-progs
    ];
    shells = with pkgs; [ zsh bashInteractive ];
    pathsToLink = [ "/share/zsh" ];
  };
  programs = {
    dconf.enable = true;
    zsh.enable = true;
  };
  documentation.man = {
    # In order to enable to mandoc man-db has to be disabled.
    man-db.enable = false;
    mandoc.enable = true;
    generateCaches = true;
  };
  stylix = {
    autoEnable = true;
    image = /persist/home/zarred/pictures/wallpapers/tarantula_nebula.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    # https://github.com/tinted-theming/base16-schemes
    #override = {
    #  base00 = "#191724";
    #};
    cursor = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "Catppuccin-Mocha-Dark-Cursors";
      size = 20;
    };
    fonts = {
      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
      sansSerif = {
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
        name = "Iosevka Nerd Font";
      };
      serif = {
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
        name = "Iosevka Nerd Font";
      };
      monospace = {
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
        name = "Iosevka Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    targets = {
      #waybar.enable = false;
    };
  };
}
