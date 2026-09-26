{ ... }: {
  # Standalone Disko and NixOS must evaluate the same reviewed target device.
  imports = [ ./target-disk.nix ];

  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [ "mode=755" ];
    };
    "/home/zarred" = {
      fsType = "tmpfs";
      mountOptions = [ "mode=0700" "uid=1000" "gid=100" ];
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    # Device is supplied by target-disk.nix only after verifying the actual SSD.
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "root";
            # Interactive LUKS2 passphrase; no keyFile or passwordFile.
            extraFormatArgs = [ "--type" "luks2" ];
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress-force=zstd:5" "noatime" "ssd" ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd" "relatime" "lazytime" "ssd" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
