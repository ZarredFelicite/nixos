{ ... }:
{
  imports = [ ./tools.nix ./desktop ];

  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "25.11";
  };
}
