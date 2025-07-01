{ lib, ... }: {
  programs.kitty = {
    shellIntegration.enableZshIntegration = true;
    settings = {
      enable_audio_bell = false;
      close_on_child_death = true;
      allow_remote_control = "socket";
      listen_on = "unix:/tmp/kitty";
      window_padding_width = 3;
      background_image_layout = "cscaled";
      background_tint = 0.0;
      dynamic_background_opacity = true;
      share_connections = true;
      enabled_layouts = "vertical,tall,grid";
    };
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
      "ctrl+alt+enter" = "launch --cwd=current";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+e" = "open_url_with_hints";
      "ctrl+shift+p>f" = "kitten hints --type path --program -";
      "ctrl+shift+p>shift+f" = "kitten hints --type path";
    };
    extraConfig = ''
      color8 #555169
    '';
  };
  programs.foot = {
    server.enable = true;
    settings = {
      main.term = "xterm-256color";
      main.pad = "2x3";
      #main.font = lib.mkForce "Hack Nerd Font Mono:size=14";
      scrollback.lines = 5000;
      colors.alpha = lib.mkForce 0.2;
      mouse.hide-when-typing = "yes";
      cursor.style = "beam";
    };
  };
  #stylix.targets.ghostty.enable = false;
  programs.ghostty = {
    enableZshIntegration = true;
    installBatSyntax = true;
    settings = {
      gtk-single-instance = true;
      #font-feature = [ "-calt" "-liga" "-dlig" ];
      adjust-cell-width = "-15%";
      adjust-cell-height = "-10%";
      background-opacity = 0;
      window-decoration = false;
      #keybind = [
      #  "ctrl+h=goto_split:left"
      #  "ctrl+l=goto_split:right"
      #];
      clipboard-trim-trailing-spaces = true;
    };
  };
}
