{ pkgs, config, ...}: {
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.iosevka-term
      # font-awesome already in nerd-fonts
      noto-fonts
      noto-fonts-emoji
      material-symbols
    ];
  };
  home-manager.sharedModules = [
    {
      stylix = {
        autoEnable = true;
        polarity = "dark";
        icons = {
          enable = true;
          #dark = "Suru++-Asprómauros";
          #package = ( pkgs.callPackage ../pkgs/suru-plus-aspromauros {} );
          #dark = "ubuntu-mono-light";
          dark = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };
    }
  ];
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../wallpaper.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
    # https://github.com/tinted-theming/base16-schemes
    #override = {
    #  base00 = "#191724";
    #};
    polarity = "dark";
    cursor = {
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      size = 24;
    };
    opacity = {
      terminal = 0.2;
    };
    fonts = {
      sizes = {
        applications = 14;
        desktop = 14;
        popups = 14;
        terminal = 14;
      };
      monospace = { package = pkgs.nerd-fonts.iosevka-term; name = "IosevkaTerm NFM"; };
      sansSerif = config.stylix.fonts.monospace;
      serif = config.stylix.fonts.monospace;
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
