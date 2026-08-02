{ pkgs, lib, config, ... }:

{
  imports = [ ./shared/core.nix ];

  home = {
    username = "zarred";
    homeDirectory = "/home/zarred";
    stateVersion = "24.11";

    sessionVariables = {
      #EDITOR = "nvim";
      #MANPAGER = "bat -l man -p'";
      #PAGER = "bat";
      # API keys are loaded conditionally from sops in shell/systemd hooks.
      PI_CODING_AGENT_DIR = "~/.config/pi/agent";
      PI_SKIP_VERSION_CHECK = "1";
      SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
    };

    # Keep this legacy host package out of shared/core.nix so ROCK does not
    # build it while existing desktop/server hosts retain it.
    packages = with pkgs; [
      (callPackage ../pkgs/usbeehive { })
    ];
  };

  # Load API keys into systemd environment for user services
  systemd.user.services.load-api-keys = {
    Unit = {
      Description = "Load API keys from sops into systemd environment";
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "load-api-keys" ''
        args=()
        for key in OPENAI_API_KEY:openai-api GEMINI_API_KEY:gemini-api OPENROUTER_API_KEY:openrouter-api FRESHRSS_API_KEY:freshrss-api; do
          name="''${key%%:*}"
          secret="/run/secrets/''${key#*:}"
          if [ -r "$secret" ]; then
            args+=("$name=$(cat "$secret")")
          fi
        done
        if [ "''${#args[@]}" -gt 0 ]; then
          ${pkgs.systemd}/bin/systemctl --user set-environment "''${args[@]}"
        fi
      ''}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  programs.git.signing = {
    format = "openpgp";
    key = "0xD276AC444633E146";
    signByDefault = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "no";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "auto";
        controlPath = "~/.ssh/controlmasters/%r@%h:%p";
        controlPersist = "1h";
        extraOptions.IdentityAgent = "/run/user/1000/gnupg/S.gpg-agent.ssh";
      };
      sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      rpicam = {
        hostname = "rpicam";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "export TERM=xterm-256color; tmux new -A -s rpicam";
        };
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      rpi = {
        hostname = "10.131.3.83";
        user = "zarred";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s horus";
        };
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      tmux-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s sankara_remote";
        };
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      home-sankara = {
        hostname = "sankara";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmuxinator home";
        };
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      tmux-web = {
        hostname = "web";
        user = "zarred";
        identityFile = "/home/zarred/.ssh/id_ed25519";
        #identitiesOnly = true;
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "tmux new -A -s web_remote";
        };
        userKnownHostsFile = "~/.ssh/known_hosts";
        addKeysToAgent = "yes";
      };
      github = {
        host = "github.com";
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "/run/user/1000/gnupg/S.gpg-agent.ssh";
        };
      };
    };
  };


}
