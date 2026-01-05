{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
      bind   =  $mod,      I,    submap, dropdowns
      submap = dropdowns
      bind   =      ,      $NAVL, exec, ~/scripts/bar/move_widget_cursor.sh l
      bind   =      ,      $NAVR, exec, ~/scripts/bar/move_widget_cursor.sh r
      bind   =      ,      E, exec, ~/scripts/hyprland/toggle_special.sh volume
      bind   =      ,      E, submap, reset
      bind   =      ,      S, exec, ~/scripts/hyprland/toggle_special.sh scratchpad
      bind   =      ,      S, submap, reset
      bind   =      ,      O, exec, ~/scripts/hyprland/toggle_special.sh finance
      bind   =      ,      O, submap, reset
      bind   =      ,      N, exec, ~/scripts/hyprland/toggle_special.sh mail
      bind   =      ,      N, submap, reset
      bind   =      ,      F, exec, ~/scripts/hyprland/toggle_special.sh server
      bind   =      ,      F, submap, reset
      bind   =      ,      M, exec, ~/scripts/hyprland/toggle_special.sh media
      bind   =      ,      M, submap, reset
      bind   =      ,      C, exec, ~/scripts/hyprland/toggle_special.sh cameras
      bind   =      ,      C, submap, reset
      bind   =      ,      I, submap, browser
      bind   =      , escape, submap, reset
      submap = reset
      submap = browser
      bind   =      ,      T, exec, ~/scripts/hyprland/toggle_special.sh browser-tradingview
      bind   =      ,      T, submap, reset
      bind   =      ,      G, exec, ~/scripts/hyprland/toggle_special.sh browser-chatgpt
      bind   =      ,      G, submap, reset
      #bind   =      ,      M, exec, ~/scripts/hyprland/toggle_special.sh browser-messages
      #bind   =      ,      M, submap, reset
      bind   =      , escape, submap, reset
      submap = reset
  '';
  wayland.windowManager.hyprland.settings = {
    binds = {
      scroll_event_delay = 100;
    };
    "$mod" = "SUPER";
    "$NAVL" = "Left";
    "$NAVD" = "Down";
    "$NAVU" = "Up";
    "$NAVR" = "Right";
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
    bind = [
      #"$mod CTRL, O, overview:toggle, all" # Dispatcher doesn't exist in v0.53
      "$mod CTRL SHIFT, O, exec, ~/scripts/hyprland/hide_window.sh obsidian 'home - Obsidian' special"
      "$mod, T, togglegroup,"
      #"$mod, T, hy3:makegroup, tab"
      "$mod CTRL, T, lockactivegroup, toggle"
      #"$mod CTRL, T, hy3:changegroup, toggletab"
      #"$mod, U, hy3:makegroup, opposite"
      #"$mod CTRL, U, hy3:changegroup, opposite"
      "$mod, H, togglefloating,"
      "$mod, K, killactive,"
      #"$mod, X, hyprexpo:expo, toggle"
      "$mod CTRL, P, pseudo,"
      "$mod SHIFT, P, exec, ~/scripts/hyprland/hyprpin"
      "$mod, E, exec, ~/scripts/hyprland/hyprfull"
      "$mod, W, exec, ~/scripts/hyprland/hyprwindow"
      "$mod SHIFT, E, fullscreenstate, -1 2"
      "$mod CTRL, E, fullscreenstate, 2 -1"
      "$mod, D, exec, ~/scripts/hyprland/toggle_special.sh stats"
      "$mod, M, exec, ~/scripts/hyprland/toggle_special.sh music"
      "$mod, A, exec, ~/scripts/hyprland/toggle_special.sh reset"
      "$mod, O, exec, ~/scripts/hyprland/toggle_special.sh obsidian"
      "$mod, G, exec, ~/scripts/hyprland/hide_window.sh firefox ChatGPT browser-chatgpt"
      "$mod, L, exec, ~/scripts/sys/system rofi"
      "$mod, C, exec, pkill 'rofi' || rofi -show calc"
      "$mod SHIFT, C, centerwindow"
      "$mod CTRL, D, movetoworkspace, special"
      "$mod, Y, exec, ~/scripts/hyprland/hypr_focusfloat"
      "$mod CTRL, Y, exec, ~/scripts/hyprland/hypr_opacity.sh"
      "$mod, R, exec, ~/scripts/stt/record2.sh --type"
      #"$mod, R, exec, ~/scripts/hyprland/resize.sh"

      "$mod CTRL, Return, exec, ghostty"
      "$mod, Return, exec, kitty -1"
      #"$mod, N, exec, makoctl invoke"
      "$mod, N, exec, swaync-client --toggle-panel"
      #"$mod CTRL, N, exec, makoctl restore"
      "$mod CTRL, N, exec, swaync-client --hide-latest"
      #"$mod SHIFT, N, exec, makoctl dismiss"
      "$mod SHIFT, N, exec, swaync-client --close-latest"
      "$mod, Q, exec, loginctl lock-session"
      "$mod, S, exec, ~/scripts/nova/nova_window"
      "$mod SHIFT, S, exec, ~/scripts/screencapture/screenshot rofi 2&> /tmp/screenshot_log"
      "$mod, P, exec, ~/scripts/launcher/rofi_programs rofi"
      "$mod, F, exec, firefox"
      " , PRINT, exec, ~/scripts/screencapture/screenshot rofi > /tmp/screenshot_log"

      "$mod CTRL SHIFT, $NAVU, movetoworkspace, r+1"
      "$mod CTRL SHIFT, $NAVD, movetoworkspace, r-1"
      "$mod CTRL SHIFT, $NAVR, workspace, r+1"
      "$mod CTRL SHIFT, $NAVL, workspace, r-1"
      "$mod,            $NAVL, movefocus, l"
      "$mod,            $NAVD, movefocus, d"
      "$mod,            $NAVU, movefocus, u"
      "$mod,            $NAVR, movefocus, r"
      "$mod,            Page_Up, changegroupactive, f"
      "$mod,            Page_Down, changegroupactive, b"
      #"$mod,            $NAVL, exec, ~/scripts/hyprland/navigation/hy3-movefocus focus l"
      #"$mod,            $NAVD, exec, ~/scripts/hyprland/navigation/hy3-movefocus focus d"
      #"$mod,            $NAVU, exec, ~/scripts/hyprland/navigation/hy3-movefocus focus u"
      #"$mod,            $NAVR, exec, ~/scripts/hyprland/navigation/hy3-movefocus focus r"
      "$mod SHIFT,      $NAVL, swapwindow, l"
      "$mod SHIFT,      $NAVD, swapwindow, d"
      "$mod SHIFT,      $NAVU, swapwindow, u"
      "$mod SHIFT,      $NAVR, swapwindow, r"
      #"$mod SHIFT,      $NAVL, exec, ~/scripts/hyprland/navigation/hy3-movefocus move l"
      #"$mod SHIFT,      $NAVD, exec, ~/scripts/hyprland/navigation/hy3-movefocus move d"
      #"$mod SHIFT,      $NAVU, exec, ~/scripts/hyprland/navigation/hy3-movefocus move u"
      #"$mod SHIFT,      $NAVR, exec, ~/scripts/hyprland/navigation/hy3-movefocus move r"
      "$mod ALT,  $NAVL, movewindoworgroup, l"
      "$mod ALT,  $NAVD, movewindoworgroup, d"
      "$mod ALT,  $NAVU, movewindoworgroup, u"
      "$mod ALT,  $NAVR, movewindoworgroup, r"
      " , mouse:275, workspace, r-1"
      " , mouse:276, workspace, r+1"
      # move into submap
      #"$mod ALT, $NAVL, exec, ~/scripts/hyprland/moveintogroup.sh l"
      #"$mod ALT, $NAVD, exec, ~/scripts/hyprland/moveintogroup.sh d"
      #"$mod ALT, $NAVU, exec, ~/scripts/hyprland/moveintogroup.sh u"
      #"$mod ALT, $NAVR, exec, ~/scripts/hyprland/moveintogroup.sh r"
      #"$mod ALT CTRL, $NAVL, exec, ~/scripts/hyprland/moveoutofgroup.sh l"
      #"$mod ALT CTRL, $NAVD, exec, ~/scripts/hyprland/moveoutofgroup.sh d"
      #"$mod ALT CTRL, $NAVU, exec, ~/scripts/hyprland/moveoutofgroup.sh u"
      #"$mod ALT CTRL, $NAVR, exec, ~/scripts/hyprland/moveoutofgroup.sh r"
      #" , edge:r:l, exec, swaync-client -t -sw"
      #" , edge:l:r, togglespecialworkspace, "
      #" , edge:d:u, exec, pkill -RTMIN wvkbd-mobintl"
      #" , edge:u:d, exec, pkill -RTMIN wvkbd-mobintl"
    ];
    binde = [
      " , XF86AudioRaiseVolume, exec, /home/zarred/scripts/sys/volume.sh +"
      " , XF86AudioLowerVolume, exec, /home/zarred/scripts/sys/volume.sh -"
      " , XF86AudioMute, exec, /home/zarred/scripts/sys/volume.sh mute"
      " , XF86MonBrightnessUp, exec, /home/zarred/scripts/waybar/brightness.sh --increase"
      " , XF86MonBrightnessDown, exec, /home/zarred/scripts/waybar/brightness.sh --decrease"
      " , XF86AudioRewind, exec, /home/zarred/scripts/sys/media-select position -5"
      " , XF86AudioPrev, exec, /home/zarred/scripts/sys/media-select previous"
      " , XF86AudioNext, exec, /home/zarred/scripts/sys/media-select next"
      " , XF86AudioForward, exec, /home/zarred/scripts/sys/media-select position +5"
      " , XF86AudioPlay, exec, /home/zarred/scripts/sys/media-select"
      " $mod CTRL, $NAVL, resizeactive, -20 0"
      " $mod CTRL, $NAVD, resizeactive, 0 20"
      " $mod CTRL, $NAVU, resizeactive, 0 -20"
      " $mod CTRL, $NAVR, resizeactive, 20 0"
      "$mod CTRL, Next, exec, ~/scripts/hyprland/hyprzoom decrease"
      "$mod CTRL, Prior, exec, ~/scripts/hyprland/hyprzoom increase"
      #" , edge:r:u, exec, brillo -A 1 -u 100000"
      #" , edge:r:d, exec, brillo -U 1 -u 100000"
      #" , edge:l:u, exec, wpctl set-volume @DEFAULT_SINK@ 0.05+ -l 1.5"
      #" , edge:l:d, exec, wpctl set-volume @DEFAULT_SINK@ 0.05- -l 1.5"
    ];
    #bindl = [
    #  " , switch:on:[Lid Switch], exec, systemctl suspend"
    #];
  };
}
