{ pkgs, lib, ... }:
let
  wallpaper = ../../config/wallpaper.jpg;
  screenshot = pkgs.writeShellScriptBin "portable-screenshot" ''
    set -eu
    mkdir -p "$HOME/Pictures/Screenshots"
    file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
    if [ "''${1:-}" = region ]; then
      geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
      ${pkgs.grim}/bin/grim -g "$geometry" "$file"
    else
      ${pkgs.grim}/bin/grim "$file"
    fi
    ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
    ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
  '';
in {
  home.packages = with pkgs; [
    fuzzel xfce.thunar grim slurp wl-clipboard libnotify screenshot
    pavucontrol brightnessctl playerctl cava jq
    nerd-fonts.iosevka-term
  ];

  xdg.configFile."quickshell/primary".source = ../../config/quickshell/primary;

  programs.hyprlock = {
    enable = true;
    settings = {
      general = { hide_cursor = false; grace = 5; ignore_empty_input = true; };
      animations.enabled = true;
      background = [ {
        monitor = "";
        path = toString wallpaper;
        blur_passes = 3;
        blur_size = 7;
        brightness = 0.7;
      } ];
      input-field = {
        monitor = "";
        size = "200, 50";
        outline_thickness = 3;
        outer_color = "rgb(31748f)";
        inner_color = "rgb(26233a)";
        font_color = "rgb(c4a7e7)";
        check_color = "rgb(9ccfd8)";
        fail_color = "rgb(eb6f92)";
        placeholder_text = "<i>Input Password...</i>";
        position = "0, -20";
        halign = "center";
        valign = "center";
      };
      label = [ {
        monitor = "";
        text = "$TIME12";
        color = "rgba(196, 167, 231, 1.0)";
        font_size = 100;
        font_family = "IosevkaTerm NFM";
        position = "0, -80";
        halign = "center";
        valign = "top";
      } ];
    };
  };

  services.hypridle = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pgrep -x hyprlock >/dev/null || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [ {
        timeout = 600;
        on-timeout = "loginctl lock-session";
      } ];
    };
  };

  programs.quickshell = {
    enable = true;
    # VideoStreamVideo.qml imports QtMultimedia even while the camera is off.
    # Supply the matching Qt QML module at runtime without rebuilding Quickshell.
    package = pkgs.symlinkJoin {
      name = "quickshell-with-multimedia";
      meta.mainProgram = "quickshell";
      paths = [ pkgs.quickshell ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = let
        qmlPath = "${pkgs.qt6.qtmultimedia}/${pkgs.qt6.qtbase.qtQmlPrefix}";
      in ''
        wrapProgram $out/bin/quickshell \
          --prefix QML_IMPORT_PATH : ${qmlPath} \
          --prefix QML2_IMPORT_PATH : ${qmlPath}
      '';
    };
    activeConfig = "primary";
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };
  systemd.user.services.quickshell.Service.Environment = [ "QUICKSHELL_DISABLE_AI_VISUALIZER=1" ];

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ (toString wallpaper) ];
      wallpaper = [ ",${toString wallpaper}" ];
      ipc = "on";
    };
  };
  systemd.user.services.hyprpaper = {
    Unit = {
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      monitor = [ ",preferred,auto,1" ];
      env = [ "GDK_BACKEND,wayland" "QT_QPA_PLATFORM,wayland" "QUICKSHELL_DISABLE_AI_VISUALIZER,1" ];
      exec-once = [
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];
      general = {
        gaps_in = 8;
        gaps_out = 6;
        border_size = 2;
        "col.active_border" = "rgba(9ccfd899)";
        "col.inactive_border" = "rgba(31748f99)";
        layout = "dwindle";
        resize_on_border = true;
      };
      decoration = {
        rounding = 20;
        blur = { enabled = true; size = 10; passes = 3; brightness = 0.7; special = true; popups = true; };
        shadow.enabled = false;
      };
      animations = {
        enabled = true;
        bezier = "overshot,0.1,0.95,0.2,1.05";
        animation = [
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
        touchpad = { disable_while_typing = true; natural_scroll = true; tap-and-drag = true; };
      };
      gesture = [ "4, horizontal, workspace" ];
      group = {
        "col.border_active" = "rgba(9ccfd899)";
        "col.border_inactive" = "rgba(31748f99)";
        groupbar = { enabled = true; height = 6; render_titles = false; gradients = false; rounding = 4; };
      };
      misc = { disable_hyprland_logo = true; focus_on_activate = true; vrr = true; };
      dwindle = { force_split = 2; use_active_for_splits = true; default_split_ratio = 1.2; };
      bindm = [ "$mod, mouse:272, movewindow" "$mod, mouse:273, resizewindow" ];
      bind = [
        "$mod, Return, exec, kitty -1"
        "$mod, F, exec, firefox"
        "$mod, B, exec, thunar"
        "$mod, Space, exec, fuzzel"
        "$mod, L, exec, fuzzel"
        "$mod, K, killactive,"
        "$mod, H, togglefloating,"
        "$mod, T, togglegroup,"
        "$mod CTRL, T, lockactivegroup, toggle"
        "$mod CTRL, P, pseudo,"
        "$mod SHIFT, P, exec, ~/scripts/hyprland/hyprpin"
        "$mod, E, exec, ~/scripts/hyprland/hyprfull"
        "$mod, W, exec, ~/scripts/hyprland/hyprwindow"
        "$mod, Y, exec, ~/scripts/hyprland/hypr_focusfloat"
        # Fixed opacity avoids the original rofi dependency; reset with Ctrl+Shift+Y.
        "$mod CTRL, Y, exec, ~/scripts/hyprland/hypr_opacity.sh 8"
        "$mod CTRL SHIFT, Y, exec, ~/scripts/hyprland/hypr_opacity.sh 0"
        "$mod SHIFT, E, fullscreenstate, -1 2"
        "$mod CTRL, E, fullscreenstate, 2 -1"
        "$mod, Q, exec, loginctl lock-session"
        "$mod, N, exec, quickshell ipc -c primary call bar toggleNotifications"
        "$mod SHIFT, slash, exec, quickshell ipc -c primary call bar toggleShortcuts"
        "$mod SHIFT, S, exec, portable-screenshot"
        "$mod CTRL, S, exec, portable-screenshot region"
        ", PRINT, exec, portable-screenshot region"
        "$mod CTRL, D, movetoworkspace, special"
        "$mod, Left, movefocus, l"
        "$mod, Down, movefocus, d"
        "$mod, Up, movefocus, u"
        "$mod, Right, movefocus, r"
        "$mod SHIFT, Left, swapwindow, l"
        "$mod SHIFT, Down, swapwindow, d"
        "$mod SHIFT, Up, swapwindow, u"
        "$mod SHIFT, Right, swapwindow, r"
        "$mod ALT, Left, movewindoworgroup, l"
        "$mod ALT, Down, movewindoworgroup, d"
        "$mod ALT, Up, movewindoworgroup, u"
        "$mod ALT, Right, movewindoworgroup, r"
        "$mod CTRL SHIFT, Up, movetoworkspace, r+1"
        "$mod CTRL SHIFT, Down, movetoworkspace, r-1"
        "$mod CTRL SHIFT, Right, workspace, r+1"
        "$mod CTRL SHIFT, Left, workspace, r-1"
        "$mod, Page_Up, changegroupactive, f"
        "$mod, Page_Down, changegroupactive, b"
      ] ++ (builtins.concatLists (builtins.genList (i: let n = toString (i + 1); in [
        "$mod, ${n}, workspace, ${n}"
        "$mod SHIFT, ${n}, movetoworkspace, ${n}"
      ]) 9));
      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPlay, exec, playerctl play-pause"
        "$mod CTRL, Left, resizeactive, -20 0"
        "$mod CTRL, Down, resizeactive, 0 20"
        "$mod CTRL, Up, resizeactive, 0 -20"
        "$mod CTRL, Right, resizeactive, 20 0"
      ];
    };
    # 25.11 pins Hyprland 0.52; Nano's 0.53+ match:-style window rules
    # cannot be copied verbatim. Keep only the compatible bar layer effect.
    extraConfig = ''
      layerrule = blur, primary-bar
      layerrule = ignorealpha 0.45, primary-bar
    '';
  };
}
