{ pkgs, ... }:
let
  pi = pkgs.callPackage ../pkgs/pi.nix { };
in
{
  home.packages = with pkgs; [
    kitty
    neomutt
    himalaya
    notmuch
    msmtp
    isync
    tor-browser
    signal-desktop
    mpv
    pass
    gnupg
    python3
    gcc
    pi
  ];

  programs = {
    home-manager.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    starship.enable = true;
    git.enable = true;
    firefox.enable = true;
    zathura.enable = true;
    nixvim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
      opts = {
        number = true;
        relativenumber = true;
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        ignorecase = true;
        smartcase = true;
      };
    };
  };
}
