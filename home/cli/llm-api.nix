{ config, lib, pkgs, ... }:

let
  piPackage = pkgs.callPackage ../../pkgs/pi.nix { };
  piSdkPath = "${piPackage}/lib/node_modules/pi-monorepo/dist/index.js";
  llmApiDaemon = pkgs.stdenvNoCC.mkDerivation {
    pname = "llm-api-daemon";
    version = "1.0.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "llm-api-daemon";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/share/llm-api-daemon"
      cp ${./llm-api-daemon.mjs} "$out/share/llm-api-daemon/daemon.mjs"
      makeWrapper ${lib.getExe pkgs.nodejs} "$out/bin/llm-api-daemon" \
        --add-flags "$out/share/llm-api-daemon/daemon.mjs" \
        --set PI_SDK_PATH ${lib.escapeShellArg piSdkPath}
      makeWrapper ${lib.getExe pkgs.nodejs} "$out/bin/llm-api-daemon-client" \
        --add-flags "$out/share/llm-api-daemon/daemon.mjs --client" \
        --set PI_SDK_PATH ${lib.escapeShellArg piSdkPath}
      runHook postInstall
    '';
  };
in
{
  home.packages = [ llmApiDaemon ];

  systemd.user.services.llm-api-daemon = {
    Unit = {
      Description = "Persistent subscription-backed LLM API daemon";
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = lib.getExe llmApiDaemon;
      Restart = "on-failure";
      RestartSec = 1;
      RuntimeDirectory = "llm-api";
      RuntimeDirectoryMode = "0700";
      Environment = "PI_CODING_AGENT_DIR=${config.xdg.configHome}/pi/agent";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
