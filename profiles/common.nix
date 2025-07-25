{ pkgs, config, lib, inputs, ...
  #pkgs-unstable,
}: {
  imports = [
    ../profiles/nix.nix
    ../profiles/impermanence.nix
    ../profiles/syncthing.nix
    ../profiles/python.nix
    inputs.sops-nix.nixosModules.sops
    ../containers/docker.nix
    ../containers/podman.nix
  ];
  system.stateVersion = "24.11";
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
    };
    timeout = 1;
    #consoleLogLevel = 0;
    efi.canTouchEfiVariables = true;
  };
  boot.kernel.sysctl."fs.file-max" = 524288;
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
  '';

  systemd.network = {
    #wait-online = {
    #  anyInterface = true;
    #  timeout = 0;
    #};
    networks = {
      "10-wired" = {
        matchConfig.Name = "enp38s0";
        #networkConfig.IPv6AcceptRA = true;
        address = [ "10.20.30.1/30" ];
        #linkConfig.RequiredForOnline = "routable";
        routes = [ { Metric = 10; } ];
      };
      "20-wired" = {
        matchConfig.Name = "enp0s13f0u3u4u5";
        #networkConfig.IPv6AcceptRA = true;
        address = [ "10.20.30.2/30" ];
        #linkConfig.RequiredForOnline = "routable";
        routes = [ { Metric = 10; } ];
      };
      "30-wired" = {
        matchConfig.Name = "enp4s0";
        networkConfig.DHCP = "yes";
        routes = [ { Metric = 10; } ];
      };
      "60-wifi" = {
        matchConfig.Name = "wlan0";
        networkConfig.DHCP = "yes";
        #networkConfig.IPv6AcceptRA = true;
        #linkConfig.RequiredForOnline = "routable";
        routes = [ { Metric = 600; } ];
      };
    };
  };
  #services.resolved = {
  #  enable = false;
  #  dnssec = "true";
  #  domains = [ "~." ];
  #  fallbackDns = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  #  dnsovertls = "true";
  #  extraConfig = ''
  #    MulticastDNS=true
  #  '';
  #};
  networking = {
    #nameservers = [ "192.168.8.1" "1.1.1.1" "1.0.0.1" ];
    useNetworkd = true;
    useDHCP = false;
    #dhcpcd.enable = false;
    #interfaces.wlan0.wakeOnLan.enable = true;
    networkmanager = {
      enable = false;
      wifi.powersave = false;
      wifi.backend = "iwd";
      logLevel = "WARN";
    };
    wireless.iwd = {
      enable = true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = true;
      };
    };
    firewall = {
      enable = false;
      allowedTCPPorts = [ 111 8080 80 443 8384]; # showmount,
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
  };
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--operator=zarred"
      "--advertise-exit-node"
    ];
    useRoutingFeatures = "both";
    openFirewall = true;
  };
  #systemd.services.tailscaled.after = [ "network.target" "network-online.target" ];
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
        extraGroups = [ "networkmanager" "wheel" "video" "render" "tss" "ftp" "keyd" "input"];
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
        immich-secrets = {
          sopsFile = ../secrets/immich.enc.env;
          format = "dotenv";
          owner = "immich";
        };
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
        ib-gateway = { owner = "zarred"; };
        ib-gateway-vnc = { owner = "zarred"; };
        syncthing-api = { owner = "zarred"; };
        jellyfin-zarred = { owner = "zarred"; };
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
    doas.enable = true;
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
    systemd-lock-handler.enable = true;
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
      ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"
    '';
  };
  programs.ssh = {
    extraConfig = ''
      Host nixremote-web
        HostName web
        User nixremote
        IdentityFile ${config.sops.secrets.nixremote-private.path}
    '';
    knownHosts = {
      #web = {
      #  extraHostNames = [ "myhost.mydomain.com" "10.10.1.4" ];
      #  publicKeyFile = ./pubkeys/myhost_ssh_host_dsa_key.pub;
      #};
      "web".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXK45mP2pGkokOWxJN0RXGIt4lkruzfwpbDJe1Y+GGP";
    };
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
      nodejs
      openjpeg
      impala
      iwgtk
    ])
    # ++ ( with pkgs-unstable; [ ])
    ;
    shells = with pkgs; [ zsh bashInteractive ];
    pathsToLink = [ "/share/zsh" ];
  };
  programs = {
    dconf.enable = true;
    zsh.enable = true;
    mosh.enable = true;
    droidcam.enable = true;
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
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.iosevka-term
      # font-awesome already in nerd-fonts
      noto-fonts
      noto-fonts-emoji
    ];
  };
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../wallpaper.jpg;
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
      terminal = 0.2;
    };
    fonts = {
      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
      sansSerif = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm NFM";
      };
      serif = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm NFM";
      };
      monospace = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm NFM";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

}
