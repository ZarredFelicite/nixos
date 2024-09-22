{ pkgs, config, ... }: {
  services.nextcloud = {
    package = pkgs.nextcloud29;
    hostName = "nextcloud.zar.red";
    https = true;
    home = "/var/lib/nextcloud";
    datadir = "/mnt/gargantua/nextcloud";
    settings = {
      trusted_domains = [ "localhost" ];
    };
    config = {
      adminpassFile = config.sops.secrets.nextcloud-admin.path;
    };
    database.createLocally = true;
  };
}
