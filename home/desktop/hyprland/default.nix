{ pkgs, pkgs-unstable, inputs, lib, osConfig, config, ... }:
let
  mkHyprlandService = lib.recursiveUpdate {
    Unit.PartOf = ["hyprland-session.target"];
    Unit.After = ["hyprland-session.target"];
    Install.WantedBy = ["hyprland-session.target"];
  };
  monitor = if osConfig.networking.hostName == "web" then "DP-3" else "eDP-1";
in {
  imports = [
    ./rules.nix
    ./binds.nix
    ./hyprlock.nix
  ];
  stylix.targets.hyprland.enable = false;
  stylix.targets.hyprlock.enable = false;
  home.packages = [
    inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.vigiland.packages.${pkgs.system}.vigiland
  ];
  services.hyprpaper = {
    enable = true;
    package = pkgs-unstable.hyprpaper;
    settings = {
      preload = [
        "~/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg"
        "~/pictures/wallpapers/tarantula_nebula_web_left_darker.png"
        "~/pictures/wallpapers/tarantula_nebula_web_right_darker.png"
      ];
      wallpaper = [
        ",~/pictures/wallpapers/tarantula_nebula_nano.png"
        "eDP-1,~/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg"
        "DP-3,~/pictures/wallpapers/tarantula_nebula_web_left_darker.png"
        "DP-2,~/pictures/wallpapers/tarantula_nebula_web_right_darker.png"
      ];
      ipc = "on";
    };
  };
  systemd.user.services.hyprpolkitagent = mkHyprlandService {
    Unit.Description = "hyprpolkitagent polkit authentication daemon";
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "always";
    };
  };
  wayland.windowManager.hyprland = lib.mkMerge [
      (lib.mkIf (osConfig.networking.hostName == "nano") {
        settings.monitor = [
          "eDP-1,preferred,auto,1"
          "desc:Dell Inc. AW3423DWF 2ZVC2S3,3440x1440@165,auto,1"
          "DP-2,preferred,auto,1,transform,1"
          "DP-3,preferred,auto,1,transform,1"
        ];
      })
      (lib.mkIf (osConfig.networking.hostName == "web") {
        settings = {
          monitor = [
            "DP-3,3440x1440@99.98,0x853,1"
            "DP-2,3440x1440@100.00,3440x0,1,transform,3"
            #"desc:ViewSonic Corporation XG2703-GS,2560x1440@120.0,3440x0,1,transform,3"
            "sunshine,1920x1080,auto,1"
            "HDMI-A-1,1920x1280@60.00,880x0,1.5,transform,2"
            "HDMI-A-2,1920x1280@60.00,2160x0,1.5,transform,2"
            "Unknown-1,disable"
          ];
          env = [
            "GDK_BACKEND,wayland"
            "QT_QPA_PLATFORM,wayland"
          #"SDL_VIDEODRIVER,wayland"
            "CLUTTER_BACKEND,wayland"
            "HYPRCURSOR_THEME,rose-pine-hyprcursor"
            "HYPRCURSOR_SIZE,24"
          ];
        };
      })
    {
    package = pkgs-unstable.hyprland;
    xwayland.enable = true;
    systemd.enable = true;
    plugins = with pkgs-unstable.hyprlandPlugins; [
        hyprspace
        hyprfocus
      # hyprgrass - Hyprland plugin for touch gestures
    ];
    settings = {
      debug.disable_logs = false;
      debug.disable_scale_checks = true;
      debug.suppress_errors = true;
      exec-once = [
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "${pkgs.hyprlock}/bin/hyprlock --immediate --immediate-render"
        "${pkgs.polychromatic}/bin/polychromatic-cli -o none"
        "${pkgs.wayvnc}/bin/wayvnc"
        "${pkgs.trayscale}/bin/trayscale --hide-window"
        "/etc/profiles/per-user/zarred/bin/discord"
      ];
      monitor = [",preferred,auto,1"];
      xwayland.force_zero_scaling = true;
      general = {
        gaps_in = 8;
        gaps_out = 6;
        border_size = 2;
        "col.active_border" = lib.mkForce "rgba(9ccfd899)";
        "col.inactive_border" = lib.mkForce "rgba(31748f99)";
        layout = "dwindle";
        no_focus_fallback = true;
        resize_on_border = true;
        snap = {
          enabled = true;
          window_gap = 100;
          monitor_gap = 100;
          respect_gaps = true;
        };
      };
      decoration = {
        rounding = 20;
        dim_around = 0.5;
        dim_special = 0;
        blur = {
          enabled = true;
          size = 10;
          passes = 3;
          brightness = 0.7;
          special = false;
          popups = true;
          popups_ignorealpha = 0.1;
          new_optimizations = true;
          ignore_opacity = true;
        };
        shadow.enabled = false;
      };
      binds = {
        movefocus_cycles_fullscreen = false;
        hide_special_on_workspace_change = true;
        workspace_center_on = 1;
        scroll_event_delay = 100;
      };
      animations = {
       enabled = true;
       bezier = "overshot,0.1,0.95,0.2,1.05";
       animation = [
          # animation = NAME, ONOFF, SPEED, CURVE [,STYLE]
          "windows, 1, 4, default, slide"
          "layers, 1, 2, default, slide"
          "fade, 1, 5, default"
          "border, 1, 6, default"
          "workspaces, 1, 4, default, slide"
          "specialWorkspace, 1, 4, default, slidevert"
        ];
      };
      input = {
        kb_layout = "us";
        repeat_rate = 60;
        repeat_delay = 250;
        follow_mouse = 1;
        mouse_refocus = true;
        float_switch_override_focus = 0;
        special_fallthrough = true;
        touchpad = {
          disable_while_typing = true;
          scroll_factor = 0.5;
          drag_lock = true;
          tap-and-drag = true;
          natural_scroll = true;
          drag_3fg = 1;
        };
        sensitivity = 0;
      };
      device = {
        name = "tpps/2-elan-trackpoint";
        sensitivity = -0.25;
        natural_scroll = false;
      };
      #  "elan0670:00-04f3:3150-touchpad" = {
      #    sensitivity = 0.1;
      #    natural_scroll = true;
      #  };
      #};
      gestures = {
        workspace_swipe_distance = 200;
        workspace_swipe_min_speed_to_force = 3;
        workspace_swipe_cancel_ratio = 0.2;
        workspace_swipe_forever = true;
      };
      gesture = [
        "4, horizontal, workspace"
        "3, up, mod: SUPER, scale: 1.5, fullscreen"
      ];
      group = {
        insert_after_current = true;
        "col.border_active" = lib.mkForce "rgba(9ccfd899)";
        "col.border_inactive" = lib.mkForce "rgba(31748f99)";
        groupbar = {
          enabled = true;
          height = 6;
          indicator_height = 6;
          render_titles = false;
          gradients = false;
          rounding = 4;
          keep_upper_gap = false;
          "col.active" = lib.mkForce "rgba(9ccfd899)";
          "col.inactive" = lib.mkForce "rgba(31748f99)";
        };
      };
      misc = {
        disable_hyprland_logo = true;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        focus_on_activate = true;
        layers_hog_keyboard_focus = true;
        mouse_move_enables_dpms = false;
        key_press_enables_dpms = true;
        enable_swallow = false;
        swallow_regex = "^(kitty)$";
        swallow_exception_regex = "^(cava|wev)$";
        vfr = true;
        vrr = true;
        new_window_takes_over_fullscreen = 2;
        initial_workspace_tracking = 0; # NOTE: 2 causing new windows to be created on previous workspaces
      };
      opengl.nvidia_anti_flicker = true;
      cursor = {
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
          #no_hardware_cursors = true;
        persistent_warps = true;
        warp_on_change_workspace = true;
          #allow_dumb_copy = true;
      };
      experimental.xx_color_management_v4 = true;
      dwindle = {
        pseudotile = true;
        force_split = 2;
        #smart_split = true;
        #smart_resizing = true;
        preserve_split = false;
        split_width_multiplier = 1.6;
          #special_scale_factor = 0.90;
        use_active_for_splits = true;
        default_split_ratio = 1.2;
      };
      plugin = {
        touch_gestures = {
          sensitivity = 4.0;
          workspace_swipe_fingers = 4;
        };
        hyprfocus = {
          enabled = true;
          focus_animation = "flash";
          animate_floating = true;
          animate_workspacechange = true;
          bezier = [
            "bezIn, 0.5,0.0,1.0,0.5"
            "bezOut, 0.0,0.5,0.5,1.0"
            "overshot, 0.05, 0.9, 0.1, 1.05"
            "smoothOut, 0.36, 0, 0.66, -0.56"
            "smoothIn, 0.25, 1, 0.5, 1"
            "realsmooth, 0.28, 0.29, 0.69, 1.08"
            "easeInOutBack, 0.68, -0.6, 0.32, 1.6"
          ];
          flash = {
            flash_opacity = 0.85;
            in_bezier = "smoothIn";
            in_speed = 0.5;
            out_bezier = "smoothOut";
            out_speed = 1;
          };
        };
        hycov = {
          overview_gappo = 60; # gas width from screem
          overview_gappi = 24; # gas width from clients
          hotarea_size = 10; # hotarea size in bottom left,10x10
          enable_hotarea = 1; # enable mouse cursor hotarea
          swipe_fingers = 3; # finger number of gesture,move any directory
          move_focus_distance = 100; # distance for movefocus,only can use 3 finger to move
          enable_gesture = 0; # enable gesture
          disable_workspace_change = 0; # disable workspace change when in overview mode
          disable_spawn = 0; # disable bind exec when in overview mode
          auto_exit = 1; # enable auto exit when no client in overview
        };
        hy3 = {
          no_gaps_when_only = false;
          node_collapse_policy = 2;
          autotile = {
            enable = false;
            ephemeral_groups = true;
            trigger_width = 800;
            trigger_height = 200;
            workspaces = "all";
          };
          tab_first_window = false;
          tabs = {
            height = 6;
            padding = 4;
            from_top = true;
            rounding = 6;
            render_text = false;
            "col.active" = "0xccc4a7e7";
            "col.urgent" = "0xccff4f4f";
            "col.inactive" = "0xcc31748f";
          };
        };
        # TODO: https://github.com/KZDKM/Hyprspace
        overview = {
            #panelColor = "0x26233a"; # Set color for the panel
            #panelBorderColor = "0xHEXCOLOR"; # Set border color for the panel
            #workspaceActiveBackground = "0xHEXCOLOR"; # Active workspace background color
            #workspaceInactiveBackground = "0xHEXCOLOR"; # Inactive workspace background color
            #workspaceActiveBorder = "0xHEXCOLOR"; # Border color for active workspace
            #workspaceInactiveBorder = "0xHEXCOLOR"; # Border color for inactive workspace
          dragAlpha = 0.7; # Set alpha value for window when dragged in overview (0-1)

          # Layout
          panelHeight = 140; # Height of the panel in pixels
          panelBorderWidth = 10; # Border width of the panel in pixels
          onBottom = false; # Set to true if the panel should be at the bottom
          workspaceMargin = 4; # Margin between workspaces and the panel edges
          reservedArea = 34; # Padding for camera notch (Macbook)
          workspaceBorderSize = 2; # Border size for workspaces
          centerAligned = true; # True for center alignment, false for left alignment
          hideBackgroundLayers = false; # Hide background layers
          hideTopLayers = false; # Hide top layers
          hideOverlayLayers = false; # Hide overlay layers
          hideRealLayers = false; # Hide layers in actual workspace
          drawActiveWorkspace = true; # Draw active workspace as-is in overview
          overrideGaps = false; # Override layout gaps in overview
          gapsIn = 0; # Gaps inside the workspace
          gapsOut = 0; # Gaps outside the workspace
          affectStrut = true; # Push window aside, disabling also disables overrideGaps

          # Animation
          overrideAnimSpeed = 1.2; # Speed of slide-in animation

          # Behaviors
          autoDrag = true; # Always drag window when overview is open
          autoScroll = true; # Scroll on active workspace area switches workspace
          exitOnClick = true; # Exits overview on click without dragging
          switchOnDrop = true; # Switch workspace when window is dropped into it
          exitOnSwitch = true; # Exit overview on switch
          showNewWorkspace = true; # Add new empty workspace at the end
          showEmptyWorkspace = true; # Show empty workspaces between non-empty ones
          showSpecialWorkspace = true; # Show special workspace if any
          disableGestures = false; # Disable gestures
          reverseSwipe = false; # Reverse swipe gesture direction (for macOS style)

          # Touchpad gesture settings
          gestures.workspace_swipe_fingers = 4; # Number of fingers for swipe
          gestures.workspace_swipe_cancel_ratio = 0.5; # Ratio to cancel swipe
          gestures.workspace_swipe_min_speed_to_force = 1000; # Min speed to force switch
        };
      };
    };
  }];
}
