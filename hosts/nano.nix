{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "nano";
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "kvm-intel" ];
    #kernelParams = [ "SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1" ];
    extraModulePackages = [ ];
    initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
    initrd.luks.devices."root".device = "/dev/disk/by-uuid/923d48e9-065c-4608-b797-d995fd6c4283";
    initrd.systemd.enable = true;
  };
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ]; # mode=755 so only root can write to those files
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2E70-D7E1";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "noatime" "ssd" "subvol=nix" ];
      neededForBoot = true;
    };
    "/home/zarred" = {
      device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [ "mode=777" ];
    };
    "/persist" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "relatime" "lazytime" "ssd" "subvol=persist" ];
      neededForBoot = true;
    };
    "/swap" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "noatime" "ssd" "subvol=swap" ];
    };
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 16392;
  }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  powerManagement = {
    enable = true;
    #cpuFreqGovernor = lib.mkDefault "powersave"; # “ondemand”, “powersave”, “performance”
    #resumeCommands = "${pkgs.kmod}/bin/rmmod atkbd; ${pkgs.kmod}/bin/modprobe atkbd reset=1";
  };
  services.power-profiles-daemon.enable = false; # not optimal
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 75;

     #Optional helps save long term battery health
     START_CHARGE_THRESH_BAT0 = 60; # 60 and bellow it starts to charge
     STOP_CHARGE_THRESH_BAT0 = 95; # 80 and above it stops charging
    };
  };
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware = {
    pulseaudio.enable = false;
    trackpoint = {
      enable = true;
      device = "tpps/2-elan-trackpoint";
      speed = 85;
      sensitivity = 128;
      emulateWheel = true;
    };
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        intel-ocl
        #vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
