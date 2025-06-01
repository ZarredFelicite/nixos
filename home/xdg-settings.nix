{ pkgs, lib, config, ... }:

{
  xdg = {
    mimeApps = {
      enable = true;
      defaultApplications = {
        "*" = "~/scripts/file-ops/linkhandler.sh";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "x-scheme-handler/omniverse-launcher" = "~/scripts/file-ops/linkhandler.sh";
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
