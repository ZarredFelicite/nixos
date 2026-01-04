{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
    # Window rules for v0.53
    windowrule = float, match:class ^(nova|zoom|xdg-desktop-portal-gtk|steam|org.kde.kdeconnect.daemon)$
    #windowrule = float, match:tag pin
    #windowrule = move 100%-w-10 40, match:tag pin
    #windowrule = size 850 480, match:tag pin
    #windowrule = pin, match:tag pin
    #windowrule = noblur, match:tag pin
    #windowrule = group barred, match:tag pin
    #windowrule = opacity 1.0 override 0.7 override 1.0 override, match:tag pin
    #windowrule = no_initial_focus, match:tag pin
    windowrule = float, match:initial_title Picture-in-Picture|cctv|Syncthing Tray
    windowrule = float, match:title nova
    windowrule = move 100%-w-10 40, match:initial_title Picture-in-Picture|cctv
    windowrule = size 850 480, match:initial_title Picture-in-Picture
    windowrule = size 530 400, match:initial_title cctv
    windowrule = pin, match:initial_title Picture-in-Picture|cctv
    windowrule = noblur, match:initial_title Picture-in-Picture|cctv
    windowrule = group barred, match:initial_title Picture-in-Picture|cctv
    windowrule = opacity 1.0 override 0.7 override 1.0 override, match:initial_title Picture-in-Picture|cctv
    windowrule = no_initial_focus, match:initial_title Picture-in-Picture|cctv
    windowrule = tag +pin, match:initial_title Picture-in-Picture|cctv
    windowrule = size 1200 800, match:class ^(nova)$
    windowrule = size 1200 800, match:title nova
    windowrule = dimaround, match:class ^(nova|obsidian)$
    windowrule = dimaround, match:title nova
    #windowrule = center, match:class ^(nova)$
    #windowrule = pin, match:class ^(nova)$
    #windowrule = stayfocused, match:class ^(nova)$
    #windowrule = animation slidefadevert, match:class ^(waybar|nova)$
    windowrule = rounding 6, match:class ^(waybar)$
    windowrule = center, match:class ^(xdg-desktop-portal-gtk|zenity|Rofi)$
    windowrule = stayfocused, match:class ^(Pinentry)$
    windowrule = stayfocused, match:title ^(Hyprland Polkit Agent)$
    #windowrule = keepaspectratio, match:class ^(mpv)$
    windowrule = noblur, match:class ^(mpv)$ match:float true match:fullscreen false
    windowrule = suppressevent maximize, match:class ^(firefox)$
    windowrule = suppressevent activatefocus, match:class ^(OrcaSlicer)$
    windowrule = pin, match:title ^(ripdrag)$
    windowrule = size 60% 50%, match:title ^(Enter name of file to save to…)$ match:class xdg-desktop-portal-gtk
    windowrule = float, match:title ^(mpd_cover|float)$
    windowrule = size 1000 1000, match:title ^(mpd_cover)$
    windowrule = pseudo, match:class swayimg.*
    windowrule = float, match:class swayimg.*
    windowrule = tile, match:class ^(kdeconnect.sms)$
    windowrule = fullscreenstate -1 2, match:workspace special:browser-tradingview
    windowrule = fullscreenstate -1 2, match:workspace special:browser-chatgpt
    windowrule = fullscreenstate -1 2, match:workspace special:browser-messages
    windowrule = fullscreenstate -1 2, match:workspace special:server

    # Layer rules for v0.53
    layerrule = blur on, match:namespace notifications
    layerrule = above_lock 1, match:namespace notifications
    layerrule = blur on, match:namespace waybar
    layerrule = blur on, match:namespace primary-bar
    layerrule = blur on, match:namespace ignis_bar_0
    layerrule = blur on, match:namespace ignis_bar_1
    layerrule = blur on, match:namespace ignis_bar_2
    layerrule = blur on, match:namespace ignis_bar_3
    layerrule = above_lock 1, match:namespace waybar
    layerrule = above_lock 1, match:namespace primary-bar
    layerrule = above_lock 1, match:namespace ignis_bar_0
    layerrule = above_lock 1, match:namespace ignis_bar_1
    layerrule = above_lock 1, match:namespace ignis_bar_2
    layerrule = above_lock 1, match:namespace ignis_bar_3
    layerrule = blur on, match:namespace rofi
    layerrule = animation popin, match:namespace rofi
    layerrule = blur on, match:namespace wlroots
    layerrule = blur on, match:namespace gtk-layer-shell
    layerrule = blur on, match:namespace anyrun
    layerrule = ignore_alpha 0, match:namespace notifications
    layerrule = ignore_alpha 0, match:namespace waybar
    layerrule = ignore_alpha 0.45, match:namespace primary-bar
    layerrule = ignore_alpha 0, match:namespace ignis_bar_0
    layerrule = ignore_alpha 0, match:namespace ignis_bar_1
    layerrule = ignore_alpha 0, match:namespace ignis_bar_2
    layerrule = ignore_alpha 0, match:namespace ignis_bar_3
    layerrule = ignore_alpha 0.1, match:namespace rofi
    layerrule = ignore_alpha 0, match:namespace wlroots
    layerrule = ignore_alpha 0, match:namespace gtk-layer-shell
    layerrule = ignore_alpha 0, match:namespace anyrun
    layerrule = blur on, match:namespace swaync-control-center
    layerrule = blur on, match:namespace swaync-notification-window
    layerrule = above_lock 1, match:namespace swaync-notification-window
    layerrule = above_lock 1, match:namespace swaync-control-center
    layerrule = ignore_alpha 0, match:namespace swaync-control-center
    layerrule = ignore_alpha 0, match:namespace swaync-notification-window
    layerrule = ignore_alpha 0.25, match:namespace swaync-control-center
    layerrule = ignore_alpha 0.25, match:namespace swaync-notification-window
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
