{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}:

stdenvNoCC.mkDerivation rec {
  pname = "obscura";
  version = "0.2.0";

  src = fetchurl {
    url = "https://github.com/h4ckf0r0day/obscura/releases/download/v${version}/obscura-x86_64-linux.tar.gz";
    hash = "sha256-1gH09UIxnDufqNyp9cz8E0osoAFkjaUo218DyebCWZs=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$TMPDIR/obscura"
    tar -xzf "$src" -C "$TMPDIR/obscura"
    install -Dm755 "$TMPDIR/obscura/obscura" "$out/bin/obscura"
    install -Dm755 "$TMPDIR/obscura/obscura-worker" "$out/bin/obscura-worker"

    runHook postInstall
  '';

  meta = {
    description = "Fast, privacy-focused web scraping CLI";
    homepage = "https://github.com/h4ckf0r0day/obscura";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "obscura";
  };
}
