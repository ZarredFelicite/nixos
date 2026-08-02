{ config, lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  # ROCK 4C+ boots U-Boot from raw Rockchip offsets rather than the FAT
  # partition used by Raspberry Pi firmware.
  image.baseName = "rock4c-plus-nixos";

  sdImage = {
    compressImage = true;
    firmwarePartitionOffset = 32;
    firmwareSize = 64;
    populateFirmwareCommands = "";
    postBuildCommands = ''
      dd conv=notrunc,fsync if=${config.hardware.rockchip.platformFirmware}/idbloader.img of=$img bs=512 seek=64
      dd conv=notrunc,fsync if=${config.hardware.rockchip.platformFirmware}/u-boot.itb of=$img bs=512 seek=16384
    '';
  };

  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];
}
