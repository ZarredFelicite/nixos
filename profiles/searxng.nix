{ config, ... }:
{
  sops.secrets.searxng-secret = {
    owner = "searx";
    group = "searx";
  };

  sops.templates."searxng.env" = {
    content = ''
      SEARXNG_SECRET=${config.sops.placeholder.searxng-secret}
      BRAVE_API_KEY=${config.sops.placeholder.brave-api}
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
        base_url = "http://sankara/searx/";
      };
      search = {
        formats = [
          "html"
          "json"
        ];
        suspended_times = {
          SearxEngineAccessDenied = 3600;
          SearxEngineCaptcha = 21600;
          SearxEngineTooManyRequests = 900;
        };
      };
      outgoing.retries = 0;
      engines = [
        {
          name = "brave";
          disabled = true;
        }
        {
          name = "braveapi";
          engine = "braveapi";
          shortcut = "bapi";
          api_key = "$BRAVE_API_KEY";
          results_per_page = 20;
          inactive = false;
          retries = 0;
        }
        {
          name = "google";
          disabled = true;
        }
      ];
    };
  };
}
