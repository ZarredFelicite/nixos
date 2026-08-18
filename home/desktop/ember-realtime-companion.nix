{ config, lib, pkgs, ... }:
let
  # Web-only local source. Keeping this out of the top-level flake inputs lets
  # other hosts (notably sankara) evaluate without the Ember checkout.
  companionFlake = builtins.getFlake "path:/home/zarred/dev/ember/companion";
  companion = companionFlake.packages.${pkgs.system}.default;
  clientId = "web-desktop";
  companionGatewayUrl = "ws://127.0.0.1:4311/ws/desktop-realtime";
  emberPublicBaseUrl = "wss://web.manticore-lenok.ts.net/ws/desktop-realtime";
  serverAllowPlainLoopbackWsEnabled = true;
  companionAllowPlainLoopbackWsEnabled = true;
  credentialFile = "~/.config/ember/realtime-companion/credential";
  credentialName = "gateway-credential";
  desktopRealtimeConfig = builtins.toJSON {
    enabled = true;
    wssPath = "/ws/desktop-realtime";
    # Keep the browser-facing endpoint on the existing authenticated TLS route;
    # only the same-host native companion uses plaintext loopback.
    publicBaseUrl = emberPublicBaseUrl;
    allowClientIds = [ clientId ];
    pairingStore = "realtime/companions.json";
    allowPlainLoopbackWs = serverAllowPlainLoopbackWsEnabled;
    trustedProxyAddresses = [ "127.0.0.1" "192.168.8.200" ];
  };
  pairCommand = pkgs.writeShellApplication {
    name = "ember-realtime-companion-pair";
    runtimeInputs = [ companion ];
    text = ''
      exec ${lib.getExe' companion "ember-realtime-companion"} \
        --config "$HOME/.config/ember/realtime-companion.toml" pair
    '';
  };
in
{
  assertions = [
    {
      assertion = companionGatewayUrl == "ws://127.0.0.1:4311/ws/desktop-realtime";
      message = "Ember companion gateway must remain the authenticated same-host loopback WebSocket";
    }
    {
      assertion = emberPublicBaseUrl == "wss://web.manticore-lenok.ts.net/ws/desktop-realtime";
      message = "Ember browser-facing desktop realtime endpoint must remain the existing TLS URL";
    }
    {
      assertion = serverAllowPlainLoopbackWsEnabled;
      message = "Ember server plaintext WebSocket allowance must be explicitly enabled for loopback control";
    }
    {
      assertion = companionAllowPlainLoopbackWsEnabled;
      message = "Ember companion TOML must explicitly allow plaintext loopback WebSocket control";
    }
    {
      assertion = credentialFile == "~/.config/ember/realtime-companion/credential" && credentialName == "gateway-credential";
      message = "Ember companion credential source/name must remain unchanged";
    }
  ];

  home.packages = [ companion pairCommand ];

  # This file contains no credentials. The companion creates the referenced
  # credential file only after an explicit stdin-based pairing exchange.
  xdg.configFile."ember/realtime-companion.toml" = {
    text = ''
      version = 1
      client_id = "${clientId}"
      gateway_url = "${companionGatewayUrl}"
      allow_plain_loopback_ws = ${if companionAllowPlainLoopbackWsEnabled then "true" else "false"}
      credential_file = "${credentialFile}"
      credential_name = "${credentialName}"
      auto_start = false
      start_muted = false

      [input]
      device_id = "default"

      [output]
      device_id = "default"

      [ice]
      stun_urls = []
      turn_url = ""
      turn_username = ""
      turn_password_credential = ""
      policy = "all"
      gather_timeout_ms = 10000
      connection_timeout_ms = 15000

      [audio]
      channels = 1
      preferred_rate = 48000
      opus_bitrate = 24000
      opus_frame_ms = 20
      noise_suppression = "off"
      aec = "disabled"

      [limits]
      max_frame_bytes = 524288
      max_inventory_devices = 128
      heartbeat_interval_ms = 15000
      reconnect_initial_ms = 1000
      reconnect_max_ms = 30000
    '';
  };

  systemd.user.services.ember-realtime-companion = {
    Unit = {
      Description = "Ember native Realtime desktop companion";
      After = [
        "network-online.target"
        "pipewire.service"
        "pipewire-pulse.service"
        "ember.service"
      ];
      Wants = [ "network-online.target" "pipewire.service" "ember.service" ];
      StartLimitIntervalSec = "60s";
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      # Keep the source credential path out of the runtime: systemd loads it
      # into its private credentials directory, and the CLI gets only that
      # path override (never the credential contents).
      ExecStart = "${lib.getExe' companion "ember-realtime-companion"} --config %h/.config/ember/realtime-companion.toml run --credential-file \${CREDENTIALS_DIRECTORY}/gateway-credential";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "10s";
      UMask = "0077";
      Environment = [
        "RUST_LOG=ember_realtime_companion=info"
        "XDG_RUNTIME_DIR=%t"
      ];
      LoadCredential = "gateway-credential:%h/.config/ember/realtime-companion/credential";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      StateDirectory = "ember-realtime-companion";
      StateDirectoryMode = "0700";
      ReadWritePaths = [ "%h/.local/state/ember-realtime-companion" ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
      LockPersonality = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
    };
    # This web host is paired explicitly during deployment; reconnect on the
    # next user session without ever auto-starting a media call.
    Install.WantedBy = [ "default.target" ];
  };

  # Merge only the gateway feature into Ember's existing mutable config. This
  # preserves provider, heartbeat, memory, and browser-Realtime settings while
  # keeping the non-secret desktop policy declarative.
  home.activation.emberDesktopRealtimeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ember"
    config_file="$HOME/.ember/config.json"
    temp_file="$(mktemp "$HOME/.ember/config.json.XXXXXX")"
    trap 'rm -f "$temp_file"' EXIT

    web_api_token=""
    if [ -e "$config_file" ]; then
      web_api_token="$(${pkgs.jq}/bin/jq -r \
        'if (.webApiToken | type == "string" and length >= 32 and length <= 512) then .webApiToken else empty end' \
        "$config_file")"
    fi
    if [ -z "$web_api_token" ]; then
      web_api_token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
    fi

    if [ -e "$config_file" ]; then
      ${pkgs.jq}/bin/jq \
        --arg webApiToken "$web_api_token" \
        --argjson desktop '${desktopRealtimeConfig}' \
        '.webApiToken = $webApiToken | .realtime = ((.realtime // {}) + {desktop: $desktop})' \
        "$config_file" > "$temp_file"
    else
      ${pkgs.jq}/bin/jq -n \
        --arg webApiToken "$web_api_token" \
        --argjson desktop '${desktopRealtimeConfig}' \
        '{webApiToken: $webApiToken, realtime: {desktop: $desktop}}' > "$temp_file"
    fi

    chmod 600 "$temp_file"
    if [ ! -e "$config_file" ] || ! cmp -s "$temp_file" "$config_file"; then
      mv -f "$temp_file" "$config_file"
    else
      rm -f "$temp_file"
    fi
    trap - EXIT
  '';
}
