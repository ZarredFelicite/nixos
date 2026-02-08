{ config, lib, pkgs, pkgs-unstable, modulesPath, inputs, outputs, self, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../profiles/fans/fans.nix
    ../modules/docling-server.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs outputs pkgs-unstable;
    };
    sharedModules = [ inputs.nix-openclaw.homeManagerModules.openclaw ];
    users.zarred = import ../home/hosts/web.nix;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  #nixpkgs.overlays = [
  #  (final: prev: {
  #    linux-firmware = pkgs-unstable.linux-firmware;
  #  })
  #];
  networking.hostName = "web";
  services.syncthing.enable = true;
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    extensions = ps: with ps; [ pgvector ];
    ensureUsers = [
      {
        name = "deepface";
        ensureDBOwnership = true;
      }
      {
        name = "zarred";
      }
    ];
    ensureDatabases = [ "deepface" ];
  };
  boot = {
    kernelPackages = pkgs-unstable.linuxPackages_latest;
    kernelModules = [ "kvm-amd" "nct6775" "i2c-dev" "ddcci_backlight" ];
    kernelParams = [ "modprobe.blacklist=nova,nova_core" "rd.driver.blacklist=nova,nova_core" "nova.modeset=0" "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1" ];
    blacklistedKernelModules = [ "nouveau" "nova" "nova_core" ];
    extraModprobeConfig = ''
      blacklist nova
      blacklist nova_core
      install nova /bin/true
      install nova_core /bin/true
    '';
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
    #kernel.sysctl = { "vm.swappiness" = 90;};
    extraModulePackages = [ config.boot.kernelPackages.ddcci-driver];
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
    size = 65568;
  }];
  environment.variables = {
    # Necessary to correctly enable va-api (video codec hardware
    # acceleration). If this isn't set, the libvdpau backend will be
    # picked, and that one doesn't work with most things, including
    # Firefox.
    LIBVA_DRIVER_NAME = "radeonsi";
    # Required to run the correct GBM backend for nvidia GPUs on wayland
    #GBM_BACKEND = "nvidia-drm";
    #GBM_BACKENDS_PATH = "/run/opengl-driver/lib/gbm";
    #WLR_BACKEND = "vulkan";
    # Apparently, without this nouveau may attempt to be used instead
    # (despite it being blacklisted)
    #__GLX_VENDOR_LIBRARY_NAME = "nvidia";
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
    NIXOS_OZONE_WL = "1";
  };
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };
  services.power-profiles-daemon.enable = true;
  services.xserver.videoDrivers = ["amdgpu" "nvidia"];
  services.hardware.openrgb = {
    package = pkgs-unstable.openrgb;
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      videoAcceleration = false;
    };
    amdgpu.initrd.enable = true;
    amdgpu.opencl.enable = true;
    amdgpu.overdrive.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      package = pkgs-unstable.mesa;
      package32 = pkgs-unstable.pkgsi686Linux.mesa;
      extraPackages = [ ];
      #extraPackages32 = with pkgs-unstable.pkgsi686Linux; [ ];
    };
    openrazer = {
      enable = false;
      users = [ "zarred" ];
      devicesOffOnScreensaver = true;
    };
  };
  services.lact.enable = true;
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lactd.wantedBy = ["multi-user.target"];
  environment.systemPackages = [
    pkgs.polychromatic
    pkgs.lact
  ];
  environment.etc.machine-id.text = "b7608440568f4ffb8d26dcadf1eb28d6";
  #environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.txt".text = ''
  #  {
  #      "rules": [
  #          {
  #              "pattern": {
  #                  "feature": "procname",
  #                  "matches": "Hyprland"
  #              },
  #              "profile": "Limit Free Buffer Pool On Wayland Compositors"
  #          }
  #      ],
  #      "profiles": [
  #          {
  #              "name": "Limit Free Buffer Pool On Wayland Compositors",
  #              "settings": [
  #                  {
  #                      "key": "GLVidHeapReuseRatio",
  #                      "value": 1
  #                  }
  #              ]
  #          }
  #      ]
  #  }
  #'';
  systemd.services.nvidia-oc = {
    wantedBy = [ "multi-user.target" ];
    description = "Set nvidia GPU settings with python wrapper of NVML";
    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      ExecStart = pkgs.writers.writePython3 "nvidia-oc" {
        libraries = [ pkgs.python313Packages.nvidia-ml-py pkgs.python313Packages.pynvml ];
        flakeIgnore = [ "E265" "E225" "E231" "F405" "F403" ];
      }
      ''
        #import pynvml
        #pynvml.nvmlInit()
        #myGPU = pynvml.nvmlDeviceGetHandleByIndex(0)
        #pynvml.nvmlDeviceSetGpuLockedClocks(myGPU, 225, 2000)
        #pynvml.nvmlDeviceSetGpcClkVfOffset(myGPU, 250)
        #pynvml.nvmlDeviceSetMemClkVfOffset(myGPU, 1000)
        #pynvml.nvmlDeviceSetPowerManagementLimit(myGPU, 330000)
        from pynvml import *
        from ctypes import byref
        nvmlInit()
        deviceCount = nvmlDeviceGetCount()
        for i in range(deviceCount):
            handle = nvmlDeviceGetHandleByIndex(i)
            print(f"Device {i} : {nvmlDeviceGetName(handle)}")
        device = nvmlDeviceGetHandleByIndex(0)
        nvmlDeviceSetGpuLockedClocks(device,225,2010)
        nvmlDeviceSetPowerManagementLimit(device,330000)

        info = c_nvmlClockOffset_t()
        info.version = nvmlClockOffset_v1
        info.type = NVML_CLOCK_GRAPHICS
        info.pstate = NVML_PSTATE_0
        info.clockOffsetMHz = 200

        nvmlDeviceSetClockOffsets(device, byref(info))

        nvmlShutdown()
      '';
    };
  };
  virtualisation.oci-containers.containers = {
    kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.1.5-pre";
      ports = [ "8880:8880" ];
    };
    crawl4ai = {
      image = "unclecode/crawl4ai:latest";
      ports = [ "11235:11235" ];
      environment = {
        OPENAI_API_KEY = "$(cat ${config.sops.secrets.openai-api.path})";
        LLM_PROVIDER = "openai/gpt-5-mini";
      };
    };
  };
  services.docling-server = {
    enable = true;
    # host = "127.0.0.1";
    # port = 5001;
  };
  # TODO: not working
  #virtualisation.oci-containers.containers.readerlm = {
  #  image = "rbehzadan/readerlm:latest";
  #  ports = [ "8083:8080" ];
  #};
}
