{ pkgs, ... }:
let
  gjoa = pkgs.callPackage ../../pkgs/gjoa.nix { };
in {
  imports = [
    ./brave
    ./firefox
  ];
  home.packages = [
    gjoa
    pkgs.tor-browser
  ];
}
