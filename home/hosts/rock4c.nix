{ pkgs, ... }:
{
  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "25.11";
    packages = with pkgs; [
      btop
      dnsutils
      fd
      jq
      ripgrep
      tree
      unzip
      zip
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less -FR";
    };
  };

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = "ZarredFelicite";
          email = "zarred.f@gmail.com";
        };
        core.editor = "nvim";
        init.defaultBranch = "main";
      };
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";
      historyLimit = 50000;
      extraConfig = ''
        set -g focus-events on
        set -g set-clipboard on
      '';
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        path = "$HOME/.local/state/zsh/history";
        save = 50000;
        size = 50000;
        share = true;
      };
      shellAliases = {
        ll = "ls -lah";
        la = "ls -A";
        gs = "git status --short --branch";
        rebuild = "sudo nixos-rebuild switch --flake /home/zarred/dots#rock4c";
      };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
      };
    };

    bat.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
