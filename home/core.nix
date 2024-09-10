{ pkgs, lib, osConfig, ... }: {
  imports = [
    ./menu
    ./cli
    ./mail
    ./finance
    ./media
    ./terminal
    ./security.nix
    ./impermanence.nix
  ];
  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "23.05";
    packages = with pkgs; [
      # system tools
      gtk3
      helvum # A GTK patchbay for pipewire
      pavucontrol
      sysstat # A collection of performance monitoring tools for Linux (such as sar, iostat and pidstat)
      lm_sensors # for `sensors` command
      pciutils # lspci
      usbutils # lsusb
      ddcutil # Query and change Linux monitor settings using DDC/CI and USB
      file # A program that shows the type of files
      iperf # Tool to measure IP bandwidth using UDP or TCP
      lychee # A fast, async, resource-friendly link checker written in Rust.
      speedtest-cli # Command line interface for testing internet bandwidth using speedtest.net
      libva-utils
      expect # A tool for automating interactive applications (provides unbuffer)
      # media
      mediainfo # Supplies technical and tag information about a video or audio file
      # system call monitoring
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files
      # archives
      atool
      unzip
      unrar
      # utils
      ripgrep # recursively searches directories for a regex pattern
      jq # A lightweight and flexible command-line JSON processor
      yq-go # yaml processer https://github.com/mikefarah/yq
      yj # Convert YAML <=> TOML <=> JSON <=> HCL
      bc # GNU software calculator
      ripdrag # An application that lets you drag and drop files from and to the terminal
      du-dust # du + rust = dust. Like du but more intuitive
      duf # Disk Usage/Free Utility
      ttyplot # A simple general purpose plotting utility for tty with data input from stdin
      # backup/recovery
      testdisk # Data recovery utilities
      trash-cli # Command line interface to the freedesktop.org trashcan
      # networking
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      nmap # A utility for network discovery and security auditing
      dig # Domain name server
      # productivity
      tidy-viewer # A cross-platform CLI csv pretty printer that uses column styling to maximize viewer enjoyment
      visidata # Interactive terminal multitool for tabular data
      xsv # A fast CSV toolkit written in Rust
      # web tools
      readability-cli # Firefox Reader Mode in your terminal - get useful text from a web page using Mozilla's Readability library
      # misc
      ffmpeg_7 # A complete, cross-platform solution to record, convert and stream audio and video
      android-tools # Android SDK platform tools
      imagemagick # A software suite to create, edit, compose, or convert bitmap images
      gotify-cli # A command line interface for pushing messages to gotify/server
      gnumake
      cmake
      pkg-config
      sqlite
      mdcat
      moreutils
      gnuplot
      neofetch
      rpi-imager # Raspberry Pi Imaging Utility
      ventoy
      exfatprogs
      psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)

      # nix
      nix-index

      # latex
      (texliveBasic.withPackages(ps: with ps; [
        enumitem
        enumitem-zref
        parskip
        etoolbox
        fontawesome
        metafont
      ]))
      #texlivePackages.enumitem
      #(texlive.combine { inherit (texlivePackages) texliveSmall enumitem; })

      piper-tts
      upscayl

      android-studio
      git-lfs

      waypipe
      wayvnc
      tigervnc
      remmina
      wlvncc
      moonlight-qt
      bottles
      protonup-qt

      # kinect
      #freenect
      freecad

      (python3.withPackages(ps: with ps; [
        pip
        ytmusicapi
        bullet
        yt-dlp
        rich
        psutil
        pillow
        colorthief
        pixcat
        mutagen
        beautifulsoup4
        python-mpv-jsonipc
        playsound
        gtts
        flask
        numpy
        matplotlib
        pybluez
        libtmux
        tensorboard
        (
          buildPythonPackage rec {
            pname = "reader";
            version = "3.13";
            src = fetchPypi {
              inherit pname version;
              hash = "sha256-bmN204LLizc3esR5CuHe4PytqyN24LHUToKU8MSkyYE=";
            };
            format = "pyproject";
            doCheck = false;
            propagatedBuildInputs = [
              pkgs.python3Packages.setuptools
              pkgs.python3Packages.feedparser
              pkgs.python3Packages.requests
              pkgs.python3Packages.werkzeug
              pkgs.python3Packages.iso8601
              pkgs.python3Packages.typing-extensions
              pkgs.python3Packages.beautifulsoup4
            ];
          }
        )
      ]))
    ];
    sessionVariables = {
      EDITOR = "nvim";
      MANPAGER = "bat -l man -p'";
      PAGER = "bat";
    };
  };
  stylix.targets.kitty.variant256Colors = true;
  programs.kitty.enable = true;
  programs.foot.enable = true;
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      color = "always";
      decorations = "always";
      italic-text = "always";
    };
  };
  services.ssh-agent.enable = false; # TODO: vs GPG-agent
  programs.ssh = {
    enable = true;
    #controlMaster = "yes";
    #controlPersist = "30m";
    userKnownHostsFile = "~/.ssh/known_hosts";
    addKeysToAgent = "yes";
    matchBlocks = {
      rpicam = {
        hostname = "rpicam";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "export TERM=xterm-256color; tmux new -A -s rpicam";
        };
      };
      rpi = {
        hostname = "10.131.3.83";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s horus";
        };
      };
      #nix-sankara = {
      #  hostname = "sankara";
      #  user = "nixremote";
      #  identityFile = "/root/.ssh/nixremote";
      #  identitiesOnly = true;
      #};
      tmux-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s sankara_remote";
        };
      };
      home-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmuxinator home";
        };
      };
      tmux-web = {
        hostname = "web";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s web_remote";
        };
      };
    };
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "ZarredFelicite";
    userEmail = "zarred.f@gmail.com";
    extraConfig = {
      core = {
        editor ="nvim";
      };
    };
    delta = {
      # https://dandavison.github.io/delta/introduction.html
      enable = true;
      options = {
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-decoration-style = "none";
          file-style = "bold yellow ul";
        };
        features = "decorations";
        whitespace-error-style = "22 reverse";
      };
    };
  };
  #xdg.configFile."gh/hosts.yml".source = osConfig.sops.secrets.github-api-token.path;
  programs.gh = {
    enable = true;
    #gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      version = "1";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = true;
        use_pager = false;
      };
      updates = {
        auto_update = true;
      };
    };
  };
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };
  programs.pandoc.enable = true;
  #programs.home-manager.enable = true;
  services = {
    udiskie = {
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
  };
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "*" = "~/scripts/file-ops/linkhandler.sh";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "x-scheme-handler/omniverse-launcher" = "~/scripts/file-ops/linkhandler.sh";
      };
      associations.added = {
        "application/pdf" = "zathura.desktop";
        "application/octet-stream" = "nvim.desktop";
        "text/xml" = [
          "nvim.desktop"
          "codium.desktop"
        ];
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
      };
    };
    userDirs = {
      enable = false;
      createDirectories = true;
      desktop = null;
      templates = null;
      publicShare = null;
      download = "/home/zarred/downloads";
      documents = "/home/zarred/documents";
      pictures = "/home/zarred/pictures";
      videos = "/home/zarred/videos";
    };
  };
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        insert_final_newline = true;
        indent_size = 2;
        indent_style = "space";
        trim_trailing_whitespace = true;
      };
      "*.md" = {
        indent_style = "tab";
        trim_trailing_whitespace = false;
      };
      "Makefile" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.html" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.go" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.rs" = {
        indent_style = "space";
        indent_size = 4;
      };
    };
  };
  xdg.configFile."/home/zarred/.jq".text = ''
    def pad_left($len; $chr):
        (tostring | length) as $l
        | "\($chr * ([$len - $l, 0] | max) // "")\(.)"
        ;
    def pad_left($len):
        pad_left($len; " ")
        ;
    def pad_right($len; $chr):
        (tostring | length) as $l
        | "\(.)\($chr * ([$len - $l, 0] | max) // "")"
        ;
    def pad_right($len):
        pad_right($len; " ")
        ;
  '';
}
