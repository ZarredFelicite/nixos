{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, python312
, qt6Packages
, bluez
, glib
, gobject-introspection
, pulseaudio
, pipewire
, systemd
, util-linux
, sbc
}:

# Qt's Python bindings depend on QtBase, but their bundled plugin path is not
# inside the generated Python environment. Keep the platform plugins explicit.


let
  python = python312.withPackages (ps: with ps; [
    dbus-python
    pygobject3
    psutil
    pyqt6
    vobject
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "handsfree-linux";
  version = "1.2.6";

  src = fetchFromGitHub {
    owner = "PavelTarlev1";
    repo = "handsfree-linux";
    rev = "8e6026ca9b1bb4e63f5f6955369d22df7fdb09dd";
    hash = "sha256-C0o+dzJ+wfmn3CaXiV2CW6aMVkRbZNeS2GsroCsK3/s=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/handsfree-linux $out/bin
    cp -r . $out/share/handsfree-linux/
    install -Dm644 resources/icon_256.png \
      $out/share/icons/hicolor/256x256/apps/handsfree.png

    makeWrapper ${python}/bin/python $out/bin/handsfree \
      --add-flags "$out/share/handsfree-linux/main.py" \
      --prefix PATH : ${lib.makeBinPath [ bluez glib pulseaudio pipewire systemd util-linux ]} \
      --set GI_TYPELIB_PATH ${lib.makeSearchPath "lib/girepository-1.0" [ glib gobject-introspection ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ sbc ]} \
      --set QT_PLUGIN_PATH ${qt6Packages.qtbase}/lib/qt-6/plugins

    install -Dm644 /dev/stdin $out/share/applications/handsfree.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=HandsFree
    Comment=Bluetooth Hands-Free calling
    Exec=$out/bin/handsfree
    Icon=handsfree
    Categories=Utility;Network;
    StartupNotify=false
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Bluetooth hands-free calling utility for Linux";
    homepage = "https://github.com/PavelTarlev1/handsfree-linux";
    license = lib.licenses.mit;
    mainProgram = "handsfree";
    platforms = lib.platforms.linux;
  };
})
