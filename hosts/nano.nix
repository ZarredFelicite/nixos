{ config, lib, pkgs, modulesPath, inputs, outputs, self, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs outputs; };
    users.zarred = import ../home/hosts/nano.nix;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "nano";
  services.syncthing.enable = true;
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "kvm-intel" ];
    #kernelParams = [
    #  #"SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
    #  "initcall_debug"
    #  "log_buf_len=16M"
    #  "i915.force_probe=!9a40"
    #  #"i915.enable_dc=0"
    #  "xe.force_probe=9a40"
    #  #"intel_idle.max_cstate=1"
    #  #"ahci.mobile_lpm_policy=1"
    #];
    #kernelPatches = [ {
    #  name = "sleepdebug-config";
    #  patch = null;
    #  extraConfig = ''
    #    PM y
    #    PM_DEBUG y
    #    PM_SLEEP_DEBUG y
    #    FTRACE y
    #    FUNCTION_TRACER y
    #    FUNCTION_GRAPH_TRACER y
    #    KPROBES y
    #    KPROBES_ON_FTRACE y
    #  '';
    #} ];
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
    size = 24 * 1024;
  }];

  powerManagement = {
    enable = true;
    #resumeCommands = "${pkgs.kmod}/bin/rmmod atkbd; ${pkgs.kmod}/bin/modprobe atkbd reset=1";
  };
  services.power-profiles-daemon.enable = false; # not optimal
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      # iGPU
      #INTEL_GPU_MIN_FREQ_ON_AC = 0;
      #INTEL_GPU_MIN_FREQ_ON_BAT = 0;
      #INTEL_GPU_MAX_FREQ_ON_AC = 1100;
      #INTEL_GPU_MAX_FREQ_ON_BAT = 800;
      #INTEL_GPU_BOOST_FREQ_ON_AC = 1100;
      #INTEL_GPU_BOOST_FREQ_ON_BAT = 900;

      # OTHER
      SOUND_POWER_SAVE_ON_AC = 1;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      WOL_DISABLE = "N";
      DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "bluetooth wifi";
      USB_AUTOSUSPEND = 1;

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 75;

      #Optional helps save long term battery health
      START_CHARGE_THRESH_BAT0 = 60; # 60 and bellow it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 90; # 90 and above it stops charging
    };
  };
  services.fwupd.enable = true;
  services.pulseaudio.enable = false;
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware = {
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
        # TODO: build fail? intel-ocl
        #vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
