{ lib
, stdenv
, fetchurl
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, alsa-lib
, atk
, cairo
, cups
, dbus
, fontconfig
, freetype
, gdk-pixbuf
, glib
, gtk3
, libGL
, libgbm
, libcanberra
, libcanberra-gtk3
, libnotify
, libpulseaudio
, libva
, pciutils
, pipewire
, pango
, udev
, vulkan-loader
, xorg
}:

stdenv.mkDerivation rec {
  pname = "gjoa";
  version = "0.4.0";

  src = fetchurl {
    url = "https://github.com/tompassarelli/gjoa/releases/download/v${version}/gjoa-${version}-linux-x86_64.tar.xz";
    hash = "sha256-YrvWPkAxInbpZhpBW73cjyZL/XjPjUycnPBS138LqvM=";
  };

  sourceRoot = "gjoa";

  nativeBuildInputs = [ makeWrapper copyDesktopItems ];

  desktopItems = [
    (makeDesktopItem {
      name = "gjoa";
      desktopName = "Gjoa";
      comment = "A programmable Firefox fork";
      exec = "gjoa %U";
      icon = "gjoa";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeTypes = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/gjoa"
    cp -r ./. "$out/libexec/gjoa/"
    chmod +x "$out/libexec/gjoa/gjoa" "$out/libexec/gjoa/gjoa-bin"

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/gjoa/gjoa" "$out/bin/gjoa" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        alsa-lib
        atk
        cairo
        cups
        dbus
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libGL
        libgbm
        libcanberra
        libcanberra-gtk3
        libnotify
        libpulseaudio
        libva
        pciutils
        pipewire
        pango
        udev
        vulkan-loader
        stdenv.cc.cc
        xorg.libX11
        xorg.libxcb
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
      ]}:$out/libexec/gjoa"

    for size in 16 32 48 64 128; do
      install -Dm644 \
        "$out/libexec/gjoa/browser/chrome/icons/default/default$size.png" \
        "$out/share/icons/hicolor/$size\x$size/apps/gjoa.png"
    done

    copyDesktopItems
    runHook postInstall
  '';

  passthru.updateScript = null;

  meta = {
    description = "A programmable Firefox fork";
    homepage = "https://github.com/tompassarelli/gjoa";
    license = lib.licenses.mpl20;
    mainProgram = "gjoa";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
