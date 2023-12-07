{ pkgs, lib, ... }: {
  services.mako = {
    actions = true;
    anchor = "top-right";
    backgroundColor = lib.mkForce "#19172480";
    borderColor = lib.mkForce "#9ccfd880";
    textColor = lib.mkForce "#e0def4";
    borderRadius = 12;
    borderSize = 1;
    defaultTimeout = 5000;
    format = "<b>%s</b>\\n%b";
    groupBy = null;
    height = 1000;
    width = 500;
    icons = true;
    layer = "overlay";
    margin = "4";
    markup = true;
    maxIconSize = 64;
    maxVisible = 6;
    padding = "4";
    progressColor = lib.mkForce "over #26233a";
    extraConfig = ''
      outer-margin=4
    '';
  };
}
