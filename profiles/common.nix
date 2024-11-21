{ pkgs, config, lib, inputs, ... }: {
  imports = [
    ../sys/nix.nix
    inputs.sops-nix.nixosModules.sops
    ../containers/docker.nix
  ];
  system.stateVersion = "23.05";
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };
    timeout = 1;
    #consoleLogLevel = 0;
    efi.canTouchEfiVariables = true;
  };
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  networking = {
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
        extraGroups = [ "networkmanager" "wheel" "video" "render" "tss"];
        home = "/home/zarred";
        createHome = true;
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr5Pg9hm9lQDhobHUmn1q5R9XBXIv9iEcGUz9u+Vo9G zarred"
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
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [];
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
        twitch-oauth = {};
        cloudflare-api-token = {};
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
  #virtualisation = {
  #  docker = {
  #    enable = false;
  #    rootless.enable = true;
  #  };
  #};
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
    };
    udev.extraRules = ''
    '';
  };
  environment = {
    systemPackages = with pkgs; [
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
    ];
    shells = with pkgs; [ zsh bashInteractive ];
    pathsToLink = [ "/share/zsh" ];
  };
  programs = {
    dconf.enable = true;
    zsh.enable = true;
    mosh.enable = true;
    nh = {
      enable = true;
      flake = /home/zarred/dots;
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
    image = lib.mkMerge [
      (lib.mkIf (config.networking.hostName == "nano") /persist/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg)
      (lib.mkIf (config.networking.hostName == "web") /persist/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg)
    ];
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
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
        name = "Iosevka Nerd Font";
      };
      serif = {
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
        name = "Iosevka Nerd Font";
      };
      monospace = {
        package = pkgs.nerdfonts.override { fonts = [ "Iosevka" ]; };
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
