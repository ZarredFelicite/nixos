{ ... }: {
  programs.coolercontrol.enable = true;
  #environment.etc."coolercontrol/config.toml".source = ./config.toml;
  #environment.etc."coolercontrol/config-ui.json".source = ./config-ui.json;
  #environment.etc."coolercontrol/modes.json".source = ./modes.json;
}
