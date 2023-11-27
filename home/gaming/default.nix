{ pkgs, ... }: {
  #programs.steam = {
  #  enable = true;
  #};
  home.packages = [
    pkgs.lutris
    pkgs.protonup-qt
    pkgs.wineWowPackages.waylandFull
    pkgs.gamescope
  ];
  xdg.configFile."lutris/system.yml".text = ''
    system:
      game_path: /home/zarred/games
      gamescope: true
      gamescope_flags: --expose-wayland
      gamescope_game_res: 3440x1440
      gamescope_output_res: 3440x1440
  '';
  xdg.configFile."lutris/lutris.conf".text = ''
    [services]
    lutris = True
    gog = True
    egs = True
    ea_app = True
    ubisoft = True
    steam = True

    [lutris]
    dark_theme = True
    show_advanced_options = True
    width = 800
    height = 600
    maximized = True
    selected_category = category:all
  '';
  xdg.configFile."lutris/games/cyberpunk-2077-setup-1700479948.yml".text = ''
    game:
      args: --launcher-skip --intro-skip --skipStartScreen
      exe: /home/zarred/games/Cyberpunk 2077/bin/x64/Cyberpunk2077.exe
      prefix: /home/zarred/games/cyberpunk-2077
    system:
      env:
        DXVK_ASYNC: '1'
        PROTON_ENABLE_NGX_UPDATER: '1'
        PROTON_ENABLE_NVAPI: '1'
        PROTON_HIDE_NVIDIA_GPU: '0'
        VKD3D_CONFIG: dxr11
        VKD3D_FEATURE_LEVEL: '12_2'
    wine:
      version: wine-ge-8-24-x86_64
  '';
}
