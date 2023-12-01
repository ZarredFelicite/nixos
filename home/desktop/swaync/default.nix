{ ... }: {
  xdg.configFile = {
    "swaync/config.json".source = ./config.json;
    "swaync/style.css".source = ./style.css;
    "swaync/configSchema.json".source = ./configSchema.json;
  };
}

