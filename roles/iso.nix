{ config, pkgs, modulesPath, ... }: {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    settings.KbdInteractiveAuthentication = true;
    settings.PermitRootLogin = "yes";
    hostKeys = [ { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; } ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+Xu5vJqXmgaWKHIp+4IsorATOO61u5X5ECanN3dn31 openpgp:0xD8C648AB"
  ];
  #networking = {
  #  networkmanager.enable = true;
  #  firewall.enable = false;
  #  #useDHCP = false;
  #  #wireless.enable = false;
  #  hostName = "nixos-iso";
  #};
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
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
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
  };
}
