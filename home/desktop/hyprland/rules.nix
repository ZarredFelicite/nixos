{ ... }: {
  wayland.windowManager.hyprland.extraConfig = ''
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
    windowrule = [
      "float, match:class ^(nova|zoom|xdg-desktop-portal-gtk|steam|org.kde.kdeconnect.daemon)$"
      #"float, match:tag pin"
      #"move 100%-w-10 40, match:tag pin"
      #"size 850 480, match:tag pin"
      #"pin, match:tag pin"
      #"noblur, match:tag pin"
      #"group barred, match:tag pin"
      #"opacity 1.0 override 0.7 override 1.0 override, match:tag pin"
      #"no_initial_focus, match:tag pin"
      "float, match:initial_title Picture-in-Picture|cctv|Syncthing Tray"
      "float, match:title nova"
      "move 100%-w-10 40, match:initial_title Picture-in-Picture|cctv"
      "size 850 480, match:initial_title Picture-in-Picture"
      "size 530 400, match:initial_title cctv"
      "pin, match:initial_title Picture-in-Picture|cctv"
      "noblur, match:initial_title Picture-in-Picture|cctv"
      "group barred, match:initial_title Picture-in-Picture|cctv"
      "opacity 1.0 override 0.7 override 1.0 override, match:initial_title Picture-in-Picture|cctv"
      "no_initial_focus, match:initial_title Picture-in-Picture|cctv"
      "tag +pin, match:initial_title Picture-in-Picture|cctv"
      "size 1200 800, match:class ^(nova)$"
      "size 1200 800, match:title nova"
      "dimaround, match:class ^(nova|obsidian)$"
      "dimaround, match:title nova"
      #"center, match:class ^(nova)$"
      #"pin, match:class ^(nova)$"
      #"stayfocused, match:class ^(nova)$"
      #"animation slidefadevert, match:class ^(waybar|nova)$"
      "rounding 6, match:class ^(waybar)$"
      "center, match:class ^(xdg-desktop-portal-gtk|zenity|Rofi)$"
      "stayfocused, match:class ^(Pinentry)$"
      "stayfocused, match:title ^(Hyprland Polkit Agent)$"
      #"keepaspectratio, match:class ^(mpv)$"
      "noblur, match:class ^(mpv)$ match:float true match:fullscreen false"
      "suppressevent maximize, match:class ^(firefox)$"
      "suppressevent activatefocus, match:class ^(OrcaSlicer)$"
      "pin, match:title ^(ripdrag)$"
      "size 60% 50%, match:title ^(Enter name of file to save to…)$ match:class xdg-desktop-portal-gtk"
      "float, match:title ^(mpd_cover|float)$"
      "size 1000 1000, match:title ^(mpd_cover)$"
      "pseudo, match:class swayimg.*"
      "float, match:class swayimg.*"
      "tile, match:class ^(kdeconnect.sms)$"
      "fullscreenstate -1 2, match:workspace special:browser-tradingview"
      "fullscreenstate -1 2, match:workspace special:browser-chatgpt"
      "fullscreenstate -1 2, match:workspace special:browser-messages"
      "fullscreenstate -1 2, match:workspace special:server"
    ];
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
