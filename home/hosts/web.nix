{ inputs, self, pkgs, pkgs-unstable, pkgs-ollama, lib, config, osConfig, ... }: # Added osConfig

let
  piPackage = pkgs.callPackage ../../pkgs/pi.nix { };
  codexDesktopPackage = pkgs.callPackage ../../pkgs/codex-desktop.nix { inherit inputs; };
  herdrPackage = inputs.herdr.packages.${pkgs.system}.herdr.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ../../pkgs/herdr-status-dot-spacing.patch ];
  });
  ollamaCudaPackage = pkgs-ollama.ollama-cuda;
  ollamaCudaLib = "${ollamaCudaPackage}/lib/ollama";
  piSdkPath = "${piPackage}/lib/node_modules/pi-monorepo/dist/index.js";
  # This checkout is the audited barnuri.herdr-web 0.1.1 install at
  # 198546e47350fc88d013889fea06f26a0daceda6.
  herdrWebPluginDir = "${config.xdg.configHome}/herdr/plugins/github/barnuri.herdr-web-313cb02235b3";
  herdrWebConfigDir = "${config.xdg.configHome}/herdr/plugins/config/barnuri.herdr-web";
  herdrWebStateDir = "${config.xdg.stateHome}/herdr-web";
  helmRuntimeDir = "${config.xdg.dataHome}/helm";
  helmStateDir = "${config.xdg.stateHome}/herdr-agent-workbench-canary";
  herdrWebPath =
    lib.makeBinPath [ pkgs.nodejs herdrPackage piPackage pkgs.bash pkgs.coreutils pkgs.openssl ]
    + ":/run/current-system/sw/bin:/home/zarred/.nix-profile/bin";
  audioSummaryPython = pkgs.python312.withPackages (ps: [
    ps.requests
    ps.numpy
    ps.torch
    ps.onnxruntime
    (ps.callPackage ../../pkgs/python/silero-vad { })
    ps.setuptools
  ]);
  announcementWatcherPython = pkgs.python313.withPackages (ps: [ ps.requests ]);
  rssNewsPython = pkgs.python312.withPackages (ps: [ ps.requests ps.html2text ]);
  llamaModelsPreset = pkgs.writeText "llama-models.ini" ''
    version = 1

    [gemma4-e4b-it-qat]
    model = /home/zarred/.cache/llama-models/gemma4-e4b-it-qat-q4_0.gguf
    mmproj = /home/zarred/.cache/llama-models/gemma-4-E4B-it-mmproj.gguf
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

    [qwen3.5-4b-q4_k_m]
    model = /home/zarred/.cache/llama-models/qwen3.5-4b-q4_k_m.gguf
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
  mkVicinaeExtension = (inputs.vicinae.overlays.default pkgs pkgs).mkVicinaeExtension;
  vicinaePrintvaultExtension = mkVicinaeExtension {
    pname = "printvault-search";
    version = "0.1.0";
    src = inputs.vicinae-printvault;
  };
  printVaultPackage = inputs.print-vault.packages.${pkgs.system}.default;
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
    ../desktop/ember-realtime-companion.nix
    ../media
    ../services/print-failure-monitor.nix
    ../terminal
    ../security.nix
    ../impermanence.nix
    inputs.recall.homeManagerModules.default
  ];

  home.packages = [
    # 0.11+ provides encrypted, fingerprint-authorized input sharing.
    pkgs-unstable.lan-mouse
    codexDesktopPackage
    herdrPackage
    (pkgs.callPackage ../../pkgs/handsfree.nix { })
    printVaultPackage
  ];

  wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
    "[workspace special:codex silent] ${codexDesktopPackage}/bin/codex-desktop"
  ];

  programs.vicinae.extensions = [ vicinaePrintvaultExtension ];
  systemd.user.services.vicinae.Service.Environment = [
    "PRINTVAULT_BIN=${lib.getExe printVaultPackage}"
  ];

  xdg.dataFile."applications/print-vault.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=PrintVault
    Comment=Open 3D models in PrintVault
    Exec=${lib.getExe printVaultPackage} %f
    Icon=${printVaultPackage}/share/icons/hicolor/scalable/apps/print-vault.svg
    MimeType=model/stl;model/3mf;
    Terminal=false
    Categories=Graphics;Utility;
    StartupWMClass=PrintVault
  '';

  # HandsFree registers the Bluetooth HFP hands-free role itself. Keep
  # WirePlumber's normal A2DP/LE Audio and HFP Audio Gateway roles, but do not
  # let it register hfp_hf as well (which conflicts with HandsFree).
  xdg.configFile."wireplumber/wireplumber.conf.d/90-handsfree.conf".text = ''
    monitor.bluez.properties = {
      bluez5.roles = [ a2dp_sink a2dp_source bap_sink bap_source hfp_ag ]
    }
  '';

  # Helm's runtime is installed under persistent ~/.local/share because the
  # home directory itself is tmpfs. State and configuration remain separate.
  systemd.user.services.helm = {
    Unit = {
      Description = "Helm agent workspace";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" "helm-proxy.service" ];
      Before = [ "helm-proxy.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${helmRuntimeDir}/bin/helm --host 127.0.0.1 --port 8789 --remote-security-config ${helmStateDir}/remote-security.json";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "HERDR_SOCKET_PATH=${config.xdg.configHome}/herdr/herdr.sock"
        "HERDR_WEB_HOST_ID=agent-workbench-canary"
        "HERDR_WEB_SEMANTIC_DIR=${config.xdg.stateHome}/herdr-web-canary/semantic"
        "HERDR_WEB_PI_EXTENSION_ENTRY=${helmRuntimeDir}/share/helm/pi-extension/dist/index.ts"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.helm-proxy = {
    Unit = {
      Description = "Helm local nginx relay";
      After = [ "helm.service" ];
      PartOf = [ "helm.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nginx}/bin/nginx -e ${helmStateDir}/nginx-error.log -c ${helmStateDir}/nginx.conf -g 'daemon off;'";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Herdr's startup hook is intentionally left enabled so its plugin actions
  # remain available. It may attempt a second bind after a Herdr restart and
  # exit with EADDRINUSE; this user service owns the persistent web listener.
  systemd.user.services.herdr-web = {
    Unit = {
      Description = "Herdr Web browser UI";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = herdrWebPluginDir;
      ExecStart = "${pkgs.nodejs}/bin/node ${herdrWebPluginDir}/server.js";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "PATH=${herdrWebPath}"
        "HERDR_PLUGIN_CONFIG_DIR=${herdrWebConfigDir}"
        "HERDR_PLUGIN_STATE_DIR=${herdrWebStateDir}"
        "HERDR_BIN_PATH=${herdrPackage}/bin/herdr"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  xdg.configFile."home-assistant/config.json".source =
    config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."home-assistant-config.json".path;

  services.recall = {
    enable = true;
    intervalSeconds = 60;
    debounceSeconds = 1;
    nsfwClassifier.enable = true;
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

  systemd.user.services.llama-server = {
    Unit.Description = "On-demand CUDA model router";
    Service = {
      Type = "simple";
      ExecStart = "${ollamaCudaLib}/llama-server --host 127.0.0.1 --port 8083 --no-webui --offline --models-preset ${llamaModelsPreset} --models-max 1 --models-autoload --metrics";
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
      # rss.py has a 240s refresh deadline; leave bounded cleanup headroom.
      TimeoutStartSec = "5m";
      StandardOutput = "null";
      StandardError = "journal";
      Environment = [
        "PATH=${lib.makeBinPath [ rssNewsPython pkgs.bash pkgs.coreutils pkgs.gnupg ]}"
        "PYTHONUNBUFFERED=1"
        "RSS_BACKGROUND_LIMIT=50"
        "RSS_NOISE_THRESHOLD=0.5"
        "RSS_DEDUPE_WINDOW_HOURS=48"
        "RSS_REFRESH_DEADLINE_SECONDS=240"
        # Keep SQLite state and the last-good cache outside /tmp. rss.py still
        # publishes /tmp/rss-news as a compatibility copy for older consumers.
        "RSS_NEWS_STATE_DIR=${config.xdg.stateHome}/rss-news"
        "RSS_NEWS_LAST_GOOD_PATH=${config.xdg.stateHome}/rss-news/rss-news.json"
        "RSS_NEWS_CACHE_PATH=/tmp/rss-news"
      ];
    };
  };

  systemd.user.timers.rss-news-cache = {
    Unit.Description = "Refresh FreshRSS news cache every 5 minutes";
    Timer = {
      OnActiveSec = "2m";
      # Activation-relative preserves the five-minute cadence; systemd
      # serializes the oneshot, so no shell lock is needed.
      OnUnitActiveSec = "5m";
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
        "IBKR_ANNOUNCEMENT_STATE_DIR=/home/zarred/.local/state/asx-announcement-analysis/announcement-pdfs"
        "IBKR_STOCK_NOTES_ROOT=/home/zarred/notes/home/finances/stocks"
        "IBKR_EMBER_SUBAGENT_CYCLE_BUDGET=8"
        "PATH=${lib.makeBinPath [ announcementWatcherPython pkgs.coreutils pkgs.curl ]}:/run/current-system/sw/bin"
      ];
      ExecStartPre = "${announcementWatcherPython}/bin/python /home/zarred/scripts/finances/ibkr/tools/watch_announcements.py --bootstrap --once --subagent-state-dir /home/zarred/.local/state/asx-announcement-analysis/announcement-pdfs --notes-root /home/zarred/notes/home/finances/stocks";
      ExecStart = "${announcementWatcherPython}/bin/python /home/zarred/scripts/finances/ibkr/tools/watch_announcements.py --interval 300 --count 20 --reclaim-seconds 1800 --max-attempts 5 --backoff-base-seconds 300 --max-alerts-per-cycle 5 --subagent-mode live --subagent-state-dir /home/zarred/.local/state/asx-announcement-analysis/announcement-pdfs --notes-root /home/zarred/notes/home/finances/stocks --subagent-cycle-budget 8";
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
  # Started by the TTS client only when the Soprano provider is requested.
  systemd.user.services.soprano-streaming-server = {
    Unit.Description = "Soprano low-latency streaming TTS server";
    Service.User = "zarred";
    Service.ExecStart = "/run/current-system/sw/bin/nix-shell /home/zarred/scripts/tts/soprano/shell.nix --run '/home/zarred/.micromamba/envs/soprano/bin/python /home/zarred/scripts/tts/soprano/streaming_server.py --backend lmdeploy --device cuda --host 0.0.0.0 --port 8000'";
    Service.WorkingDirectory = "/home/zarred/scripts/tts/soprano";
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

  systemd.user.services.local-new-tab = {
    Unit.Description = "Local new-tab page";
    Service = {
      Type = "simple";
      WorkingDirectory = "/home/zarred/dev/local-new-tab";
      ExecStart = "${pkgs.python3}/bin/python3 /home/zarred/dev/local-new-tab/server.py";
      Restart = "on-failure";
      RestartSec = 1;
      NoNewPrivileges = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Ember's Pi settings are scoped to ~/.ember; keep standalone Pi's global
  # compaction defaults unchanged. Preserve the existing settings while
  # overriding only Ember's recent-token retention.
  home.file.".ember/settings.json" = {
    force = true;
    text = builtins.toJSON {
      theme = "rose-pine-clear-tools";
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.6-luna";
      transport = "websocket";
      lastChangelogVersion = "0.70.0";
      defaultThinkingLevel = "high";
      compaction = {
        keepRecentTokens = 5000;
      };
    };
  };

  # Ember's Realtime resolver disables Pi's ambient environment fallback. Keep
  # the provider mapping declarative while resolving the key only at runtime.
  home.file.".ember/models.json".text = builtins.toJSON {
    providers = {
      openai = {
        apiKey = "$OPENAI_API_KEY";
        baseUrl = "https://api.openai.com/v1";
      };
      "local-gemma" = {
        baseUrl = "http://127.0.0.1:8083/v1";
        api = "openai-completions";
        apiKey = "local";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
          maxTokensField = "max_tokens";
        };
        models = [
          {
            id = "gemma4-e4b-it-qat";
            name = "Gemma 4 E4B IT QAT (local)";
            reasoning = false;
            input = [ "text" "image" ];
            contextWindow = 4096;
            maxTokens = 4096;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
          {
            id = "qwen3.5-4b-q4_k_m";
            name = "Qwen 3.5 4B Q4_K_M (local)";
            reasoning = false;
            input = [ "text" ];
            contextWindow = 65536;
            maxTokens = 65536;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
        ];
      };
    };
  };
}
