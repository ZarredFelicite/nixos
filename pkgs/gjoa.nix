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

    # Patch release-bundle incompatibilities without rebuilding Firefox:
    # - Firefox 152 moved CustomizableUI to moz-src://.
    # - Gjoa registers its chrome CSS as an AGENT_SHEET, which overrides
    #   userChrome.css and paints opaque surfaces. Append the Linux transparency
    #   overrides at the same origin and make Gjoa's privileged new-tab page
    #   transparent as well.
    python3 - <<PY
import os
import tempfile
import zipfile

archive = os.path.join("$out", "libexec", "gjoa", "browser", "omni.ja")
chrome_overrides = b"""

/* Nix package: transparent Linux/Wayland chrome for Latin Accent. */
:root {
  --gjoa-bg: transparent !important;
  --toolbar-bgcolor: transparent !important;
  --tabpanel-background-color: transparent !important;
  --lwt-accent-color: transparent !important;
  --lwt-accent-color-inactive: transparent !important;
  --inactive-titlebar-opacity: 1 !important;
  --inactive-window-transition: 0s !important;
}

.browser-titlebar:-moz-window-inactive {
  opacity: 1 !important;
}

/* Keep non-zero alpha on the top-level GTK/Wayland surface. Fully transparent
 * roots can be cleared through Firefox's opaque fallback instead. */
#main-window {
  background: #00000066 !important;
  background-color: #00000066 !important;
  background-image: none !important;
}

#browser,
#appcontent,
#navigator-toolbox,
#TabsToolbar,
#nav-bar,
#PersonalToolbar,
#tabbrowser-tabpanels,
#tabbrowser-tabbox,
#tabbrowser-tabpanels > .deck-selected,
#sidebar-main,
#sidebar-box,
.browserContainer,
.browserStack {
  background: transparent !important;
  background-color: transparent !important;
  background-image: none !important;
}
"""

with zipfile.ZipFile(archive, "r") as source:
    fd, patched = tempfile.mkstemp(dir=os.path.dirname(archive))
    os.close(fd)
    uri_replacements = 0
    newtab_replacements = 0
    css_patches = 0
    with zipfile.ZipFile(patched, "w") as target:
        for entry in source.infolist():
            data = source.read(entry.filename)
            if entry.filename.endswith("gjoa-tabs.uc.js"):
                old = b"resource:///modules/CustomizableUI.sys.mjs"
                new = b"moz-src:///browser/components/customizableui/CustomizableUI.sys.mjs"
                uri_replacements += data.count(old)
                data = data.replace(old, new)
            elif entry.filename.endswith("gjoa/styles/gjoa.uc.css"):
                data += chrome_overrides
                css_patches += 1
            elif entry.filename.endswith("gjoa-newtab/newtab.html"):
                old = b"--bg: #1c1b22;"
                newtab_replacements += data.count(old)
                data = data.replace(old, b"--bg: transparent;")
            target.writestr(entry, data)
if uri_replacements != 1:
    raise SystemExit(f"expected one CustomizableUI URI, found {uri_replacements}")
if css_patches != 1:
    raise SystemExit(f"expected one Gjoa chrome stylesheet, found {css_patches}")
if newtab_replacements != 1:
    raise SystemExit(f"expected one Gjoa new-tab background, found {newtab_replacements}")
os.replace(patched, archive)
PY

    chmod +x "$out/libexec/gjoa/gjoa" "$out/libexec/gjoa/gjoa-bin"

    mkdir -p "$out/bin"
    makeWrapper "$out/libexec/gjoa/gjoa" "$out/bin/gjoa" \
      --add-flags '-profile "$HOME/.config/mozilla/gjoa/0hfl40c6.default-default"' \
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
