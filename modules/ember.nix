# NixOS systemd user service for Ember web server
# Runs as your user account via the local checkout wrapper package
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ember;
  qmdDevice = pkgs.writeShellApplication {
    name = "qmd-device";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.systemd ];
    text = ''
      set -euo pipefail

      readonly service=qmd-mcp.service
      readonly state_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/qmd"
      readonly state_file="$state_dir/device.env"
      readonly default_gpu=cuda

      mode_for_value() {
        case "$1" in
          cuda) printf 'cuda' ;;
          false|off|none|disable|disabled) printf 'cpu' ;;
          *) printf 'unknown' ;;
        esac
      }

      configured_gpu() {
        local value="$default_gpu"
        if [[ -r "$state_file" ]]; then
          while IFS= read -r line; do
            case "$line" in
              NODE_LLAMA_CPP_GPU=*) value="''${line#NODE_LLAMA_CPP_GPU=}"; break ;;
            esac
          done < "$state_file"
        fi
        printf '%s' "$value"
      }

      print_status() {
        local configured_value configured_mode active_state sub_state pid runtime_gpu backend
        configured_value="$(configured_gpu)"
        configured_mode="$(mode_for_value "$configured_value")"
        active_state="$(systemctl --user show "$service" -p ActiveState --value 2>/dev/null || printf unknown)"
        sub_state="$(systemctl --user show "$service" -p SubState --value 2>/dev/null || printf unknown)"
        pid="$(systemctl --user show "$service" -p MainPID --value 2>/dev/null || printf 0)"
        runtime_gpu=not-running
        backend=not-loaded

        if [[ "$pid" =~ ^[1-9][0-9]*$ ]]; then
          if [[ -r "/proc/$pid/environ" ]]; then
            runtime_gpu="$(tr '\0' '\n' < "/proc/$pid/environ" | grep '^NODE_LLAMA_CPP_GPU=' | head -n1 | cut -d= -f2- || true)"
            runtime_gpu="''${runtime_gpu:-unset}"
          fi
          if [[ -r "/proc/$pid/maps" ]]; then
            if grep -qE 'libggml-cuda|libllama\.cuda' "/proc/$pid/maps"; then
              backend=cuda
            elif grep -qE 'libggml-cpu|libllama\.' "/proc/$pid/maps"; then
              backend=cpu
            fi
          fi
        fi

        printf 'configured: %s (NODE_LLAMA_CPP_GPU=%s)\n' "$configured_mode" "$configured_value"
        printf 'service: %s/%s (pid %s)\n' "$active_state" "$sub_state" "$pid"
        printf 'service env: NODE_LLAMA_CPP_GPU=%s\n' "$runtime_gpu"
        printf 'loaded backend: %s\n' "$backend"

        [[ "$active_state" == active ]]
      }

      usage() {
        printf 'usage: qmd-device status|cpu|cuda\n' >&2
        exit 2
      }

      command="''${1:-status}"
      case "$command" in
        status)
          print_status
          ;;
        cpu|cuda)
          mkdir -p "$state_dir"
          chmod 700 "$state_dir"
          temp_file="$(mktemp "$state_dir/device.env.XXXXXX")"
          trap 'rm -f "$temp_file"' EXIT
          chmod 600 "$temp_file"
          if [[ "$command" == cpu ]]; then
            printf 'NODE_LLAMA_CPP_GPU=false\n' > "$temp_file"
          else
            printf 'NODE_LLAMA_CPP_GPU=cuda\n' > "$temp_file"
          fi
          mv -f "$temp_file" "$state_file"
          trap - EXIT

          if ! systemctl --user restart "$service"; then
            printf 'qmd-mcp.service restart failed; persisted mode is %s\n' "$command" >&2
            print_status || true
            exit 1
          fi
          print_status
          ;;
        *)
          usage
          ;;
      esac
    '';
  };
in
{
  options.services.ember = {
    enable = mkEnableOption "Ember web server service";

    port = mkOption {
      type = types.port;
      default = 4311;
      description = "Port for the Ember web server";
    };

    projectDir = mkOption {
      type = types.str;
      default = "/home/zarred/dev/ember";
      description = "Path to the Ember source checkout";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ qmdDevice ];

    systemd.user.services = let
      qmdPkg = pkgs.callPackage ../pkgs/qmd/package.nix {};
    in {
      qmd-mcp = {
        description = "Persistent qmd MCP server";
        partOf = [ "ember.service" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "simple";
          Environment = [ "HOME=%h" ];
          EnvironmentFile = [ "-%h/.config/qmd/device.env" ];
          ExecStart = "${lib.getExe qmdPkg} mcp --http --port 8181";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      ember = let
        emberPackage = pkgs.callPackage ../pkgs/ember.nix {
          projectDir = cfg.projectDir;
        };
        emberStart = pkgs.writeShellScript "ember-start" ''
          export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter-api.path})"
          exec ${lib.getExe emberPackage} --daemon --web-port=${toString cfg.port}
        '';
      in {
        description = "Ember Web Server";
        after = [ "network-online.target" "qmd-mcp.service" ];
        wants = [ "network-online.target" "qmd-mcp.service" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "simple";
          WorkingDirectory = cfg.projectDir;
          Environment = [
            "HOME=%h"
            "QMD_MCP_URL=http://localhost:8181/mcp"
            "PATH=${qmdPkg}/bin:%h/.nix-profile/bin:%h/.local/state/nix/profile/bin:/etc/profiles/per-user/%u/bin:/nix/profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
          ];
          ExecStart = "${emberStart}";
          Restart = "on-failure";
          RestartSec = "10s";
        };

        path = [ qmdPkg "/run/current-system/sw" ];
      };
    };
  };
}
