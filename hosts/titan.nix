{ config, lib, pkgs, pkgs-unstable, pkgs-quickshell, pkgs-brave-origin, pkgs-titan-gpu, inputs, self, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./titan/disko.nix
    ./titan/gpg-ssh.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs pkgs-unstable pkgs-quickshell pkgs-brave-origin;
      outputs = self;
      headless = false;
    };
    users.zarred = {
      imports = [ ../home/hosts/nano.nix ];
      services.hypridle.settings.general.on_lock_cmd =
        "${pkgs.gnupg}/bin/gpg-connect-agent --no-autostart reloadagent /bye >/dev/null";
      # Override the shared Titan VRR-off baseline only after the DC-balance
      # patch restored 120Hz animation with genuine VRR on this panel.
      wayland.windowManager.hyprland.settings = {
        monitor = lib.mkOverride 40 [ "eDP-1,2880x1920@120,auto,1.5,vrr,1" ];
        misc.vrr = lib.mkOverride 40 true;
      };
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "titan";
  services.syncthing.enable = true;
  # XHCI immediately wakes s2idle; leave USB operational but disallow USB wake.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:00:14.0", ATTR{vendor}=="0x8086", ATTR{device}=="0xe47d", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';
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
    loader.efi.canTouchEfiVariables = lib.mkForce false;
    kernelPatches = lib.mkAfter [
      {
        # Keep the evaluated patch identity to reuse the tested kernel build.
        name = "vrr-dc-balance-off-test";
        patch = ./titan/vrr-dc-balance-off.patch;
      }
    ];
  };

  # Safe fallback: the original kernel, fixed 120Hz, and VRR disabled.
  specialisation."stock-kernel".configuration = {
    boot.kernelPatches = lib.mkForce [ ];
    home-manager.users.zarred.wayland.windowManager.hyprland.settings = {
      monitor = lib.mkOverride 30 [ "eDP-1,2880x1920@120,auto,1.5,vrr,0" ];
      misc.vrr = lib.mkOverride 30 false;
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

  # The Web↔Titan cable is a dedicated static-only link. Matching this exact
  # adapter earlier than 30-wired keeps other en* adapters on DHCP and avoids
  # a default route, DNS, or link-local address on the direct link. Static-only
  # is intentional: if this adapter is reused elsewhere it must not acquire a
  # potentially conflicting DHCP configuration.
  systemd.network.networks."10-direct-link" = lib.mkForce {
    matchConfig.Name = "enp0s13f0u2u4u5";
    networkConfig = {
      Address = "192.168.86.219/24";
      DHCP = "no";
      LinkLocalAddressing = "no";
    };
    linkConfig.RequiredForOnline = "no";
  };
  # IWD configures Wi-Fi; networkd has no managed link on Wi-Fi-only boots.
  # Its shared unlimited wait would block network-online and the NFS mounts.
  systemd.network.wait-online.enable = lib.mkForce false;

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
