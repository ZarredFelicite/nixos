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
  services.freshrss = {
    enable = true;
    package = pkgs.freshrss;
    virtualHost = "freshrss.zar.red";
    baseUrl = "https://freshrss.zar.red";
    passwordFile = "/run/secrets/freshrss";
    defaultUser = "admin";
    authType = "form";
    #api.enable = true;
    extensions = with pkgs.freshrss-extensions; [
      reddit-image
    ] ++ [
      (pkgs.freshrss-extensions.buildFreshRssExtension {
        FreshRssExtUniqueId = "ArticleSummary";
        pname = "ArticleSummary";
        version = "1.0";
        src = pkgs.fetchFromGitHub {
          owner = "LiangWei88";
          repo = "xExtension-ArticleSummary";
          rev = "b1e83a67fc24d5686309444b773ad84d15889270";
          hash = "sha256-2XJgIE+4t9/Cs1AdVBbc1hFyjxpI/WXj6vLtFw4tXoc=";
       };
      })
    ];
  };
  services.nginx.virtualHosts."freshrss.zar.red" = {
    enableACME = true;
    forceSSL = true;
    sslTrustedCertificate = "/etc/ssl/certs/ca-bundle.crt";
  };
}
