{ self, pkgs,
#pkgs-unstable,
  inputs, outputs, ... }: {
  imports = [
    # inputs.home-manager.nixosModules.home-manager # Removed: Handled by individual host configs
    ../profiles/common.nix
    ../profiles/media-server.nix
    ../profiles/server-management.nix
    ../profiles/rss.nix
    ../profiles/nginx.nix
    ../profiles/cloud.nix
    ../profiles/printer.nix
    ../profiles/home-assistant.nix
    #../profiles/ib.nix
  ];
  # home-manager block removed: Handled by individual host configs
  #environment.systemPackages = [
  #  pkgs.mergerfs
  #  pkgs.mergerfs-tools
  #  pkgs.headscale
  #];
  #networking.firewall.allowedTCPPorts = [ 2049 80 443 6600 22 ];
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # TT-RSS
  #services.postgresql.enable = true;
  services.tt-rss.enable = true;

  services.gotify.enable = true;
  services.klipper.enable = true;
  services.mjpg-streamer.enable = false; # TODO: enable for 3d printer monitoring

  services.mpd.enable = true;
  services.jellyfin.enable = true;
  services.jellyseerr.enable = true;
  services.radarr.enable = true;
  services.sonarr.enable = true;
  services.readarr.enable = true;
  services.prowlarr.enable = true;
  services.transmission.enable = true;
  services.nzbget.enable = true;

  services.nextcloud.enable = true;
  services.syncthing.enable = true;

  services.authelia.instances.primary.enable = true;
  services.nginx.enable = true;
  services.headscale = {
    enable = false;
    #address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "http://127.0.0.1:8080";
      #tls_cert_path = "/var/lib/acme/headscale.zar.red/cert.pem";
      #tls_key_path = "/var/lib/acme/headscale.zar.red/key.pem";
      #dns_config.base_domain = "zar.red";
    };
  };

  services.vsftpd = {
    enable = true;
    localUsers = true;
    userlist = [ "zarred" ];
    writeEnable = true;
    allowWriteableChroot = true;
    anonymousUser = true;
    anonymousUserHome = "/mnt/gargantua/ftp";
    anonymousMkdirEnable = true;
    anonymousUploadEnable = true;
    anonymousUserNoPassword = true;
    anonymousUmask = "002";
  };

  systemd.user.services.cctv = {
    description = "Watch CCTV Cameras";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${pkgs.bash}/bin/bash /home/zarred/scripts/security/inotify_cctv.sh";
    serviceConfig.Restart = "always";
    serviceConfig.RuntimeMaxSec = "1d";
    serviceConfig.RestartSec = "1min";
    environment.SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
    path = [
      pkgs.inotify-tools
      pkgs.unixtools.ping
      pkgs.openssh
    ];
  };
  systemd.services.cctv-cleanup = {
    description = "CCTV footage cleanup service";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /home/zarred/scripts/security/cleanup_cctv.sh";
      User = "root";
      Group = "root";
    };
  };

  # Define the timer to run every Sunday at 2 AM
  systemd.timers.cctv-cleanup = {
    description = "Run CCTV cleanup every Sunday at 2 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 02:00:00";
      Persistent = true;
      AccuracySec = "1h";
    };
  };
}
