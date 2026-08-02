{ inputs, pkgs, ... }:
let
  gjoa = pkgs.callPackage ../../pkgs/gjoa.nix { };
in {
  imports = [
    ./brave
    ./firefox
  ];
  home.packages = [
    gjoa
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.tor-browser
  ];
}
