{ self, pkgs, pkgs-unstable, lib, inputs, outputs, config, ... }: {
  imports = [
    ../profiles/common.nix
    ../profiles/media-server.nix
    ../profiles/server-management.nix
    ../profiles/rss.nix
    ../profiles/nginx.nix
    ../profiles/cloud.nix
    ../profiles/printer.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs outputs pkgs-unstable; };
    users.zarred = import ../home/core.nix;
  };
  #environment.systemPackages = [
  #  pkgs.mergerfs
  #  pkgs.mergerfs-tools
  #  pkgs.headscale
  #];
  #networking.firewall.allowedTCPPorts = [ 2049 80 443 6600 22 ];
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.postgresql.enable = true;

  services.tt-rss.enable = true;
  services.gotify.enable = true;
  services.klipper.enable = true;
  services.mjpg-streamer.enable = false; #TODO enable for 3d printer monitoring

  services.mpd.enable = true;
  services.jellyfin.enable = true;
  services.jellyseerr.enable = true;
  services.radarr.enable = true;
  services.sonarr.enable = true;
  services.readarr.enable = true;
  services.prowlarr.enable = true;
  services.transmission.enable = true;
  services.nzbget.enable = true;

  services.nextcloud.enable = true;

  services.authelia.instances.primary.enable = true;
  services.nginx.enable = true;
  services.headscale = {
    enable = false;
    #address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "http://127.0.0.1:8080";
      #tls_cert_path = "/var/lib/acme/headscale.zar.red/cert.pem";
      #tls_key_path = "/var/lib/acme/headscale.zar.red/key.pem";
      #dns_config.base_domain = "zar.red";
    };
  };
}
