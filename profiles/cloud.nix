{ pkgs, config, ... }: {
  services.nextcloud = {
    package = pkgs.nextcloud29;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = config.services.nextcloud.home;
    settings = {
      trusted_domains = [ "localhost" ];
    };
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
    };
    database.createLocally = true;
  };
}
