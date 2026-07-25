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
    hass = "http://127.0.0.1:80/hass";
    ocr = "http://127.0.0.1:80/ocr";
    ember = "http://127.0.0.1:80/ember";
    freshrss = "http://127.0.0.1:80/freshrss";
    ttrss = "http://127.0.0.1:80/ttrss";
  };

  # Private HTTP routes are available only on Sankara's tailnet addresses.
  # Each target includes its mount path because Tailscale replaces the matched
  # Serve prefix with the target URL's path before proxying to nginx.
  privateRoutes = lib.genAttrs [
    "gotify"
    "jellyfin"
    "dashdot"
    "prowlarr"
    "sonarr"
    "radarr"
    "readarr"
    "lazylibrarian"
    "deemix"
    "transmission"
    "nzb"
    "pdf"
    "mainsail"
    "ocr"
    "ember"
    "freshrss"
    "ttrss"
    "searx"
    "syncthing"
    "hotcopper"
    "asr"
  ] (name: "http://127.0.0.1:18080/${name}");

  rootRouteCommand = ''
    ${pkgs.tailscale}/bin/tailscale funnel --bg --yes --https=443 http://127.0.0.1:80
  '';

  # Dedicated root-scoped endpoints for applications that do not support
  # path-prefix hosting. Immich emits root-relative frontend and API paths,
  # so it must not be exposed through /immich.
  tmuxyRouteCommand = ''
    ${pkgs.tailscale}/bin/tailscale funnel --bg --yes --https=8443 http://127.0.0.1:18090
  '';

  immichRouteCommand = ''
    ${pkgs.tailscale}/bin/tailscale funnel --bg --yes --https=9443 http://127.0.0.1:18091
  '';

  routeCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: target: ''
      ${pkgs.tailscale}/bin/tailscale funnel --bg --yes --https=443 --set-path=/${name} ${target}
    '') routes
  );

  privateRootRouteCommand = ''
    ${pkgs.tailscale}/bin/tailscale serve --bg --yes --http=80 --set-path=/ http://127.0.0.1:18080
  '';

  privateRouteCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: target: ''
      ${pkgs.tailscale}/bin/tailscale serve --bg --yes --http=80 --set-path=/${name} ${target}
    '') privateRoutes
  );
in
{
  systemd.services.tailscale-funnel-routes = {
    description = "Configure Sankara Tailscale Funnel and private Serve routes";
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "tailscaled.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.tailscale pkgs.coreutils ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "15s";
    };

    script = ''
      set -euo pipefail

      for attempt in $(seq 1 60); do
        if ${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.gnugrep}/bin/grep -q '"BackendState": "Running"'; then
          break
        fi

        if [ "$attempt" -eq 60 ]; then
          echo "tailscaled did not reach BackendState=Running" >&2
          ${pkgs.tailscale}/bin/tailscale status || true
          exit 1
        fi

        sleep 2
      done

      # Funnel and Serve share one serve-config document. Funnel reset clears
      # both kinds of listeners, so reset exactly once and then restore the
      # unchanged public routes before adding private HTTP routes.
      ${pkgs.tailscale}/bin/tailscale funnel reset || true

      ${rootRouteCommand}
      ${tmuxyRouteCommand}
      ${immichRouteCommand}
      ${routeCommands}
      ${privateRootRouteCommand}
      ${privateRouteCommands}

      ${pkgs.tailscale}/bin/tailscale funnel status
      ${pkgs.tailscale}/bin/tailscale serve status
    '';

    preStop = ''
      ${pkgs.tailscale}/bin/tailscale funnel reset || true
    '';
  };
}
