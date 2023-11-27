{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
      bind   =  $mod,      C,    submap, workspaces
      submap = workspaces
      bind   =      ,      C, workspace,         previous
      bind   =      ,      N, workspace,       name:music
      bind   =      ,      E, workspace,         name:mpv
      bind   =      ,      I, workspace,       name:stats
      bind   =      ,      S, workspace,      name:stocks
      bind   = SHIFT,      N, movetoworkspace, name:music
      bind   = SHIFT,      E, movetoworkspace,   name:mpv
      bind   = SHIFT,      I, movetoworkspace, name:stats
      bind   = SHIFT,      S, movetoworkspace,name:stocks
      bind   =      , escape,          submap,      reset
      bind   =      ,      R,          submap,      reset
      bind   =      ,      C,          submap,      reset
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
      "$mod, R, exec, ~/scripts/hyprland/resize.sh"
      "$mod, Return, exec, kitty -1"
      #"$mod SHIFT, Return, exec, kitty -1 ssh rehoboam"   -- submap/menu to select ssh targets, term with tmux, etc
      "$mod, N, exec, swaync-client -t -sw"
      "$mod CTRL, N, changegroupactive, b"
      "$mod SHIFT, N, changegroupactive, f"
      "$mod, T, togglegroup,"
      "$mod CTRL, T, lockactivegroup, toggle"
      "$mod, S, exec, ~/scripts/nova/nova_window"
      "$mod, K, killactive,"
      "$mod, Q, exec, hyprctl dispatch dpms off DP-3; hyprctl dispatch dpms off DP-2; swaylock"
      "$mod, H, togglefloating,"
      "$mod, P, exec, ~/scripts/launcher/rofi_programs "
      "$mod CTRL, P, pseudo,"
      "$mod SHIFT, P, exec, ~/scripts/hyprland/hyprpin"
      "$mod, F, exec, firefox"
      "$mod, E, exec, ~/scripts/hyprland/hyprfull"
      "$mod SHIFT, E, fakefullscreen,"
      "$mod, D, togglespecialworkspace,"
      "$mod CTRL, D, movetoworkspace, special"
      "$mod, Y, exec, ~/scripts/hyprland/hypr_focusfloat"
      "$mod CTRL, Y, exec, ~/scripts/hyprland/hypr_opacity.sh"
      " , PRINT, exec, ~/scripts/screencapture/screenshot > /dev/null"

      "$mod CTRL SHIFT, $NAVU, movetoworkspace, r+1"
      "$mod CTRL SHIFT, $NAVD, movetoworkspace, r-1"
      "$mod CTRL SHIFT, $NAVR, workspace, r+1"
      "$mod CTRL SHIFT, $NAVL, workspace, r-1"
      "$mod,            $NAVL, movefocus, l"
      "$mod,            $NAVD, movefocus, d"
      "$mod,            $NAVU, movefocus, u"
      "$mod,            $NAVR, movefocus, r"
      "$mod SHIFT,      $NAVL, swapwindow, l"
      "$mod SHIFT,      $NAVD, swapwindow, d"
      "$mod SHIFT,      $NAVU, swapwindow, u"
      "$mod SHIFT,      $NAVR, swapwindow, r"
      "$mod SHIFT ALT,  $NAVL, movewindoworgroup, l"
      "$mod SHIFT ALT,  $NAVD, movewindoworgroup, d"
      "$mod SHIFT ALT,  $NAVU, movewindoworgroup, u"
      "$mod SHIFT ALT,  $NAVR, movewindoworgroup, r"
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
      # move into submap
      "$mod ALT, $NAVL, exec, ~/scripts/hyprland/moveintogroup.sh l"
      "$mod ALT, $NAVD, exec, ~/scripts/hyprland/moveintogroup.sh d"
      "$mod ALT, $NAVU, exec, ~/scripts/hyprland/moveintogroup.sh u"
      "$mod ALT, $NAVR, exec, ~/scripts/hyprland/moveintogroup.sh r"
      "$mod ALT CTRL, $NAVL, exec, ~/scripts/hyprland/moveoutofgroup.sh l"
      "$mod ALT CTRL, $NAVD, exec, ~/scripts/hyprland/moveoutofgroup.sh d"
      "$mod ALT CTRL, $NAVU, exec, ~/scripts/hyprland/moveoutofgroup.sh u"
      "$mod ALT CTRL, $NAVR, exec, ~/scripts/hyprland/moveoutofgroup.sh r"
      #" , edge:r:l, exec, swaync-client -t -sw"
      #" , edge:l:r, togglespecialworkspace, "
      #" , edge:d:u, exec, pkill -RTMIN wvkbd-mobintl"
      #" , edge:u:d, exec, pkill -RTMIN wvkbd-mobintl"
    ];
    binde = [
      " , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05+ -l 1"
      " , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ 0.05- -l 1"
      " , XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"
      " , XF86MonBrightnessUp, exec, brillo -A 2 -q -u 200000"
      " , XF86MonBrightnessDown, exec, brillo -U 2 -q -u 200000"
      " , XF86AudioRewind, exec, playerctl position 5-"
      " , XF86AudioPrev, exec, playerctl previous"
      " , XF86AudioNext, exec, playerctl next"
      " , XF86AudioForward, exec, playerctl position 5+"
      " , XF86AudioPlay, exec, playerctl play-pause"
      " $mod CTRL, $NAVL, resizeactive, -20 0"
      " $mod CTRL, $NAVD, resizeactive, 0 20"
      " $mod CTRL, $NAVU, resizeactive, 0 -20"
      " $mod CTRL, $NAVR, resizeactive, 20 0"
      #" , edge:r:u, exec, brillo -A 1 -u 100000"
      #" , edge:r:d, exec, brillo -U 1 -u 100000"
      #" , edge:l:u, exec, wpctl set-volume @DEFAULT_SINK@ 0.05+ -l 1.5"
      #" , edge:l:d, exec, wpctl set-volume @DEFAULT_SINK@ 0.05- -l 1.5"
    ];
  };
}
