{ ... }:
final: prev:

let unstablePkgs = import (builtins.fetchTarball {
      # Nov 18 2022
      url = https://github.com/NixOS/nixpkgs/tarball/a04a4bbbeb5476687a5a1444a187c4b2877233ed;
      sha256 = "1n8sb8a0bv9lg4rihpg9df5x55zq3baqc9055n3jydakncca374f"; # NOTE: UPDATE
    }) {
      config.allowUnfree = true;
      system = prev.system;
    };

in {
  omniverse-launcher = final.callPackage ../pkgs/omniverse/bin.nix {};
}
