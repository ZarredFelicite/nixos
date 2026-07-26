{ config, lib, pkgs, pkgs-unstable, pkgs-ollama, pkgs-quickshell, pkgs-brave-origin, modulesPath, inputs, outputs, self, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../profiles/fans/fans.nix
    ../modules/docling-server.nix
    ../modules/ember.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs outputs pkgs-unstable pkgs-ollama pkgs-quickshell pkgs-brave-origin;
    };
    users.zarred = import ../home/hosts/web.nix;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  nix.settings.extra-platforms = [ "aarch64-linux" ];
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  #nixpkgs.overlays = [
  #  (final: prev: {
  #    linux-firmware = pkgs-unstable.linux-firmware;
  #  })
  #];
  networking.hostName = "web";
  networking.extraHosts = ''
    149.154.166.110 api.telegram.org
  '';
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
    kernelPackages = pkgs.linuxPackages_7_0;
    kernelPatches = [
      {
        name = "amdgpu-hmm-null-dereference";
        patch = pkgs.fetchpatch {
          url = "https://github.com/torvalds/linux/commit/631849ff5d603841e74f19f4a5e30fe1f7d7cf30.patch";
          hash = "sha256-MlaeGPk0dC+IjUxZSaz2m5IANHlkvt/cKnzKdanpLPw=";
        };
      }
    ];
    # Keep the NVIDIA driver available, but don't eagerly load it during boot;
    # the display is on AMD and NVIDIA can autoload when CUDA/NVML needs it.
    kernelModules = lib.mkForce [
      "atkbd"
      "br_netfilter"
      "bridge"
      "cpufreq_powersave"
      "ddcci_backlight"
      "i2c-dev"
      "i2c-piix4"
      "iwlmvm"
      "iwlwifi"
      "kvm-amd"
      "loop"
      "nct6775"
      "snd-aloop"
      "tun"
      "uinput"
      "v4l2loopback"
      "veth"
      "xt_nat"
    ];
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
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" "usbhid" "iwlwifi" "iwlmvm" ];
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

    SUBSYSTEM=="i2c-dev", ACTION=="add",\
      ATTR{name}=="AMDGPU DM aux hw bus*",\
      TAG+="ddcci",\
      TAG+="systemd",\
      ENV{SYSTEMD_WANTS}+="ddcci@$kernel.service"

    SUBSYSTEM=="i2c-dev", ACTION=="add",\
      ATTR{name}=="AMDGPU DM i2c hw bus*",\
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

  # Prefer systemd-oomd for normal cgroup-aware memory pressure handling.
  # Keep earlyoom as a last-resort fallback when RAM and swap are both nearly exhausted.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    enableSystemSlice = true;
    settings.OOM = {
      DefaultMemoryPressureDurationSec = "20s";
      DefaultMemoryPressureLimit = "60%";
      SwapUsedLimit = "95%";
    };
  };
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 3;
    freeMemKillThreshold = 1;
    freeSwapKillThreshold = 1;
    enableNotifications = true;
  };
  systemd.services.systemd-oomd-notify = {
    description = "Desktop notifications for systemd-oomd actions";
    after = [ "systemd-oomd.service" ];
    wants = [ "systemd-oomd.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.systemd pkgs.libnotify pkgs.gnugrep pkgs.coreutils ];
    serviceConfig = {
      Type = "simple";
      User = "zarred";
      Group = "users";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "DISPLAY=:0"
        "XDG_RUNTIME_DIR=/run/user/${toString config.users.users.zarred.uid}"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString config.users.users.zarred.uid}/bus"
      ];
      ExecStart = pkgs.writeShellScript "systemd-oomd-notify" ''
        journalctl -f -n 0 -u systemd-oomd.service -o short-iso | while IFS= read -r line; do
          if printf '%s\n' "$line" | grep -Eiq 'killed|killing|memory pressure|swap'; then
            notify-send -u critical -a systemd-oomd "systemd-oomd action" "$line"
          fi
        done
      '';
    };
  };

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
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      gsp.enable = false;
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
  systemd.timers.nvidia-oc-delayed = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      Unit = "nvidia-oc.service";
    };
  };

  systemd.services.nvidia-oc = {
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

        try:
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
        except NVMLError as e:
            # Avoid failing full system activation during driver transitions.
            print(f"nvidia-oc skipped: {e}")
      '';
    };
  };
  virtualisation.oci-containers.containers = {
    kokoro = {
      image = "ghcr.io/remsky/kokoro-fastapi-gpu:v0.1.5-pre";
      ports = [ "8880:8880" ];
      autoStart = false;
    };
  };
  systemd.timers.kokoro-delayed-start = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      Unit = "podman-kokoro.service";
    };
  };
  services.docling-server = {
    enable = true;
    # host = "127.0.0.1";
    # port = 5001;
  };
  services.ember = {
    enable = true;
  };

  systemd.services.tmuxy = {
    description = "Tmuxy web UI for zarred's tmux sessions";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bash pkgs.coreutils pkgs.tmux pkgs.openssl ];
    serviceConfig = {
      Type = "simple";
      User = "zarred";
      Group = "users";
      WorkingDirectory = "/home/zarred/dev/tmuxy";
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1000"
        "TMUX_TMPDIR=/run/user/1000"
      ];
      ExecStart = "/home/zarred/dev/tmuxy/target/release/tmuxy-server --host 0.0.0.0 --port 9010";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # TODO: not working
  #virtualisation.oci-containers.containers.readerlm = {
  #  image = "rbehzadan/readerlm:latest";
  #  ports = [ "8083:8080" ];
  #};
}
