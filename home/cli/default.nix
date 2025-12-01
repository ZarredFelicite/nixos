{ self, inputs, config, pkgs, pkgs-unstable, lib, osConfig, ... }: let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "d7588f6d29b5998733d5a71ec312c7248ba14555";
    hash = "sha256-...";
  };
  yazi-flavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "4296a380570399e3c36aec054f37aa48f35cf6b1";
    hash = "sha256-KNpr7eYHm2dPky1L6EixoD956bsYZZO3bCyKIyAlIEw=";
  };
  yazi-augment-command = pkgs.fetchFromGitHub {
    owner = "hankertrix";
    repo = "augment-command.yazi";
    rev = "v25.5.28-or-lower";
    hash = "sha256-nhu02TSVcyPxjgUjz/hOvjgE78tJ1KVqXktyLWiWxgQ=";
  };
in {
  imports = [
    ./zsh
    ./nixvim
    ./nb.nix
    ./sys_monitors.nix
    ./newsboat.nix
    ./nnn/default.nix
    ./tmux.nix
    ./glow.nix
    ./ueberzugpp.nix
    # INFO: does not have opencode compat ./mcp-servers.nix
  ];

  home.packages = [
    # Packages from home/cli-apps.nix (originally from home/home.nix)
    # System tools (CLI focus)
    pkgs.sysstat # A collection of performance monitoring tools for Linux (such as sar, iostat and pidstat)
    pkgs.lm_sensors # for `sensors` command
    pkgs.pciutils # lspci
    pkgs.usbutils # lsusb
    pkgs.ddcutil # Query and change Linux monitor settings using DDC/CI and USB
    pkgs.file # A program that shows the type of files
    pkgs.iperf # Tool to measure IP bandwidth using UDP or TCP
    pkgs.lychee # A fast, async, resource-friendly link checker written in Rust.
    pkgs.speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    # libva-utils (kept in home.nix as it's often a dep for GUI media players too)
    pkgs.expect # A tool for automating interactive applications (provides unbuffer)
    pkgs.tio # Serial console TTY

    # stress-testing / benchmarking (CLI)
    pkgs.stress-ng
    pkgs.s-tui
    pkgs.sysbench

    # system call monitoring
    pkgs.strace # system call monitoring
    pkgs.ltrace # library call monitoring
    pkgs.lsof # list open files

    # archives
    pkgs.atool
    pkgs.unzip
    pkgs.unrar

    # utils (CLI focus)
    pkgs.yq-go # yaml processer https://github.com/mikefarah/yq
    pkgs.yj # Convert YAML <=> TOML <=> JSON <=> HCL
    pkgs.bc # GNU software calculator
    pkgs.ripdrag # An application that lets you drag and drop files from and to the terminal
    pkgs.du-dust # du + rust = dust. Like du but more intuitive
    pkgs.duf # Disk Usage/Free Utility
    pkgs.ttyplot # A simple general purpose plotting utility for tty with data input from stdin
    pkgs.grc # Generic text colouriser

    # backup/recovery (CLI)
    pkgs.testdisk # Data recovery utilities
    pkgs.gtrash # Command line interface to the freedesktop.org trashcan https://github.com/umlx5h/gtrash

    # networking (CLI focus)
    pkgs.aria2 # A lightweight multi-protocol & multi-source command-line download utility
    pkgs.socat # replacement of openbsd-netcat
    pkgs.nmap # A utility for network discovery and security auditing
    pkgs.dig # Domain name server

    # productivity (CLI focus)
    pkgs.tidy-viewer # A cross-platform CLI csv pretty printer that uses column styling to maximize viewer enjoyment
    pkgs.visidata # Interactive terminal multitool for tabular data
    pkgs.xan # Command line tool to process CSV files directly from the shell

    # web tools (CLI)
    pkgs.readability-cli # Firefox Reader Mode in your terminal - get useful text from a web page using Mozilla's Readability library

    # misc (CLI focus)
    pkgs.ffmpeg # A complete, cross-platform solution to record, convert and stream audio and video
    pkgs.android-tools # Android SDK platform tools (contains adb, fastboot - CLI)
    pkgs.imagemagick # A software suite to create, edit, compose, or convert bitmap images
    pkgs.gotify-cli # A command line interface for pushing messages to gotify/server
    pkgs.gnumake
    pkgs.cmake
    pkgs.pkg-config
    pkgs.sqlite # CLI and library
    pkgs.mdcat
    pkgs.moreutils
    pkgs.gnuplot # Can be used from CLI, but also by GUI tools
    pkgs.fastfetch
    pkgs.exfatprogs
    pkgs.psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
    pkgs.qrrs # CLI QR code generator and reader written in rust
    pkgs.catt # CLI Chromecast tool
    pkgs.wiki-tui # Simple and easy to use Wikipedia Text User Interface

    # nix (CLI tools)
    pkgs.nix-index # A files database for nixpkgs
    pkgs.manix # A fast CLI documentation searcher for Nix
    pkgs.comma # Runs programs without installing them
    pkgs.nix-init # Command line tool to generate Nix packages from URLs

    # dev tools (general CLI)
    pkgs-unstable.devenv # TODO: stable is broken
    pkgs.git-lfs # Git Large File Storage extension

    # ai (CLI focus)
    # TODO: broken - pkgs-unstable.aider-chat # AI pair programming in your terminal
    pkgs-unstable.claude-code # An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
    pkgs-unstable.codex # Lightweight coding agent that runs in your terminal
    pkgs.oterm # Text-based terminal client for Ollama
    pkgs-unstable.gemini-cli
    #pkgs.opencode
    pkgs-unstable.opencode
    pkgs-unstable.antigravity-fhs
    #pkgs-unstable.playwright-mcp
    #(pkgs-unstable.callPackage ../../pkgs/opencode.nix {} )

    # latex (CLI toolchain)
    (pkgs.texliveBasic.withPackages(ps: with ps; [
      enumitem
      enumitem-zref
      parskip
      etoolbox
      fontawesome
      metafont
    ]))

    # text conversion (CLI)
    pkgs.lynx # Text-mode web browser
    ( pkgs.callPackage ../../pkgs/html-to-markdown {} ) # Path relative to home/cli/default.nix
    pkgs.presenterm # Terminal based slideshow tool https://github.com/mfontanini/presenterm
  ];

  xdg.configFile."fd/ignore".text = '' # Original from home/cli/default.nix
    /mnt
  '';

  stylix.targets.yazi.enable = false;
  programs = {
    # Original programs from home/cli/default.nix
    zsh.enable = true;
    nixvim.enable = true;
    nnn.enable = true;
    yazi = {
      enable = true;
      enableZshIntegration = true;
      flavors = {
        catppuccin-mocha = "${yazi-flavors}/catppuccin-mocha.yazi";
      };
      plugins = {
        yatline = pkgs.yaziPlugins.yatline;
        yatline-catppuccin = pkgs.yaziPlugins.yatline-catppuccin;
        mediainfo = pkgs.yaziPlugins.mediainfo;
        augment-command = "${yazi-augment-command}";
        full-border = pkgs.yaziPlugins.full-border;
      };
      settings = {
        mgr = {
          show_hidden = true;
          show_symlink = true;
          scrolloff = 4;
        };
        preview = {
          tab_size = 2;
        };
        plugin = {
          prepend_preloaders = [
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "$mediainfo";
            }
          ];
          prepend_previewers = [
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "mediainfo";
            }
          ];
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "T" ];
            run = "plugin --sync max-preview";
            desc = "Maximize or restore the preview pane";
          }
          {
            on = [ "c" "m" ];
            run = "plugin chmod";
            desc = "Chmod on selected files";
          }
        ];
      };
      initLua = ''
        local catppuccin_theme = require("yatline-catppuccin"):setup("mocha")
        require("yatline"):setup({
          show_background = false,
          display_header_line = true,
          display_status_line = true,
          component_positions = { "header", "tab", "status" },
          theme = catppuccin_theme,
        })
        require("full-border"):setup()
        -- Custom configuration for augment-command
        require("augment-command"):setup({
          smart_paste = true,
          smart_tab_create = true,
        })
        -- Makes yazi update the zoxide database on navigation
        require("zoxide"):setup
        {
          update_db = true,
        }
      '';
    };
    tmux.enable = true;
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      config = {
        whitelist = {
          prefix = [
            "/home/zarred/dev"
            "/home/zarred/scripts"
          ];
        };
      };
    };
    eza = {
      enable = true;
      extraOptions = [
        "--icons"
        "--sort=modified"
      ];
      git = true;
      icons = "auto";
      enableZshIntegration = true;
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    script-directory = {
      enable = true;
      settings = {
        SD_ROOT = "${config.home.homeDirectory}/scripts";
        SD_EDITOR = "$EDITOR";
        SD_CAT = "$PAGER";
      };
    };
    hyfetch = {
      enable = true;
      #settings = builtins.toJSON {};
    };

    # Programs from home/cli-apps.nix
    pandoc.enable = true;
  };

  xdg.configFile."neofetch/config.conf".source = ./neofetch_config.conf; # Original from home/cli/default.nix

  # Gnuplot config from original home/cli/default.nix
  xdg.configFile."../.gnuplot".text = ''
    set macros
    png="set terminal png size 1800,1800 crop enhanced font \"/usr/share/fonts/truetype/times.ttf,30\" dashlength 2; set termoption linewidth 3"
    eps="set terminal postscript fontfile \"/usr/share/fonts/truetype/times.ttf\"; set termoption linewidth 3;

    set style line 1 linecolor rgb '#de181f' linetype 1  # Red
    set style line 2 linecolor rgb '#0060ae' linetype 1  # Blue
    set style line 3 linecolor rgb '#228C22' linetype 1  # Forest green

    set style line 4 linecolor rgb '#18ded7' linetype 1  # opposite Red
    set style line 5 linecolor rgb '#ae4e00' linetype 1  # opposite Blue
    set style line 6 linecolor rgb '#8c228c' linetype 1  # opposite Forest green
  '';

  # Aider configuration (from home/cli-apps.nix)
  xdg.configFile."/home/zarred/.config/aider.env".text = ''
    AIDER_MODEL=o3-mini
    AIDER_REASONING_EFFORT=medium
    AIDER_AUTO_ACCEPT_ARCHITECT=false
    AIDER_CACHE_PROMPTS=true
    AIDER_DARK_MODE=true
    AIDER_USER_INPUT_COLOR=#c4a7e7
    AIDER_TOOL_OUTPUT_COLOR=#31748f
    AIDER_TOOL_ERROR_COLOR=#eb6f92
    AIDER_TOOL_WARNING_COLOR=#f6c177
    AIDER_ASSISTANT_OUTPUT_COLOR=#ebbcba
    AIDER_COMPLETION_MENU_COLOR=#6e6a86
    AIDER_COMPLETION_MENU_CURRENT_COLOR=#9ccfd8
    AIDER_CODE_THEME=dracula
    AIDER_WATCH_FILES=true
    AIDER_LINT=false
    AIDER_LINT_CMD="python: ruff check"
    AIDER_EDITOR=nvim
  '';

  programs.zsh.shellAliases.aider = "aider --env-file ~/.config/aider.env --openai-api-key $(pass dev/openai-api) --api-key gemini=$(pass google/gemini_api)";

  services.udiskie = { # From home/cli-apps.nix
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
    settings = {
      program_options.udisks_version = 2;
      program_options.tray = true;
      icon_names.media = [ "media-optical" ];
    };
  };
}
