flake: final: prev:
let
  inherit (flake.outputs) global;
  inherit (global) rootPath;
  inherit (final) callPackage;
  inherit (prev) lib writeShellScript;
  inherit (lib) recursiveUpdate;
  inherit (builtins) toString length head tail;
in
let
  cp = f: (callPackage f) { };
in
{
  inherit flake;

  wrapWine = cp ../pkgs/wrapWine.nix;
}
