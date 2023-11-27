{ lib, pkgs, config, ... }:
let
  cfg = config.services.lisgd;
  lisgd = pkgs.lisgd.overrideAttrs (oldAttrs: rec {
    configFile = pkgs.writeText "config.def.h" ''
        /*
           distancethreshold: Minimum cutoff for a gestures to take effect
           degreesleniency: Offset degrees within which gesture is recognized (max=45)
           timeoutms: Maximum duration for a gesture to take place in miliseconds
           orientation: Number of 90 degree turns to shift gestures by
           verbose: 1=enabled, 0=disabled; helpful for debugging
           device: Path to the /dev/ filesystem device events should be read from
           gestures: Array of gestures; binds num of fingers / gesturetypes to commands
           Supported gestures: SwipeLR, SwipeRL, SwipeDU, SwipeUD,
           SwipeDLUR, SwipeURDL, SwipeDRUL, SwipeULDR
         */

        unsigned int distancethreshold = 125;
        unsigned int distancethreshold_pressed = 60;
        unsigned int degreesleniency = 15;
        unsigned int timeoutms = 800;
        unsigned int orientation = 0;
        unsigned int verbose = 1;
        double edgesizeleft = 100.0;
        double edgesizetop = 100.0;
        double edgesizeright = 100.0;
        double edgesizebottom = 100.0;
        char *device = "/dev/input/event18";

        //Gestures can also be specified interactively from the command line using -g
        Gesture gestures[] = {
          /* nfingers  gesturetype  command */
          { 1,         SwipeDU,     EdgeLeft, DistanceAny, ActModePressed, "wpctl set-volume @DEFAULT_SINK@ 0.05+ -l 1.5" },
          { 1,         SwipeUD,     EdgeLeft, DistanceAny, ActModePressed, "wpctl set-volume @DEFAULT_SINK@ 0.05- -l 1.5" },
          { 1,         SwipeDU,     EdgeRight, DistanceAny, ActModePressed, "brillo -A 1 -u 100000" },
          { 1,         SwipeUD,     EdgeRight, DistanceAny, ActModePressed, "brillo -U 1 -u 100000" },
          { 1,         SwipeDU,     EdgeBottom, DistanceAny, ActModeReleased, "pkill -RTMIN wvkbd-mobintl" },
          { 1,         SwipeUD,     EdgeTop, DistanceAny, ActModeReleased, "pkill -RTMIN wvkbd-mobintl" },
          { 1,         SwipeRL,     EdgeRight, DistanceAny, ActModeReleased, "swaync-client -t -sw" },
          { 1,         SwipeLR,     EdgeLeft, DistanceAny, ActModeReleased, "hyprctl dispatch togglespecialworkspace" },
        };
      '';
    postPatch = "${oldAttrs.postPatch}\n cp ${configFile} config.def.h";
  });
in {
  options.services.lisgd.enable = lib.mkEnableOption "lisgd service";
  config = lib.mkIf cfg.enable {
    systemd.user.services.lisgd = {
      description = "lisgd - libinput synthetic gesture daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      path = [
        pkgs.hyprland
        pkgs.wireplumber
        pkgs.libnotify
        pkgs.brillo
        pkgs.procps
        pkgs.swaynotificationcenter
      ];
      serviceConfig = {
        EnvironmentFile = "/tmp/lisgd_rot";
        ExecStart = "${lisgd}/bin/lisgd -v -o \${LISGD_ROT} -d \${LISGD_DEV}";
      };
    };
  };
}
