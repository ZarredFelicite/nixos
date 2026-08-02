{ config, lib, pkgs, inputs, self, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "rock4c";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs self; };
    users.zarred = import ../home/hosts/rock4c.nix;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      timeout = 2;
    };
    supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];
    # 7.1.2 loads the AP6256 firmware but times out on SDIO control requests.
    kernelPackages = inputs.rock4c-nixpkgs.legacyPackages.aarch64-linux.linuxPackages_latest;
    initrd.kernelModules = [ "reset-gpio" ];
    kernelModules = [ "reset-gpio" ];
    kernelParams = [ "console=ttyS2,1500000n8" ];
    tmp.cleanOnBoot = true;
  };

  # AP6256 Wi-Fi/BT needs its reset provider early, board calibration data,
  # and a short delay after SDIO power-on.
  hardware.enableRedistributableFirmware = true;

  hardware.deviceTree.overlays = [
    {
      name = "rock4c-wifi-power-sequence";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "radxa,rock-4c-plus";
        };

        &sdio_pwrseq {
          post-power-on-delay-ms = <200>;
        };
      '';
    }
  ];

  hardware.firmware = [
    (pkgs.runCommand "rock4c-ap6256-firmware" { } ''
      install -Dm644 ${pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/radxa/firmware/7ee0bc437c75bc771b6207ea9c58768b8607c73d/rkwifi/nvram_ap6256.txt";
        hash = "sha256-ZscetTtHxJ1COGtmc1E0V4ZAsJRvP0bkTzhP71qs/Z4=";
      }} $out/lib/firmware/brcm/brcmfmac43455-sdio.radxa,rock-4c-plus.txt
    '')
  ];

  networking = {
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      ensureProfiles.profiles."direct-ethernet-managed" = {
        connection = {
          id = "direct-ethernet-managed";
          type = "ethernet";
          interface-name = "end0";
          autoconnect = true;
          autoconnect-priority = 200;
        };
        ethernet = { };
        ipv4 = {
          method = "manual";
          address1 = "192.168.86.151/24";
        };
        ipv6.method = "disabled";
      };
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    tailscale = {
      enable = true;
      openFirewall = true;
      extraSetFlags = [ "--operator=zarred" ];
    };
    journald.extraConfig = ''
      SystemMaxUse=256M
      RuntimeMaxUse=64M
    '';
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.zarred = {
      isNormalUser = true;
      uid = 1000;
      description = "Zarred";
      extraGroups = [ "wheel" "networkmanager" "video" "render" "dialout" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+Xu5vJqXmgaWKHIp+4IsorATOO61u5X5ECanN3dn31 openpgp:0xD8C648AB"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEr5Pg9hm9lQDhobHUmn1q5R9XBXIv9iEcGUz9u+Vo9G zarred@web"
      ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  programs = {
    zsh.enable = true;
    nix-ld.enable = true;
  };

  environment.systemPackages = with pkgs; [
    curl
    ethtool
    git
    htop
    iw
    pciutils
    rsync
    tmux
    usbutils
    vim
    wget
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "zarred" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "arm-trusted-firmware-rk3399" ];

  system.stateVersion = "26.11";
}
