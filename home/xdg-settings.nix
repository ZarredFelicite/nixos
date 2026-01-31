{ pkgs, lib, config, ... }:

{
  xdg = {
    desktopEntries.linkhandler = {
      name = "Link Handler";
      genericName = "File Opener";
      exec = "/home/zarred/scripts/file-ops/linkhandler.sh %U";
      terminal = false;
      categories = [ "Utility" ];
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "*" = "linkhandler.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "x-scheme-handler/omniverse-launcher" = "linkhandler.desktop";
        "image/png" = "linkhandler.desktop";
        "image/jpeg" = "linkhandler.desktop";
        "image/gif" = "linkhandler.desktop";
        "image/webp" = "linkhandler.desktop";
      };
      associations.added = {
        "application/pdf" = "zathura.desktop";
        "application/octet-stream" = "nvim.desktop";
        "text/xml" = [
          "nvim.desktop"
          "codium.desktop"
        ];
        "x-scheme-handler/https" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "image/png" = "firefox.desktop;swappy.desktop;satty.desktop;swayimg.desktop;pqiv.desktop";
      };
    };
    userDirs = {
      enable = false;
      createDirectories = true;
      desktop = null;
      templates = null;
      publicShare = null;
      download = "/home/zarred/downloads";
      documents = "/home/zarred/documents";
      pictures = "/home/zarred/pictures";
      videos = "/home/zarred/videos";
    };
  };
}
