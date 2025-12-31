{ config, lib, pkgs, modulesPath, inputs, outputs, self, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "nano";
  services.syncthing.enable = false;
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
    initrd.luks.devices."root".device = "/dev/nvme0n1p2";
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
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd:5" "noatime" "ssd" "subvol=nix" ];
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
      options = [ "defaults" "compress=zstd" "relatime" "lazytime" "ssd" "subvol=persist" ];
      neededForBoot = true;
    };
    "/swap" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "compress=no" "noatime" "ssd" "subvol=swap" ];
    };
  };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 24 * 1024;
  }];

  systemd.services.radio-power-on-sleep = {
    description = "Save WiFi and Bluetooth state before sleep";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "radio-pre-sleep" ''
        # Save WiFi state
        if ${pkgs.iwd}/bin/iwctl device wlan0 show | ${pkgs.gnugrep}/bin/grep -q "Powered: on"; then
          echo "on" > /run/wifi_state
        else
          echo "off" > /run/wifi_state
        fi

        # Bluetooth logic: turn off if no active connections
        if ${pkgs.bluez}/bin/bluetoothctl devices Connected | ${pkgs.gnugrep}/bin/grep -q "Device"; then
          echo "connected" > /run/bluetooth_state
        else
          echo "disconnected" > /run/bluetooth_state
          ${pkgs.bluez}/bin/bluetoothctl power off
        fi
      '';
    };
  };

  systemd.services.radio-power-on-resume = {
    description = "Restore WiFi and Bluetooth state after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "radio-post-resume" ''
        # Restore WiFi if it was on
        if [ -f /run/wifi_state ] && [ "$(${pkgs.coreutils}/bin/cat /run/wifi_state)" = "on" ]; then
          ${pkgs.iwd}/bin/iwctl device wlan0 set-property Powered on
        fi
      '';
    };
  };

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
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "";
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
        libvdpau-va-gl
        libva-vdpau-driver
      ];
    };
  };
}
