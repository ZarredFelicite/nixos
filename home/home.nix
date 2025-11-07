{ pkgs, pkgs-unstable, lib, osConfig, ... }:
  let
    mkGraphicalService = lib.recursiveUpdate {
      Unit.PartOf = [ "graphical-session.target" ];
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service.Restart = "always";
    };
  in {
  home = {
    packages = [
      # system tools
      pkgs.gtk3
      pkgs.helvum # A GTK patchbay for pipewire
      pkgs.pavucontrol
      pkgs.libva-utils # Often a dependency for GUI media players too

      # media
      pkgs.mediainfo # Supplies technical and tag information about a video or audio file

      # networking
      pkgs.trayscale # An unofficial GUI wrapper around the Tailscale CLI client

      # misc
      # TODO: broken pkgs-unstable.rpi-imager # Raspberry Pi Imaging Utility
      #ventoy # NOTE: marked insecure - binary blobs

      # AI (GUI or mixed usage)
      pkgs.piper-tts # A fast, local neural text to speech system
      pkgs.upscayl # Free and Open Source AI Image Upscaler
      pkgs.openai-whisper-cpp # Port of OpenAI's Whisper model in C/C++

      pkgs.android-studio

      # Desktop/Wayland specific tools
      pkgs.waypipe
      pkgs.wayvnc
      pkgs.tigervnc
      pkgs.remmina
      pkgs.wlvncc
      pkgs.moonlight-qt
      pkgs.bottles
      pkgs.protonup-qt

      # kinect
      #freenect
      pkgs.freecad-wayland

      # Offic
      pkgs.libreoffice-qt6-fresh
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
