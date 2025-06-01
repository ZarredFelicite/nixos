{ pkgs, lib, osConfig, ... }: {
  # imports array removed - these are now handled by home/hosts/*.nix files
  home = {
    # username, homeDirectory, stateVersion moved to home/core-settings.nix
    packages = with pkgs; [
      # Packages moved to home/cli-apps.nix have been removed along with their comments.
      # Remaining packages (mostly GUI or broadly used libraries):
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
      ffmpeg # A complete, cross-platform solution to record, convert and stream audio and video
      imagemagick # A software suite to create, edit, compose, or convert bitmap images
      rpi-imager # Raspberry Pi Imaging Utility
      #ventoy # NOTE: marked insecure - binary blobs

      # AI (GUI or mixed usage)
      piper-tts # A fast, local neural text to speech system
      upscayl # Free and Open Source AI Image Upscaler
      openai-whisper-cpp # Port of OpenAI's Whisper model in C/C++

      #android-studio

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

      # PYTHON packages moved to home/python.nix
    ];
    # sessionVariables moved to home/core-settings.nix
  };
  programs.kitty.enable = true;
  programs.foot.enable = false;
  programs.ghostty.enable = true;
  # programs.bat moved to home/core-settings.nix
  services.ssh-agent.enable = false; # TODO: vs GPG-agent
  # programs.ssh moved to home/core-settings.nix
  # programs.git moved to home/core-settings.nix
  #xdg.configFile."gh/hosts.yml".source = osConfig.sops.secrets.github-api-token.path; # This should go with gh config if sops is used
  # programs.gh moved to home/core-settings.nix
  # programs.tealdeer moved to home/core-settings.nix
  # programs.starship moved to home/core-settings.nix
  # programs.pandoc.enable = true; # Moved to home/cli-apps.nix
  #programs.home-manager.enable = true;
  # services.udiskie moved to home/cli-apps.nix
  # xdg.mimeApps and xdg.userDirs moved to home/xdg-settings.nix
  # editorconfig moved to home/core-settings.nix
  # xdg.configFile."/home/zarred/.jq".text moved to home/core-settings.nix
  # Aider config and alias moved to home/cli-apps.nix
}
