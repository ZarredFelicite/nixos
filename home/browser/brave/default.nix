{ pkgs-brave-origin, ... }: {
  programs.chromium = {
    enable = true;
    package = pkgs-brave-origin.brave-origin;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      { id = "noimedcjdohhokijigpfcbjcfcaaahej"; } # ublock origin
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # ublock origin
    ];
  };
}
