{ pkgs, ... }: {
  imports = [
    ./brave
    ./firefox
  ];
  home.packages = [
    pkgs.tor-browser
  ];
}
