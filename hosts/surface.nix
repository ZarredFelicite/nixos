{ config, lib, pkgs, modulesPath, inputs, ... }: {
  imports = [
    ../modules/iio-hyprland/default.nix
    ../modules/lisgd.nix
    ../modules/wvkbd.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    #(inputs.hyprgrass: { nixpkgs.overlays = import ../overlays inputs.hyprgrass; })
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "surface";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    initrd.availableKernelModules = [
      "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "surface_aggregator"
      "surface_aggregator_registry" "surface_aggregator_hub" "surface_hid_core"
      "surface_hid" "intel_lpss" "intel_lpss_pci" "8250_dw" "pinctrl_icelake"
    ];
    initrd.kernelModules = [ ];
    initrd.luks.devices."root".device = "/dev/disk/by-uuid/0c2e7811-4812-4525-9527-2442efcc2411";
  };
  systemd.services.iptsd.wantedBy = [ "graphical.target" ];
  environment.systemPackages = [ pkgs.wvkbd ];
  services = {
    iio-hyprland.enable = true;
    lisgd.enable = true;
    wvkbd.enable = true;
    xserver.libinput.enable = true;
  };
  #microsoft-surface = {
  #  kernelVersion = "6.5.11";
  #  ipts.enable = true;
  #  surface-control.enable = true;
  #};
  users.users.zarred.extraGroups = [ "surface-control" ];

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ]; # mode=755 so only root can write to those files, "size=3G" "
      neededForBoot = true;
    };
    "/home" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "size=4G" "mode=777" ]; # mode=777 so user can write home dir"
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/87C9-94D6";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "noatime" "ssd" "subvol=nix" ];
      neededForBoot = true;
    };
    "/persist" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "noatime" "ssd" "subvol=persist" ];
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
    size = 8196;
  }];
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave"; # “ondemand”, “powersave”, “performance”
  };
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    brillo.enable = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };
}
