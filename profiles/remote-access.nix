{ pkgs, config, lib, ... }: {
  #environment.systemPackages = lib.mkIf (config.networking.hostName == "web") [
  #  (pkgs.sunshine.override {
  #    cudaSupport = true;
  #    stdenv = pkgs.cudaPackages.backendStdenv;
  #  })
  #];
  #security.wrappers.sunshine = {
  #  owner = "root";
  #  group = "root";
  #  capabilities = "cap_sys_admin+p";
  #  source = "${pkgs.sunshine}/bin/sunshine";
  #};
  #services.avahi.publish.enable = true;
  #services.avahi.publish.userServices = true;
  #networking.firewall = {
  #  allowedTCPPorts = [ 47984 47989 47990 48010 ];
  #  allowedUDPPortRanges = [
  #    { from = 47998; to = 48000; }
  #    { from = 8000; to = 8010; }
  #  ];
  #};
  #systemd.user.services.sunshine = {
  #  description = "sunshine";
  #  wantedBy = [ "graphical-session.target" ];
  #  serviceConfig = {
  #    ExecStart = "${config.security.wrapperDir}/sunshine";
  #  };
  #};
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      sw_preset = "fast";
    };
    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Steam Big Picture";
          detached = [
            "setsid steam steam://open/bigpicture"
          ];
          image-path = "steam.png";
        }
        {
          name = "1080p Desktop";
          image-path = "desktop.png";
          prep-cmd = [
            {
              do = "${pkgs.hyprland}/bin/hyprctl output create headless sunshine";
              undo = "${pkgs.hyprland}/bin/hyprctl output remove sunshine";
            }
          ];
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };
  };
}
