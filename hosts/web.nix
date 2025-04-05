{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../profiles/fans/fans.nix
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "web";
  boot = {
    #kernelPackages = pkgs.linuxPackages_cachyos;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" "nct6775" "i2c-dev" "ddcci_backlight" ];
    kernelParams = [
    #  #"SYSTEMD_CGROUP_ENABLE_LEGACY_FORCE=1"
    #  "initcall_debug"
    #  "log_buf_len=16M"
    #  "nvidia-drm.fbdev=1"
    #  "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      #"nvidia.NVreg_UsePageAttributeTable=1"
      #''nvidia.NVreg_RegistryDwords="OverrideMaxPerf=0x1"''
    ];
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
    #blacklistedKernelModules = ["nouveau"];
    #kernel.sysctl = { "vm.swappiness" = 90;};
    extraModulePackages = [ config.boot.kernelPackages.ddcci-driver];
    #extraModulePackages = [ pkgs.linuxPackages_cachyos.ddcci-driver ];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "usbhid" ];
    initrd.kernelModules = [ ];
    initrd.luks.devices."root".device = "/dev/disk/by-uuid/2ab90543-1156-4f0d-8674-8b1d35d4a7e8";
    initrd.systemd.enable = true;
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="i2c-dev", ACTION=="add",\
      ATTR{name}=="NVIDIA i2c adapter*",\
      TAG+="ddcci",\
      TAG+="systemd",\
      ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"
  '';
  systemd.services."ddcci@" = {
    scriptArgs = "%i";
    script = ''
      echo Trying to attach ddcci to $1
      i=0
      id=$(echo $1 | cut -d "-" -f 2)
      counter=5
      while [ $counter -gt 0 ]; do
        if ${pkgs.ddcutil}/bin/ddcutil getvcp 10 -b $id; then
          sleep 5
          echo ddcci 0x37 > /sys/bus/i2c/devices/$1/new_device
          break
        fi
        sleep 1
        counter=$((counter - 1))
      done
    '';
    serviceConfig.Type = "oneshot";
  };
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
    size = 65568;
  }];
  environment.variables = {
    # Necessary to correctly enable va-api (video codec hardware
    # acceleration). If this isn't set, the libvdpau backend will be
    # picked, and that one doesn't work with most things, including
    # Firefox.
    LIBVA_DRIVER_NAME = "nvidia";
    # Required to run the correct GBM backend for nvidia GPUs on wayland
    GBM_BACKEND = "nvidia-drm";
    GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
    WLR_BACKEND = "vulkan";
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
    #__EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa.outPath}/share/glvnd/egl_vendor.d/50_mesa.json";
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    NIXOS_OZONE_WL = "1";
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };
  services.power-profiles-daemon.enable = true;
  services.xserver.videoDrivers = ["nvidia"];
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };
  # HibernateDelaySec=1h
  systemd.sleep.extraConfig = ''
    MemorySleepMode=s2idle
  '';
  nixpkgs.config.nvidia.acceptLicense = true;
  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = true;
    nvidia = {
      open = true;
      nvidiaSettings = true;
      #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #  version = "570.86.16"; # use new 570 drivers
      #  sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
      #  openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
      #  settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
      #  usePersistenced = false;
      #};
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # TODO:
      # flicker on 570.124.04
      # nixpkgs search linuxKernel.packages.linux_6_13.nvidia_x11
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      videoAcceleration = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [nvidia-vaapi-driver];
    };
    openrazer = {
      enable = false; # TODO: broken pr:384992
      users = [ "zarred" ];
      devicesOffOnScreensaver = true;
    };
  };
  environment.systemPackages = [
    pkgs.polychromatic
  ];
  environment.etc.machine-id.text = "b7608440568f4ffb8d26dcadf1eb28d6";
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.txt".text = ''
    {
        "rules": [
            {
                "pattern": {
                    "feature": "procname",
                    "matches": "Hyprland"
                },
                "profile": "Limit Free Buffer Pool On Wayland Compositors"
            }
        ],
        "profiles": [
            {
                "name": "Limit Free Buffer Pool On Wayland Compositors",
                "settings": [
                    {
                        "key": "GLVidHeapReuseRatio",
                        "value": 1
                    }
                ]
            }
        ]
    }
'';
  systemd.services.nvidia-oc = {
    wantedBy = [ "multi-user.target" ];
    description = "Set nvidia GPU settings with python wrapper of NVML";
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      ExecStart = pkgs.writers.writePython3 "nvidia-oc" {
        libraries = [ pkgs.python312Packages.nvidia-ml-py pkgs.python312Packages.pynvml ];
        flakeIgnore = [ "E265" "E225" ];
      }
      ''
        import pynvml
        pynvml.nvmlInit()
        myGPU = pynvml.nvmlDeviceGetHandleByIndex(0)
        #pynvml.nvmlDeviceSetGpuLockedClocks(myGPU, 225, 2115)
        pynvml.nvmlDeviceSetGpcClkVfOffset(myGPU, 100)
        pynvml.nvmlDeviceSetMemClkVfOffset(myGPU, 1000)
        pynvml.nvmlDeviceSetPowerManagementLimit(myGPU, 370000)
      '';
    };
  };
  virtualisation.oci-containers.containers.kokoro = {
    image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.1.5-pre";
    ports = [ "8880:8880" ];
  };
  # TODO: not working
  #virtualisation.oci-containers.containers.readerlm = {
  #  image = "rbehzadan/readerlm:latest";
  #  ports = [ "8083:8080" ];
  #};
}

