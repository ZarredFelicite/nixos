{ pkgs, ... }: {
  users.users.media = {
    isSystemUser = true;
    group = "media";
  };
  users.groups.media = {};
  services.jellyfin = {
    user = "media";
    group = "users";
  };
  services.jellyseerr = {
    port = 5055;
  };
  services.radarr = {
    user = "media";
    group = "users";
    dataDir = "/var/lib/radarr";
  };
  services.sonarr = {
    user = "media";
    group = "users";
    dataDir = "/var/lib/sonarr";
  };
  services.readarr = {
    user = "media";
    group = "users";
    dataDir = "/var/lib/readarr";
  };
  virtualisation.oci-containers.containers."lidarr" = {
    image = "youegraillot/lidarr-on-steroids";
    ports = [
      "8686:8686" # Lidarr web UI
      "6595:6595" # Deemix web UI
    ];
    extraOptions = ["--network=host"];
    volumes = [
      "/var/lib/lidarr/config/Lidarr:/config"
      "/var/lib/deemix/config:/config_deemix"
      "/mnt/gargantua/downloads/deemix:/downloads"
      "/mnt/gargantua/media/music:/music"
    ];
  };
  virtualisation.oci-containers.containers."lazylibrarian" = {
    image = "lscr.io/linuxserver/lazylibrarian:latest";
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Etc/UTC";
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    ports = [
      "5299:5299" # web UI
    ];
    extraOptions = ["--network=host"];
    volumes = [
      "/var/lib/lazylibrarian:/config"
      "/mnt/gargantua/downloads:/downloads"
      "/mnt/gargantua/media/books:/books"
    ];
  };
  services.mpd = {
    startWhenNeeded = false;
    network.port = 6600;
    dataDir = "/mnt/gargantua/media/music/data";
    musicDirectory = "/mnt/gargantua/media/music";
    playlistDirectory = "/mnt/gargantua/media/music/playlists";
    dbFile = "/mnt/gargantua/media/music/data/mpd.db";
    group = "users";
  };
  virtualisation.oci-containers.containers."audiobookshelf" = {
    autoStart = true;
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    environment = {
      AUDIOBOOKSHELF_UID = "99";
      AUDIOBOOKSHELF_GID = "100";
    };
    ports = [ "13378:80" ];
    volumes = [
      "/mnt/gargantua/media/books/audiobooks:/audiobooks"
      "/var/lib/audiobookshelf/config:/config"
      "/var/lib/audiobookshelf/audiobooks:/metadata"
    ];
  };
  services.prowlarr = {
  };
  services.nzbget = {
    user = "media";
    group = "users";
    settings = {
      MainDir = "/mnt/gargantua/downloads/nzb";
      InterDir = "/mnt/gargantua/downloads/nzb/incomplete";
      DestDir = "/mnt/gargantua/downloads/nzb/complete";
      TempDir = "/mnt/gargantua/downloads/nzb/tmp";
      QueueDir = "/mnt/gargantua/downloads/nzb/queue";
      NzbDir = "/mnt/gargantua/downloads/nzb/nzb";
    };
  };
  services.transmission = {
    package = pkgs.transmission_4;
    openRPCPort = true;
    user = "media";
    group = "users";
    settings = {
      message-level = 3;
      download-dir = "/mnt/gargantua/downloads/torrents/complete" ;
      incomplete-dir-enabled = true;
      incomplete-dir = "/mnt/gargantua/downloads/torrents/incomplete" ;
      watch-dir-enabled = true;
      watch-dir = "/mnt/gargantua/downloads/torrents/watchdir" ;
      trash-original-torrent-files = true;
      script-torrent-done-enabled = false;
      script-torrent-done-filename = null;
      peer-port = 51413;
      # ip announce
      announce-ip-enabled = false;
      # bandwidth
      speed-limit-down-enabled = false;
      speed-limit-up-enabled = false;
      alt-speed-enabled = false;
      alt-speed-time-enabled = false;
      upload-slots-per-torrent = 14;
      # blocklist
      blocklist-enabled = false;
      # files
      rename-partial-files = true;
      start-added-torrents = true;
      #trash-original-torrent-files = false;
      # umask = 022;
      # misc
      cache-size-mb = 4;
      dht-enabled = true;
      encryption = 1;
      lpd-enabled = false;
      pex-enabled = true;
      scrape-paused-torrents-enabled = true;
      script-torrent-added-enabled = false;
      script-torrent-added-filename = "";
      #script-torrent-done-enabled = false;
      #script-torrent-done-filename = "";
      script-torrent-done-seeding-enabled = false;
      script-torrent-done-seeding-filename = "";
      tcp-enabled = true;
      torrent-added-verify-mode = "fast";
      utp-enabled = true;
      # queue
      download-queue-enabled = true;
      download-queue-size = 50;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;
      seed-queue-enabled = false;
      seed-queue-size = 10;
      # RPC
      rpc-port = 9091;
      rpc-bind-address = "0.0.0.0";
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.* 192.168.*.*";
      rpc-authentication-required = false;
      anti-brute-force-enabled = true;
      anti-brute-force-threshold = 50;
      # scheduling
      idle-seeding-limit = 30;
      idle-seeding-limit-enabled = false;
      ratio-limit = 1.5;
      ratio-limit-enabled = true;
    };
    #downloadDirPermissions = "770";
    #performanceNetParameters = false;
  };
}
