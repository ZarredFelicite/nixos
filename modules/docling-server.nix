# NixOS systemd service for docling-server
# Runs as your user account
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.docling-server;
in
{
  options.services.docling-server = {
    enable = mkEnableOption "docling-server document processing service";

    port = mkOption {
      type = types.port;
      default = 5001;
      description = "Port to listen on";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.docling-server = {
      description = "Docling Serve - Document Processing API";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = "/home/zarred/dev/ocr/docling/docling-server";
        ExecStart = "${pkgs.nix}/bin/nix-shell /home/zarred/dev/ocr/docling/docling-server/shell.nix --run '.venv/bin/docling-serve run --host 127.0.0.1 --port ${toString cfg.port} --enable-ui'";
        
        Restart = "on-failure";
        RestartSec = "5s";
      };

      environment = {
        HF_HOME = "/home/zarred/.cache/docling/huggingface";
        EASYOCR_MODULE_PATH = "/home/zarred/.cache/docling/easyocr";
        MPLCONFIGDIR = "/home/zarred/.cache/docling/matplotlib";
        
        # Disable torch.compile to avoid overhead (critical for VLM performance)
        TORCH_COMPILE_DISABLE = "1";
        TORCHDYNAMO_DISABLE = "1";
      };
    };
  };
}
