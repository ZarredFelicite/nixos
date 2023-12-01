{ pkgs, ... }: {
  #xdg.configFile.".config/nnn/plugins/previewer" = { source = ./nnn-previewer; executable = true; };
  programs.nnn = {
    package = pkgs.nnn.override ({ withNerdIcons = true; });
    extraPackages = [ pkgs.ffmpegthumbnailer pkgs.mediainfo ];
    plugins = {
      mappings = {
        #f = "finder";
        #o = "fzopen";
        #v = "imgview";
        p = "nnn-previewer";
        #s = "-!printf $PWD/$nnn|wl-copy*";
        #d = "";
      };
      src = ./plugins;
      #src = (pkgs.fetchFromGitHub {
      #  owner = "jarun";
      #  repo = "nnn";
      #  rev = "v4.0";
      #  sha256 = "sha256-Hpc8YaJeAzJoEi7aJ6DntH2VLkoR6ToP6tPYn3llR7k=";
      #}) + "/plugins";
    };
  };
  home.sessionVariables = {
    NNN_OPENER = "/home/zarred/scripts/file-ops/linkhandler.sh";
    NNN_FCOLORS = "$BLK$CHR$DIR$EXE$REG$HARDLINK$SYMLINK$MISSING$ORPHAN$FIFO$SOCK$OTHER";
    NNN_TRASH = 1;
    NNN_FIFO = "/tmp/nnn.fifo";
  };
}
