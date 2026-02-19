{ config, lib, inputs, ... }: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [];
    # NOTE:Prevents pure eval
    templates."gotify-cli.json" = {
      content = ''
        {
          "token": "${config.sops.placeholder.gotify-app-web-token}",
          "url": "https://gotify.zar.red",
          "defaultPriority": 6
        }
      '';
      owner = "zarred";
    };
    templates."gotify-desktop-config.toml" = {
      content = ''
        [gotify]
        url = "wss://gotify.zar.red"
        token = "${config.sops.placeholder.gotify-client-web-token}"
        auto_delete = false  # optional, if true, deletes messages that have been handled, defaults to false
        [notification]
        min_priority = 1  # optional, ignores messages with priority lower than given value
        [action]
        # optional, run the given command for each message, with the following environment variables set: GOTIFY_MSG_PRIORITY, GOTIFY_MSG_TITLE and GOTIFY_MSG_TEXT.
        #on_msg_command = "/usr/bin/beep"
      '';
      owner = "zarred";
    };
    secrets = lib.mkMerge [
      (lib.mkIf (config.networking.hostName == "sankara") {
        nextcloud-admin = { owner = "nextcloud"; };
        immich-secrets = { sopsFile = ../secrets/immich.enc.env; format = "dotenv"; owner = "immich"; };
      })
      {
        users-zarred.neededForUsers = true;
        users-root.neededForUsers = true;
        gmail-personal = { owner = "zarred"; };
        restic-home = { owner = "zarred"; };
        gotify-client-web-token = { owner = "zarred"; };
        gotify-app-web-token = { owner = "zarred"; };
        twitch-oauth = {};
        cloudflare-api-token = {};
        ib-gateway = { owner = "zarred"; };
        ib-gateway-vnc = { owner = "zarred"; };
        syncthing-api = { owner = "zarred"; };
        syncthing-gui = { owner = "zarred"; };
        transmission-rpc = { owner = "zarred"; };
        jellyfin-zarred = { owner = "zarred"; };
        freshrss = { owner = "zarred"; };
        twitch-api-token = {
          sopsFile = ../secrets/twitch-api-token.json;
          format = "binary";
          owner = "zarred";
          #path = "/home/zarred/.config/wtwitch/api.json";
        };
        #github-api-token = {
        #  sopsFile = ../secrets/github-hosts.yaml;
        #  format = "binary";
        #  owner = "zarred";
        #  path = "/home/zarred/.config/gh/hosts.yml";
        #};
        binary-cache-key = {};
        #nixremote-private = { owner = config.users.users.zarred.name; group = config.users.users.zarred.group; mode = "0440";};
        nixremote-private = { };
        openai-api = { owner = "zarred"; };
        gemini-api = { owner = "zarred"; };
        openrouter-api = { owner = "zarred"; };
        elevenlabs-api = { owner = "zarred"; };
        openclaw-token = { owner = "zarred"; };
        nixAccessTokens = { mode = "0440"; group = config.users.groups.keys.name; };
        authelia-jwtSecret = { owner = "zarred"; };
        authelia-storageEncryptionKey = { owner = "zarred"; };
        freshrss-api = { owner = "zarred"; };
        firecrawl-api = { owner = "zarred"; };
        opencode-api = { owner = "zarred"; };
      }
    ];
  };
}
