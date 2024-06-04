{ ... }: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "center, ^(zenity)$"
      "pin, ^(dragon-drop)$"
      "tile, ^(Vtk)$"
      "workspace special, (special)$"
    ];
    windowrulev2 = [
      "float, class:^(nova|zoom|cctv)$"
      "size 800 500, class:^(nova)$"
      "center, class:^(nova)$"
      "pin, class:^(nova)$"
      "stayfocused, class:^(nova)$"
      "animation slidefadevert, class:^(waybar|nova)$"
      "rounding 6, class:^(waybar)$"
      "stayfocused, class:^(rofi)$"
      "stayfocused, class:^(Pinentry)$"
      "keepaspectratio, class:^(mpv)$"
      "noblur, class:^(mpv)$,floating:1,fullscreen:0"
      "fakefullscreen, class:^(firefox)$"
      "noborder, class:^(firefox)$"
      "pin, title:^(ripdrag)$"
      "size 60% 50%, title:^(Enter name of file to save to…)$|class:xdg-desktop-portal-gtk"
      "float, title:^(mpd_cover)$"
      "size 1000 1000, title:^(mpd_cover)$"
      #"pseudo, class:^(imv)$"
      "tile, class:^(kdeconnect.sms)$"
    ];
    layerrule = [
      "blur, notifications"
      "blur, swaync-control-center"
      "blur, swaync-notification-window"
      "blur, waybar"
      "blur, rofi"
      "blur, wlroots"
      "blur, gtk-layer-shell"
      "blur, anyrun"
      "ignorezero, swaync-control-center"
      "ignorezero, notifications"
      "ignorezero, swaync-notification-window"
      "ignorezero, waybar"
      "ignorezero, rofi"
      "ignorezero, wlroots"
      "ignorezero, gtk-layer-shell"
      "ignorezero, anyrun"
    ];
    workspace = [
      "special, on-created-empty:kitty --class stats --override window_border_width=0 --session ~/scripts/sys/stats"
      "special:volume, on-created-empty:pavucontrol"
      "special:scratchpad, on-created-empty:kitty --class kitty-scratchpad zsh -c 'tmux new -A -s scratchpad'"
      "special:mail, on-created-empty:~/scripts/hyprland/special_mail.sh"
      "special:media, on-created-empty:~/scripts/hyprland/special_media.sh"
      "special:finance, on-created-empty:~/scripts/hyprland/special_finance.sh"
      "special:server, on-created-empty:~/scripts/hyprland/special_server.sh"
    ];
  };
}
