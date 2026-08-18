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

    webHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host address for the Ember web listener";
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
      tailscaleServeStart = pkgs.writeShellScript "ember-tailscale-serve-start" ''
        set -euo pipefail

        for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
          backend_running=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null \
            | ${pkgs.jq}/bin/jq -e '.BackendState == "Running"' >/dev/null 2>&1 && echo true || echo false)
          local_ready=$(${pkgs.bash}/bin/bash -c \
            'exec 3<>/dev/tcp/127.0.0.1/${toString cfg.port}' >/dev/null 2>&1 && echo true || echo false)
          if [[ "$backend_running" == true && "$local_ready" == true ]]; then
            break
          fi

          if [[ "$attempt" -eq 60 ]]; then
            echo "Tailscale or Ember did not become ready" >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done

        # Ember also reconciles this route at daemon startup. Keep this narrow,
        # idempotent Serve-only unit for boot/readiness recovery; never enable
        # Funnel and never expose Ember's separate gateway endpoint.
        exec ${pkgs.tailscale}/bin/tailscale serve --bg --https 443 http://127.0.0.1:${toString cfg.port}
      '';
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
        emberStart = pkgs.writeShellScript "ember-start" ''
          export OPENAI_API_KEY="$(cat ${config.sops.secrets.openai-api.path})"
          export OPENROUTER_API_KEY="$(cat ${config.sops.secrets.openrouter-api.path})"
          exec ${pkgs.nodejs}/bin/node ${cfg.projectDir}/dist/src/app/main.js --daemon --web-host=${cfg.webHost} --web-port=${toString cfg.port}
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
            "PATH=/run/wrappers/bin:${qmdPkg}/bin:%h/.nix-profile/bin:%h/.local/state/nix/profile/bin:/etc/profiles/per-user/%u/bin:/nix/profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
          ];
          ExecStart = "${emberStart}";
          Restart = "on-failure";
          RestartSec = "10s";
        };

        path = [ qmdPkg "/run/current-system/sw" ];
      };

      ember-tailscale-serve = {
        description = "Ember web UI via Tailscale Serve (HTTPS)";
        after = [ "network-online.target" "ember.service" ];
        wants = [ "network-online.target" "ember.service" ];
        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${tailscaleServeStart}";
        };
      };
    };
  };
}
