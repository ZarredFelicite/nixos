{ pkgs, ... }: {
  home.packages = [ pkgs.ueberzugpp ];
  xdg.configFile."ueberzugpp/config.json".text = builtins.toJSON {
    layer = {
      silent = true;
      "use-escape-codes" = false;
      "no-stdin" = false;
      output = "kitty";
    };
  };
}
