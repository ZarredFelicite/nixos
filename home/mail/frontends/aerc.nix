{ ... }: {
  accounts.email.accounts.personal.aerc = {
    enable = true;
  };
  programs.aerc = {
    enable = true;
    extraConfig = {
      general.unsafe-accounts-conf = true;
      ui = {
        border-char-vertical = "│";
        border-char-horizontal = "─";
        styleset-name = "catppuccin-mocha";
      };
    };
  };
  xdg.configFile."aerc/stylesets/catppuccin-mocha".source = ./catppuccin-mocha;
}
