{ self, pkgs, inputs, outputs, config, ... }: {
  imports = [
    ../profiles/common.nix
    ../containers/docker.nix
    ../profiles/media-server.nix
    ../profiles/server-management.nix
    ../profiles/rss.nix
    ../profiles/nginx.nix
    ../profiles/cloud.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs outputs; };
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
  services.mpd.enable = true;
  services.jellyfin.enable = true;
  services.jellyseerr.enable = true;
  services.radarr.enable = true;
  services.sonarr.enable = true;
  services.prowlarr.enable = true;
  services.transmission.enable = true;
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
