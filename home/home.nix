{ pkgs, lib, osConfig, ... }:
  let
    mkGraphicalService = lib.recursiveUpdate {
      Unit.PartOf = [ "graphical-session.target" ];
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service.Restart = "always";
    };
  in {
  home = {
    packages = with pkgs; [
      # system tools
      gtk3
      helvum # A GTK patchbay for pipewire
      pavucontrol
      libva-utils # Often a dependency for GUI media players too

      # media
      mediainfo # Supplies technical and tag information about a video or audio file

      # networking
      trayscale # An unofficial GUI wrapper around the Tailscale CLI client

      # misc
      rpi-imager # Raspberry Pi Imaging Utility
      #ventoy # NOTE: marked insecure - binary blobs

      # AI (GUI or mixed usage)
      piper-tts # A fast, local neural text to speech system
      upscayl # Free and Open Source AI Image Upscaler
      openai-whisper-cpp # Port of OpenAI's Whisper model in C/C++

      android-studio

      # Desktop/Wayland specific tools
      waypipe
      wayvnc
      tigervnc
      remmina
      wlvncc
      moonlight-qt
      bottles
      protonup-qt

      # kinect
      #freenect
      #freecad
    ];
  };
  programs.kitty.enable = true;
  programs.foot.enable = true;
  programs.ghostty.enable = true;
  services.ssh-agent.enable = false;

  systemd.user.services.syncthingtray = mkGraphicalService {
    Unit.Description = "Syncthing monitoring tray";
    Service.ExecStart = "${pkgs.syncthingtray}/bin/syncthingtray";
  };
  systemd.user.services.mppv_watcher = mkGraphicalService {
    Unit.Description = "Watch for mppv changes";
    Service.ExecStart = "/home/zarred/scripts/video/mppv -w";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
  };
}
