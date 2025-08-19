{ pkgs, lib, ... }: {
  gtk = {
    enable = true;
    #gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    #gtk3.extraConfig = {
      #gtk-decoration-layout = "menu:";
      #gtk-xft-antialias = 1;
      #gtk-xft-hinting = 1;
      #gtk-xft-hintstyle = "hintfull";
      #gtk-xft-rgba = "rgb";
      #gtk-recent-files-enabled = false;
    #};
    #iconTheme = {
    #  #name = "Papirus-Dark";
    #  #package = pkgs.papirus-icon-theme;
    #  name = "Suru++-Asprómauros";
    #  package = ( pkgs.callPackage ../../pkgs/suru-plus-aspromauros {} );
    #};
  };
}
