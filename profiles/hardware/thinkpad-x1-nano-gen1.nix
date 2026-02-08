{ config, lib, pkgs, ... }:

{
  # Localized replacement for nixos-hardware lenovo-thinkpad-x1-nano-gen1,
  # intentionally excluding systemd.services.x1-fix.

  # From common/pc/default.nix
  boot.blacklistedKernelModules = lib.optionals (!config.hardware.enableRedistributableFirmware) [
    "ath3k"
  ];

  # From common/pc/ssd/default.nix
  services.fstrim.enable = lib.mkDefault true;

  # From common/pc/laptop/default.nix
  services.tlp.enable = lib.mkDefault (!config.services.power-profiles-daemon.enable);

  # From lenovo/thinkpad/default.nix
  hardware.trackpoint.enable = lib.mkDefault true;
  hardware.trackpoint.emulateWheel = lib.mkDefault config.hardware.trackpoint.enable;

  # From common/cpu/intel/cpu-only.nix
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # From lenovo/thinkpad/x1-nano/gen1/default.nix (excluding x1-fix service)
  environment.systemPackages = with pkgs; [
    alsa-utils
  ];
}
