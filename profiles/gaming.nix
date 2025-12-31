{ pkgs, pkgs-unstable, ... }: {
  #nixpkgs.config.packageOverrides = pkgs-unstable: {
  #  steam = pkgs-unstable.steam.override {
  #    extraPkgs = pkgs-unstable:
  #      with pkgs-unstable; [
  #        xorg.libXcursor
  #        xorg.libXi
  #        xorg.libXinerama
  #        xorg.libXScrnSaver
  #        libpng
  #        libpulseaudio
  #        libvorbis
  #        stdenv.cc.cc.lib
  #        libkrb5
  #        keyutils
  #        gamescope-wsi
  #        vulkan-loader
  #        zenity
  #        wayland
  #      ];
  #  };
  #};
  programs.steam = {
    enable = true;
    package = pkgs-unstable.steam.override {
      extraPkgs = pkgs-unstable:
        with pkgs-unstable; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
          gamescope-wsi
          vulkan-loader
          zenity
          wayland
          vkd3d-proton
          vkd3d
          dxvk_2
          proton-ge-bin
          freetype
          openjdk21_headless
          wineWowPackages.waylandFull
          gamescope
          #gamescope-wsi
          vulkan-loader
        ];
    };
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    gamescopeSession.enable = true;
    #extraCompatPackages = with pkgs; [
    #];
  };
  environment.systemPackages = with pkgs; [
    freetype
    mangohud
    vulkan-tools
    #wine
    winetricks
    #wineWowPackages.waylandFull
    wineWowPackages.staging
    #gamemode
    libva
    libva-utils
    protonup-ng

    (pkgs.callPackage ../pkgs/rgd {}) # Installed game detection utility for Linux. Built to be simple and scriptable.
   ];
  #environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/zarred/.steam/root/compatibilitytools.d";
  programs.gamescope = {
    # NOTE: Gamescope Compositor / "Boot to Steam Deck"
    enable = true;
    capSysNice = true;
    #args = [
      #"--rt"
      #"--adaptive-sync" # VRR support
      #"--hdr-enabled"
      #"--mangoapp"
      #"--steam"
    #];
  };
  programs.gamemode = {
    enable = true;
    #enableRenice = true;
    settings = {
      #general = {
      #  renice = 10;
      #};
      ## Warning: GPU optimisations have the potential to damage hardware
      #gpu = {
      #  apply_gpu_optimisations = "accept-responsibility";
      #  gpu_device = 0;
      #  amd_performance_level = "high";
      #};
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
      };
    };
  };
}
