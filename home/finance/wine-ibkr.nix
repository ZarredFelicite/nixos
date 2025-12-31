{ pkgs, fetchurl, ... }:
let
  bin = pkgs.wrapWine {
    name = "ibkr";
    executable = "/home/zarred/games/installers/ntws-latest-standalone-windows-x64.exe";
    home = "/home/zarred/games/wine-ibkr";
  };
in pkgs.makeDesktopItem {
  name = "ibkr";
  desktopName = "IBKR";
  type = "Application";
  exec = ''${bin}/bin/ibkr'';
  icon = fetchurl {
    # icon from playstore
    name = "amongus.png";
    url = "https://play-lh.googleusercontent.com/l6m9l92a4SgtCXGnJX97AXNSSh8eVZPxDLpklXe4QpSE2PGam69wTWzr1sna1fc74no6=w240-h480-rw";
    sha256 = "0knyfxbmnw0ad68zv9h5rmh6102lnn81silzkqi1rpixzc2dgp6b"; # NOTE: UPDATE
  };
}
