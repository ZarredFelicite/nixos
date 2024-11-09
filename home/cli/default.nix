{ self, inputs, outputs, config, pkgs, lib, ... }: {
  imports = [
    ./zsh
    ./nixvim
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
    inputs.qrrs.packages.x86_64-linux.default
  ];
  xdg.configFile."fd/ignore".text = ''
    /mnt
  '';
  programs = {
    zsh.enable = true;
    direnv.enable = true;
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
      icons = "auto";
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
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
  xdg.configFile."neofetch/config.conf".source = ./neofetch_config.conf;
  xdg.configFile."../.gnuplot".text = ''
    set macros
    png="set terminal png size 1800,1800 crop enhanced font \"/usr/share/fonts/truetype/times.ttf,30\" dashlength 2; set termoption linewidth 3"
    eps="set terminal postscript fontfile \"/usr/share/fonts/truetype/times.ttf\"; set termoption linewidth 3;

    set style line 1 linecolor rgb '#de181f' linetype 1  # Red
    set style line 2 linecolor rgb '#0060ae' linetype 1  # Blue
    set style line 3 linecolor rgb '#228C22' linetype 1  # Forest green

    set style line 4 linecolor rgb '#18ded7' linetype 1  # opposite Red
    set style line 5 linecolor rgb '#ae4e00' linetype 1  # opposite Blue
    set style line 6 linecolor rgb '#8c228c' linetype 1  # opposite Forest green
  '';
}
