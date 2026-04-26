# https://github.com/Lurkki14/tuxclocker

{ config, lib, pkgs, pkgs-unstable, pkgs-quickshell, pkgs-brave-origin, modulesPath, inputs, outputs, self, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs outputs pkgs-unstable pkgs-quickshell pkgs-brave-origin; };
    users.zarred = import ../home/hosts/sankara.nix;
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "sankara";
  boot = {
    kernelPackages = pkgs.linuxPackages;
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
  };
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/B96A-A35F";
      fsType = "vfat";
    };
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "mode=755" ]; # mode=755 so only root can write to those files
      neededForBoot = true;
    };
    "/nix" = {
      device = "/dev/disk/by-uuid/14b9a0cb-c9b2-4721-ad21-b68ec7b8688c";
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
      device = "/dev/disk/by-uuid/14b9a0cb-c9b2-4721-ad21-b68ec7b8688c";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "ssd" "subvol=persist" ];
      neededForBoot = true;
    };
    "/mnt/gargantua" = {
      device = "/dev/disk/by-uuid/30899f26-306a-42d1-b6a8-61d47a2fe5c1";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "auto" ];
    };
    #"/mnt/dagobah" = {
    #  device = "/dev/disk/by-uuid/47b66da6-0d0f-45aa-a43c-63f636496dbe";
    #  fsType = "btrfs";
    #  options = [ "defaults" "compress-force=zstd" "auto" ];
    #};
    "/mnt/eros" = {
      device = "/dev/disk/by-uuid/bf0612f6-780c-410b-b723-b9d3f182cf0e";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "auto" "nofail" ];
    };
    "/mnt/ceres" = {
      device = "/dev/disk/by-uuid/d11573fe-e1e8-4693-a8d7-41245c9a12ac";
      fsType = "btrfs";
      options = [ "defaults" "compress-force=zstd" "auto" "nofail" ];
    };
    "/mnt/turing" = {
      device = "/dev/disk/by-uuid/F454803C54800398";
      fsType = "ntfs";
      options = [ "defaults" "compress-force=zstd" "auto" "nofail" ];
    };
    #"/mnt/gargantua" = {
    #  device = "/mnt/merge-gargantua/nvme1:/mnt/merge-gargantua/sata1:/mnt/merge-gargantua/hdd1";
    #  fsType = "fuse.mergerfs";
    #  options = [
    #    "cache.files=partial"
    #    "dropcacheonclose=true"
    #    "category.create=mfs"
    #    "defaults"
    #  ];
    #  depends = [
    #    "/mnt/merge-gargantua/nvme1"
    #    "/mnt/merge-gargantua/sata1"
    #    "/mnt/merge-gargantua/hdd1"
    #  ];
    #};
  };
  swapDevices = [{
    device = "/persist/swap/swapfile";
    size = 32 * 1024;
  }];

  hardware.bluetooth.enable = true;

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt        *(rw,fsid=0,no_subtree_check)
    /mnt/gargantua   *(rw,fsid=1,nohide,insecure,no_subtree_check)
    /mnt/gargantua/media/music   *(rw,fsid=5,nohide,insecure,no_subtree_check)
    /mnt/ceres   *(rw,fsid=2,nohide,insecure,no_subtree_check)
    /mnt/eros   *(rw,fsid=3,nohide,insecure,no_subtree_check)
    /mnt/turing   *(rw,fsid=4,nohide,insecure,no_subtree_check)
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "agent-nixos-switch-flake" ''
      set -euo pipefail
      exec ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake /home/zarred/dots#sankara
    '')
  ];

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          subject.user == "zarred" &&
          action.lookup("program") == "/run/current-system/sw/bin/agent-nixos-switch-flake") {
        return polkit.Result.YES;
      }
    });
  '';

  powerManagement.cpuFreqGovernor = "performance";
  services.xserver.videoDrivers = ["nvidia"];
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        #intel-media-driver # LIBVA_DRIVER_NAME=iHD
        #vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        #libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };
  };
  systemd.services.parakeet-devenv = {
    description = "Devenv service parakeet";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "zarred";
      Group = "users";
      WorkingDirectory = "/home/zarred/dev/parakeet-transcriber";
      ExecStart = "${pkgs.nix}/bin/nix develop --command 'start'";
      Restart = "on-failure";
    };
  };

  systemd.services.ocr-server = {
    description = "OCR HTTP + MCP server";
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "zarred";
      Group = "users";
      WorkingDirectory = "/home/zarred/dev/ocr";
      ExecStart = "${pkgs.bash}/bin/bash -lc '/home/zarred/dev/ocr/run.sh server.py --host 0.0.0.0 --port 5498'";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
