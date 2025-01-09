{ lib, ... }: {
  services.swaync = {
    settings = {
      #schema = "~/.config/swaync/configSchema.json";
      positionX = "right";
      positionY = "top";
      cssPriority = "user";

      control-center-width = 450;
      #control-center-height = 860;
      control-center-margin-top = 2;
      control-center-margin-bottom = 2;
      control-center-margin-right = 1;
      control-center-margin-left = 0;

      notification-window-width = 500;
      notification-icon-size = 48;
      notification-body-image-height = 160;
      notification-body-image-width = 200;

      timeout = 4;
      timeout-low = 2;
      timeout-critical = 6;

      fit-to-screen = true;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = false;
      script-fail-notify = true;

      scripts = {
        example-script = {
          exec = "echo 'Do something...'";
          urgency = "Normal";
        };
      };

      notification-visibility = {
        example-name = {
          state = "muted";
          urgency = "Low";
          app-name = "Spotify";
        };
      };

      widgets = [
        "label"
        "buttons-grid"
        "mpris"
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = " 󰎟 ";
        };
        dnd = {
          text = "Do not disturb";
        };
        label = {
          max-lines = 1;
          text = " ";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
        volume = {
          label = "󰕾";
          show-per-app = true;
        };
        buttons-grid = {
          actions = [
            {
              label = " ";
              command = "wpctl set-mute @DEFAULT_SINK@ toggle";
            }
            {
              label = "";
              command = "wpctl set-mute @DEFAULT_SOURCE@ toggle";
            }
            {
              label = " ";
              command = "nm-connection-editor";
            }
            {
              label = "󰂯";
              command = "blueman-manager";
            }
            {
              label = "󰏘";
              command = "nwg-look";
            }
          ];
        };
      };
    };
    #settings = {
    #  schema = "~/.config/swaync/configSchema.json";
    #  positionX = "right";
    #  positionY = "top";
    #  layer = "top";
    #  cssPriority = "application";
    #  control-center-exclusive-zone = false;
    #  control-center-margin-top = 10;
    #  control-center-margin-bottom = 0;
    #  control-center-margin-right = 4;
    #  control-center-margin-left = 0;
    #  notification-icon-size = 48;
    #  notification-body-image-height = 100;
    #  notification-body-image-width = 200;
    #  timeout = 5;
    #  timeout-low = 5;
    #  timeout-critical = 0;
    #  fit-to-screen = true;
    #  control-center-width = 450;
    #  notification-window-width = 500;
    #  keyboard-shortcuts = true;
    #  image-visibility = "when-available";
    #  transition-time = 50;
    #  hide-on-clear = false;
    #  hide-on-action = true;
    #  script-fail-notify = true;
    #  widgets = [
    #    "inhibitors"
    #    "mpris"
    #    "notifications"
    #  ];
    #  widget-config = {
    #    inhibitors = {
    #      text = "Inhibitors";
    #      button-text = "Clear All";
    #      clear-all-button = true;
    #    };
    #    mpris = {
    #      image-size = 64;
    #      image-radius = 12;
    #    };
    #  };
    #};
    style = lib.mkForce ./style.css;
  };
  xdg.configFile = {
  #  "swaync/configSchema.json".source = ./configSchema.json;
    "swaync/notifications.css".source = ./notifications.css;
    #"swaync/colors.css".source = ./colors.css;
    "swaync/central_control.css".source = ./central_control.css;
  };
}

