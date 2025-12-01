{ pkgs, pkgs-unstable, lib, osConfig, ... }:
  let
    mkGraphicalService = lib.recursiveUpdate {
      Unit.PartOf = [ "graphical-session.target" ];
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service.Restart = "always";
    };

    upscayl-wrapped = pkgs.symlinkJoin {
      name = "upscayl-wrapped";
      paths = [ pkgs.upscayl ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/upscayl \
          --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json \
          --add-flags "--ozone-platform=wayland"
      '';
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
      pkgs.exiftool # Tool to read, write and edit EXIF meta information

      # networking
      # TODO: broken pkgs.trayscale # An unofficial GUI wrapper around the Tailscale CLI client

      # misc
      # TODO: broken pkgs-unstable.rpi-imager # Raspberry Pi Imaging Utility
      #ventoy # NOTE: marked insecure - binary blobs

      # AI (GUI or mixed usage)
      pkgs.piper-tts # A fast, local neural text to speech system
      upscayl-wrapped # Free and Open Source AI Image Upscaler (wrapped with NVIDIA EGL + Wayland)
      pkgs.video2x
      pkgs.openai-whisper-cpp # Port of OpenAI's Whisper model in C/C++

      # android dev
      pkgs.android-studio
      pkgs.android-tools
      pkgs.jdk17
      pkgs.gradle

      # Desktop/Wayland specific tools
      pkgs.waypipe
      pkgs.wayvnc
      pkgs.tigervnc
      pkgs.remmina
      pkgs.wlvncc
      pkgs.moonlight-qt
      #TODO: broken pkgs.bottles
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
    Service.ExecStart = "${pkgs.syncthingtray}/bin/syncthingtray --wait";
  };
  systemd.user.services.mppv_watcher = mkGraphicalService {
    Unit.Description = "Watch for mppv changes";
    Service.ExecStart = "/home/zarred/scripts/video/mppv/mppv -w";
    Service.RestartSec = "300s";
    Service.StartLimitIntervalSec = "0";
  };
  systemd.user.services.bambu-gateway = mkGraphicalService {
    Unit.Description = "Bambu Labs Printer Gateway";
    Unit.After = "network.target";
    Unit.Documentation = "file:///home/zarred/scripts/3d/README.md";
    Service.ExecStart = "/usr/bin/env python3 /home/zarred/scripts/3d/bambu_gateway.py";
    Service.WorkingDirectory = "/home/zarred/scripts/3d";
    Service.RestartSec = "10";
    Service.StartLimitIntervalSec = "0";
  };
}
