{ config, lib, pkgs, ... }:
let
  cfg = config.services.privateAsr;
  allowedPrivateCidr = import ./private-asr-cidr.nix { inherit lib; };
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
  healthArguments = [
    "${servicePackage}/bin/check-asr-health"
    "--url"
    "http://${cfg.bindAddress}:5001/health"
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
        assertion = builtins.match "100[.](6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])[.][0-9]+[.][0-9]+" cfg.bindAddress != null;
        message = "Credential-free private ASR services must bind an explicit Tailnet address, never a wildcard or public interface";
      }
      {
        assertion = cfg.allowedNetworks != [] && lib.all allowedPrivateCidr cfg.allowedNetworks;
        message = "Every private ASR allowed network must be a bounded loopback, RFC1918, link-local, ULA, or Tailnet CIDR";
      }
    ];

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
        ]));
      };
    };
  };
}
