{ config, ... }:
{
  sops.secrets.searxng-secret = {
    owner = "searx";
    group = "searx";
  };

  sops.templates."searxng.env" = {
    content = ''
      SEARXNG_SECRET=${config.sops.placeholder.searxng-secret}
    '';
    owner = "searx";
    group = "searx";
    mode = "0400";
  };

  services.searx = {
    enable = true;
    environmentFile = config.sops.templates."searxng.env".path;
    settings = {
      server = {
        bind_address = "0.0.0.0";
        port = 8888;
      };
      search.formats = [
        "html"
        "json"
      ];
    };
  };
}
