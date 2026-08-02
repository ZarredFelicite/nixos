{ pkgs, ... }:

{
  # Lightweight tools and portable CLI defaults shared by the desktop/server
  # profiles and the ARM-safe ROCK profile. Host-specific services, SSH hosts,
  # signing policy, and secret loading stay out of this module.
  home.packages = with pkgs; [
    fd
    jq
    ripgrep
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "ZarredFelicite";
      user.email = "zarred.f@gmail.com";
      core.editor = "nvim";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = true;
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
      features = "decorations interactive";
      syntax-theme = "ansi";
      minus-style = "red";
      plus-style = "green";
      zero-style = "normal";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
      whitespace-error-style = "22 reverse";
      line-numbers = true;
    };
  };

  programs.gh = {
    enable = true;
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
      updates.auto_update = true;
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
