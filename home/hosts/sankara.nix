{ inputs, self, pkgs, lib, config, osConfig, ... }: # Added osConfig

let
  piPackage = pkgs.callPackage ../../pkgs/pi.nix { };
  piSdkPath = "${piPackage}/lib/node_modules/pi-monorepo/dist/index.js";
in
{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied

    ../theme

    # Modules for a server/CLI focused experience (previously via home/core.nix's imports)
    ../cli # General CLI applications and tools
    ../mail      # For CLI mail clients or background sync
    ../finance
    ../media     # For CLI media tools or background services
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  # Placeholder for any home-manager settings absolutely specific to zarred on sankara
  # that don't fit into a reusable profile.
  home.packages = [ pkgs.firefox ]; # required for web scraping with selenium

  systemd.user.services.llm-api-daemon = {
    Unit.Description = "Persistent subscription-backed LLM API daemon";
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.nodejs} /home/zarred/scripts/ai/llm-api-daemon.mjs";
      Restart = "on-failure";
      RestartSec = 1;
      RuntimeDirectory = "llm-api";
      RuntimeDirectoryMode = "0700";
      Environment = [
        "PI_CODING_AGENT_DIR=${config.xdg.configHome}/pi/agent"
        "PI_SDK_PATH=${piSdkPath}"
      ];
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.hotcopper = {
    Unit.Description = "Scrape HotCopper for user posts";
    Unit.After = [ "graphical-session.target" ];
    Unit.StartLimitIntervalSec = 0;
    Service = {
      ExecStart = "/home/zarred/scripts/scrapers/hotcopper/hotcopper_parse.py -rst 300 --serve --serve-port 8186";
      Restart = "always";
      RestartSec = "300s";
      RuntimeMaxSec = "6h";
      MemoryMax = "3G";
      MemorySwapMax = "4G";
      Environment = [
        "PATH=${lib.makeBinPath [ pkgs.gnupg pkgs.firefox pkgs.geckodriver ]}:$PATH"
        "FIREFOX_BIN=${pkgs.firefox}/bin/firefox"
        "GECKODRIVER_BIN=${pkgs.geckodriver}/bin/geckodriver"
        "GECKODRIVER_LOG_PATH=/tmp/hotcopper_geckodriver.log"
        "MOZ_HEADLESS=1"
        "HOME=/home/zarred"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
