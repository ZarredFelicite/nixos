{ pkgs, ... }: {
  home.packages = [ pkgs.nb ];
  xdg.configFile = {
    "nb/nbrc".text = ''
      #!/usr/bin/env bash

      export NB_DIR="/home/zarred/notes"
      export NB_HEADER=0
      export NB_SYNTAX_THEME=Dracula
      export NBRC_PATH="$HOME/.config/nb/nbrc"
      export EDITOR=/usr/bin/nvim
      export NB_FOOTER=0
      export NB_INDICATOR_AUDIO=" "
      export NB_INDICATOR_BOOKMARK=" "
      export NB_INDICATOR_DOCUMENT="󰈙 "
      export NB_INDICATOR_EBOOK=" "
      export NB_INDICATOR_ENCRYPTED="🔒"
      export NB_INDICATOR_FOLDER=" "
      export NB_INDICATOR_IMAGE=" "
      export NB_INDICATOR_PINNED=" "
      export NB_INDICATOR_TODO="󰄱 "
      export NB_INDICATOR_TODO_DONE="󰡖 "
      export NB_INDICATOR_VIDEO=" "
      export NB_COLOR_THEME="utility"
      export NB_COLOR_PRIMARY="223"
      export NB_COLOR_SECONDARY="12"
      export EDITOR="nvim"
      export NB_LIMIT="auto"
      export NB_MARKDOWN_TOOL="glow"
    '';
  };
}
