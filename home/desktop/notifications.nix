{ pkgs, lib, ... }: {
  services.mako = {
    actions = true;
    anchor = "top-right";
    backgroundColor = lib.mkForce "#19172480";
    borderColor = lib.mkForce "#9ccfd8";
    textColor = lib.mkForce "#e0def4";
    borderRadius = 10;
    borderSize = 2;
    defaultTimeout = 5000;
    format = "%s\\n%b";
    groupBy = null;
    height = 200;
    width = 300;
    icons = true;
    layer = "overlay";
    margin = "4";
    markup = true;
    maxIconSize = 64;
    maxVisible = 6;
    padding = "4";
    progressColor = lib.mkForce "over #26233a";
  };
}
