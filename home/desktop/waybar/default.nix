{ pkgs, lib, osConfig, inputs, ... }:
# TODO: backup, recording indicator by grepping ps for wf-recorder, restic
let
  height = if osConfig.networking.hostName == "web" then "14" else "14";
  cava_config = {
    framerate = 30;
    autosens = 1;
    sensitivity = 1;
    lower_cutoff_freq = 20;
    higher_cutoff_freq = 20000;
    method = "pipewire";
    source = "auto";
    #channels = "mono";
    waves = false;
    monstercat = true;
    #bar_delimiter = 32;
    bar_delimiter = 0;
    noise_reduction = 0.3;
    input_delay = 1;
    sleep_timer = 5;
    hide_on_silence = true;
    format-icons = [ " " "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
  };
  workspaces = {
    "hyprland/workspaces#pills" = {
      format = "{icon}";
      format-icons = {
        default = "";
      };
      #active-only = true;
      all-outputs = false;
      show-special = false;
      on-scroll-up = "hyprctl dispatch workspace +1";
      on-scroll-down = "hyprctl dispatch workspace -1";
    };
    "hyprland/workspaces#number" = {
      format = "<span color='#1f1d2e'>{windows}</span> ";
      #format = " <span color='#1f1d2e'>{name} {windows}</span> ";
      all-outputs = false;
      show-special = true;
      special-visible-only = true;
      window-rewrite-default = "";
      window-rewrite = {
        "class<Caprine>" = "󰈎";
        "class<Slack>" = "󰒱";
        "class<code>" = "󰨞";
        "class<discord>" = "󰙯";
        "class<firefox>" = "󰈹";
        "class<firefox> title<.*github.*>" = "";
        "class<firefox> title<.*twitch|youtube.*>" = "";
        "class<kitty>" = "󰅬";
        "class<ghostty>" = "";
        "title<tmux.*>" = "";
        "class<org.telegram.desktop>" = "";
        "class<steam>" = "";
        "class<thunderbird>" = "";
        "class<virt-manager>" = "󰢹";
        "class<vlc>" = "󰕼";
        "class<mpv>" = "";
        "class<imv>" = " ";
        "class<stats>" = "󱕍";
        "class<obsidian>" = "";
        "class<org.pwmt.zathura>" = "󰈦";
        "class<brave-browser>" = "";
        "class<.*Slicer>" = "";
        "newsboat" = "";
      };
    };
    "hyprland/window" = {
      separate-outputs = true;
      tooltip = true;
      rewrite = {
        #" - ([^|]+)\|" = "$1";
        ".* Mozilla Firefox" = "$1";
      };
    };
    "hyprland/submap" = {
      format = " {}";
      max-length = 20;
      tooltip = true;
    };
  };
in {
  home.packages = [ pkgs.wttrbar ];
  stylix.targets.waybar.enable = false;
  systemd.user.services.zmk_battery = {
    Unit.Description = "Get ZMK Keyboard battery";
    Service.ExecStart = "/home/zarred/scripts/waybar/zmk-battery.py json";
    Service.Restart = "always";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.airpods_battery = {
    Unit.Description = "Get AirPods battery";
    Service.ExecStart = "/home/zarred/scripts/waybar/airpods_battery_data.py";
      #Service.ExecStart = pkgs.writers.writePython3 "airpods_battery_python" {
      #  libraries = with pkgs.python3Packages; [ bleak ];
      #  flakeIgnore = [ "E265" "E225" ];
      #  doCheck = false;
      #  } (builtins.readFile ./scripts/airpods_battery.py);
    Service.Restart = "always";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  systemd.user.services.airpods_battery_icons = {
    Unit.Description = "Get AirPods battery icons";
    Service.ExecStart = "/home/zarred/scripts/waybar/battery_icons.sh";
    Service.Restart = "always";
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.After = [ "graphical-session.target" ];
  };
  programs.waybar = {
    systemd.enable = true;
    #package = inputs.waybar.packages.${pkgs.system}.waybar.overrideAttrs (oldAttrs: {
    #  mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    #});
    settings = lib.mkMerge [
      (lib.mkIf (osConfig.networking.hostName == "web"){
        primary.output = "DP-3";
        secondary.output = "DP-2";
      })
      (lib.mkIf (osConfig.networking.hostName == "nano"){
        primary.output = "eDP-1";
        secondary.output = "DP-2";
      })
      (lib.mkIf (osConfig.networking.hostName == "surface"){
        primary.output = "eDP-1";
      })
      {
      secondary = workspaces // {
        layer = "top";
        position = "top";
        #mode = "dock";
        passthrough = false;
        exclusive = true;
        spacing = 4;
        margin = "4 4 0 4";
        gtk-layer-shell = true;
        modules-left = [ "hyprland/workspaces#number" "hyprland/submap" ];
        modules-right = [ ];
      };
      primary = workspaces // {
        layer = "top";
        position = "top";
        #mode = "overlay";
        passthrough = false;
        exclusive = true;
        spacing = 4;
        margin = "4 4 0 4";
        gtk-layer-shell = true;
        modules-left = [ "image#logo-hyprland" "hyprland/workspaces#number" "cava" "mpris" "group/group-stocks" "custom/news" "custom/mail" ];
        modules-center = [  ];
        modules-right = [ "hyprland/submap" "image#recording" "group/zmk-battery" "group/airpods-battery"  "custom/weather" "tray" "group/stats-group" "group/clock-group" "group/group-power" ];
        tray = {
          icon-size = 14;
          spacing = 3;
        };
        mpris = {
          format = "{status_icon} {dynamic}";
          dynamic-order = ["title" "artist" "album" "position" "length"];
          dynamic-len = 75;
          title-len = 35;
          artist-len = 15;
          format-stopped = "";
          status-icons = {
            paused = " ";
            playing = " ";
            stopped = "";
          };
          player-icons = {
            default = "▶";
            mpd = "󰎆 ";
            mpv = " ";
            firefox = " ";
          };
          ignored-players = [ "kdeconnect" ];
        };
        "group/updates-group" = {
          orientation = "horizontal";
          modules = [ "systemd-failed-units" "custom/updates" ];
        };
        "group/network-group" = {
          orientation = "horizontal";
          modules = [ "network" "bluetooth" ];
        };
        "group/clock-group" = {
          orientation = "horizontal";
          modules = [ "custom/timer" "clock" ];
        };
        "group/stats-group" = {
          orientation = "inherit";
          modules = [ "systemd-failed-units" "custom/updates" "image#notifications" "image#wifi" "image#bluetooth" "image#volume-sink" "image#volume-source" "image#cpu" "image#brightness" "image#battery" ];
        };
        "image#wifi" = {
          exec = "/home/zarred/scripts/waybar/wifi_icon.sh";
          interval = 1;
          size = 20;
        };
        "image#bluetooth" = {
          exec = "/home/zarred/scripts/waybar/bluetooth_icon.sh";
          interval = 1;
          size = 20;
        };
        "image#battery" = {
          exec = "/home/zarred/scripts/waybar/battery_icon.sh";
          interval = 1;
          size = 20;
        };
        "image#cpu" = {
          exec = "/home/zarred/scripts/waybar/create_cpu_icon.sh";
          on-click = "/home/zarred/scripts/waybar/create_cpu_icon.sh --switch-mode";
          interval = 3;
          size = 20;
          signal = 5;
        };
        "image#brightness" = {
          exec = "/home/zarred/scripts/waybar/brightness.sh";
          on-click = "/home/zarred/scripts/waybar/brightness.sh --idle";
          interval = 5;
          size = 20;
          signal = 6;
        };
        "group/volume-custom" = {
          orientation = "inherit";
          modules = [ "image#volume-sink" "image#volume-source" ];
        };
        "image#volume-sink" = {
          exec = "/home/zarred/scripts/waybar/volume_device_switcher.sh --sink";
          interval = 2;
          size = 20;
          on-click = "/home/zarred/scripts/waybar/volume_device_switcher.sh --next-sink";
          on-click-right = "/home/zarred/scripts/waybar/volume_device_switcher.sh --sink --mute";
          on-scroll-up = "/home/zarred/scripts/waybar/volume_device_switcher.sh --sink --increase";
          on-scroll-down = "/home/zarred/scripts/waybar/volume_device_switcher.sh --sink --decrease";
          signal = 4;
        };
        "image#volume-source" = {
          exec = "/home/zarred/scripts/waybar/volume_device_switcher.sh --source";
          interval = 2;
          size = 20;
          on-click = "/home/zarred/scripts/waybar/volume_device_switcher.sh --next-source";
          on-click-right = "/home/zarred/scripts/waybar/volume_device_switcher.sh --source --mute";
          on-scroll-up = "/home/zarred/scripts/waybar/volume_device_switcher.sh --source --increase";
          on-scroll-down = "/home/zarred/scripts/waybar/volume_device_switcher.sh --source --decrease";
          signal = 4;
        };
        "group/airpods-battery" = {
          orientation = "inherit";
          modules = [ "image#airpods-battery-left" "image#airpods-battery-case" "image#airpods-battery-right" ];
        };
        "image#airpods-battery-left" = {
          exec = "cat /tmp/airpods_battery_left";
          interval = 1;
          size = 20;
          on-click = "bluetoothctl disconnect 14:28:76:9E:F5:60; bluetoothctl connect 14:28:76:9E:F5:60";
        };
        "image#airpods-battery-right" = {
          exec = "cat /tmp/airpods_battery_right";
          interval = 1;
          size = 20;
          on-click = "bluetoothctl disconnect 14:28:76:9E:F5:60; bluetoothctl connect 14:28:76:9E:F5:60";
        };
        "image#airpods-battery-case" = {
          exec = "cat /tmp/airpods_battery_case";
          interval = 1;
          size = 20;
          on-click = "bluetoothctl disconnect 14:28:76:9E:F5:60; bluetoothctl connect 14:28:76:9E:F5:60";
        };
        "group/zmk-battery" = {
          orientation = "inherit";
          modules = [ "image#zmk-battery-left" "image#zmk-battery-central" "image#zmk-battery-right" ];
        };
        "image#zmk-battery-left" = {
          exec = "cat /tmp/zmk_battery_left";
          interval = 2;
          size = 20;
        };
        "image#zmk-battery-right" = {
          exec = "cat /tmp/zmk_battery_right";
          interval = 2;
          size = 20;
        };
        "image#zmk-battery-central" = {
          exec = "cat /tmp/zmk_battery_central";
          interval = 2;
          size = 20;
        };
        "image#logo-hyprland" = {
          path = "/home/zarred/pictures/Icons/hyprland.png";
          size = 24;
        };
        "image#logo-nixos" = {
          path = "/home/zarred/pictures/Icons/nixos.png";
          size = 24;
        };
        "image" = {
          exec = "/home/zarred/scripts/waybar/playerctl-art.sh";
          interval = 30;
        };
        "image#recording" = {
            #exec = "/home/zarred/scripts/waybar/process-icon.sh 'ffmpeg -nostdin -loglevel error -y -f pulse -i default -ac 1 -ar 16000 -c:a pcm_s16le /tmp/audio_recording.wav' '/home/zarred/pictures/icons/waybar/recording.png'";
          exec = "/home/zarred/scripts/waybar/process-icon.sh 'sox -t raw' '/home/zarred/pictures/icons/waybar/recording.png'";
          signal = 3;
          interval = 30;
          size = 20;
        };
        systemd-failed-units = {
          hide-on-ok = true;
          format = "✗ {nr_failed}";
          #format-ok": "✓",
          system = true;
          user = true;
        };
        bluetooth = {
          format = " ";
          format-disabled = "";
          format-connected = "<sup> {num_connections}</sup>";
          format-connected-battery = "<sup> {num_connections}</sup>";
            #format-connected-battery = " {num_connections} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
        };
        wireplumber = {
          format = "{icon}";
          format-muted = " ";
          on-click = "pavucontrol";
          max-volume = 150;
          scroll-step = 0.2;
          format-icons = [ "󰝦 " "󰪞 " "󰪟 " "󰪠 " "󰪡 " "󰪢 " "󰪣 " "󰪤 " "󰪥 " ];
        };
        network = {
          format-wifi = " ";
          format-ethernet = " ";
          format-disconnected = "󰤮 ";
          tooltip-format = "{ifname} via {gwaddr}  ";
          tooltip-format-wifi = "{essid} ({signalStrength}%)  ";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}";
          tooltip-format-disconnected = "Disconnected";
        };
        cpu = {
          interval = 5;
          format = "{icon}";
          format-icons = [ "󰝦 " "󰪞 " "󰪟 " "󰪠 " "󰪡 " "󰪢 " "󰪣 " "󰪤 " "󰪥 " ];
        };
        temperature = {
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
          format = "{icon}";
          format-icons = [ "󰝦 " "󰪞 " "󰪟 " "󰪠 " "󰪡 " "󰪢 " "󰪣 " "󰪤 " "󰪥 " ];
        };
        battery = {
          interval = 10;
          format = "{icon}";
          format-time = "{H}:{m}";
          tooltip-format = "{capacity}% | {power:.2f}W | {timeTo}";
          format-icons = [ "󰝦 " "󰪞 " "󰪟 " "󰪠 " "󰪡 " "󰪢 " "󰪣 " "󰪤 " "󰪥 " ];
        };
        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = " ";
            performance = " ";
            balanced = " ";
            power-saver = " ";
          };
        };
        backlight = {
          device = "intel_backlight";
          format = "{icon}";
          format-icons = [ "󰝦 " "󰪞 " "󰪟 " "󰪠 " "󰪡 " "󰪢 " "󰪣 " "󰪤 " "󰪥 " ];
        };
        clock = {
          format = " {:%I:%M %d}";
          format-alt = "{ :%A; %B %d; %Y (%R)} ";
          tooltip-format = "{:%d/%m/%Y}";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            on-click-right = "mode";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions =  {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
        privacy = {
          icon-spacing = 4;
          icon-size = 18;
          transition-duration = 250;
          modules = [
            { type = "screenshare"; tooltip = true; tooltip-icon-size = 24; }
            { type = "audio-out"; tooltip = true; tooltip-icon-size = 24; }
            { type = "audio-in"; tooltip = true; tooltip-icon-size = 24; }
          ];
        };
        "custom/timer" = {
          exec = "/home/zarred/scripts/waybar/timer.sh updateandprint";
          exec-on-event = true;
          return-type = "json";
          interval = 5;
          signal = 4;
          format = "{icon}<sup> {}</sup>";
          format-icons = {
            standby = "󱎫";
            running = "󱫡";
            paused = "󱫟";
          };
          on-click = "/home/zarred/scripts/waybar/timer.sh new 15 'notify-send -u critical \"Timer expired.\"; mpv --force-window=no /home/zarred/scripts/notifications/audio/soft-4.mp3'";
          on-click-middle = "/home/zarred/scripts/waybar/timer.sh cancel";
          on-click-right = "/home/zarred/scripts/waybar/timer.sh togglepause";
          on-scroll-up = "/home/zarred/scripts/waybar/timer.sh increase 60 || /home/zarred/scripts/waybar/timer.sh new 1 'notify-send -u critical \"Timer expired.\"; mpv --force-window=no /home/zarred/scripts/notifications/audio/soft-4.mp3'";
          on-scroll-down = "/home/zarred/scripts/waybar/timer.sh increase -60";
        };
        "image#notifications" = {
          exec = "/home/zarred/scripts/waybar/notification_icon.sh";
          on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
          on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
          interval = 1;
          size = 20;
        };
        "custom/notification" = {
          tooltip = false;
          #format = "{icon}<sup> {}</sup>";
          format = "{icon} {}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
            #exec = "${pkgs.mako}/bin/makoctl history | ${pkgs.jq}/bin/jq '.data[] | length'";
          on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
          on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
          escape = true;
        };
        "custom/firefox" = {
          exec-if = "hyprctl activewindow -j | jq .class | grep firefox || exit 1 && exit 0";
          format = "";
          #exec = "echo 'hello'";
        };
          #"custom/zmk-battery" = {
          #  format = "{}";
          #  tooltip = false;
          #  interval = 3600;
          #  exec = "~/scripts/waybar/zmk-battery.py icons";
          #    #return-type = "json";
          #};
          #"custom/airpods-battery" = {
          #  format = "{}";
          #  tooltip = true;
          #  exec = "${airpods_battery_python} /tmp/airpods_battery | jq --unbuffered --compact-output";
          #  return-type = "json";
          #  restart-interval = 1;
          #};
        "custom/mail" = {
          format = "{}";
          tooltip = false;
          interval = 60;
          exec = "~/scripts/waybar/last_mail.sh";
        };
        "custom/updates" = {
          format = "{}";
          tooltip = true;
          interval = 10;
          exec = "~/scripts/nix/nix-update";
          return-type = "json";
        };
        "custom/weather" = {
          format = "{}";
          tooltip = true;
          interval = 3600;
          exec = "~/scripts/waybar/weather.sh -37.99116,145.17385";
          return-type = "json";
        };
        "custom/news" = {
          format = "{}";
          tooltip = true;
          interval = 1800;
          exec = "~/scripts/waybar/rss.py -c news -s";
          return-type = "json";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = " ";
            deactivated = " ";
          };
        };
        cava = (cava_config // {
          stereo = true;
          bars = 12;
        });
        "cava#before" = (cava_config // {
          mono_option = "left";
          stereo = false;
          reverse = true;
          bars = 8;
        });
        "cava#after" = (cava_config // {
          mono_option = "right";
          stereo = false;
          reverse = false;
          bars = 8;
        });
        "group/group-power" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 500;
            children-class = "not-power";
            transition-left-to-right = false;
          };
          modules = [ "image#logo-nixos" "custom/quit" "custom/lock" "custom/reboot" "custom/power" ];
        };
        "custom/quit" = {
          format = "󰈆";
          tooltip = false;
          on-click = "hyprctl dispatch exit";
        };
        "custom/lock" = {
          format = "";
          tooltip = false;
          on-click = "loginctl lock-session";
        };
        "custom/reboot" = {
          format = "";
          tooltip = false;
          on-click = "reboot";
        };
        "custom/power" = {
          format = "";
          tooltip = false;
          on-click = "shutdown now";
        };
          #"group/group-stocks" = {
          #  orientation = "inherit";
          #  drawer = {
          #    transition-duration = 500;
          #    children-class = "stocks-ticker";
          #    transition-left-to-right = true;
          #  };
          #  modules = [
          #    "custom/stock-ticker0"
          #    "custom/stock-ticker1"
          #    "custom/stock-ticker2"
          #    "custom/stock-ticker3"
          #    "custom/stock-ticker4"
          #    "custom/stock-ticker5"
          #    "custom/stock-ticker6"
          #    "custom/stock-ticker7"
          #    "custom/stock-ticker8"
          #    "custom/stock-ticker9"
          #  ];
          #};
          #"custom/stock-ticker0" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 0";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker1" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 1";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker2" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 2";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker3" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 3";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker4" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 4";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker5" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 5";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker6" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 6";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker7" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 7";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker8" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 8";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
          #"custom/stock-ticker9" = {
          #  exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 9";
          #  tooltip = false;
          #  restart-interval = 300;
          #};
      };
    }];
    style = ''
      * {
          font-family: IosevkaTerm NF;
          font-size: ${height}px;
          min-height: 0px;
          /*color: #B0C6F4;*/
      }
      tooltip {
        background: rgba(38, 35, 58, 0.9);
        border: 2px solid rgba(49, 116, 143, 0.7);
        border-radius: 10px ;
      }
      tooltip label {
        color: rgb(235, 188, 186);
      }
      window#waybar {
          background: rgba(0, 0, 0, 0);
      }
      /*
      .modules-right {
          padding: 0 2 0 2px;
          margin: 0 0 0 0px;
          border-radius: 12px;
          border: 2px solid rgba(49, 116, 143, 0.6);
          background: rgba(43, 48, 59, 0.3);
          color: #c4a7e7;
      }
      */
      #battery.charging {
          color: #a6e3a1;
      }
      @keyframes blink {
          to {
              background-color: #ffffff;
              color: black;
          }
      }
      #custom-stock-ticker0,
      #custom-stock-ticker1,
      #custom-stock-ticker2,
      #custom-stock-ticker3,
      #custom-stock-ticker4,
      #custom-stock-ticker5,
      #custom-stock-ticker6,
      #custom-stock-ticker7,
      #custom-stock-ticker8,
      #custom-stock-ticker9 {
          color: #c4a7e7;
          padding: 0 3 0 3px;
          margin: 0px 2px 0px 2px;
          background: rgba(38, 35, 58, 0.5);
          border-radius: 12px;
          border: 2px solid rgba(49, 116, 143, 0.6);
      }
      #mpris, #submap, #custom-news, #custom-mail, #airpods-battery, #zmk-battery,
      #clock-group, #stats-group, #updates-group, #network-group, #battery, #tray,
      #custom-weather, #custom-notification, #privacy, #volume-custom {
          padding: 0 4 0 4px;
          margin: 0px 1px 0px 1px;
          border-radius: 12px;
          border: 2px solid rgba(49, 116, 143, 0.6);
          background: rgba(38, 35, 58, 0.4);
          color: #c4a7e7;
      }
      #custom-power, #custom-reboot, #custom-lock, #custom-quit {
        border-radius: 10px;
        margin: 2px;
        padding: 0 8 0 4px;
        background-color: rgba(49, 116, 143, 0.4);
        transition: all 0.2s ease-in-out;
      }
      #workspaces {
        background: rgba(38, 35, 58, 0.4);
        margin: 1px;
        padding: 2px;
        border-radius: 12px;
        border: 2px solid rgba(49, 116, 143, 0.6);
      }
      #workspaces box {
        margin: -2px -6px -2px -6px;
        padding: 0px;
        background: transparent;
      }
      #workspaces button{
        color: #31748f;
        border-radius: 8px;
        margin: 1px 2px;
        padding: 0px 2px;
        background-color: #31748f;
        transition: all 0.2s ease-in-out;
      }
      #workspaces button.empty{
        background-color: #31748f;
        transition: all 0.2s ease-in-out;
      }
      #workspaces button.active {
        color: #c4a7e7;
        padding: 0px 4px;
        background-color: #c4a7e7;
        transition: all 0.2s ease-in-out;
      }
      #battery.warning:not(.charging) {
          background: #f53c3c;
          color: white;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }
      #cava {
          color: #c4a7e7;
          padding: 0 2 0 2px;
          margin: 0px 2px 0px 2px;
          background: rgba(38, 35, 58, 0.5);
          border-radius: 12px;
          border: 1px solid rgba(49, 116, 143, 0.7);
      }
      #image, #backlight, #cpu, #temperature, #wireplumber, #power-profiles-daemon, #idle_inhibitor {
          padding: 0 1 0 1px;
          margin: 0px;
      }
      button {
        min-width: 14px;
        min-height: 14px;
      }
    '';
  };
}
