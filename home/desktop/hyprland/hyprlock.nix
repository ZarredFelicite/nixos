{ osConfig, ... }:
let
  monitor = if osConfig.networking.hostName == "web" then "DP-3" else "eDP-1";
in {
  programs.hyprlock.settings = {
    general = {
      hide_cursor = true;
      grace = 5;
      ignore_empty_input = true;
      #screencopy_mode = 1;
    };
    animations.enabled = true;
    background = [
      {
        monitor = "DP-2";
        path = "/home/zarred/pictures/wallpapers/tarantula_nebula_web_right.png";
        color = "rgba(25, 20, 20, 1.0)";
        blur_passes = 4;
        blur_size = 7;
        #noise = 0.0117
        #contrast = 0.8916
        brightness = 0.7;
        #vibrancy = 0.1696
        #vibrancy_darkness = 0.0
      }
      {
        monitor = "DP-3";
        path = "/home/zarred/pictures/wallpapers/tarantula_nebula_web_left.png";
        color = "rgba(25, 20, 20, 1.0)";
        blur_passes = 4;
        blur_size = 7;
        brightness = 0.7;
      }
      {
        monitor = "eDP-1";
        path = "/home/zarred/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg";
        color = "rgba(25, 20, 20, 1.0)";
        blur_passes = 3;
        blur_size = 7;
        brightness = 0.7;
      }
    ];
    image = {
      monitor = monitor;
      path = "/home/zarred/documents/career/photos/ProfilePhoto.jpg";
      size = 150; # lesser side if not 1:1 ratio
      rounding = -1; # negative values mean circle
      border_size = 4;
      border_color = "rgb(38, 35, 58)";
      rotate = 0; # degrees, counter-clockwise
      #reload_time = -1; # seconds between reloading, 0 to reload with SIGUSR2
      #reload_cmd =  # command to get new path. if empty, old path will be used. don't run "follow" commands like tail -F
      position = "0, 200";
      halign = "center";
      valign = "center";
    };
    input-field = {
      monitor = monitor;
      size = "200, 50";
      outline_thickness = 3;
      dots_size = 0.33; # Scale of input-field height, 0.2 - 0.8
      dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
      dots_center = false;
      dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
      outer_color = "rgb(31748f)";
      inner_color = "rgb(26233a)";
      font_color = "rgb(c4a7e7)";
      fade_on_empty = true;
      fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
      placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
      hide_input = false;
      rounding = -1; # -1 means complete rounding (circle/oval)
      check_color = "rgb(9ccfd8)";
      fail_color = "rgb(eb6f92)"; # if authentication failed, changes outer_color and fail message color
      fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
      capslock_color = -1;
      numlock_color = -1;
      bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
      invert_numlock = false; # change color if numlock is off
      swap_font_color = false; # see below
      position = "0, -20";
      halign = "center";
      valign = "center";
    };
      #shape = {
      #  monitor = "";
      #  size = "360, 60";
      #  color = "rgba(25, 23, 36, 0.8)";
      #  rounding = -1;
      #  border_size = 4;
      #  border_color = "rgba(49, 116, 143, 0.8)";
      #  rotate = 0;
      #  xray = false; # if true, make a "hole" in the background (rectangle of specified size, no rotation)
      #  position = "0, 80";
      #  halign = "center";
      #  valign = "center";
      #};
    label = [
      {
        monitor = monitor;
        text = "$TIME12";
        text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 100;
        font_family = "IosevkaTerm NFM";
        rotate = 0; # degrees, counter-clockwise
        position = "0, -40";
        halign = "center";
        valign = "top";
      }
      {
        monitor = monitor;
        text = "cmd[update:300000] cat /tmp/tickers";
        text_align = "left"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 16;
        font_family = "IosevkaTerm NFM";
        rotate = 0; # degrees, counter-clockwise
        position = "20, -20";
        halign = "left";
        valign = "top";
      }
      {
        monitor = monitor;
        text = "cmd[update:300000] cat /tmp/rss-news | jq -r '.text,.tooltip' | sed '1s/$/\\n----------------------------------------------------------------------/' | head -n20";
        text_align = "left"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 14;
        font_family = "IosevkaTerm NFM";
        rotate = 0; # degrees, counter-clockwise
        position = "20, 20";
        halign = "left";
        valign = "bottom";
      }
      {
        monitor = monitor;
        text = "cmd[update:300000] playerctl metadata --format \"{{ title }}|{{ artist }}|{{ album }}\" | tr \"|\" \"\\n\"";
        text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 20;
        font_family = "IosevkaTerm NFM";
        rotate = 0; # degrees, counter-clockwise
        position = "0, -250";
        halign = "center";
        valign = "top";
      }
      {
        monitor = monitor;
        text = "cmd[update:300000] curl -s 'https://wttr.in/-37.99116,145.17385?format=1'";
        text_align = "center"; # center/right or any value for default left. multi-line text alignment inside label container
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 24;
        font_family = "IosevkaTerm NFM";
        rotate = 0; # degrees, counter-clockwise
        position = "0, -200";
        halign = "center";
        valign = "top";
      }
    ];
  };
}
