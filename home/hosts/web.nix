{ inputs, self, pkgs, pkgs-unstable, pkgs-ollama, lib, config, osConfig, ... }: # Added osConfig

let
  piPackage = pkgs.callPackage ../../pkgs/pi.nix { };
  ollamaCudaPackage = pkgs-ollama.ollama-cuda;
  ollamaCudaLib = "${ollamaCudaPackage}/lib/ollama";
  piSdkPath = "${piPackage}/lib/node_modules/pi-monorepo/dist/index.js";
  audioSummaryPython = pkgs.python312.withPackages (ps: [ ps.requests ps.numpy ]);
  announcementWatcherPython = pkgs.python313.withPackages (ps: [ ps.requests ]);
  rssNewsPython = pkgs.python312.withPackages (ps: [ ps.requests ps.html2text ]);
  gemma4ModelsPreset = pkgs.writeText "gemma4-models.ini" ''
    version = 1

    [gemma4-e4b-it-qat]
    model = /home/zarred/.cache/llama-models/gemma4-e4b-it-qat-q4_0.gguf
    ctx-size = 65536
    n-gpu-layers = 99
    device = CUDA0
    parallel = 1
    reasoning = off
    reasoning-format = none
    flash-attn = auto
    batch-size = 512
    ubatch-size = 512
    load-on-startup = false

    [gemma4-12b-heretic]
    model = /home/zarred/.cache/llama-models/gemma4-12b-heretic-q4_k_m.gguf
    ctx-size = 32768
    n-gpu-layers = 99
    device = CUDA0
    parallel = 1
    reasoning = off
    reasoning-format = deepseek
    flash-attn = auto
    batch-size = 512
    ubatch-size = 512
    load-on-startup = false
  '';
  audioSummaryPath = lib.makeBinPath [
    audioSummaryPython
    piPackage
    pkgs.bash
    pkgs.coreutils
    pkgs.ffmpeg
    pkgs.curl
    pkgs.jq
    pkgs.pass
    pkgs.gnupg
    pkgs.linuxPackages.nvidia_x11
  ];
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

  xdg.configFile."home-assistant/config.json".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."home-assistant-config.json".path;

  services.recall = {
    enable = true;
    intervalSeconds = 60;
    debounceSeconds = 1;
  };

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

  systemd.user.services.gemma4-e4b-server = {
    Unit.Description = "On-demand Gemma 4 CUDA model router";
    Service = {
      Type = "simple";
      ExecStart = "${ollamaCudaLib}/llama-server --host 127.0.0.1 --port 8083 --no-webui --offline --models-preset ${gemma4ModelsPreset} --models-max 1 --models-autoload --metrics";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStartSec = 30;
      Environment = [
        "GGML_BACKEND_PATH=${ollamaCudaLib}/cuda_v12/libggml-cuda.so"
        "LD_LIBRARY_PATH=${ollamaCudaLib}:${ollamaCudaLib}/cuda_v12"
        "CUDA_VISIBLE_DEVICES=0"
      ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
    Install.WantedBy = [ "default.target" ];
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
        "PATH=${audioSummaryPath}"
        "PI_CODING_AGENT_DIR=/home/zarred/.config/pi/agent"
        "PI_SKIP_VERSION_CHECK=1"
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

  systemd.user.services.rss-news-cache = {
    Unit = {
      Description = "Refresh FreshRSS news cache and AI-mark noisy stories read";
      After = [ "network-online.target" "load-api-keys.service" ];
      Wants = [ "network-online.target" "load-api-keys.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/zarred/scripts/rss/rss-news-cache-refresh";
      WorkingDirectory = "/home/zarred/scripts/rss";
      StandardOutput = "null";
      StandardError = "journal";
      Environment = [
        "PATH=${lib.makeBinPath [ rssNewsPython pkgs.bash pkgs.coreutils ]}"
        "PYTHONUNBUFFERED=1"
      ];
    };
  };

  systemd.user.timers.rss-news-cache = {
    Unit.Description = "Refresh FreshRSS news cache every 30 minutes";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "30m";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
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

  systemd.user.services.ibkr-announcement-watcher = {
    Unit = {
      Description = "Summarize held-company ASX announcements and route urgent events to Ember";
      After = [ "network-online.target" "ember.service" ];
      Wants = [ "network-online.target" "ember.service" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "/home/zarred/scripts/finances/ibkr";
      EnvironmentFile = [ "-/home/zarred/.config/ibkr/announcement-watcher.env" ];
      Environment = [
        "PYTHONUNBUFFERED=1"
        "PATH=${lib.makeBinPath [ announcementWatcherPython pkgs.coreutils pkgs.curl ]}:/run/current-system/sw/bin"
      ];
      ExecStartPre = "${announcementWatcherPython}/bin/python /home/zarred/scripts/finances/ibkr/tools/watch_announcements.py --bootstrap --once";
      ExecStart = "${announcementWatcherPython}/bin/python /home/zarred/scripts/finances/ibkr/tools/watch_announcements.py --interval 300 --count 20 --reclaim-seconds 1800 --max-attempts 5 --backoff-base-seconds 300 --max-alerts-per-cycle 5 --subagent-mode canary --subagent-canary-ticker AUE --subagent-cycle-budget 2";
      Restart = "on-failure";
      RestartSec = "60s";
      TimeoutStartSec = "20m";
    };
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.services.computer-vision = {
    Unit.Description = "Server for computer vision inference";
    Service.User = "zarred";
    Service.ExecStart = "/home/zarred/dev/computer-vision/run.sh";
    Service.Environment = [ "COMPUTER_VISION_PYTHON=${deepfacePython}/bin/python" ];
    Service.Restart = "always";
    Service.RestartSec = "5s";
    Service.StartLimitIntervalSec = "5";
    Service.WorkingDirectory = "/home/zarred/dev/computer-vision";
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
    Unit = {
      Description = "Crawl4AI FastAPI server";
      After = [ "graphical-session.target" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      User = "zarred";
      ExecStart = "/run/current-system/sw/bin/nix-shell /home/zarred/scripts/scrapers/crawl4ai/shell.nix --run 'env -u WAYLAND_DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE=x11 xvfb-run -a -s \"-screen 0 1920x1080x24\" uvicorn server:app --host 0.0.0.0 --port 11235'";
      Restart = "always";
      RestartSec = "5s";
      RuntimeMaxSec = "6h";
      TimeoutStopSec = "30s";
      KillMode = "control-group";
      MemoryMax = "3G";
      MemorySwapMax = "1G";
      WorkingDirectory = "/home/zarred/scripts/scrapers/crawl4ai";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.crawl4ai-health-check = {
    Unit.Description = "Restart Crawl4AI when its health endpoint is unavailable";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "crawl4ai-health-check" ''
        if ! ${pkgs.curl}/bin/curl --fail --silent --show-error \
          --connect-timeout 3 --max-time 10 http://127.0.0.1:11235/health >/dev/null; then
          ${pkgs.systemd}/bin/systemctl --user restart crawl4ai-api.service
        fi
      '';
    };
  };

  systemd.user.timers.crawl4ai-health-check = {
    Unit.Description = "Check Crawl4AI health every two minutes";
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "2m";
      Unit = "crawl4ai-health-check.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.lwake-multi-listen = {
    Unit = {
      Description = "Listen for local wake words and trigger phrase actions";
      After = [ "graphical-session.target" ];
      StartLimitIntervalSec = 0;
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      ExecStart = "/home/zarred/scripts/stt/lwake-multi-listen.sh /home/zarred/audio/wake-words";
      Restart = "always";
      RestartSec = "2s";
      OOMPolicy = "kill";
      MemoryHigh = "1800M";
      MemoryMax = "2G";
      MemorySwapMax = "512M";
    };
  };

  # Placeholder for any home-manager settings absolutely specific to zarred on web
  # that don't fit into a reusable profile.
  # home.packages = [ pkgs.some-web-specific-tool ];
}
