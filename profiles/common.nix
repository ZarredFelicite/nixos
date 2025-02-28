{ pkgs, pkgs-unstable, config, lib, inputs, ... }: {
  imports = [
    ../sys/nix.nix
    inputs.sops-nix.nixosModules.sops
    ../containers/docker.nix
    ../containers/podman.nix
  ];
  system.stateVersion = "23.05";
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };
    timeout = 0;
    #consoleLogLevel = 0;
    efi.canTouchEfiVariables = true;
  };
  boot.kernel.sysctl."fs.file-max" = 524288;
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  networking = {
    #nameservers = [ "1.1.1.1" "9.9.9.9" ];
    networkmanager.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [ 111 8080 80 443 8384]; # showmount,
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
    extraHosts =
      "
      100.64.1.200 sankara
      100.64.1.125 nano
      100.64.1.150 web
      192.168.86.224 rprinter
      192.168.86.240 rpizero
      192.168.86.246 oneplus
      ";
  };
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=zarred" ];
  };
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    groups = {
      nixremote = {};
    };
    users = {
      root = {
        hashedPasswordFile = config.sops.secrets.users-root.path;
      };
      zarred = {
        isNormalUser = true;
        description = "Zarred";
        hashedPasswordFile = config.sops.secrets.users-zarred.path;
        extraGroups = [ "networkmanager" "wheel" "video" "render" "tss" "ftp"];
        home = "/home/zarred";
        createHome = true;
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+Xu5vJqXmgaWKHIp+4IsorATOO61u5X5ECanN3dn31 openpgp:0xD8C648AB"
        ];
      };
      nixremote = {
        # TODO: disable su into user
        description = "Unsecured user for distributed nix builds";
        isNormalUser = true;
        createHome = true;
        shell = pkgs.bash;
        #homeMode =
        group = "nixremote";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdeXfQX7Ql7RRrv4GGtwfet2q6p0dxUJac3dNLnU+BY root@nano"
        ];
      };
    };
	};
  # Permission modes are in octal representation (same as chmod),
  # the digits represent: user|group|others
  # 7 - full (rwx)
  # 6 - read and write (rw-)
  # 5 - read and execute (r-x)
  # 4 - read only (r--)
  # 3 - write and execute (-wx)
  # 2 - write only (-w-)
  # 1 - execute only (--x)
  # 0 - none (---)
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [];
    # NOTE:Prevents pure eval
    templates."gotify-cli.json" = {
      content = ''
        {
          "token": "${config.sops.placeholder.gotify-app-web-token}",
          "url": "https://gotify.zar.red",
          "defaultPriority": 6
        }
      '';
      owner = "zarred";
    };
    templates."gotify-desktop-config.toml" = {
      content = ''
        [gotify]
        url = "wss://gotify.zar.red"
        token = "${config.sops.placeholder.gotify-client-web-token}"
        auto_delete = false  # optional, if true, deletes messages that have been handled, defaults to false
        [notification]
        min_priority = 1  # optional, ignores messages with priority lower than given value
        [action]
        # optional, run the given command for each message, with the following environment variables set: GOTIFY_MSG_PRIORITY, GOTIFY_MSG_TITLE and GOTIFY_MSG_TEXT.
        #on_msg_command = "/usr/bin/beep"
      '';
      owner = "zarred";
    };
    secrets = lib.mkMerge [
      (lib.mkIf (config.networking.hostName == "sankara") {
        nextcloud-admin = { owner = "nextcloud"; };
        authelia-jwtSecret = { owner = "zarred"; };
        authelia-storageEncryptionKey = { owner = "zarred"; };
      })
      {
        users-zarred.neededForUsers = true;
        users-root.neededForUsers = true;
        gmail-personal = { owner = "zarred"; };
        restic-home = { owner = "zarred"; };
        gotify-client-web-token = { owner = "zarred"; };
        gotify-app-web-token = { owner = "zarred"; };
        twitch-oauth = {};
        cloudflare-api-token = {};
        ib-gateway = {};
        twitch-api-token = {
          sopsFile = ../secrets/twitch-api-token.json;
          format = "binary";
          owner = "zarred";
          #path = "/home/zarred/.config/wtwitch/api.json";
        };
        #github-api-token = {
        #  sopsFile = ../secrets/github-hosts.yaml;
        #  format = "binary";
        #  owner = "zarred";
        #  path = "/home/zarred/.config/gh/hosts.yml";
        #};
        binary-cache-key = {};
        #nixremote-private = { owner = config.users.users.zarred.name; group = config.users.users.zarred.group; mode = "0440";};
        nixremote-private = { };
      }
    ];
  };
  security = {
    # TODO: enable lanzaboote for secureboot on nixos
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
    polkit.enable = true;
    rtkit.enable = true;
    pam.loginLimits = [{
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "8192";
    }];
    pam.services.hyprlock = {
      text = ''
        auth include login
      '';
      logFailures = true;
      fprintAuth = true;
      failDelay.enable = true;
      failDelay.delay = 1000000;
      gnupg.enable = true;
      gnupg.noAutostart = true;
    };
    pam.services.swaylock = {
      text = ''
        # PAM configuration file for the swaylock screen locker. By default, it includes
        # the 'login' configuration file (see /etc/pam.d/login)
        auth include login
      '';
      logFailures = true;
      fprintAuth = true;
      failDelay.enable = true;
      failDelay.delay = 1000000;
      gnupg.enable = true;
      gnupg.noAutostart = true;
    };
  };
  services = {
    dbus.enable = true;
    fprintd.enable = false;
    udisks2.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
    udev.extraRules = ''
    '';
  };
  programs.ssh = {
    extraConfig = ''
      Host nixremote-web
        HostName web
        User nixremote
        IdentityFile ${config.sops.secrets.nixremote-private.path}
    '';
  };
  environment = {
    systemPackages = (with pkgs; [
      git
      jq
      iotop
      wget
      curl
      neovim
      cmake
      gnumake
      ninja
      tailscale
      sops
      direnv
      inotify-tools
      inputs.rose-pine-hyprcursor.packages.${pkgs.hostPlatform.system}.default
      (python311.withPackages(ps: with ps; [
        pip
        pandas
        requests
        psutil
        pillow
        libtmux
        shtab
      ]))
      nodejs
      openjpeg
    ]) ++
    ( with pkgs-unstable; [
        #
    ]);
    shells = with pkgs; [ zsh bashInteractive ];
    pathsToLink = [ "/share/zsh" ];
  };
  programs = {
    dconf.enable = true;
    zsh.enable = true;
    mosh.enable = true;
    nh = {
      enable = true;
      clean.enable = false;
      clean.extraArgs = "--keep 5 --keep-since 3d";
      clean.dates = "weekly";
    };
  };
  documentation.man = {
    # In order to enable to mandoc man-db has to be disabled.
    man-db.enable = false;
    mandoc.enable = true;
    generateCaches = true;
  };
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../wallpaper.jpg;
    # NOTE: Impure access to paths
    #image = lib.mkMerge [
    #  (lib.mkIf (config.networking.hostName == "nano") /persist/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg)
    #  (lib.mkIf (config.networking.hostName == "web") /persist/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg)
    #  (lib.mkIf (config.networking.hostName == "sankara") /persist/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg)
    #];
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    # https://github.com/tinted-theming/base16-schemes
    #override = {
    #  base00 = "#191724";
    #};
    cursor = {
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      size = 24;
    };
    opacity = {
      terminal = 0.4;
    };
    fonts = {
      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
      sansSerif = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font";
      };
      serif = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font";
      };
      monospace = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    targets = {
      #waybar.enable = false;
    };
  };

}
