{ config, lib, pkgs, pkgs-unstable, pkgs-quickshell, pkgs-brave-origin, pkgs-titan-gpu, inputs, self, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./titan/disko.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs pkgs-unstable pkgs-quickshell pkgs-brave-origin;
      outputs = self;
      headless = false;
    };
    users.zarred = import ../home/hosts/nano.nix;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "titan";
  services.syncthing.enable = true;
  # The shared desktop role refreshes the lockfile nightly, but Titan has no
  # private-GitHub credentials until its own authentication is provisioned.
  system.autoUpgrade.enable = lib.mkForce false;
  hardware.enableRedistributableFirmware = true;
  # The SSD generation used older Xe firmware without Panther Lake blobs.
  hardware.firmware = lib.mkForce [ pkgs-titan-gpu.linux-firmware ];

  boot = {
    kernelPackages = pkgs-titan-gpu.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    initrd.systemd.enable = true;
    initrd.systemd.tpm2.enable = true;
    initrd.luks.devices.root.crypttabExtraOpts = [ "tpm2-device=auto" ];
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
    };
    lanzaboote = {
      enable = true;
      # Runtime sbctl keys stay out of the Nix store. profiles/impermanence.nix
      # persists /var/lib under encrypted /persist across Titan's tmpfs root.
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # Disko supplies the tmpfs root/home and the encrypted persistent mounts.
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/home/zarred".neededForBoot = true;

  # Titan decrypts SOPS using its own persisted SSH host key. Its login hash is
  # provisioned separately into encrypted /persist, never into the Nix store.
  users.users.root = {
    hashedPasswordFile = lib.mkForce null;
    hashedPassword = lib.mkForce "!";
  };
  users.users.zarred.hashedPasswordFile = lib.mkForce "/persist/secrets/zarred-password-hash";

  # Do not use Nano's fixed wlan0 or host-specific wired device rules.
  systemd.network.networks."30-wired" = lib.mkForce {
    matchConfig.Name = "en*";
    networkConfig.DHCP = "yes";
  };
  systemd.network.networks."60-wifi" = lib.mkForce {
    matchConfig.Name = "wl*";
    linkConfig.Unmanaged = true;
  };

  # Shared Docker config enables NVIDIA containers on every non-Nano host;
  # Titan's Intel GPU has no NVIDIA driver.
  hardware.nvidia-container-toolkit.enable = lib.mkForce false;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs-titan-gpu.mesa;
    package32 = pkgs-titan-gpu.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [ intel-media-driver libva-vdpau-driver libvdpau-va-gl ];
  };
}
