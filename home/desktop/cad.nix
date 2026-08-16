{ pkgs, ... }:

let
  build123dPython = pkgs.callPackage ../../pkgs/cad/build123d.nix { };
in
{
  # Keep the OCP/build123d closure desktop-only and isolated from the shared
  # system Python profile. Use the named wrapper to avoid colliding with the
  # profile's existing python3 executable.
  home.packages = [ build123dPython ];
}
