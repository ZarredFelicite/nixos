{ pkgs, lib, config, ... }:

{
  xdg = {
    desktopEntries.linkhandler = {
      name = "Link Handler";
      genericName = "File Opener";
      exec = "/home/zarred/scripts/file-ops/linkhandler.sh %U";
      terminal = false;
      mimeType = [
        "inode/directory"
        "application/pdf"
        "text/html"
        "text/plain"
        "text/xml"
        "text/csv"
        "text/markdown"
        "application/json"
        "application/x-yaml"
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/tiff"
        "image/bmp"
        "image/svg+xml"
        "audio/mpeg"
        "audio/mp4"
        "audio/ogg"
        "audio/flac"
        "audio/wav"
        "audio/x-wav"
        "video/mp4"
        "video/mpeg"
        "video/webm"
        "video/x-matroska"
        "video/quicktime"
        "application/zip"
        "application/x-tar"
        "application/gzip"
        "application/x-bzip2"
        "application/vnd.rar"
        "model/stl"
        "application/vnd.sqlite3"
        "application/x-sqlite3"
        "application/x-mpegurl"
        "application/vnd.apple.mpegurl"
        "application/x-bittorrent"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/omniverse-launcher"
      ];
      categories = [ "Utility" ];
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "linkhandler.desktop";
        "application/pdf" = "linkhandler.desktop";
        "text/html" = "linkhandler.desktop";
        "text/plain" = "linkhandler.desktop";
        "text/xml" = "linkhandler.desktop";
        "text/csv" = "linkhandler.desktop";
        "text/markdown" = "linkhandler.desktop";
        "application/json" = "linkhandler.desktop";
        "application/x-yaml" = "linkhandler.desktop";
        "image/png" = "linkhandler.desktop";
        "image/jpeg" = "linkhandler.desktop";
        "image/gif" = "linkhandler.desktop";
        "image/webp" = "linkhandler.desktop";
        "image/tiff" = "linkhandler.desktop";
        "image/bmp" = "linkhandler.desktop";
        "image/svg+xml" = "linkhandler.desktop";
        "audio/mpeg" = "linkhandler.desktop";
        "audio/mp4" = "linkhandler.desktop";
        "audio/ogg" = "linkhandler.desktop";
        "audio/flac" = "linkhandler.desktop";
        "audio/wav" = "linkhandler.desktop";
        "audio/x-wav" = "linkhandler.desktop";
        "video/mp4" = "linkhandler.desktop";
        "video/mpeg" = "linkhandler.desktop";
        "video/webm" = "linkhandler.desktop";
        "video/x-matroska" = "linkhandler.desktop";
        "video/quicktime" = "linkhandler.desktop";
        "application/zip" = "linkhandler.desktop";
        "application/x-tar" = "linkhandler.desktop";
        "application/gzip" = "linkhandler.desktop";
        "application/x-bzip2" = "linkhandler.desktop";
        "application/vnd.rar" = "linkhandler.desktop";
        "model/stl" = "linkhandler.desktop";
        "application/vnd.sqlite3" = "linkhandler.desktop";
        "application/x-sqlite3" = "linkhandler.desktop";
        "application/x-mpegurl" = "linkhandler.desktop";
        "application/vnd.apple.mpegurl" = "linkhandler.desktop";
        "application/x-bittorrent" = "linkhandler.desktop";
        "x-scheme-handler/http" = "linkhandler.desktop";
        "x-scheme-handler/https" = "linkhandler.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "x-scheme-handler/omniverse-launcher" = "linkhandler.desktop";
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
