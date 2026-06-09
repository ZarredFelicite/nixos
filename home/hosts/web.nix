{ inputs, self, pkgs, lib, osConfig, ... }: # Added osConfig

let
  audioSummaryPython = pkgs.python312.withPackages (ps: [ ps.requests ps.numpy ]);
  deepfacePython = pkgs.python313.withPackages (ps: [
    ps.deepface
    ps.fastapi
    ps.numpy
    ps.opencv4
    ps.pgvector
    ps.psycopg
    ps.python-multipart
    ps.tensorflow
    ps.ultralytics
    ps.uvicorn
  ]);
in
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
    ../mail
    ../finance
    ../media
    ../terminal
    ../security.nix
    ../impermanence.nix
    inputs.recall.homeManagerModules.default
  ];

  services.recall = {
    enable = true;
    intervalSeconds = 60;
    debounceSeconds = 1;
  };

  systemd.user.services.audio-summary-obsidian = {
    Unit = {
      Description = "Watch audio recordings and create Obsidian summaries";
      After = [ "network-online.target" "load-api-keys.service" ];
      Wants = [ "network-online.target" "load-api-keys.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${audioSummaryPython}/bin/python3 /home/zarred/scripts/stt/stt --watch --llm-intelligence low --recent-days 7";
      Restart = "always";
      RestartSec = "60s";
      WorkingDirectory = "/home/zarred/scripts/stt";
      Environment = [
        "PATH=${lib.makeBinPath [ audioSummaryPython pkgs.bash pkgs.coreutils pkgs.ffmpeg pkgs.curl pkgs.jq pkgs.pass pkgs.gnupg ]}"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

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
  systemd.user.services.ibkr = {
    Unit.Description = "Serve IBKR web UI with in-process refresh";
    Service.EnvironmentFile = [
      "/home/zarred/.config/ibkr/auth/env.list"
      osConfig.sops.templates."user-api-keys.env".path
    ];
    Service.ExecStart = "/home/zarred/scripts/finances/ibkr/ibkr.py --server --yfinance --flex-period 1 --timer 300 --port 8001 --verbose";
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "0";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.computer-vision = {
    Unit.Description = "Server for computer vision inference";
    Service.User = "zarred";
    Service.ExecStart = "/home/zarred/dev/computer-vision/run.sh";
    Service.Environment = [ "COMPUTER_VISION_PYTHON=${deepfacePython}/bin/python" ];
    Service.Restart = "always";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "5";
    Service.WorkingDirectory = "/home/zarred/dev/computer-vision";
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
    Service.ExecStart = "${deepfacePython}/bin/python -m uvicorn api.main:app --app-dir /home/zarred/dev/deepface --host 0.0.0.0 --port 5005";
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "0";
    Service.WorkingDirectory = "/home/zarred/dev/deepface";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.speech-enhancement = {
    Unit.Description = "MossGAN audio enhancement server";
    Service.Environment = [
      "AUDIO_ENHANCE_BACKEND=mossgan"
      "CLEARVOICE_PYTHON=/persist/home/zarred/.venvs/clearvoice/bin/python"
      "HF_HOME=/persist/home/zarred/.cache/huggingface"
      "LD_LIBRARY_PATH=/run/opengl-driver/lib"
      "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/zarred/bin:/home/zarred/.nix-profile/bin"
    ];
    Service.ExecStart = "/run/current-system/sw/bin/python server_onnx.py --port 8649";
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

  systemd.user.services.chatterbox = {
    Unit.Description = "Chatterbox TTS server";
    Service.User = "zarred";
    Service.ExecStart = "/home/zarred/scripts/tts/chatterbox/systemd-start.sh";
    Service.WorkingDirectory = "/home/zarred/scripts/tts/chatterbox";
    Service.Restart = "on-failure";
    Service.RestartSec = "5s";
    Service.TimeoutStartSec = "15min";
    Service.Environment = [ "PYTHONUNBUFFERED=1" ];
  };

  systemd.user.services.crawl4ai-api = {
    Unit.Description = "Crawl4AI FastAPI server";
    Service.User = "zarred";
    Service.ExecStart = "/run/current-system/sw/bin/nix-shell /home/zarred/scripts/scrapers/crawl4ai/shell.nix --run 'xvfb-run -a -s \"-screen 0 1920x1080x24\" uvicorn server:app --host 0.0.0.0 --port 11235'";
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "0";
    Service.WorkingDirectory = "/home/zarred/scripts/scrapers/crawl4ai";
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

  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
