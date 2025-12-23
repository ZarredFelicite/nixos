{ pkgs, ... }: {
  #xdg.configFile.".config/nnn/plugins/previewer" = { source = ./nnn-previewer; executable = true; };
  programs.nnn = {
    package = pkgs.nnn.override ({ withNerdIcons = true; });
    extraPackages = [ pkgs.mediainfo pkgs.ffmpegthumbnailer ];
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
    };
  };
  home.sessionVariables = {
    NNN_OPENER = "/home/zarred/scripts/file-ops/linkhandler.sh";
    NNN_FCOLORS = "$BLK$CHR$DIR$EXE$REG$HARDLINK$SYMLINK$MISSING$ORPHAN$FIFO$SOCK$OTHER";
    NNN_TRASH = 1;
    NNN_FIFO = "/tmp/nnn.fifo";
  };
}
