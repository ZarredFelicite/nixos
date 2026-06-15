{ lib, pkgs, ... }:

let
  # Public paths served at https://sankara.manticore-lenok.ts.net/<name>/
  # via Tailscale Funnel. Funnel always targets nginx; nginx owns per-app
  # headers, redirects, cookies, rewrites, and backend routing.
  routes = {
    auth = "http://127.0.0.1:80/auth";
    gotify = "http://127.0.0.1:80/gotify";
    jellyfin = "http://127.0.0.1:80/jellyfin";
    homarr = "http://127.0.0.1:80/homarr";
    dashdot = "http://127.0.0.1:80/dashdot";
    prowlarr = "http://127.0.0.1:80/prowlarr";
    sonarr = "http://127.0.0.1:80/sonarr";
    radarr = "http://127.0.0.1:80/radarr";
    lidarr = "http://127.0.0.1:80/lidarr";
    readarr = "http://127.0.0.1:80/readarr";
    lazylibrarian = "http://127.0.0.1:80/lazylibrarian";
    deemix = "http://127.0.0.1:80/deemix";
    transmission = "http://127.0.0.1:80/transmission";
    nzb = "http://127.0.0.1:80/nzb";
    jellyseerr = "http://127.0.0.1:80/jellyseerr";
    audiobookshelf = "http://127.0.0.1:80/audiobookshelf";
    pdf = "http://127.0.0.1:80/pdf";
    mainsail = "http://127.0.0.1:80/mainsail";
    immich = "http://127.0.0.1:80/immich";
    hass = "http://127.0.0.1:80/hass";
    ocr = "http://127.0.0.1:80/ocr";
    freshrss = "http://127.0.0.1:80/freshrss";
    ttrss = "http://127.0.0.1:80/ttrss";
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
