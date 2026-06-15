{ pkgs, ... }: let
  funnelHost = "sankara.manticore-lenok.ts.net";
  phpSubpathProxy = path: host: {
    proxyPass = "https://127.0.0.1/";
    recommendedProxySettings = false;
    extraConfig = ''
      auth_request /authelia;
      auth_request_set $target_url https://$http_host$request_uri;
      auth_request_set $user $upstream_http_remote_user;
      auth_request_set $groups $upstream_http_remote_groups;
      auth_request_set $name $upstream_http_remote_name;
      auth_request_set $email $upstream_http_remote_email;
      proxy_set_header Remote-User $user;
      proxy_set_header Remote-Groups $groups;
      proxy_set_header Remote-Name $name;
      proxy_set_header Remote-Email $email;
      error_page 401 =302 https://$http_host/?rd=$target_url;
      proxy_ssl_verify off;
      proxy_set_header Host ${host};
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Proto https;
      proxy_redirect http://$host/${path}/ https://$host/${path}/;
      proxy_redirect http://$host/ https://$host/${path}/;
      proxy_redirect / /${path}/;
      proxy_cookie_path /i/ /${path}/i/;
      proxy_cookie_path / /${path}/;
      sub_filter_once off;
      sub_filter_types text/html text/css application/javascript;
      sub_filter 'href="/' 'href="/${path}/';
      sub_filter 'src="/' 'src="/${path}/';
      sub_filter 'action="/' 'action="/${path}/';
      sub_filter 'url(/' 'url(/${path}/';
    '';
  };
  freshrssSubpathProxy = phpSubpathProxy "freshrss" "freshrss.zar.red";
  ttrssSubpathProxy = phpSubpathProxy "ttrss" "ttrss.zar.red";
in {
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
    locations."/freshrss/" = freshrssSubpathProxy;
    locations."= /freshrss".extraConfig = ''
      return 302 /freshrss/;
    '';
  };
  services.nginx.virtualHosts.${funnelHost} = {
    locations."/freshrss/" = freshrssSubpathProxy;
    locations."= /freshrss".extraConfig = ''
      return 302 /freshrss/;
    '';
    locations."/ttrss/" = ttrssSubpathProxy;
    locations."= /ttrss".extraConfig = ''
      return 302 /ttrss/;
    '';
  };
}
