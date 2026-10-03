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

  # Separate all-author stock scans share the DB but never alter the user RSS feed.
  systemd.user.services.hotcopper-stock-feed = {
    Unit.Description = "Cache recent HotCopper stock discussions from all authors";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "/home/zarred/scripts/finances/ibkr";
      ExecStart = "/home/zarred/scripts/scrapers/hotcopper/stock_feed --once --run-budget 900";
      TimeoutStartSec = "20min";
      Nice = 10;
      MemoryMax = "1G";
      NoNewPrivileges = true;
      PrivateTmp = true;
      Environment = [
        "PATH=/run/current-system/sw/bin:/home/zarred/scripts/ai"
        "HOTCOPPER_CRAWL4AI_BASE=http://web:11235"
        "TZ=Australia/Sydney"
      ];
    };
  };
  systemd.user.timers.hotcopper-stock-feed = {
    Unit.Description = "Refresh cached stock-wide HotCopper discussion in rotating batches";
    Timer = {
      OnStartupSec = "2min";
      OnUnitInactiveSec = "5min";
      AccuracySec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
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
        "PATH=/run/current-system/sw/bin:${lib.makeBinPath [ pkgs.gnupg pkgs.firefox pkgs.geckodriver ]}:/home/zarred/scripts/ai"
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
