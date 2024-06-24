{ lib
, fetchurl
, writeText
, appimageTools
}:

let omniverse-launcher-desktop = writeText "omniverse-launcher.desktop" ''
      [Desktop Entry]
      Exec=omniverse-launcher %u
      Terminal=false
      Type=Application
      Name=omniverse-launcher
      MimeType=x-scheme-handler/omniverse-launcher
    '';

in appimageTools.wrapType2 {
  name = "omniverse-launcher";

  src = fetchurl {
    url = "https://extorage.breakds.org/binaries/omniverse-launcher-linux.AppImage";
    sha256 = "03rqbg8ghlm3yh9yfsfazl836nkwbagfzb05lv7rz2j196wz2j9f";
  };

  extraPkgs = pkgs: with pkgs; [ icu ];

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    ln -s ${omniverse-launcher-desktop} $out/share/applications/omniverse-launcher.desktop
  '';
}
