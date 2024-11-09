{ ... }: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "center, ^(zenity)$"
      "pin, ^(dragon-drop)$"
      "tile, ^(Vtk)$"
      "workspace special, (special)$"
    ];
    windowrulev2 = [
      "float, class:^(nova|zoom|cctv|xdg-desktop-portal-gtk)$"
      "size 800 500, class:^(nova)$"
      #"center, class:^(nova)$"
      #"pin, class:^(nova)$"
      #"stayfocused, class:^(nova)$"
      #"animation slidefadevert, class:^(waybar|nova)$"
      "rounding 6, class:^(waybar)$"
      "stayfocused, class:^(Rofi)$"
      "center, class:^(Rofi|xdg-desktop-portal-gtk)$"
      "stayfocused, class:^(Pinentry)$"
      #"keepaspectratio, class:^(mpv)$"
      "noblur, class:^(mpv)$,floating:1,fullscreen:0"
      "suppressevent maximize, class:^(firefox)$"
      "pin, title:^(ripdrag)$"
      "size 60% 50%, title:^(Enter name of file to save to…)$|class:xdg-desktop-portal-gtk"
      "float, title:^(mpd_cover)$"
      "size 1000 1000, title:^(mpd_cover)$"
      #"pseudo, class:^(imv)$"
      "tile, class:^(kdeconnect.sms)$"
      "fullscreenstate -1 2, onworkspace:special:browser-tradingview"
      "fullscreenstate -1 2, onworkspace:special:browser-messages"
      "fullscreenstate -1 2, onworkspace:special:server"
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
      "ignorealpha 0.1, rofi"
      "ignorezero, wlroots"
      "ignorezero, gtk-layer-shell"
      "ignorezero, anyrun"
    ];
    workspace = [
      "special:special, on-created-empty:kitty --class stats zsh -c 'btop', gapsout:40, gapsin:40"
      "special:volume, on-created-empty:pavucontrol, gapsout:40, gapsin:40"
      "special:scratchpad, on-created-empty:kitty --class kitty-scratchpad zsh -c 'tmux new -A -s scratchpad', gapsout:40, gapsin:40"
      "special:mail, on-created-empty:~/scripts/hyprland/special_mail.sh, gapsout:40, gapsin:40"
      "special:media, on-created-empty:~/scripts/hyprland/special_media.sh, gapsout:40, gapsin:40"
      "special:finance, on-created-empty:~/scripts/hyprland/special_finance.sh, gapsout:40, gapsin:40"
      "special:server, on-created-empty:~/scripts/hyprland/special_server.sh, gapsout:40, gapsin:40"
      "special:browser-tradingview, on-created-empty:firefox --new-window 'https://www.tradingview.com/chart', gapsout:40"
      "special:browser-messages, on-created-empty:firefox --new-window 'https://messages.google.com/web', gapsout:40"
    ];
  };
}
