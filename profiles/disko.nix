# Disko configuration for impermanence setup
# Replicates: LUKS + Btrfs subvolumes + tmpfs root + selective persistence
# Based on your current filesystem analysis from data.txt
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";  # Change this to match your target disk
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "500M";
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
                # For initial setup, use passwordFile or interactive password
                # After installation, you can set up TPM2 auto-unlock with:
                # systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
                # The keyFile option is commented out.
                # Disko will prompt for a password interactively.
                # keyFile = "/tmp/secret.key";
                #passwordFile = "/tmp/secret.key";  # Create this file with your password
                settings = {
                  allowDiscards = true;
                  # Optional: add TPM2 support after initial setup
                  # keyFile = "/dev/urandom";
                };
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
                      mountOptions = [ "compress=zstd" "relatime" "ssd"];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "compress=no" "noatime" "ssd"];
                      swap.swapfile.size = "8G";  # Adjust size as needed
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
