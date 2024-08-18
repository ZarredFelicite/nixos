{ pkgs, config, ... }: {
  services.authelia.instances.primary = {
    user = "zarred";
    secrets.jwtSecretFile = config.sops.secrets.authelia-jwtSecret.path;
    secrets.storageEncryptionKeyFile = config.sops.secrets.authelia-storageEncryptionKey.path;
    settings = {
      theme = "dark";
      telemetry.metrics.enabled = false;
      server.address = "tcp://127.0.0.1:9092";
      #server.address = "tcp://:9092/";
      #default_redirection_url = "https://google.com";
      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = ["auth.zar.red"];
            policy = "bypass";
          }
          {
            domain = ["*.zar.red"];
            policy = "one_factor";
          }
        ];
      };
      authentication_backend = {
        file = {
          path = "/var/lib/authelia-primary/users_database.yml";
        };
      };
      session = {
        name = "authelia_session";
        expiration = "12h";
        inactivity = "45m";
        remember_me_duration = "1M";
        domain = "zar.red";
      };
      storage = {
        local = {
          path = "/var/lib/authelia-primary/db.sqlite3";
        };
      };
      notifier = {
        disable_startup_check = false;
        filesystem = {
          filename = "/var/lib/authelia-primary/notification.txt";
        };
      };
    };
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "zarred.f@gmail.com";
  };
  services.nginx = {
    package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
    logError = "stderr debug";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    statusPage = true; # reachable from localhost on http://127.0.0.1/nginx_status
    commonHttpConfig = ''
      map $http_upgrade $connection_upgrade {
          default      keep-alive;
          'websocket'  upgrade;
          '''           close;
      }
    '';
    appendHttpConfig = ''
      proxy_cache_path /tmp/pkgcache levels=1:2 keys_zone=cachecache:100m max_size=20g inactive=365d use_temp_path=off;
      map $status $cache_header {
        200     "public";
        302     "public";
        default "no-cache";
      }
      access_log /var/log/nginx/access.log;
    '';
    virtualHosts =
      let SSLA = {
        enableACME = true;
        forceSSL = true;
        sslTrustedCertificate = "/etc/ssl/certs/ca-bundle.crt";
        extraConfig = ''
          location /authelia {
            internal;
            set $upstream_authelia http://127.0.0.1:9092/api/verify;
            proxy_pass_request_body off;
            proxy_pass $upstream_authelia;
            proxy_set_header Content-Length "";

            # Timeout if the real server is dead
            proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

            # [REQUIRED] Needed by Authelia to check authorizations of the resource.
            # Provide either X-Original-URL and X-Forwarded-Proto or
            # X-Forwarded-Proto, X-Forwarded-Host and X-Forwarded-Uri or both.
            # Those headers will be used by Authelia to deduce the target url of the     user.
            # Basic Proxy Config
            client_body_buffer_size 128k;
            proxy_set_header Host $host;
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
            proxy_set_header X-Forwarded-Uri $request_uri;
            proxy_set_header X-Forwarded-Ssl on;
            proxy_redirect  http://  $scheme://;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_cache_bypass $cookie_session;
            proxy_no_cache $cookie_session;
            proxy_buffers 4 32k;

            # Advanced Proxy Config
            send_timeout 5m;
            proxy_read_timeout 240;
            proxy_send_timeout 240;
            proxy_connect_timeout 240;
          }
        '';
      };
      SSL = {
        enableACME = true;
        forceSSL = true;
        sslTrustedCertificate = "/etc/ssl/certs/ca-bundle.crt";
      };
      AUTH = {
        extraConfig = ''
          auth_request /authelia;
          auth_request_set $target_url $scheme://$http_host$request_uri;
          auth_request_set $user $upstream_http_remote_user;
          auth_request_set $groups $upstream_http_remote_groups;
          auth_request_set $name $upstream_http_remote_name;
          auth_request_set $email $upstream_http_remote_email;
          proxy_set_header Remote-User $user;
          proxy_set_header Remote-Groups $groups;
          proxy_set_header Remote-Name $name;
          proxy_set_header Remote-Email $email;
          error_page 401 =302 https://auth.zar.red/?rd=$target_url;
        '';
      };
      in {
        # NON AUTH
        "auth.zar.red" = SSL//{locations."/".proxyPass = "http://127.0.0.1:9092"; locations."/".proxyWebsockets = true;};
        "jellyfin.zar.red" = SSL//{locations."/" = {proxyPass = "http://127.0.0.1:8096";};};
        # AUTH
        "nextcloud.zar.red" = SSLA//{locations."= /" = AUTH;};
        "gotify.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8081"; proxyWebsockets = true;};}; #TODO remove auth if not working with app
        "homarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:7575";};};
        "ttrss.zar.red" = SSLA//{locations."/" = AUTH;};
        "dashdot.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:3001";};};
        "prowlarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:9696";};};
        "sonarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8989";};};
        "radarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:7878";};};
        "lidarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8686";};};
        "readarr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8787";};};
        "lazylibrarian.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:5299";};};
        "deemix.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:6595";};};
        "transmission.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:9091"; proxyWebsockets = true;};};
        "nzb.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:6789"; proxyWebsockets = true;};};
        "jellyseerr.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:5055";};};
        "audiobookshelf.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:13378";};};
        "pdf.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8088";};};
        "mainsail.zar.red" = SSLA//{locations."/" = AUTH//{proxyPass = "http://127.0.0.1:8001"; proxyWebsockets = true;};};
        #"headscale.zar.red" = SSL//{
        #  locations."/" = {
        #    proxyPass = "http://127.0.0.1:8080";
        #    proxyWebsockets = true;
        #    recommendedProxySettings = false;
        #    extraConfig = ''
        #      proxy_set_header Host $server_name;
        #      proxy_redirect http:// https://;
        #      proxy_buffering off;
        #      proxy_set_header X-Real-IP $remote_addr;
        #      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #      proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        #      add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
        #    '';
        #  };
        #};
        #"syncthing.zar.red" = SSLA // {
        #  locations."/web" = AUTH // {proxyPass = "http://192.168.86.150:8384";};
        #  locations."/sankara" = AUTH // {proxyPass = "http://localhost:8384";};
        #  locations."/nano" = AUTH // {proxyPass = "http://192.168.86.125:8384";};
        #};
        #"binarycache.zar.red" = { locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}"; };
        #"nixcache.zar.red" = {
        #  locations."/" = {
        #    root = "/var/public-nix-cache";
        #    extraConfig = ''
        #      expires max;
        #      add_header Cache-Control $cache_header always;
        #      # Ask the upstream server if a file isn't available locally
        #      error_page 404 = @fallback;
        #    '';
        #  };
        #  extraConfig = ''
        #    resolver 10.42.42.42;
        #    set $upstream_endpoint http://cache.nixos.org;
        #  '';
        #  locations."@fallback" = {
        #    proxyPass = "$upstream_endpoint";
        #    extraConfig = ''
        #      proxy_cache cachecache;
        #      proxy_cache_valid  200 302  60d;
        #      expires max;
        #      add_header Cache-Control $cache_header always;
        #    '';
        #  };
        #  locations."= /nix-cache-info" = {
        #    # Note: This is duplicated with the `@fallback` above,
        #    # would be nicer if we could redirect to the @fallback instead.
        #    proxyPass = "$upstream_endpoint";
        #    extraConfig = ''
        #      proxy_cache cachecache;
        #      proxy_cache_valid  200 302  60d;
        #      expires max;
        #      add_header Cache-Control $cache_header always;
        #    '';
        #  };
        #};
    };
  };
}
