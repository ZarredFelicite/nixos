{ lib, pkgs, ... }:

let
  # Public paths served at https://sankara.manticore-lenok.ts.net/<name>/
  # via Tailscale Funnel. These intentionally target loopback services directly
  # so they do not depend on router port-forwarding, Cloudflare DNS, or nginx
  # virtual-host matching.
  routes = {
    auth = "http://127.0.0.1:9092";
    gotify = "http://127.0.0.1:80/gotify";
    jellyfin = "http://127.0.0.1:80/jellyfin";
    homarr = "http://127.0.0.1:7575";
    dashdot = "http://127.0.0.1:3001";
    prowlarr = "http://127.0.0.1:9696/prowlarr";
    sonarr = "http://127.0.0.1:8989/sonarr";
    radarr = "http://127.0.0.1:7878/radarr";
    lidarr = "http://127.0.0.1:8686";
    readarr = "http://127.0.0.1:8787/readarr";
    lazylibrarian = "http://127.0.0.1:5299";
    deemix = "http://127.0.0.1:6595";
    transmission = "http://127.0.0.1:9091";
    nzb = "http://127.0.0.1:6789";
    jellyseerr = "http://127.0.0.1:80/jellyseerr";
    audiobookshelf = "http://127.0.0.1:13378";
    pdf = "http://127.0.0.1:8088";
    mainsail = "http://127.0.0.1:8001";
    immich = "http://127.0.0.1:2283";
    hass = "http://127.0.0.1:8123";
    hotcopper = "http://127.0.0.1:8186";
    ocr = "http://127.0.0.1:5498";

    # PHP apps are nginx/php-fpm virtual-host based. These path routes may need
    # app base-url tweaks if the app emits absolute root/subdomain URLs.
    freshrss = "http://127.0.0.1:80/freshrss";
    ttrss = "http://127.0.0.1:80";
  };

  routeCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: target: ''
      ${pkgs.tailscale}/bin/tailscale funnel --bg --yes --https=443 --set-path=/${name} ${target}
    '') routes
  );
in
{
  systemd.services.tailscale-funnel-routes = {
    description = "Expose sankara services through Tailscale Funnel";
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "tailscaled.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.tailscale pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -euo pipefail

      # Keep the declarative config authoritative.
      ${pkgs.tailscale}/bin/tailscale funnel reset || true

      ${routeCommands}

      ${pkgs.tailscale}/bin/tailscale funnel status
    '';

    preStop = ''
      ${pkgs.tailscale}/bin/tailscale funnel reset || true
    '';
  };
}
