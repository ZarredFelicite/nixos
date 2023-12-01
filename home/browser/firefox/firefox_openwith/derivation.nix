{ pkgs }:
  pkgs.stdenv.mkDerivation {
    pname = "firefox-native-client";
    version = "0.1";
    src = ./.;
    installPhase = ''
      mkdir -p $out/bin
      cp $src/run.sh $out/bin/native-messaging-run.sh
      cp $src/host.js $out/bin/native-me
      cp $src/follow-redirects.js $out/bin/
      cp $src/messaging.js $out/bin/
    '';
  }
