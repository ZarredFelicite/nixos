{ self, inputs, config, pkgs, lib, osConfig, ... }: # Added osConfig from cli-apps.nix
{
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
  ];

  home.packages = with pkgs; [
    # Packages from home/cli-apps.nix (originally from home/home.nix)
    # System tools (CLI focus)
    sysstat # A collection of performance monitoring tools for Linux (such as sar, iostat and pidstat)
    lm_sensors # for `sensors` command
    pciutils # lspci
    usbutils # lsusb
    ddcutil # Query and change Linux monitor settings using DDC/CI and USB
    file # A program that shows the type of files
    iperf # Tool to measure IP bandwidth using UDP or TCP
    lychee # A fast, async, resource-friendly link checker written in Rust.
    speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
    # libva-utils (kept in home.nix as it's often a dep for GUI media players too)
    expect # A tool for automating interactive applications (provides unbuffer)
    tio # Serial console TTY

    # stress-testing / benchmarking (CLI)
    stress-ng
    s-tui
    sysbench

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # archives
    atool
    unzip
    unrar

    # utils (CLI focus)
    yq-go # yaml processer https://github.com/mikefarah/yq
    yj # Convert YAML <=> TOML <=> JSON <=> HCL
    bc # GNU software calculator
    ripdrag # An application that lets you drag and drop files from and to the terminal
    du-dust # du + rust = dust. Like du but more intuitive
    duf # Disk Usage/Free Utility
    ttyplot # A simple general purpose plotting utility for tty with data input from stdin
    grc # Generic text colouriser

    # backup/recovery (CLI)
    testdisk # Data recovery utilities
    gtrash # Command line interface to the freedesktop.org trashcan https://github.com/umlx5h/gtrash

    # networking (CLI focus)
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    dig # Domain name server

    # productivity (CLI focus)
    tidy-viewer # A cross-platform CLI csv pretty printer that uses column styling to maximize viewer enjoyment
    visidata # Interactive terminal multitool for tabular data
    # TODO: unmaintained - replace with (xan https://github.com/medialab/xan ); xsv # A fast CSV toolkit written in Rust

    # web tools (CLI)
    readability-cli # Firefox Reader Mode in your terminal - get useful text from a web page using Mozilla's Readability library

    # misc (CLI focus)
    # ffmpeg (kept in home.nix, general media tool)
    android-tools # Android SDK platform tools (contains adb, fastboot - CLI)
    # imagemagick (kept in home.nix, often used by GUI too)
    gotify-cli # A command line interface for pushing messages to gotify/server
    gnumake
    cmake
    pkg-config
    sqlite # CLI and library
    mdcat
    moreutils
    gnuplot # Can be used from CLI, but also by GUI tools
    fastfetch
    exfatprogs
    psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
    qrrs # CLI QR code generator and reader written in rust
    catt # CLI Chromecast tool
    wiki-tui # Simple and easy to use Wikipedia Text User Interface

    # nix (CLI tools)
    nix-index # A files database for nixpkgs
    manix # A fast CLI documentation searcher for Nix
    comma # Runs programs without installing them
    nix-init # Command line tool to generate Nix packages from URLs

    # dev tools (general CLI)
    devenv
    git-lfs # Git Large File Storage extension

    # ai (CLI focus)
    aider-chat # AI pair programming in your terminal
    claude-code # An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
    codex # Lightweight coding agent that runs in your terminal
    oterm # Text-based terminal client for Ollama

    # latex (CLI toolchain)
    (texliveBasic.withPackages(ps: with ps; [
      enumitem
      enumitem-zref
      parskip
      etoolbox
      fontawesome
      metafont
    ]))

    # text conversion (CLI)
    lynx # Text-mode web browser
    ( pkgs.callPackage ../../pkgs/html-to-markdown {} ) # Path relative to home/cli/default.nix
    presenterm # Terminal based slideshow tool https://github.com/mfontanini/presenterm

    # PYTHON Tools moved to home/python.nix
  ];

  xdg.configFile."fd/ignore".text = '' # Original from home/cli/default.nix
    /mnt
  '';

  programs = {
    # Original programs from home/cli/default.nix
    zsh.enable = true;
    nixvim.enable = true;
    nnn.enable = true;
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
