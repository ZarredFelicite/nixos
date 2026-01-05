{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied

    # Desktop specific modules (previously via home/desktop.nix)
    ../browser
    ../desktop # This is home/desktop/default.nix
    ../theme
    ../gaming

    # Modules for a full desktop experience (previously via home/core.nix's imports)
    ../cli
    ../menu
    ../mail
    ../finance
    ../media
    ../terminal
    ../security.nix
    ../impermanence.nix
  ];

  systemd.user.services.stocks = {
    Unit.Description = "Get stock prices from yfinance";
    Service.ExecStart = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.hotcopper = {
    Unit.Description = "Scrape HotCopper for user posts";
    Service.ExecStart = "/home/zarred/scripts/scrapers/hotcopper/hotcopper_parse.py -rst 300";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.abc-news = {
    Unit.Description = "Summarize abc news rss feed";
    Service.ExecStart = "/home/zarred/scripts/rss/rss-transform/rss_transformer.py --interval 300";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.timers.ibkr = {
    Unit.Description = "Timer for ibkr stocks service";
    Unit.Requires = "ibkr.service";
    Install.WantedBy = [ "timers.target" ];
    Timer.OnCalendar = "*:0/5";
    Timer.Persistent = true;
  };
  systemd.user.services.ibkr = {
    Unit.Description = "Get stocks data from ibkr and yfinance";
    Service.ExecStart = "/home/zarred/scripts/finances/ibkr/ibkr.py -psyvc --flex-period 1";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.computer-vision = {
    Unit.Description = "Server for computer vision inference";
    Service.User = "zarred";
    Service.ExecStart = "/home/zarred/dev/yolo-server/run.sh";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "5";
    Service.WorkingDirectory = "/home/zarred/dev/yolo-server";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.speech-enhancement = {
    Unit.Description = "Server for streaming audio for speech enhancement";
    Service.User = "zarred";
    Service.ExecStart = "/run/current-system/sw/bin/nix develop --command ./entry.sh";
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "5";
    Service.WorkingDirectory = "/home/zarred/dev/speech-enhancement/gtcrn";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
