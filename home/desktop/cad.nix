{ pkgs, ... }:

let
  cadPython = pkgs.callPackage ../../pkgs/cad/build123d.nix { };
in
{
  # Keep the OCP/build123d closure desktop-only and isolated from the shared
  # system Python profile. The environment intentionally exposes its normal
  # `python` and package scripts; the named wrapper remains available too.
  home.packages = [ cadPython.environment cadPython.wrapper ];
}
