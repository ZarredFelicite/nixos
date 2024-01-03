{ pkgs, inputs, lib, osConfig, config, ... }:
let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
in {
  imports = [
    #inputs.hyprland.homeManagerModules.default
    ./autoname-workspaces/hyprland-autoname-workspaces.nix
    ./rules.nix
    ./binds.nix
  ];
  stylix.targets.hyprland.enable = false;
  home.packages = [
    inputs.hyprpaper.packages.${pkgs.hostPlatform.system}.hyprpaper
    inputs.hyprlang.packages.${pkgs.hostPlatform.system}.hyprlang
    pkgs.hyprland-autoname-workspaces
    pkgs.pyprland
    #(pkgs.poetry2nix.mkPoetryApplication rec {
    #  pname = "pyprland";
    #  version = "1.4.1";
    #  src = pkgs.python311.fetchPypi {
    #    inherit pname version;
    #    sha256 = "sha256-JRxUn4uibkl9tyOe68YuHuJKwtJS//Pmi16el5gL9n8=";
    #  };
    #})
    #(pkgs.python311.withPackages(ps: with ps; [
    #  (
    #    buildPythonPackage rec {
    #      pname = "pyprland";
    #      version = "1.4.1";
    #      src = fetchPypi {
    #        inherit pname version;
    #        sha256 = "sha256-JRxUn4uibkl9tyOe68YuHuJKwtJS//Pmi16el5gL9n8=";
    #      };
    #      doCheck = false;
    #      dontUseCmakeConfigure = true;
    #      nativeBuildInputs = [
    #        pkgs.poetry
    #        setuptools
    #      ];
    #    }
    #  )
    #]))
  ];
  services.hyprland-autoname-workspaces.enable = false;
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ~/pictures/wallpapers/tarantula_nebula.png
    preload = ~/pictures/wallpapers/nebula1_r.png
    preload = ~/pictures/wallpapers/nebula2_dark.png
    wallpaper = ,~/pictures/wallpapers/tarantula_nebula.png
    wallpaper = eDP-1,~/pictures/wallpapers/tarantula_nebula.png
    wallpaper = DP-2,~/pictures/wallpapers/nebula1_r.png
    wallpaper = DP-3,~/pictures/wallpapers/nebula2_dark.png
    ipc = off
  '';
  systemd.user.services.pyprland = mkHyprlandService {
    Unit.Description = "Pyprland plugins";
    Service = {
      ExecStart = "${pkgs.pyprland}/bin/pypr";
      Restart = "always";
    };
  };
  xdg.configFile."hypr/pyprland.json" = {
    text = builtins.toJSON {
      pyprland.plugins = [ "scratchpads" ];
      scratchpads = {
        kitty = {
          command = "${pkgs.kitty}/bin/kitty --class kitty-scratchpad zsh -c 'tmux new -A -s scratchpad'";
          lazy = true;
          size = "80% 80%";
          position = "40% 10%";
          class = "kitty-scratchpad";
          margin = 50;
        };
        volume = {
          command = "${pkgs.pavucontrol}/bin/pavucontrol";
          lazy = true;
          size = "100% 100%";
          position = "0% 0%";
          class = "pavucontrol";
          margin = 200;
        };
      };
    };
  };
  wayland.windowManager.hyprland = lib.mkMerge [
      (lib.mkIf (osConfig.networking.hostName == "surface") {
        settings.monitor = [
          "eDP-1,preferred,auto,2"
          "eDP-1,addreserved,0,0,0,0"
        ];
        plugins = [
          #inputs.hyprgrass.packages.${pkgs.hostPlatform.system}.default
        ];
      })
      (lib.mkIf (osConfig.networking.hostName == "nano") {
        settings.monitor = [
          "eDP-1,preferred,auto,1"
          "eDP-1,addreserved,1,0,0,0"
        ];
      })
      (lib.mkIf (osConfig.networking.hostName == "web") {
        settings = {
          monitor = [
            #"DP-3,3440x1440@144,0x110,1.25"
            "DP-3,3440x1440@144,0x110,1"
            #"DP-3,addreserved,2,0,0,0"
            #"DP-2,2560x1440@165,2752x0,1.25,transform,3"
            "DP-2,2560x1440@144,3440x0,1,transform,3"
            #"DP-2,addreserved,2,0,0,0"
          ];
          env = [
            "GDK_BACKEND,wayland"
            "QT_QPA_PLATFORM,wayland"
            "SDL_VIDEODRIVER,wayland"
            "CLUTTER_BACKEND,wayland"
            "WLR_NO_HARDWARE_CURSORS,1"
          ];
        };
      })
    {
    package = inputs.hyprland.packages.x86_64-linux.default;
    xwayland.enable = true;
    systemd.enable = true;
    enableNvidiaPatches = false;
    extraConfig = builtins.readFile(./plugins.conf);
    plugins = [
        inputs.hy3.packages.x86_64-linux.hy3
        #inputs.hycov.packages.${pkgs.system}.hycov
        inputs.hyprfocus.packages.${pkgs.system}.hyprfocus
    ];
    settings = {
      exec-once = [
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${inputs.hyprpaper.packages.${pkgs.hostPlatform.system}.hyprpaper}/bin/hyprpaper"
        "${pkgs.kitty}/bin/kitty --class stats --override window_border_width=0 --session ~/scripts/sys/stats"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];
      monitor = [",preferred,auto,1"];
      xwayland.force_zero_scaling = true;
      general = {
        gaps_in = 4;
        gaps_out = 3;
        border_size = 2;
        "col.active_border" = lib.mkForce "rgba(9ccfd899)";
        "col.inactive_border" = lib.mkForce "rgba(31748f99)";
        layout = "hy3";
        no_cursor_warps = false;
        no_focus_fallback = true;
        resize_on_border = true;
      };
      binds = {
        movefocus_cycles_fullscreen = false;
      };
      decoration = {
        rounding = 20;
        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          new_optimizations = true;
          ignore_opacity = true;
        };
        drop_shadow = false;
        #dim_special = 0.0;
      };
      animations = {
       enabled = true;
       bezier = "overshot,0.05,0.9,0.1,1.1";
       animation = [
          "windowsIn, 1, 6, overshot, slide"
          "windowsOut, 1, 6, overshot, slide"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
          "specialWorkspace, 1, 6, overshot"
        ];
      };
      #dwindle = {
      #  pseudotile = true;
      #  force_split = 2;
      #  #smart_split = true;
      #  #smart_resizing = true;
      #  preserve_split = true;
      #  split_width_multiplier = 2.35;
      #  special_scale_factor = 0.95;
      #  no_gaps_when_only = 0;
      #  use_active_for_splits = true;
      #  default_split_ratio = 1;
      #};
      dwindle = {
        pseudotile = true;
        force_split = 2;
        #smart_split = true;
        #smart_resizing = true;
        preserve_split = false;
        split_width_multiplier = 1.0;
        special_scale_factor = 0.90;
        no_gaps_when_only = 0;
        use_active_for_splits = true;
        default_split_ratio = 1.2;
      };
      misc = {
        disable_hyprland_logo = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        focus_on_activate = true;
        layers_hog_keyboard_focus = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
        enable_swallow = false;
        swallow_regex = "^(kitty)$";
        swallow_exception_regex = "^(cava|wev)$";
        vfr = true;
        vrr = true;
      };
      #group = {
      #  groupbar = {
      #    render_titles = false;
      #    font_size = 11;
      #    gradients = false;
      #    "col.active" = lib.mkForce "rgba(9ccfd899)";
      #    "col.inactive" = lib.mkForce "rgba(31748f99)";
      #  };
      #};
      input = {
        kb_layout = "us";
        repeat_rate = 60;
        repeat_delay = 250;
        follow_mouse = 1;
        mouse_refocus = true;
        float_switch_override_focus = 0;
        touchpad = {
          disable_while_typing = true;
          scroll_factor = 0.5;
          drag_lock = true;
          tap-and-drag = true;
          natural_scroll = true;
        };
        sensitivity = 0;
      };
      "device:tpps/2-elan-trackpoint" = {
        sensitivity = -0.25;
        natural_scroll = false;
      };
      "device:elan0670:00-04f3:3150-touchpad" = {
        sensitivity = 0.1;
        natural_scroll = true;
      };
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 4;
        workspace_swipe_distance = 200;
        workspace_swipe_min_speed_to_force = 3;
        workspace_swipe_cancel_ratio = 0.2;
        workspace_swipe_forever = true;
        workspace_swipe_numbered = true;
      };
    };
  }];
}
