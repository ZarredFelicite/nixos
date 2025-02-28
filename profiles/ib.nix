{ config, ... }: {
  virtualisation.oci-containers.containers."ibgateway" = {
    image = "ghcr.io/gnzsnz/ib-gateway:latest";
    ports = [ "4003:4001" "4004:4002" "5900:5900" ];
    environment = {
      TWS_USERID = "zarred727";
      TWS_PASSWORD_FILE = config.sops.secrets.ib-gateway.path;
      TRADING_MODE = "live";
      READ_ONLY_API = "yes";
      TZ = "Etc/UTC";
    };
  };
}
