{ pkgs, ... }:
{
  imports = [
    ../shared/core.nix
    ../shared/starship.nix
    ../shared/tmux.nix
    ../shared/nixvim
  ];

  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "25.11";
    packages = with pkgs; [
      btop
      dnsutils
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
    git.settings.init.defaultBranch = "main";

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
