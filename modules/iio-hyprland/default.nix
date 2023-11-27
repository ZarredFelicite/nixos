{ lib, pkgs, config, ... }:
let
  cfg = config.services.iio-hyprland;
  iio-hyprland = pkgs.stdenv.mkDerivation {
    name = "iio-hyprland";
    nativeBuildInputs = with pkgs; [ iio-sensor-proxy pkg-config ];
    buildInputs = with pkgs; [ meson ninja cmake dbus ];
    src = ./.;
  };
in {
  options.services.iio-hyprland.enable = lib.mkEnableOption "iio-hyprland service";
  config = lib.mkIf cfg.enable {
    systemd.user.services.iio-hyprland = {
      description = "iio-hyprland - Listens to iio-sensor-proxy and automatically changes Hyprland output orientation";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      path = [ pkgs.hyprland pkgs.gawk ];
      script = "${iio-hyprland}/bin/iio-hyprland";
    };
  };
}

