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
  systemd.user.services.deepface-api = {
    Unit.Description = "DeepFace API server";
    Service.User = "zarred";
    Service.Environment = [
      "DEEPFACE_DATABASE_TYPE=pgvector"
      "DEEPFACE_CONNECTION_DETAILS=postgresql://zarred@/deepface?host=/run/postgresql"
      "OPENCV_OPENCL_RUNTIME=disabled"
      "CUDA_VISIBLE_DEVICES="
      "HIP_VISIBLE_DEVICES="
      "ROCR_VISIBLE_DEVICES="
    ];
    Service.ExecStart = "/run/current-system/sw/bin/python -m uvicorn api.main:app --app-dir /home/zarred/dev/deepface --host 0.0.0.0 --port 5005";
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "0";
    Service.WorkingDirectory = "/home/zarred/dev/deepface";
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
  systemd.user.services.soprano-streaming-server = {
    Unit.Description = "Soprano low-latency streaming TTS server";
    Service.User = "zarred";
    Service.ExecStart = "/run/current-system/sw/bin/nix-shell /home/zarred/scripts/tts/soprano/shell.nix --run '/home/zarred/.micromamba/envs/soprano/bin/python /home/zarred/scripts/tts/soprano/streaming_server.py --backend lmdeploy --device cuda --host 0.0.0.0 --port 8000'";
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "0";
    Service.WorkingDirectory = "/home/zarred/scripts/tts/soprano";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };

  systemd.user.services.lwake-multi-listen = {
    Unit.Description = "Listen for local wake words and trigger phrase actions";
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      ExecStart = "/home/zarred/scripts/stt/lwake-multi-listen.sh /home/zarred/audio/wake-words";
      Restart = "always";
      RestartSec = "2s";
      StartLimitIntervalSec = "0";
    };
  };

  # Expose loopback-bound OpenClaw gateway over Tailscale Serve (HTTPS).
  systemd.user.services.openclaw-tailnet-serve = {
    Unit = {
      Description = "OpenClaw gateway via Tailscale Serve (HTTPS 18789)";
      After = [ "network-online.target" "openclaw-gateway.service" ];
      Wants = [ "network-online.target" "openclaw-gateway.service" ];
      PartOf = [ "openclaw-gateway.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https 18789 https+insecure://127.0.0.1:18789";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=18789 off";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
