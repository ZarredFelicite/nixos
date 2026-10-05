{ inputs, pkgs, ... }:
let
  herdrPackage = inputs.herdr.packages.${pkgs.system}.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../../pkgs/herdr-status-dot-spacing.patch ];
  });
in {
  # Web's Herdr services use the same package as the shared CLI installation.
  _module.args.herdrPackage = herdrPackage;
  home.packages = [ herdrPackage ];
}
