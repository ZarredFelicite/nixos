{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.arion
  ];
}
