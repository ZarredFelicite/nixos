{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  kdePackages,
  adwaita-icon-theme,
  gnome-icon-theme,
  hicolor-icon-theme,
  gitUpdater,
}:

stdenvNoCC.mkDerivation rec {
  pname = "suru-plus-aspromauros";
  version = "3.0";

  src = fetchFromGitHub {
    owner = "gusbemacbe";
    repo = "suru-plus-aspromauros";
    rev = "v${version}";
    sha256 = "sha256-TLXicDAb7VmzjwCsKtNTnSDq8Z8P1ZBJTMcghF0r0gk=";
  };

  nativeBuildInputs = [
    gtk3
  ];

  propagatedBuildInputs = [
    kdePackages.breeze-icons
    adwaita-icon-theme
    gnome-icon-theme
    hicolor-icon-theme
  ];

  # breeze-icons propagates qtbase
  dontWrapQtApps = true;

  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -a "Suru++-Asprómauros" "$out/share/icons/"

    # Remove unnecessary files
    rm -f $out/share/icons/Suru++-Asprómauros/{AUTHORS,CHANGELOG.md,CODE_OF_CONDUCT.md,CONTRIBUTING.md,COPYING,CREDITS,LICENSE,Makefile,README.md,install.sh}

    # Update icon cache
    for theme in $out/share/icons/*; do
      if [ -d "$theme" ]; then
        gtk-update-icon-cache -f "$theme"
      fi
    done

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "A fully monochromatic icons theme for users of dark graphic environments";
    longDescription = ''
      Suru++ Asprómauros is a monochromatic icon theme based on Suru++ 30 Dark icons.
      It is flat, minimalist and designed for full dark environments. The word "Asprómauros" 
      comes from the modern Greek word ασπρόμαυρος, which means "black and white".
      
      The theme includes:
      - 2000+ action icons
      - 5400+ app icons  
      - 190+ device icons
      - 1600+ mimetype icons
      - 1900+ panel icons
      - 160+ place icons
    '';
    homepage = "https://github.com/gusbemacbe/suru-plus-aspromauros";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ]; # Add your maintainer info here
  };
}