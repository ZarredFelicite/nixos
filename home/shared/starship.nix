{ ... }:

{
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
      python.symbol = " ";
      python.format = "[\${symbol}\${pyenv_prefix}(\${version} )(\($virtualenv\) )]($style)";
      git_branch.format = "[$symbol$branch(:$remote_branch)]($style)";
    };
  };
}
