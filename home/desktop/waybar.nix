{ pkgs, lib, osConfig, inputs, ... }:
let
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
        "class<firefox> title<.*twitch|youtube|plex|tntdrama|bally sports.*>" = "";
        "class<kitty>" = "󰅬";
        "class<org.telegram.desktop>" = "";
        "class<steam>" = "";
        "class<thunderbird>" = "";
        "class<virt-manager>" = "󰢹";
        "class<vlc>" = "󰕼";
        "class<mpv>" = "";
        "class<stats>" = "󱕍";
        "class<org.pwmt.zathura>" = "󰈦";
        "class<brave-browser>" = "";
        "class<PrusaSlicer>" = "";
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
        #modules-left = [ "hyprland/workspaces#number" "hyprland/submap" ];
        modules-center = [ "hyprland/workspaces#number" "hyprland/submap" ];
        #modules-center = [ "mpris" ];
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
        modules-left = [ "cava" "mpris" ];
        modules-center = [ "hyprland/workspaces#number" "hyprland/submap" ];
        modules-right = [ "systemd-failed-units" "custom/weather" "custom/updates" "tray" "custom/notification" "idle_inhibitor" "network" "custom/zmk-battery" "bluetooth" "power-profiles-daemon" "cpu" "temperature" "wireplumber" "backlight" "battery" "clock" ];
        tray = {
          icon-size = 14;
          spacing = 3;
        };
        mpris = {
          format = "{dynamic}";
          format-paused = " ";
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
      .modules-left, .modules-right {
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
      /*
      #cava {
        opacity: 0.80;
        font-size: 0;
        margin: 0;
        padding: 0;
      }
      */
    '';
  };
}
