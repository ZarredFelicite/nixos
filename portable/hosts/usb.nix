{ pkgs, ... }:
{
  networking.hostName = "portable-usb";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usb_storage"
      "uas"
      "usbhid"
      "sd_mod"
    ];
    initrd.luks.devices.portable_usb.device = "/dev/disk/by-uuid/71e6355f-be02-4e5c-9bb2-7a9022f925f0";

    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/portable_usb";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/54E2-2E21";
      fsType = "vfat";
    };
    "/data" = {
      device = "/dev/disk/by-uuid/3de76d8b-c3e1-4045-9b0f-fbe78848b0c0";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
    };
  };

  users.mutableUsers = true;
  users.users.zarred = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    # Set the local password interactively after installation; no password material
    # is embedded in this flake or copied into the Nix store.
    openssh.authorizedKeys.keys = [ ];
  };
  programs.zsh.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
    };
  };
  networking.firewall.enable = true;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.fwupd.enable = true;
  services.tailscale.enable = true;
  environment.systemPackages = with pkgs; [
    btrfs-progs
    curl
    dosfstools
    e2fsprogs
    git
    gptfdisk
    parted
    tmux
    util-linux
    vim
    wget
    wireguard-tools
  ];

  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;

  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.gnome.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.hyprland.enable = true;
  # Home Manager provides hyprlock; PAM must be configured by the system.
  security.pam.services.hyprlock = {};

  hardware.graphics.enable = true;
  xdg.portal.enable = true;
}
