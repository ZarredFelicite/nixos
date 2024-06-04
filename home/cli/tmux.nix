{ pkgs, fetchFromGithub, ... }: {
  stylix.targets.tmux.enable = false;
  xdg.configFile."tmuxinator/home.yml".text = builtins.toJSON {
    name = "home";
    root = "~/";
    windows = [
      { newsboat = "newsboat"; }
      { neomutt = "neomutt"; }
      { tickrs = "tickrs"; }
      { ticker = "ticker"; }
    ];
  };
  programs.tmux = {
    mouse = true;
    aggressiveResize = true;
    baseIndex = 1;
    disableConfirmationPrompt = true;
    escapeTime = 0;
    historyLimit = 100000;
    keyMode = "vi";
    prefix = "C-a";
    customPaneNavigationAndResize = false;
    newSession = true;
    terminal = "xterm-256color";
    sensibleOnTop = true;
    tmuxinator.enable = true;
    extraConfig = ''
      bind r source-file ~/.config/tmux/tmux.conf
      set -g pane-border-format "#P: #{pane_current_command}"
      set -g pane-border-status top
      set-option -g status-interval 5
      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{b:pane_current_path}'
      set-option -g detach-on-destroy off
    '';
    plugins = with pkgs; [
      { plugin = tmuxPlugins.catppuccin;
        # https://github.com/catppuccin/tmux
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
          set -g @catppuccin_status_modules_right "directory application session host"
          set -g @catppuccin_directory_text "#{pane_current_path}"
          set -g @catppuccin_icon_window_last "󰖰"
          set -g @catppuccin_icon_window_current "󰖯"
          set -g @catppuccin_icon_window_zoom "󰁌"
          set -g @catppuccin_icon_window_mark "󰃀"
          set -g @catppuccin_icon_window_silent "󰂛"
          set -g @catppuccin_icon_window_activity "󰖲"
          set -g @catppuccin_icon_window_bell "󰂞"
          set -g @catppuccin_window_default_text "#W"
          set -g @catppuccin_window_current_text "#W"
          set -g @catppuccin_window_right_separator "█ "
          set -g @catppuccin_window_number_position "left"
          set -g @catppuccin_window_middle_separator " | "
          set -g @catppuccin_window_default_fill "none"
          set -g @catppuccin_window_current_fill "all"
        '' ;}
      tmuxPlugins.cpu
      { plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-save 'S'
          set -g @resurrect-restore 'R' ''; }
      { plugin = tmuxPlugins.continuum;
        extraConfig = " set -g @continuum-restore 'on' "; }
      { plugin = tmuxPlugins.yank;
        extraConfig = "set -g @yank_selection 'primary'"; }
      { plugin = tmuxPlugins.tmux-fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="C-f"
          TMUX_FZF_MENU=\
          "foo\necho 'Hello!'\n"\
          "bar\nls ~\n"\
          "sh\nsh ~/test.sh\n"
        ''; }
      { plugin = tmuxPlugins.tilish;
      # https://github.com/jabirali/tmux-tilish
        extraConfig = ''
          set -g @tilish-default 'main-vertical'
          set -g @tilish-easymode 'on'
        ''; }
      #{ plugin = tmuxPlugins.vim-tmux-navigator;
      #  extraConfig = ''
      #    # Smart pane switching with awareness of Vim splits.
      #    # See: https://github.com/christoomey/vim-tmux-navigator
      #    is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      #        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
      #    bind-key -n 'C-n' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      #    bind-key -n 'C-e' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      #    bind-key -n 'C-i' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      #    bind-key -n 'C-o' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      #    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      #    if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
      #        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      #    if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
      #        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      #    bind-key -T copy-mode-vi 'C-h' select-pane -L
      #    bind-key -T copy-mode-vi 'C-j' select-pane -D
      #    bind-key -T copy-mode-vi 'C-k' select-pane -U
      #    bind-key -T copy-mode-vi 'C-l' select-pane -R
      #    bind-key -T copy-mode-vi 'C-\' select-pane -l
      #  ''; }
    ];
  };
}
