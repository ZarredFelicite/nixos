{ pkgs, lib, osConfig, inputs, ... }:
let
  stocks = pkgs.writers.writePython3 "stocks-waybar" { libraries = [ pkgs.python312Packages.yfinance ]; flakeIgnore = [ "E265" "E225" "E501" "F401"];}
    ''
      import yfinance as yf
      import sys

      def process(ticker, yfticker):
        text = ticker.replace('.AX',"") + ' '
        text += str(yfticker.info['currentPrice']) + ' '
        data = yfticker.history(period="1d")
        change = round((data['Close'].iloc[0] - data['Open'].iloc[0])/data['Open'].iloc[0] * 100, 2)
        text += str(change) + '%'
        return text

      tickers = sys.argv[1:]
      yftickers = [yf.Ticker(ticker) for ticker in tickers]
      formatted = ' '.join([process(ticker,yfticker) for ticker, yfticker in zip(tickers, yftickers)])
      print(formatted)
    '';
  height = if osConfig.networking.hostName == "web"
    then "14"
    else "16";
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
      format = " <span color='#1f1d2e'>{name} {windows}</span> ";
      all-outputs = false;
      show-special = false;
      window-rewrite-default = "";
      window-rewrite = {
        "class<Caprine>" = "󰈎";
        "class<Godot>" = "";
        "class<Slack>" = "󰒱";
        "class<code>" = "󰨞";
        "class<discord>" = "󰙯";
        "class<firefox>" = "󰈹";
        "class<firefox> title<.*github.*>" = "";
        "class<firefox> title<.*twitch|youtube.*>" = "";
        "class<kitty>" = "󰅬";
        "class<org.telegram.desktop>" = "";
        "class<steam>" = "";
        "class<thunderbird>" = "";
        "class<virt-manager>" = "󰢹";
        "class<vlc>" = "󰕼";
        "class<mpv>" = "";
        "class<imv>" = " ";
        "class<stats>" = "󱕍";
        "class<org.pwmt.zathura>" = "󰈦";
        "class<brave-browser>" = "";
        "class<.*Slicer>" = "";
        "nheko" = "<span color='#ABE9B3'>󰊌</span>";
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
        modules-center = [ "hyprland/workspaces#number" "hyprland/submap" ];
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
        modules-left = [ "cava" "mpris" "group/group-stocks" "custom/news" ];
        modules-center = [ "hyprland/workspaces#number" "hyprland/submap" ];
        modules-right = [ "systemd-failed-units" "custom/weather" "custom/updates" "tray" "custom/notification" "idle_inhibitor" "network" "custom/zmk-battery" "bluetooth" "power-profiles-daemon" "cpu" "temperature" "wireplumber" "backlight" "battery" "custom/timer" "clock" "group/group-power" ];
        tray = {
          icon-size = 14;
          spacing = 3;
        };
        mpris = {
          format = "{dynamic}";
          dynamic-len = 100;
            #format-paused = " ";
          status-icons = {
            paused = "⏸";
            playing = "▶";
          };
          player-icons = {
            default = "▶";
            mpd = "󰎆 ";
            mpv = " ";
            firefox = " ";
          };
        };
        "image" = {
          exec = "/home/zarred/scripts/waybar/playerctl-art.sh";
          interval = 30;
        };
        bluetooth = {
          format = " ";
          format-disabled = "";
          format-connected = "<sup> {num_connections}</sup>";
          format-connected-battery = " {num_connections} {device_battery_percentage}%";
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
          format = "{:%I:%M}";
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
        "custom/timer" = {
          exec = "/home/zarred/scripts/waybar/timer.sh updateandprint";
          exec-on-event = true;
          return-type = "json";
          interval = 5;
          signal = 4;
          format = "{icon} {}";
          format-icons = {
            standby = "󱎫";
            running = "󱫡";
            paused = "󱫟";
          };
          on-click = "/home/zarred/scripts/waybar/timer.sh new 15 'notify-send \"Session finished\"'";
          on-click-middle = "/home/zarred/scripts/waybar/timer.sh cancel";
          on-click-right = "/home/zarred/scripts/waybar/timer.sh togglepause";
          on-scroll-up = "/home/zarred/scripts/waybar/timer.sh increase 60 || /home/zarred/scripts/waybar/timer.sh new 1 'notify-send -u critical \"Timer expired.\"'";
          on-scroll-down = "/home/zarred/scripts/waybar/timer.sh increase -60";
        };
        "custom/notification" = {
          tooltip = false;
          #format = "{icon}<sup> {}</sup>";
          format = "{icon} {}";
          format-icons = {
            notification = "";
            none = "";
            dnd-notification = "";
            dnd-none = "";
            inhibited-notification = "";
            inhibited-none = "";
            dnd-inhibited-notification = "";
            dnd-inhibited-none = "";
          };
          return-type = "json";
            #exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
          exec = "${pkgs.mako}/bin/makoctl history | ${pkgs.jq}/bin/jq '.data[] | length'";
            #on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
            #on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
          escape = true;
        };
        "custom/firefox" = {
          exec-if = "hyprctl activewindow -j | jq .class | grep firefox || exit 1 && exit 0";
          format = "";
          #exec = "echo 'hello'";
        };
        "custom/zmk-battery" = {
          format = "{}";
          tooltip = false;
          interval = 3600;
          exec = "~/scripts/waybar/zmk-battery.py icons";
            #return-type = "json";
        };
        "custom/updates" = {
          format = "{}";
          tooltip = true;
          interval = 3600;
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
          exec = "~/scripts/waybar/rss.py -f 'http://feeds.bbci.co.uk/news/world/rss.xml' 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml' 'https://news.google.com/rss' -s";
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
          modules = [ "custom/power" "custom/quit" "custom/lock" "custom/reboot" ];
        };
        "custom/quit" = {
          format = "󰗼 ";
          tooltip = false;
          on-click = "hyprctl dispatch exit";
        };
        "custom/lock" = {
          format = "󰍁 ";
          tooltip = false;
          on-click = "hyprlock";
        };
        "custom/reboot" = {
          format = "󰜉 ";
          tooltip = false;
          on-click = "reboot";
        };
        "custom/power" = {
          format = " ";
          tooltip = false;
          on-click = "shutdown now";
        };
        "group/group-stocks" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 500;
            children-class = "stocks-ticker";
            transition-left-to-right = true;
          };
          modules = [
            "custom/stock-ticker0"
            "custom/stock-ticker1"
            "custom/stock-ticker2"
            "custom/stock-ticker3"
            "custom/stock-ticker4"
            "custom/stock-ticker5"
            "custom/stock-ticker6"
            "custom/stock-ticker7"
            "custom/stock-ticker8"
            "custom/stock-ticker9"
          ];
        };
        "custom/stock-ticker0" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 0 ADT.AX AFM.V MLX.AX AAR.AX AWJ.AX MM8.AX AUC.AX USL.AX AZY.AX HRZ.AX";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker1" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 1";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker2" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 2";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker3" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 3";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker4" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 4";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker5" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 5";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker6" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 6";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker7" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 7";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker8" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 8";
          tooltip = false;
          restart-interval = 60;
        };
        "custom/stock-ticker9" = {
          exec = "/home/zarred/scripts/finances/yfinance/yfinance-waybar.py 9";
          tooltip = false;
          restart-interval = 60;
        };
      };
    }];
    style = ''
      * {
          font-family: Iosevka Nerd Font;
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
      .modules-right {
          padding: 0 2 0 2px;
          margin: 0 0 0 0px;
          border-radius: 12px;
          border: 1px solid rgba(49, 116, 143, 0.7);
          background: rgba(43, 48, 59, 0.3);
          color: #c4a7e7;
      }
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
          padding: 0 0 0 0px;
          margin: 0px 2px 0px 2px;
          background: rgba(38, 35, 58, 0.5);
          border-radius: 12px;
          border: 0px solid #26233a;
      }
      #mpris, #submap, #custom-news {
          padding: 0 2 0 2px;
          margin: 0 0 0 0px;
          border-radius: 12px;
          border: 1px solid rgba(49, 116, 143, 0.7);
          background: rgba(43, 48, 59, 0.3);
          color: #c4a7e7;
      }
      #workspaces {
        background: rgba(38, 35, 58, 0.4);
        margin: 1px;
        padding: 2px;
        border-radius: 12px;
        border: 1px solid rgba(49, 116, 143, 0.7);
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
        padding: 0px 6px;
        background-color: #31748f;
        transition: all 0.2s ease-in-out;
      }
      #workspaces button.empty{
        background-color: #31748f;
        transition: all 0.2s ease-in-out;
      }
      #workspaces button.active {
        color: #c4a7e7;
        padding: 0px 10px;
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
          padding: 0 0 0 0px;
          margin: 0px 2px 0px 2px;
          background: rgba(38, 35, 58, 0.5);
          border-radius: 12px;
          border: 0px solid #26233a;
      }
    '';
  };
}
