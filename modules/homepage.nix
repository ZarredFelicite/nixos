{ pkgs, ... }:
let
  homepage-settings = pkgs.writeTextFile {
    name = "settings.yaml";
    executable = false;
    destination = "/var/lib/private/homepage-dashboard/settings.yaml";
    text = ''
    ---
    headerStyle: boxed
    layout:
      Media:
        style: row
        columns: 2
      Network:
        style: row
        columns: 2
    '';
  };
  homepage-widgets = pkgs.writeTextFile {
    name = "widgets.yaml";
    executable = false;
    destination = "/var/lib/private/homepage-dashboard/widgets.yaml";
    text = ''
    ---
    # For configuration options and examples, please see:
    # https://gethomepage.dev/en/configs/widgets

    - resources:
        cpu: true
          #cputemp: true
        memory: true
          #uptime: true
        units: metric
    - resources:
        label: Mass
        disk: /mnt/mass
    - resources:
        label: Turing
        disk: /mnt/turing
    - resources:
        label: Evo
        disk: /mnt/evo
    - resources:
        label: Linus
        disk: /mnt/linus
    '';
  };
  homepage-services = pkgs.writeTextFile {
    name = "services.yaml";
    executable = false;
    destination = "/var/lib/private/homepage-dashboard/services.yaml";
    text = ''
      ---
      # For configuration options and examples, please see:
      # https://gethomepage.dev/en/configs/services
      - Media:
          - Sonarr:
              icon: sonarr.png
              href: https://sonarr.zar.red
              description: Shows
              container: sonarr
              widget:
                type: sonarr
                url: https://sonarr.zar.red
      #    - Radarr:
      #        icon: radarr.png
      #        href: https://radarr.zar.red
      #        description: Movies
      #        container: radarr
      #        widget:
      #          type: radarr
      #          url: https://radarr.zar.red
      #    - Prowlarr:
      #        icon: prowlarr.png
      #        href: https://prowlarr.zar.red
      #        description: Indexers
      #        container: prowlarr
      #        widget:
      #          type: prowlarr
      #          url: https://prowlarr.zar.red
      #    - AudioBookShelf:
      #        icon: audiobookshelf.png
      #        href: https://audiobookshelf.zar.red
      #        container: audiobookshelf
      #        widget:
      #          type: audiobookshelf
      #          url: https://audiobookshelf.zar.red
      #    - Jellyfin:
      #        icon: jellyfin.png
      #        href: https://jellyfin.zar.red
      #        description: Jellyfin
      #        container: jellyfin
      #        widget:
      #          type: jellyfin
      #          url: https://jellyfin.zar.red
      #          enableBlocks: true
      #          enableNowPlaying: true
      #    - JellySeerr:
      #        icon: jellyseerr.png
      #        href: jellyseerr.zar.red
      #        container: jellyseerr
      #        widget:
      #          type: jellyseerr
      #          url: http://jellyseerr.zar.red
      #    - Transmission:
      #        icon: transmission.png
      #        href: https://transmission.zar.red
      #        container: transmission
      #        widget:
      #          type: transmission
      #          url: https://transmission.zar.red
      #- Network:
      #    - Gotify:
      #        icon: gotify.png
      #        href: https://gotify.zar.red
      #        container: gotify
      #        widget:
      #          type: gotify
      #          url: https://gotify.zar.red
   #  #     - Tailscale:
   #  #         icon: tailscale.png
   #  #         href: https://login.tailscale.com
   #  # - RSS:
   #  #     - FreshRSS:
   #  #         icon: freshrss.png
   #  #         href: https://freshrss.zar.red
   #  #         widget:
   #  #           type: freshrss
   #  #           url: https://freshrss.zar.red
   #  #           username: zarred
      #- 3D-Print:
      #  #- OctoPrint:
      #  #      icon: octoprint.png
      #  #      href: https://octoprint.zar.red
      #  #      widget:
      #  #        type: octoprint
      #  #        url: https://octoprint.zar.red
      #    - Mainsail:
      #        icon: moonraker.png
      #        href: https://mainsail.zar.red
      #        widget:
      #          type: moonraker
      #          url: https://mainsail.zar.red
  '';
};
in {
  environment.systemPackages = [
    homepage-settings
    homepage-services
    homepage-widgets
  ];
}
