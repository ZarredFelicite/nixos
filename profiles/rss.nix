{ pkgs, ... }: {
  #services.postgresql = {
  #  ensureDatabases = [ "tt_rss" ];
  #  identMap = ''
  #    # ArbitraryMapName systemUser DBUser
  #    zarred-user zarred tt_rss
  #    tt_rss-user tt_rss tt_rss
  #  '';
  #  authentication = pkgs.lib.mkOverride 10 ''
  #    #type   database   DBuser  auth-method optional_ident_map
  #    local   sameuser   all     trust
  #    #host    all       all     127.0.0.1/32  ident map=tt_rss
  #    #host    all       all     ::1/128       ident
  #  '';
  #};
  services.tt-rss = {
    pubSubHubbub.enable = false;
    singleUserMode = true;
    virtualHost = "ttrss.zar.red";
    selfUrlPath = "https://ttrss.zar.red/";
    user = "tt_rss";
    plugins = [
      "auth_internal"
      "note"
    ];
    logDestination = "syslog";
  };
  virtualisation.oci-containers.containers."freshrss" = {
    image = "lscr.io/linuxserver/freshrss:latest";
    ports = [ "8880:80" ];
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Etc/UTC";
    };
    volumes = [
      "/var/lib/freshrss:/config"
    ];
  };
}
