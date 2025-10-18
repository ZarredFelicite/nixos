{ pkgs, lib, config, ... }:

{
  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "24.11";

    sessionVariables = {
      OPENAI_API_KEY = "$(${pkgs.pass}/bin/pass dev/openai-api)";
      OPENROUTER_API_KEY = "$(${pkgs.pass}/bin/pass dev/openrouter-api)";
      GEMINI_API_KEY = "$(${pkgs.pass}/bin/pass google/gemini_api)";
      #EDITOR = "nvim";
      #MANPAGER = "bat -l man -p'";
      #PAGER = "bat";
    };

    # A few truly core packages. Most packages will be in other profiles.
    packages = with pkgs; [
      fd # A simple, fast and user-friendly alternative to find
      ripgrep # recursively searches directories for a regex pattern
      jq # A lightweight and flexible command-line JSON processor
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "ZarredFelicite";
    userEmail = "zarred.f@gmail.com";
    signing = {
      format = "openpgp";
      key = "0xD276AC444633E146";
      signByDefault = true;
    };
    extraConfig = {
      core = {
        editor ="nvim";
      };
    };
    delta = {
      # https://dandavison.github.io/delta/introduction.html
      enable = true;
      options = {
        dark = true;
        hyperlinks = true; # makes file paths clickable in the terminal
        hyperlinks-file-link-format = "vscode://file/{path}:{line}"; # opens links in vscode
        features = "decorations interactive";
        #interactive = {
        #  keep-plus-minus-markers = false;
        #};
        minus-style = "red bold ul \"#ffeeee\"";
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
        whitespace-error-style = "22 reverse";
        #side-by-side = true;
        line-numbers = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    #controlMaster = "yes";
    #controlPersist = "30m";
    userKnownHostsFile = "~/.ssh/known_hosts";
    addKeysToAgent = "yes";
    matchBlocks = {
      rpicam = {
        hostname = "rpicam";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "export TERM=xterm-256color; tmux new -A -s rpicam";
        };
      };
      rpi = {
        hostname = "10.131.3.83";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s horus";
        };
      };
      tmux-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s sankara_remote";
        };
      };
      home-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmuxinator home";
        };
      };
      tmux-web = {
        hostname = "web";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s web_remote";
        };
      };
    };
  };

  programs.gh = {
    enable = true;
    #gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      version = "1";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
      package.disabled = true;
      nix_shell.format = "$symbol ";
      nix_shell.symbol = "";
      #nix_shell.disabled = true;
      python.symbol = " ";
      python.format = "[\${symbol}\${pyenv_prefix}(\${version} )(\($virtualenv\) )]($style)";
      git_branch.format = "[$symbol$branch(:$remote_branch)]($style)";
    };
  };

  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      color = "always";
      decorations = "always";
      italic-text = "always";
    };
  };

  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = true;
        use_pager = false;
      };
      updates = {
        auto_update = true;
      };
    };
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        insert_final_newline = true;
        indent_size = 2;
        indent_style = "space";
        trim_trailing_whitespace = true;
      };
      "*.md" = {
        indent_style = "tab";
        trim_trailing_whitespace = false;
      };
      "Makefile" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.html" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.go" = {
        indent_style = "tab";
        indent_size = 4;
      };
      "*.rs" = {
        indent_style = "space";
        indent_size = 4;
      };
    };
  };

  xdg.configFile."/home/zarred/.jq".text = ''
    def pad_left($len; $chr):
        (tostring | length) as $l
        | "\($chr * ([$len - $l, 0] | max) // "")\(.)"
        ;
    def pad_left($len):
        pad_left($len; " ")
        ;
    def pad_right($len; $chr):
        (tostring | length) as $l
        | "\(.)\($chr * ([$len - $l, 0] | max) // "")"
        ;
    def pad_right($len):
        pad_right($len; " ")
        ;
  '';
}
