{ pkgs, ... }:
let
  tmuxWindowNamePython = pkgs.python3.withPackages (ps: [ ps.libtmux ]);
  tmuxRenamePiWindow = pkgs.writeShellApplication {
    name = "tmux-rename-pi-window";
    text = ''
      target="''${1:-}"
      [ -n "$target" ] || exit 0

      # Run after tmux-window-name's async hook so Pi's terminal title wins.
      sleep 0.3

      cmd="$(${pkgs.tmux}/bin/tmux display-message -p -t "$target" '#{pane_current_command}' 2>/dev/null || true)"
      [ "$cmd" = "pi" ] || exit 0

      title="$(${pkgs.tmux}/bin/tmux display-message -p -t "$target" '#{pane_title}' 2>/dev/null || true)"
      [ -n "$title" ] || exit 0

      ${pkgs.tmux}/bin/tmux rename-window -t "$target" "$title"
    '';
  };
  tmuxWindowName = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-window-name";
    version = "unstable-2026-04-26";
    rtpFilePath = "tmux_window_name.tmux";
    src = pkgs.fetchFromGitHub {
      owner = "ofirgall";
      repo = "tmux-window-name";
      rev = "e98189f9a9487d2cdaa2d207b06780d1f5f58a41";
      hash = "sha256-YI2s/OtywKJQAPpb07dCbWA/6+sWAl+DB+QQbvZOG5k=";
    };
    postInstall = ''
      substituteInPlace "$target/tmux_window_name.tmux" \
        --replace-fail "python -c" "${tmuxWindowNamePython}/bin/python -c"
      patchShebangs "$target/scripts"
      substituteInPlace "$target/scripts/rename_session_windows.py" \
        --replace-fail "#!/usr/bin/env python" "#!${tmuxWindowNamePython}/bin/python"
    '';
  };
in {
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
    baseIndex = 1;  # recommended by tilish plugin
    disableConfirmationPrompt = true;
    escapeTime = 0; # recommended by tilish plugin
    historyLimit = 100000;
    keyMode = "vi";
    prefix = "C-a";
    customPaneNavigationAndResize = false;
    newSession = true;
    terminal = "xterm-256color";
    focusEvents = true;
    tmuxinator.enable = true;
    extraConfig = ''
      set-option -sa terminal-features ',xterm-256color:RGB'
      set-option -ga terminal-overrides ",xterm-256color:Tc"
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -g window-style bg=default
      set -g window-active-style bg=default
      bind r source-file ~/.config/tmux/tmux.conf
      set -g pane-border-format "#P: #{pane_current_command}"
      set -g pane-border-status top
      set-option -g display-time 4000
      set-option -g status-interval 5
      # tmux-window-name owns window naming now. The plugin briefly uses tmux's
      # automatic-rename flag to detect unnamed windows, then disables it per-window.
      # set-option -g automatic-rename on
      # set-option -g automatic-rename off
      # set-option -g automatic-rename-format '#{pane_current_command}'
      # set-option -g detach-on-destroy off

      # Pi sets useful terminal titles; prefer those over tmux-window-name's
      # process/directory naming for Pi windows. The status hook is invisible;
      # it keeps Pi window names synced when Pi updates its session title.
      set-hook -g after-select-window[8922] 'run-shell -b "${tmuxRenamePiWindow}/bin/tmux-rename-pi-window #{window_id}"'
      set-hook -g after-new-window[8922] 'run-shell -b "${tmuxRenamePiWindow}/bin/tmux-rename-pi-window #{window_id}"'
      set -g @rose_pine_status_right_prepend_section '#(${tmuxRenamePiWindow}/bin/tmux-rename-pi-window #{window_id})'

      # Catppuccin status modules were set here after the plugin loaded.
      # set -g status-left-length 100
      # set -g status-right-length 100
      # set -g status-left ""
      # set -g status-right "#{E:@catppuccin_status_application}"
      # set -ag status-right "#{E:@catppuccin_status_session}"
      # set -ag status-right "#{E:@catppuccin_status_host}"

      # Post-theme window list tweaks.
      set -g window-status-current-style 'fg=#ebbcba,bg=#191724'
      set -g window-status-current-format '#I#[fg=#ebbcba,bg=]|#[fg=#ebbcba,bg=]#W'
    '';
    plugins = with pkgs; [
      # { plugin = tmuxPlugins.catppuccin;
      #   # https://github.com/catppuccin/tmux
      #   extraConfig = ''
      #     set -g @catppuccin_flavour 'mocha'
      #     # set -g @catppuccin_status_modules_right "directory application session host"
      #     # set -g @catppuccin_directory_text "#{pane_current_path}"
      #     # set -g @catppuccin_icon_window_last "󰖰"
      #     # set -g @catppuccin_icon_window_current "󰖯"
      #     # set -g @catppuccin_icon_window_zoom "󰁌"
      #     # set -g @catppuccin_icon_window_mark "󰃀"
      #     # set -g @catppuccin_icon_window_silent "󰂛"
      #     # set -g @catppuccin_icon_window_activity "󰖲"
      #     # set -g @catppuccin_icon_window_bell "󰂞"
      #     # set -g @catppuccin_window_default_text "#T"
      #     # set -g @catppuccin_window_current_text "#T"
      #     # set -g @catppuccin_window_right_separator "█ "
      #     # set -g @catppuccin_window_number_position "left"
      #     # set -g @catppuccin_window_middle_separator " | "
      #     # set -g @catppuccin_window_default_fill "none"
      #     # set -g @catppuccin_window_current_fill "all"
      #   '' ;}
      { plugin = tmuxPlugins.rose-pine;
        # https://github.com/rose-pine/tmux
        extraConfig = ''
          set -g @rose_pine_variant 'main'
          set -g @rose_pine_host 'on'
          set -g @rose_pine_user 'on'
          set -g @rose_pine_directory 'on'
          set -g @rose_pine_date_time '%H:%M'
          set -g @rose_pine_disable_active_window_menu 'on'
          set -g @rose_pine_show_current_program 'on'
          set -g @rose_pine_left_separator '|'
        ''; }
      { plugin = tmuxWindowName;
        # https://github.com/ofirgall/tmux-window-name
        # Must load before tmux-resurrect.
        extraConfig = ''
          set -g @tmux_window_name_max_name_len "24"
          set -g @tmux_window_name_icon_style "'name'"
          set -g @tmux_window_name_show_program_args "False"
          set -g @tmux_window_name_dir_programs "['git', 'pi']"
        ''; }
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
          set -g @tilish-default 'main-horizontal'
          set -g @tilish-easymode 'on'
        '';}
      #   -------------------------------------------------
      #   Alt + 0-9 	Switch to workspace number 0-9
      #   Alt + Shift + 0-9 	Move pane to workspace 0-9
      #   Alt + hjkl 	Move focus left/down/up/right
      #   Alt + Shift + hjkl 	Move pane left/down/up/right
      #   Alt + o 	Move focus cyclically
      #   Alt + Shift + o 	Move pane cyclically
      #   Alt + Enter 	Create a new pane at "the end" of the current layout
      #   Alt + s 	Switch to layout: split then vsplit
      #   Alt + Shift + s 	Switch to layout: only split
      #   Alt + v 	Switch to layout: vsplit then split
      #   Alt + Shift + v 	Switch to layout: only vsplit
      #   Alt + t 	Switch to layout: fully tiled
      #   Alt + z 	Switch to layout: zoom (fullscreen)
      #   Alt + r 	Refresh current layout
      #   Alt + n 	Name current workspace
      #   Alt + d 	Application launcher (if enabled)
      #   Alt + p 	Project launcher (if enabled)
      #   Alt + Shift + q 	Quit (close) pane
      #   Alt + Shift + e 	Exit (detach) tmux
      #   Alt + Shift + c 	Reload config
      #   -------------------------------------------------

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
