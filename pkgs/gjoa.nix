{ lib
, stdenv
, fetchurl
, makeWrapper
, copyDesktopItems
, makeDesktopItem
, python3
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

  nativeBuildInputs = [ makeWrapper copyDesktopItems python3 ];

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

    # Firefox 152 exposes CustomizableUI through moz-src:// rather than the
    # older resource:///modules/ alias used by the v0.4.0 release bundle.
    # Patch the bundled toolbar migration without rebuilding Firefox.
    python3 - <<PY
import os
import tempfile
import zipfile

archive = os.path.join("$out", "libexec", "gjoa", "browser", "omni.ja")
with zipfile.ZipFile(archive, "r") as source:
    fd, patched = tempfile.mkstemp(dir=os.path.dirname(archive))
    os.close(fd)
    replacements = 0
    with zipfile.ZipFile(patched, "w") as target:
        for entry in source.infolist():
            data = source.read(entry.filename)
            if entry.filename.endswith("gjoa-tabs.uc.js"):
                old = b"resource:///modules/CustomizableUI.sys.mjs"
                new = b"moz-src:///browser/components/customizableui/CustomizableUI.sys.mjs"
                replacements += data.count(old)
                data = data.replace(old, new)
            target.writestr(entry, data)
if replacements != 1:
    raise SystemExit(f"expected one CustomizableUI URI, found {replacements}")
os.replace(patched, archive)
PY

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
