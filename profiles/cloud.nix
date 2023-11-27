{ pkgs, config, ... }: {
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud27;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = config.services.nextcloud.home;
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
      extraTrustedDomains = [ "localhost" ];
    };
    database.createLocally = true;
  };
}
