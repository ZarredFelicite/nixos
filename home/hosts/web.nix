{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

{
  imports = [
    ../core-settings.nix
    ../xdg-settings.nix
    ../home.nix # Main collection of remaining settings from old core.nix - will be emptied
    #../python.nix # All python packages

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
  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
