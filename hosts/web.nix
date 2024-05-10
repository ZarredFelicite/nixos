{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "web";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
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
    # Hardware cursors are currently broken on nvidia
    WLR_NO_HARDWARE_CURSORS = "1";
    # Required to use va-api it in Firefox. See
    # https://github.com/elFarto/nvidia-vaapi-driver/issues/96
    MOZ_DISABLE_RDD_SANDBOX = "1";
    # It appears that the normal rendering mode is broken on recent
    # nvidia drivers:
    # https://github.com/elFarto/nvidia-vaapi-driver/issues/213#issuecomment-1585584038
    #NVD_BACKEND = "direct";
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
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      #package = let
      #  linux_6_8_patch = pkgs.fetchpatch {
      #    url = "https://gist.github.com/joanbm/24f4d4f4ec69f0c37038a6cc9d132b43/raw/bacb9bf3617529d54cb9a57ae8dc9f29b41d4362/nvidia-470xx-fix-linux-6.8.patch";
      #    hash = "sha256-SPLC2uGdjHSy4h9i3YFjQ6se6OCdWYW6tlC0CtqmP50=";
      #    extraPrefix = "kernel/";
      #    stripLen = 1;
      #  };
      #  rcu_patch = pkgs.fetchpatch {
      #    url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
      #    hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
      #  };
      #in config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #  version = "545.29.06";
      #  sha256_64bit = "sha256-grxVZ2rdQ0FsFG5wxiTI3GrxbMBMcjhoDFajDgBFsXs=";
      #  sha256_aarch64 = "sha256-o6ZSjM4gHcotFe+nhFTePPlXm0+RFf64dSIDt+RmeeQ=";
      #  openSha256 = "sha256-h4CxaU7EYvBYVbbdjiixBhKf096LyatU6/V6CeY9NKE=";
      #  settingsSha256 = "sha256-YBaKpRQWSdXG8Usev8s3GYHCPqL8PpJeF6gpa2droWY=";
      #  persistencedSha256 = "sha256-AiYrrOgMagIixu3Ss2rePdoL24CKORFvzgZY3jlNbwM=";
      #  patches = [ rcu_patch linux_6_8_patch ];
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
  ];
}
