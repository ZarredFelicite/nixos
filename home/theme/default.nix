{ pkgs, lib, ... }: {
  #xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
  #  [General]
  #  theme=Catppuccin-Mocha-Compact-Mauve-dark
  #'';
  gtk = {
    enable = true;
    #gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    #theme = lib.mkDefault {
    #  name = "Catppuccin-Mocha-Compact-Mauve-dark";
    #  package = pkgs.catppuccin-gtk.override {
    #    accents = [ "mauve" ];
    #    size = "compact";
    #    variant = "mocha";
    #    tweaks = [ "rimless" ];
    #  };
    #};
    gtk3.extraConfig = {
      gtk-decoration-layout = "menu:";
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintfull";
      gtk-xft-rgba = "rgb";
      gtk-recent-files-enabled = false;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
  #qt = {
  #  enable = lib.mkForce false;
  #  style.name = "kvantum-dark";
  #};
}
