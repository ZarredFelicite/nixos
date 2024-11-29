# https://github.com/Lurkki14/tuxclocker

{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "sankara";
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
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
      options = [ "defaults" "compress-force=zstd" "auto" "nofail" ];
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
  swapDevices = [ ];

  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt        *(rw,fsid=0,no_subtree_check)
    /mnt/gargantua   *(rw,fsid=1,nohide,insecure,no_subtree_check)
    /mnt/gargantua/media/music   *(rw,fsid=5,nohide,insecure,no_subtree_check)
    /mnt/ceres   *(rw,fsid=2,nohide,insecure,no_subtree_check)
    /mnt/eros   *(rw,fsid=3,nohide,insecure,no_subtree_check)
    /mnt/turing   *(rw,fsid=4,nohide,insecure,no_subtree_check)
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
        #vaapiVdpau
        #libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };
  };
}
