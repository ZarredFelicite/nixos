{ lib
, stdenvNoCC
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-quality-menu";
  version = "unstable-2023-9-30";

  src = fetchFromGitHub {
    owner = "christoph-heinrich";
    repo = "mpv-quality-menu";
    rev = "c326936094fa3ba5f841e17aaafc157b2b4f38f5";
    sha256 = "sha256-y2XYl40OU6O6TTzDxs1cCH6jOOR2i43aYqkjG+git1E=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mpv/scripts
    cp quality-menu.lua $out/share/mpv/scripts
    runHook postInstall
  '';

  passthru.scriptName = "quality-menu.lua";

  meta = with lib; {
    description = "A userscript for MPV that allows you to change youtube video quality (ytdl-format) on the fly";
    homepage = "https://github.com/christoph-heinrich/mpv-quality-menu";
    license = licenses.unfree;
    platforms = platforms.all;
    maintainers = with maintainers; [ lunik1 ];
  };
}
