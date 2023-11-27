{ self, inputs, outputs, config, pkgs, lib, ... }: {
  imports = [
    ./zsh/zsh.nix
    ./nixvim.nix
    ./neovim.nix
    ./nb.nix
    ./sys_monitors.nix
    ./newsboat.nix
    ./nnn/default.nix
    ./tmux.nix
    ./glow.nix
    ./ueberzugpp.nix
  ];
  home.packages = with pkgs; [
    fd # A simple, fast and user-friendly alternative to find
  ];
  xdg.configFile."fd/ignore".text = ''
    /mnt
  '';
  programs = {
    zsh = {
      enable = true;
      shellAliases = {
        ls = "eza";
        lsa = "eza -a";
        lsl = "eza -l";
        lsla = "eza -al";
        lst = "eza --tree";
        lsta = "eza --tree -a";
        lstl = "eza --tree -l";
        lstla = "eza --tree -la";
      };
    };
    nixvim.enable = true;
    nnn.enable = true;
    tmux.enable = true;
    eza = {
      enable = true;
      extraOptions = [
        "--icons"
        "--sort=modified"
      ];
      git = true;
      icons = true;
      enableAliases = false;
    };
    script-directory = {
      enable = true;
      settings = {
        SD_ROOT = "${config.home.homeDirectory}/scripts";
        SD_EDITOR = "$EDITOR";
        SD_CAT = "$PAGER";
      };
    };
    hyfetch = {
      enable = true;
      #settings = builtins.toJSON {};
    };
  };
  xdg.configFile."neofetch.conf".source = ./config.conf;
}
