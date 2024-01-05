{ pkgs, config, ... }: {
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = config.services.nextcloud.home;
    extraOptions.trusted_domains = [ "localhost" ];
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
    };
    database.createLocally = true;
  };
}
