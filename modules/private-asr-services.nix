{ config, lib, pkgs, ... }:
let
  cfg = config.services.privateAsr;
  source = builtins.fetchGit {
    url = cfg.sourceRepository;
    rev = cfg.sourceRevision;
  };
  packagedServiceVersion = lib.removeSuffix "\n" (builtins.readFile "${source}/SERVICE_VERSION");
  servicePackage = pkgs.callPackage ../pkgs/asr-services.nix {
    src = source;
    sourceRevision = cfg.sourceRevision;
    serviceVersion = cfg.serviceVersion;
    nemotronPython = "${cfg.nemotronEnvironmentRoot}/bin/python";
    parakeetPython = "${cfg.parakeetEnvironmentRoot}/bin/python";
    nemotronEnvironmentMarker = "${cfg.nemotronEnvironmentRoot}/ASR_ENVIRONMENT";
    parakeetEnvironmentMarker = "${cfg.parakeetEnvironmentRoot}/ASR_ENVIRONMENT";
  };
  cachePath = "/var/cache/private-asr-models";
  commonEnvironment = {
    HF_HOME = "${cachePath}/huggingface";
    HUGGINGFACE_HUB_CACHE = "${cachePath}/huggingface/hub";
    TORCH_HOME = "${cachePath}/torch";
    XDG_CACHE_HOME = cachePath;
    HF_HUB_DISABLE_XET = "1";
    PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True";
    PYTHONDONTWRITEBYTECODE = "1";
  };
  authTokenFile = if cfg.auth.enable then "%d/asr-auth-token" else "";
  authCredential = lib.optional cfg.auth.enable
    "asr-auth-token:${config.sops.secrets.${cfg.auth.sopsSecretName}.path}";
  authArguments = if cfg.auth.enable then [
    "--auth-token-file"
    authTokenFile
  ] else [ "--disable-auth" ];
  healthArguments = [
    "${servicePackage}/bin/check-asr-health"
    "--url"
    "http://${cfg.bindAddress}:5001/health"
  ] ++ lib.optionals cfg.auth.enable [
    "--auth-token-file"
    authTokenFile
  ];
  commonHardening = {
    User = "zarred";
    Group = "users";
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = "read-only";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    CacheDirectory = "private-asr-models";
    CacheDirectoryMode = "0750";
    ReadWritePaths = [ cachePath ];
    ReadOnlyPaths = [ "${servicePackage}/libexec/private-asr-services" ];
    InaccessiblePaths = [ cfg.sourceRepository ];
    Restart = "on-failure";
    RestartSec = "5s";
    TimeoutStopSec = "20s";
    UMask = "0077";
  };
in
{
  options.services.privateAsr = {
    enable = lib.mkEnableOption "pinned private Nemotron and Parakeet ASR services";
    sourceRepository = lib.mkOption {
      type = lib.types.str;
      default = "/home/zarred/dev/parakeet-transcriber";
      description = "Local Git object database used only at Nix evaluation/build time.";
    };
    sourceRevision = lib.mkOption {
      type = lib.types.str;
      description = "Exact committed ASR source revision copied into the Nix store.";
    };
    serviceVersion = lib.mkOption {
      type = lib.types.str;
      description = "Expected SERVICE_VERSION marker embedded in the pinned source.";
    };
    bindAddress = lib.mkOption {
      type = lib.types.str;
      description = "Explicit private interface address; wildcard addresses are rejected.";
    };
    allowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Mandatory private CIDR allowlist for TCP and HTTP clients.";
    };
    nemotronEnvironmentRoot = lib.mkOption {
      type = lib.types.str;
      description = "Read-only pre-provisioned Nemotron Python environment root.";
    };
    parakeetEnvironmentRoot = lib.mkOption {
      type = lib.types.str;
      description = "Read-only pre-provisioned Parakeet Python environment root.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Pinned Nix-store ASR service package.";
    };
    auth = {
      enable = lib.mkEnableOption "SOPS-backed bearer authentication for Nemotron TCP and public batch HTTP";
      sopsSecretName = lib.mkOption {
        type = lib.types.str;
        default = "private-asr-auth-token";
        description = "SOPS key declared only when authentication is explicitly enabled.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.match "[0-9a-f]{40}" cfg.sourceRevision != null;
        message = "services.privateAsr.sourceRevision must be an exact 40-character Git revision";
      }
      {
        assertion = packagedServiceVersion == cfg.serviceVersion;
        message = "Pinned ASR source SERVICE_VERSION does not match services.privateAsr.serviceVersion";
      }
      {
        assertion = cfg.bindAddress != "0.0.0.0" && cfg.bindAddress != "::" && cfg.bindAddress != "[::]";
        message = "Private ASR services must bind an explicit private interface";
      }
      {
        assertion = cfg.allowedNetworks != [];
        message = "Private ASR services require a non-empty CIDR allowlist";
      }
      {
        assertion = !cfg.auth.enable || cfg.auth.sopsSecretName != "";
        message = "Private ASR authentication requires a SOPS secret name";
      }
    ];

    sops.secrets = lib.mkIf cfg.auth.enable {
      ${cfg.auth.sopsSecretName} = {
        owner = "zarred";
        group = "users";
        mode = "0400";
        # systemd credentials are immutable snapshots. A future SOPS rotation
        # refreshes them by restarting both units; direct token-file users pick
        # up rotations per HTTP request/new TCP connection without a restart.
        restartUnits = [
          "nemotron-asr.service"
          "parakeet-batch.service"
        ];
      };
    };

    services.privateAsr.package = servicePackage;
    environment.systemPackages = [ servicePackage ];

    systemd.services.parakeet-batch = {
      description = "Pinned internal Parakeet TDT batch ASR worker";
      after = [ "network.target" "nemotron-asr.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = commonEnvironment;
      serviceConfig = commonHardening // {
        WorkingDirectory = "${servicePackage}/libexec/private-asr-services";
        RuntimeDirectory = "parakeet-batch";
        ReadOnlyPaths = commonHardening.ReadOnlyPaths ++ [ cfg.parakeetEnvironmentRoot ];
        LoadCredential = authCredential;
        ExecStartPre = [
          "${servicePackage}/bin/check-parakeet-asr-environment"
          (lib.escapeShellArgs healthArguments)
        ];
        ExecStart = lib.escapeShellArgs ([
          "${servicePackage}/bin/parakeet-batch-service"
          "--listen" "127.0.0.1:5003"
          "--segment-length" "60"
          "--chunk-overlap" "2"
          "--wait-timeout" "30"
          "--media-timeout" "600"
          "--max-media-duration" "1800"
          "--max-upload-bytes" "104857600"
          "--request-timeout" "900"
          "--max-requests" "2"
          "--disable-auth"
        ]);
      };
    };

    systemd.services.nemotron-asr = {
      description = "Pinned private Nemotron streaming and hybrid ASR gateway";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = commonEnvironment;
      serviceConfig = commonHardening // {
        WorkingDirectory = "${servicePackage}/libexec/private-asr-services";
        RuntimeDirectory = "nemotron-asr";
        ReadOnlyPaths = commonHardening.ReadOnlyPaths ++ [ cfg.nemotronEnvironmentRoot ];
        LoadCredential = authCredential;
        ExecStartPre = "${servicePackage}/bin/check-nemotron-asr-environment";
        ExecStart = lib.escapeShellArgs (([
          "${servicePackage}/bin/nemotron-asr-service"
          "--listen" "${cfg.bindAddress}:5002"
          "--http-listen" "${cfg.bindAddress}:5001"
        ] ++ lib.concatMap (network: [ "--allow-network" network ]) cfg.allowedNetworks ++ [
          "--batch-backend-url" "http://127.0.0.1:5003"
          "--lookahead-tokens" "0"
          "--device" "auto"
          "--dtype" "auto"
          "--max-clients" "8"
          "--max-message-bytes" "65536"
          "--max-audio-frame-bytes" "32000"
          "--max-stream-duration" "300"
          "--audio-queue-capacity" "64"
          "--client-idle-timeout" "30"
          "--session-idle-timeout" "15"
          "--cleanup-timeout" "10"
          "--media-timeout" "600"
          "--max-media-duration" "1800"
          "--max-upload-bytes" "104857600"
          "--request-timeout" "900"
          "--max-http-requests" "2"
          "--max-receive-concurrency" "4"
        ] ++ authArguments));
      };
    };
  };
}
