{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
      bind   =  $mod,      I,    submap, dropdowns
      submap = dropdowns
      bind   =      ,      E, togglespecialworkspace, volume
      bind   =      ,      E, submap, reset
      bind   =      ,      I, togglespecialworkspace, scratchpad
      bind   =      ,      I, submap, reset
      bind   =      ,      O, togglespecialworkspace, finance
      bind   =      ,      O, submap, reset
      bind   =      ,      N, togglespecialworkspace, mail
      bind   =      ,      N, submap, reset
      bind   =      ,      F, togglespecialworkspace, server
      bind   =      ,      F, submap, reset
      bind   =      ,      M, togglespecialworkspace, media
      bind   =      ,      M, submap, reset
      bind   =      ,      C, exec, ~/scripts/hyprland/cctv
      bind   =      ,      C, submap, reset
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
      #"$mod, O, hycov:toggleoverview"
      "$mod, T, togglegroup,"
      #"$mod, T, hy3:makegroup, tab"
      "$mod CTRL, T, lockactivegroup, toggle"
      #"$mod CTRL, T, hy3:changegroup, toggletab"
      #"$mod, U, hy3:makegroup, opposite"
      #"$mod CTRL, U, hy3:changegroup, opposite"
      "$mod, H, togglefloating,"
      "$mod, K, killactive,"
      "$mod CTRL, P, pseudo,"
      "$mod SHIFT, P, exec, ~/scripts/hyprland/hyprpin"
      "$mod, E, exec, ~/scripts/hyprland/hyprfull"
      "$mod SHIFT, E, fullscreenstate, -1 2"
      "$mod, D, togglespecialworkspace, special"
      "$mod, L, exec, ~/scripts/sys/system"
      "$mod CTRL, D, movetoworkspace, special"
      "$mod, Y, exec, ~/scripts/hyprland/hypr_focusfloat"
      "$mod CTRL, Y, exec, ~/scripts/hyprland/hypr_opacity.sh"
      "$mod, R, exec, ~/scripts/hyprland/resize.sh"

      "$mod, Return, exec, kitty -1"
      "$mod, N, exec, makoctl invoke"
      "$mod CTRL, N, exec, makoctl restore"
      "$mod SHIFT, N, exec, makoctl dismiss"
      "$mod, Q, exec, hyprctl dispatch dpms off DP-3; hyprctl dispatch dpms off DP-2; swaylock"
      "$mod, S, exec, ~/scripts/nova/nova_window"
      "$mod, P, exec, ~/scripts/launcher/rofi_programs "
      "$mod, F, exec, firefox"
      " , PRINT, exec, ~/scripts/screencapture/screenshot > /dev/null"

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
      "$mod,                1, workspace, 1"
      "$mod,                2, workspace, 2"
      "$mod,                3, workspace, 3"
      "$mod,                4, workspace, 4"
      "$mod,                5, workspace, 5"
      "$mod,                6, workspace, 6"
      "$mod,                7, workspace, 7"
      "$mod,                8, workspace, 8"
      "$mod,                9, workspace, 9"
      "$mod,                0, workspace, 10"
      "$mod SHIFT,          1, movetoworkspace, 1"
      "$mod SHIFT,          2, movetoworkspace, 2"
      "$mod SHIFT,          3, movetoworkspace, 3"
      "$mod SHIFT,          4, movetoworkspace, 4"
      "$mod SHIFT,          5, movetoworkspace, 5"
      "$mod SHIFT,          6, movetoworkspace, 6"
      "$mod SHIFT,          7, movetoworkspace, 7"
      "$mod SHIFT,          8, movetoworkspace, 8"
      "$mod SHIFT,          9, movetoworkspace, 9"
      "$mod SHIFT,          0, movetoworkspace, 10"
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
      " , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05+ -l 1"
      " , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05- -l 1"
      " , XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
      " , XF86MonBrightnessUp, exec, brillo -L | xargs -P 0 -I {} brillo -A 5 -q -s {} -u 100000 &"
      " , XF86MonBrightnessDown, exec, brillo -L | xargs -P 0 -I {} brillo -U 5 -q -s {} -u 100000 &"
      " , XF86AudioRewind, exec, playerctl position 5-"
      " , XF86AudioPrev, exec, playerctl previous"
      " , XF86AudioNext, exec, playerctl next"
      " , XF86AudioForward, exec, playerctl position 5+"
      " , XF86AudioPlay, exec, playerctl play-pause"
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
  };
}
