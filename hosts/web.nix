{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "web";
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [ "kvm-amd" "nct6775" ];
    extraModulePackages = [ ];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "usbhid" ];
    initrd.kernelModules = [ ];
  };
  boot.initrd.luks.devices."root".device = "/dev/disk/by-uuid/2ab90543-1156-4f0d-8674-8b1d35d4a7e8";
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-partuuid/32b7f825-a526-b14a-b44a-327f158f3c34";
      fsType = "vfat";
    };
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ];
      neededForBoot = true;
    };
    "/home/zarred" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=777" ];
      neededForBoot = true;
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
      options = [ "defaults" "compress-force=zstd" "ssd" "subvol=persist" ];
      neededForBoot = true;
    };
    "/swap" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "noatime" "compress-force=zstd" "ssd" "subvol=swap" ];
    };
  };
  swapDevices = [{
    device = "/swap/swapfile";
    size = 32784;
  }];
  environment.variables = {
    # Necessary to correctly enable va-api (video codec hardware
    # acceleration). If this isn't set, the libvdpau backend will be
    # picked, and that one doesn't work with most things, including
    # Firefox.
    LIBVA_DRIVER_NAME = "nvidia";
    # Required to run the correct GBM backend for nvidia GPUs on wayland
    GBM_BACKEND = "nvidia-drm";
    # Apparently, without this nouveau may attempt to be used instead
    # (despite it being blacklisted)
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Required to use va-api it in Firefox. See
    # https://github.com/elFarto/nvidia-vaapi-driver/issues/96
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # It appears that the normal rendering mode is broken on recent
    # nvidia drivers:
    # https://github.com/elFarto/nvidia-vaapi-driver/issues/213#issuecomment-1585584038
    NVD_BACKEND = "direct";
    # Required for firefox 98+, see:
    # https://github.com/elFarto/nvidia-vaapi-driver#firefox
    EGL_PLATFORM = "wayland";
  };
  powerManagement.cpuFreqGovernor = "performance";
  services.xserver.videoDrivers = ["nvidia"];
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #  version = "555.42.02";
      #  sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
      #  sha256_aarch64 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #  openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #  settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #  persistencedSha256 = "sha256-3ae31/egyMKpqtGEqgtikWcwMwfcqMv2K4MVFa70Bqs=";
      #};
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        #vaapiVdpau
        #libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };
    openrazer = {
      enable = true;
      users = [ "zarred" ];
      devicesOffOnScreensaver = true;
    };
  };
  environment.systemPackages = [
    pkgs.polychromatic
    pkgs.gwe
  ];
  systemd.services.nvidia-oc = {
    wantedBy = [ "multi-user.target" ];
    description = "Set nvidia GPU settings with python wrapper of NVML";
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      ExecStart = pkgs.writers.writePython3 "nvidia-oc" {
        libraries = [ pkgs.python311Packages.nvidia-ml-py pkgs.python311Packages.pynvml ];
        flakeIgnore = [ "E265" "E225" ];
      }
      ''
        import pynvml
        pynvml.nvmlInit()
        myGPU = pynvml.nvmlDeviceGetHandleByIndex(0)
        pynvml.nvmlDeviceSetGpcClkVfOffset(myGPU, 130)
        pynvml.nvmlDeviceSetMemClkVfOffset(myGPU, 3000)
        pynvml.nvmlDeviceSetPowerManagementLimit(myGPU, 350000)
      '';
    };
  };
}

