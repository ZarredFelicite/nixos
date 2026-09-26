# Replace this placeholder with a reviewed /dev/disk/by-id/... SSD path only
# after identifying Titan's physical target disk. Until then evaluation of any
# installer disk device or system build must fail closed.
{ ... }: {
  disko.devices.disk.main.device = throw "Titan target SSD not verified: replace hosts/titan/target-disk.nix with a reviewed /dev/disk/by-id path before building or running disko";
}
