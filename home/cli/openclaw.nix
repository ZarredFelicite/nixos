{ osConfig, pkgs, inputs, lib, ... }:
let
  qmdSrc = inputs.qmd;

  qmdNodeModules = pkgs.stdenvNoCC.mkDerivation {
    pname = "qmd-node-modules";
    version = "1.0.0";
    src = qmdSrc;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install --frozen-lockfile --no-progress
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules $out/
      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-LPAbmfBXKlTmInQ+KYJrTvlB1Z9esBY9yziQ8IkKbtY=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  qmdPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "qmd";
    version = "1.0.0";
    src = qmdSrc;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ pkgs.sqlite ];

    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/qmd $out/bin
      cp -r src $out/lib/qmd/
      cp package.json bun.lock $out/lib/qmd/
      cp -r ${qmdNodeModules}/node_modules $out/lib/qmd/

      makeWrapper ${pkgs.bun}/bin/bun $out/bin/qmd \
        --add-flags "$out/lib/qmd/src/qmd.ts" \
        --set DYLD_LIBRARY_PATH "${pkgs.sqlite.out}/lib" \
        --set LD_LIBRARY_PATH "${pkgs.sqlite.out}/lib"

      runHook postInstall
    '';
  };

  # Create a wrapper script that sets OPENROUTER_API_KEY from the secret file
  openclawWrapper = pkgs.writeShellScript "openclaw-gateway-wrapper" ''
    export OPENROUTER_API_KEY=$(cat ${osConfig.sops.secrets.openrouter-api.path})
    exec ${pkgs.openclaw-gateway}/bin/openclaw gateway --port 18789
  '';
in {
  home.packages = [ pkgs.openclaw-gateway qmdPkg ];

  # Manually defined service (bypasses the module's config generation)
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "Openclaw Gateway";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${openclawWrapper}";
      WorkingDirectory = "%h/.openclaw";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "MOLTBOT_NIX_MODE=1"
        "CLAWDBOT_NIX_MODE=1"
        "HOME=%h"
        "PATH=${qmdPkg}/bin:${pkgs.openssl.bin}/bin:/run/current-system/sw/bin"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
