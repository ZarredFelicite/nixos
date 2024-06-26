{ self, config, pkgs, lib, inputs, outputs, ... }: {
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
    extraSpecialArgs = { inherit self inputs outputs; };
    users.zarred = import ../home/desktop.nix;
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    brillo.enable = true;
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
    };
    greetd = {
      enable = true;
      vt = 2; # clean login screen, no startup logs
      restart = false;
      settings = rec {
        #initial_session = {
	      #  command = "${pkgs.hyprland}/bin/Hyprland";
	      #  user = "zarred";
	      #};
        #default_session = initial_session;
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
              --time \
              --asterisks \
              --user-menu \
              --cmd Hyprland \
              -s ${config.services.xserver.displayManager.sessionData.desktops}/share/wayland-sessions \
              --remember \
              --remember-user-session \
              --width 50
          '';
          user = "greeter";
        };
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/bluetooth.lua.d/51-bluez-config.lua" ''
            bluez_monitor.properties = {
              ["bluez5.enable-sbc-xq"] = true,
              ["bluez5.enable-msbc"] = true,
              ["bluez5.enable-hw-volume"] = true,
              ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
            }
          '')
        ];
      };
      audio.enable = true;
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
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true; #TODO
  };
  programs.gamescope = {
    enable = true; #TODO
    args = [ "--rt" ];
  };
  programs.gamemode = {
    enable = true;
    enableRenice = true;
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
  environment = {
    etc."greetd/environments".text = ''
      Hyprland
    '';
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "Iosevka" "Hack" ]; })
      iosevka
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
