{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
    # Window rules for v0.53
    windowrule = match:class ^(nova|zoom|xdg-desktop-portal-gtk|steam|org.kde.kdeconnect.daemon)$, float on
    #windowrule = match:tag pin, float on
    #windowrule = match:tag pin, move 100%-w-10 40
    #windowrule = match:tag pin, size 850 480
    #windowrule = match:tag pin, pin on
    #windowrule = match:tag pin, no_blur on
    #windowrule = match:tag pin, group barred
    #windowrule = match:tag pin, opacity 1.0 override 0.7 override 1.0 override
    #windowrule = match:tag pin, no_initial_focus on
    windowrule = match:initial_title Picture-in-Picture|cctv|Syncthing Tray, float on
    windowrule = match:title nova, float on
    windowrule = match:initial_title Picture-in-Picture|cctv, move 100%-w-10 40
    windowrule = match:initial_title Picture-in-Picture, size 850 480
    windowrule = match:initial_title cctv, size 530 400
    windowrule = match:initial_title Picture-in-Picture|cctv, pin on
    windowrule = match:initial_title Picture-in-Picture|cctv, no_blur on
    windowrule = match:initial_title Picture-in-Picture|cctv, group barred
    windowrule = match:initial_title Picture-in-Picture|cctv, opacity 1.0 override 0.7 override 1.0 override
    windowrule = match:initial_title Picture-in-Picture|cctv, no_initial_focus on
    windowrule = match:initial_title Picture-in-Picture|cctv, tag +pin
    windowrule = match:class ^(nova)$, size 1200 800
    windowrule = match:title nova, size 1200 800
    windowrule = match:class ^(nova|obsidian)$, dimaround on
    windowrule = match:title nova, dimaround on
    #windowrule = match:class ^(nova)$, center on
    #windowrule = match:class ^(nova)$, pin on
    #windowrule = match:class ^(nova)$, stay_focused on
    #windowrule = match:class ^(waybar|nova)$, animation slidefadevert
    windowrule = match:class ^(waybar)$, rounding 6
    windowrule = match:class ^(xdg-desktop-portal-gtk|zenity|Rofi)$, center on
    windowrule = match:class ^(Pinentry)$, stay_focused on
    windowrule = match:title ^(Hyprland Polkit Agent)$, stay_focused on
    #windowrule = match:class ^(mpv)$, keepaspectratio on
    windowrule = match:class ^(mpv)$, match:float true, match:fullscreen false, no_blur on
    windowrule = match:class ^(firefox)$, suppress_event maximize
    windowrule = match:class ^(OrcaSlicer)$, suppress_event activatefocus
    windowrule = match:title ^(ripdrag)$, pin on
    windowrule = match:title ^(Enter name of file to save to…)$, match:class xdg-desktop-portal-gtk, size 60% 50%
    windowrule = match:title ^(mpd_cover|float)$, float on
    windowrule = match:title ^(mpd_cover)$, size 1000 1000
    windowrule = match:class swayimg.*, pseudo on
    windowrule = match:class swayimg.*, float on
    windowrule = match:class ^(kdeconnect.sms)$, tile on
    windowrule = match:workspace special:browser-tradingview, fullscreen_state -1 2
    windowrule = match:workspace special:browser-chatgpt, fullscreen_state -1 2
    windowrule = match:workspace special:browser-messages, fullscreen_state -1 2
    windowrule = match:workspace special:server, fullscreen_state -1 2

    # Layer rules for v0.53
    layerrule = match:namespace notifications, blur on
    layerrule = match:namespace notifications, above_lock 1
    layerrule = match:namespace waybar, blur on
    layerrule = match:namespace primary-bar, blur on
    layerrule = match:namespace ignis_bar_0, blur on
    layerrule = match:namespace ignis_bar_1, blur on
    layerrule = match:namespace ignis_bar_2, blur on
    layerrule = match:namespace ignis_bar_3, blur on
    layerrule = match:namespace waybar, above_lock 1
    layerrule = match:namespace primary-bar, above_lock 1
    layerrule = match:namespace ignis_bar_0, above_lock 1
    layerrule = match:namespace ignis_bar_1, above_lock 1
    layerrule = match:namespace ignis_bar_2, above_lock 1
    layerrule = match:namespace ignis_bar_3, above_lock 1
    layerrule = match:namespace rofi, blur on
    layerrule = match:namespace rofi, animation popin
    layerrule = match:namespace wlroots, blur on
    layerrule = match:namespace gtk-layer-shell, blur on
    layerrule = match:namespace anyrun, blur on
    layerrule = match:namespace notifications, ignore_alpha 0
    layerrule = match:namespace waybar, ignore_alpha 0
    layerrule = match:namespace primary-bar, ignore_alpha 0.45
    layerrule = match:namespace ignis_bar_0, ignore_alpha 0
    layerrule = match:namespace ignis_bar_1, ignore_alpha 0
    layerrule = match:namespace ignis_bar_2, ignore_alpha 0
    layerrule = match:namespace ignis_bar_3, ignore_alpha 0
    layerrule = match:namespace rofi, ignore_alpha 0.1
    layerrule = match:namespace wlroots, ignore_alpha 0
    layerrule = match:namespace gtk-layer-shell, ignore_alpha 0
    layerrule = match:namespace anyrun, ignore_alpha 0
    layerrule = match:namespace swaync-control-center, blur on
    layerrule = match:namespace swaync-notification-window, blur on
    layerrule = match:namespace swaync-notification-window, above_lock 1
    layerrule = match:namespace swaync-control-center, above_lock 1
    layerrule = match:namespace swaync-control-center, ignore_alpha 0
    layerrule = match:namespace swaync-notification-window, ignore_alpha 0
    layerrule = match:namespace swaync-control-center, ignore_alpha 0.25
    layerrule = match:namespace swaync-notification-window, ignore_alpha 0.25
  '';
  wayland.windowManager.hyprland.settings = {
    workspace = [
      "1, monitor:DP-3, default:true"
      "5, monitor:DP-2, default:true"
      "special:obsidian, on-created-empty:obsidian, gapsout:40, gapsin:40"
      "special:stats, on-created-empty:kitty --class stats zsh -c 'btop', gapsout:40, gapsin:40"
      "special:volume, on-created-empty:pavucontrol, gapsout:40, gapsin:40"
      "special:scratchpad, on-created-empty:kitty --class kitty-scratchpad zsh -c 'tmux new -A -s scratchpad', gapsout:40, gapsin:40"
      "special:mail, on-created-empty:~/scripts/hyprland/special_mail.sh, gapsout:40, gapsin:40"
      "special:media, on-created-empty:~/scripts/hyprland/special_media.sh, gapsout:40, gapsin:40"
      #"special:music, on-created-empty:spotify & kitty zsh -c 'cava', gapsout:80, gapsin:80"
      "special:music, on-created-empty:spotify, gapsout:80, gapsin:80"
      "special:finance, on-created-empty:~/scripts/hyprland/special_finance.sh, gapsout:40, gapsin:40"
      "special:server, on-created-empty:~/scripts/hyprland/special_server.sh, gapsout:40, gapsin:40"
      "special:cameras, on-created-empty:~/scripts/hyprland/cctv, gapsout:40"
      "special:browser-tradingview, on-created-empty:firefox --new-window 'https://www.tradingview.com/chart', gapsout:40"
      "special:browser-chatgpt, on-created-empty:firefox --new-window 'https://chatgpt.com', gapsout:20"
      "special:browser-messages, on-created-empty:firefox --new-window 'https://messages.google.com/web', gapsout:40"
    ];
  };
}
