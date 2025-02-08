{ self, config, pkgs, pkgs-unstable, pkgs-stable, lib, inputs, outputs, ... }: {
  imports = [
    ../profiles/common.nix
    ../sys/keyd.nix
    ../profiles/remote-access.nix
    ../profiles/qemu.nix
    ../profiles/ai.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs outputs pkgs-unstable pkgs-stable; };
    users.zarred = import ../home/desktop.nix;
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    brillo.enable = true;
  };
  system.autoUpgrade = {
    enable = true;
    operation = "boot";
    flake = inputs.self.outPath;
    #flake = "/home/zarred/dots";
    flags = [
      "--update-input"
      "nixpkgs"
      "--update-input"
      "home-manager"
      #"--commit-lock-file"
      "--no-write-lock-file"
      #"--recreate-lock-file"
      "-L" # print build logs
      "--impure"
      "--builders"
      "''"
      #"--option"
      #"substituters"
      #"'https://cache.nixos.org'"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
    persistent = true;
    allowReboot = false;
  };
  #stylix.targets.plymouth.enable = false;
  #systemd.tmpfiles.rules = [
  #  "d /etc/systemd/system/display-manager.service.d 1777 root root"
  #];
  environment.etc = {
    #"systemd/system/display-manager.service.d/plymouth.conf".text = ''
    #  [Unit]
    #  Conflicts=plymouth-quit.service
    #  After=plymouth-quit.service rc-local.service plymouth-start.service systemd-user-sessions.service
    #  OnFailure=plymouth-quit.service

    #  [Service]
    #  ExecStartPost=-/usr/bin/sleep 30
    #  ExecStartPost=-/usr/bin/plymouth quit --retain-splash
    #'';
  };
  boot.plymouth = {
    # TODO: add fireship nix video to stylix-plymouth generation script
    enable = false;
    #theme = "breeze";
    #themePackages = [
    #  (pkgs.catppuccin-plymouth.override { variant = "mocha"; })
    #];
  };
  xdg = {
    portal = {
      enable = true;
      xdgOpenUsePortal = false;
      wlr.enable = true;
      config.common.default = "*";
      #config = {
      #  common = {
      #    default = [
      #      "gtk"
      #    ];
      #  };
      #  pantheon = {
      #    default = [
      #      "pantheon"
      #      "gtk"
      #    ];
      #    "org.freedesktop.impl.portal.Secret" = [
      #      "gnome-keyring"
      #    ];
      #  };
      #  x-cinnamon = {
      #    default = [
      #      "xapp"
      #      "gtk"
      #    ];
      #  };
      #};
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  #systemd.services.greetd.serviceConfig = {
  #  Type = "idle";
  #  StandardInput = "tty";
  #  StandardOutput = "tty";
  #  StandardError = "journal"; # Without this errors will spam on screen
  #  # Without these bootlogs will spam on screen
  #  TTYReset = true;
  #  TTYVHangup = true;
  #  TTYVTDisallocate = true;
  #};
  security.pam.services =
    let defaults = {
      gnupg = {
        enable = true;
        noAutostart = true;
        #storeOnly = true;
      };
    };
    in {
      login = defaults;
      greetd = defaults;
  };
  services = {
    ollama.enable = true;
    printing.enable = true;
    avahi.enable = true;
    avahi.nssmdns4 = true;
    avahi.openFirewall = true;
    xserver = {
      enable = true;
      desktopManager.gnome = {
        enable = false;
      };
      #displayManager.session = [
      #  { name = "Desktop"; manage = "desktop"; start = "Hyprland"; }
      #];
    };
    greetd = {
      enable = true;
      vt = 1; # clean login screen, no startup logs
      restart = false;
      settings = rec {
        initial_session = {
	        command = "${pkgs.hyprland}/bin/Hyprland";
	        user = "zarred";
	      };
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --cmd ${pkgs.hyprland}/bin/Hyprland \
              -s ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
              --remember \
              --remember-user-session \
              --width 50
              --theme "border=magenta;text=cyan;prompt=lightblue;time=lightblue;action=lightblue;button=darkgrey;container=black;input=lightcyan"
              --debug /tmp/tuigreet.log
          '';
          #user = "greeter";
        };
      };
    };
    pipewire = {
      enable = true;
      systemWide = false;
      audio.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #extraConfig.pipewire-pulse."mpd-connection" = {
      #  "server.address" = [ {
      #    address = "tcp:4713";              # address
      #    max-clients = 64;                  # maximum number of clients
      #    listen-backlog = 32;               # backlog in the server listen queue
      #    client.access = "allowed";         # permissions for clients (was restricted)
      #  } ];
      #};
      wireplumber = {
        enable = true;
        extraConfig."11-bluetooth-policy" = {"wireplumber.settings" = {"bluetooth.autoswitch-to-headset-profile" = false;};};
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
            bluez_monitor.properties = {
              ["bluez5.enable-sbc-xq"] = true,
              ["bluez5.enable-msbc"] = true,
              ["bluez5.enable-hw-volume"] = true,
            }
          '')
          #["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
        ];
      };
    };
    transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openRPCPort = true;
      group = "users";
      settings = {
        message-level = 3;
        download-dir = "/var/lib/transmission/downloads/complete" ;
        incomplete-dir-enabled = true;
        incomplete-dir = "/var/lib/transmission/downloads/incomplete" ;
        watch-dir-enabled = true;
        watch-dir = "/var/lib/transmission/watch-dir" ;
        trash-original-torrent-files = true;
        script-torrent-done-enabled = false;
        script-torrent-done-filename = null;
        peer-port = 51413;
        # ip announce
        announce-ip-enabled = false;
        # bandwidth
        speed-limit-down-enabled = false;
        speed-limit-up-enabled = false;
        alt-speed-enabled = false;
        alt-speed-time-enabled = false;
        upload-slots-per-torrent = 14;
        # blocklist
        blocklist-enabled = false;
        # files
        rename-partial-files = true;
        start-added-torrents = true;
        #trash-original-torrent-files = false;
        # umask = 022;
        # misc
        cache-size-mb = 4;
        dht-enabled = true;
        encryption = 1;
        lpd-enabled = false;
        pex-enabled = true;
        scrape-paused-torrents-enabled = true;
        script-torrent-added-enabled = false;
        script-torrent-added-filename = "";
        #script-torrent-done-enabled = false;
        #script-torrent-done-filename = "";
        script-torrent-done-seeding-enabled = false;
        script-torrent-done-seeding-filename = "";
        tcp-enabled = true;
        torrent-added-verify-mode = "fast";
        utp-enabled = true;
        # queue
        download-queue-enabled = true;
        download-queue-size = 50;
        queue-stalled-enabled = true;
        queue-stalled-minutes = 30;
        seed-queue-enabled = false;
        seed-queue-size = 10;
        # RPC
        rpc-port = 9091;
        rpc-bind-address = "0.0.0.0";
        rpc-host-whitelist-enabled = false;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.* 192.168.*.* 100.64.1.*";
        rpc-authentication-required = false;
        anti-brute-force-enabled = true;
        anti-brute-force-threshold = 50;
        # scheduling
        idle-seeding-limit = 30;
        idle-seeding-limit-enabled = false;
        ratio-limit = 1.5;
        ratio-limit-enabled = true;
      };
    };
  };
  systemd.services.mpd = {
    serviceConfig.SupplementaryGroups = [ "pipewire" ];
    environment = {
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
      XDG_RUNTIME_DIR = "/run/user/1002"; # User-id 1000 must match above user. MPD will look inside this directory for the PipeWire socket.
    };
  };
  services.mpd = {
    user = "zarred";
    group = "users";
    enable = true;
    dataDir = "/mnt/gargantua/media/music/data";
    musicDirectory = "/mnt/gargantua/media/music";
    dbFile = null;
    network.listenAddress = "any";
    network.port = 6600;
    startWhenNeeded = true;
    extraConfig = (if config.networking.hostName == "sankara"
      then ''
        database {
          plugin  "simple"
          path    "/mnt/gargantua/media/music/data/mpd.db"
          cache_directory    "/mnt/gargantua/media/music/data/cache"
        }
        audio_output {
          type    "null"
          name    "MPD Server"
        }
        ''
      else ''
        database {
          plugin  "proxy"
          host    "sankara"
          port    "6600"
        }
        audio_output {
          type    "pipewire"
          name    "Pipewire Sound Server"
        }
      '');
  };
  services.flatpak.enable = false;
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          gamescope-wsi
          vulkan-loader
          zenity
          wayland
        ];
    };
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true;
    #extraCompatPackages = with pkgs; [
    #  vkd3d-proton
    #  vkd3d
    #  dxvk_2
    #  proton-ge-bin
    #  freetype
    #  openjdk21_headless
    #  wineWowPackages.waylandFull
    #  gamescope
    #  #gamescope-wsi
    #  vulkan-loader
    #];
  };
  environment.systemPackages = with pkgs; [
    freetype
    mangohud
    vulkan-tools
    wine
    #gamemode
    libva
    libva-utils
    protonup
  ];
  #environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/zarred/.steam/root/compatibilitytools.d";
  programs.gamescope = {
    # NOTE: Gamescope Compositor / "Boot to Steam Deck"
    enable = true;
    capSysNice = true;
    #args = [
      #"--rt"
      #"--adaptive-sync" # VRR support
      #"--hdr-enabled"
      #"--mangoapp"
      #"--steam"
    #];
  };
  programs.gamemode = {
    enable = true;
    #enableRenice = true;
    settings = {
      #general = {
      #  renice = 10;
      #};
      ## Warning: GPU optimisations have the potential to damage hardware
      #gpu = {
      #  apply_gpu_optimisations = "accept-responsibility";
      #  gpu_device = 0;
      #  amd_performance_level = "high";
      #};
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
      nerd-fonts.hack
      font-awesome
      noto-fonts
      noto-fonts-emoji
    ];
  };
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit # text editor
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gnome-terminal
    epiphany # web browser
    geary # email reader
    evince # document viewer
    gnome-characters
    totem # video player
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);
}
