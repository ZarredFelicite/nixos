{ lib, ... }: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      # Rosé Pine Main: https://rosepinetheme.com/palette
      "bg" = lib.mkForce "#191724";
      "bg+" = lib.mkForce "#26233a";
      "fg" = lib.mkForce "#e0def4";
      "fg+" = lib.mkForce "#e0def4";
      "hl" = lib.mkForce "#ebbcba";
      "hl+" = lib.mkForce "#ebbcba";
      "border" = lib.mkForce "#403d52";
      "gutter" = lib.mkForce "#191724";
      "header" = lib.mkForce "#9ccfd8";
      "info" = lib.mkForce "#6e6a86";
      "marker" = lib.mkForce "#f6c177";
      "pointer" = lib.mkForce "#eb6f92";
      "prompt" = lib.mkForce "#c4a7e7";
      "spinner" = lib.mkForce "#f6c177";
      "scrollbar" = lib.mkForce "#6e6a86";
    };
    defaultCommand = "fd --type file --no-ignore";
    defaultOptions = [
      "--layout reverse"
      #"--border"
      "--info inline"
      "--no-separator"
      "--cycle"
      "--scroll-off 10"
      "--pointer '⏽'"
      "--marker '󰧟'"
      "--prompt '  '"
      "--gutter ' '"
      "--ansi"
      "-m"
      "--bind='ctrl-a:toggle-all,ctrl-j:replace-query,ctrl-p:change-preview-window(right,70%|down,40%|hidden),change:top'"
    ];
    fileWidgetCommand = "fd --type f";
    fileWidgetOptions = [ "--preview 'head {}'" ];
    historyWidgetOptions = [ "--sort" "--exact" ];
    tmux.enableShellIntegration = true;
  };
}
