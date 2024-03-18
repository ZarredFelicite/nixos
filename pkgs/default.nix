{ pkgs, ... }:
let
  wrapWine = pkgs.callPackage ./wrapWine.nix {};
in
{
  environment.systemPackages = [ wrapWine ];
  #iio-hyprland = pkgs.callPackage ./iio-hyprland.nix { };
}
