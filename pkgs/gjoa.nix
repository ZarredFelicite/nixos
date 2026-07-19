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
    #   userChrome.css and paints opaque surfaces. Append UI-only Linux
    #   transparency at the same origin while keeping the content viewport
    #   opaque. The root/body alpha technique is adapted from WaveFox commit
    #   cdb4d9ce857c3fe8e34c0958849216b76fd912c5.
    python3 - <<PY
import os
import tempfile
import zipfile

archive = os.path.join("$out", "libexec", "gjoa", "browser", "omni.ja")
chrome_overrides = b"""

/* Nix package: WaveFox-derived per-pixel alpha for Linux/Wayland chrome. */
:root,
body,
#main-window {
  background: transparent !important;
  background-color: transparent !important;
  background-image: none !important;
}

:root {
  --gjoa-bg: transparent !important;
  --toolbar-bgcolor: transparent !important;
  --lwt-accent-color: transparent !important;
  --lwt-accent-color-inactive: transparent !important;
  --toolbox-background-color-inactive: var(--toolbox-background-color) !important;
  --toolbox-text-color-inactive: var(--toolbox-text-color) !important;
}

/* Only browser chrome is transparent. */
#navigator-toolbox,
#TabsToolbar,
#nav-bar,
#PersonalToolbar,
#sidebar-main,
#sidebar-box {
  background: rgba(12, 14, 20, 0.30) !important;
  background-color: rgba(12, 14, 20, 0.30) !important;
  background-image: none !important;
}

/* Firefox-Mod-Blur's WebRender workaround establishes a filter layer on the
 * content stack, allowing a chrome overlay to sample it as its backdrop. */
.browserContainer .browserStack {
  backdrop-filter: blur(0) !important;
}

#sidebar-main[data-gjoa-compact] {
  background: transparent !important;
}

#sidebar-main[data-gjoa-compact]::before {
  display: block !important;
  content: "" !important;
  position: absolute !important;
  inset: 0 !important;
  z-index: -1 !important;
  pointer-events: none !important;
  background: rgba(12, 14, 20, 0.30) !important;
  backdrop-filter: blur(32px) saturate(140%) !important;
}

/* Firefox's classic chatbot uses an opaque remote page canvas. Blend only
 * that sidebar browser over the transparent backing; normal tabs stay opaque. */
#sidebar-box[sidebarcommand="viewGenaiChatSidebar"] #sidebar {
  opacity: 0.65 !important;
}

/* Web content and transparent internal pages retain an opaque backdrop. */
#tabbrowser-tabpanels,
#tabbrowser-tabbox,
#tabbrowser-tabpanels > .deck-selected,
.browserContainer,
.browserStack {
  background: #1c1b22 !important;
  background-color: #1c1b22 !important;
  background-image: none !important;
}
"""

with zipfile.ZipFile(archive, "r") as source:
    fd, patched = tempfile.mkstemp(dir=os.path.dirname(archive))
    os.close(fd)
    uri_replacements = 0
    sidebar_browser_replacements = 0
    sidebar_focus_replacements = 0
    sidebar_shortcut_replacements = 0
    preference_patches = 0
    css_patches = 0
    with zipfile.ZipFile(patched, "w") as target:
        for entry in source.infolist():
            data = source.read(entry.filename)
            if entry.filename.endswith("gjoa-tabs.uc.js"):
                old = b"resource:///modules/CustomizableUI.sys.mjs"
                new = b"moz-src:///browser/components/customizableui/CustomizableUI.sys.mjs"
                uri_replacements += data.count(old)
                data = data.replace(old, new)

                # Gjoa checks inputs in the selected tab, but Firefox sidebars
                # use a separate browser. Do not steal Vim-style letter keys
                # while that browser owns focus.
                old = b"(!contentFocus.contentInputFocused()) && (!current_host_blacklisted())"
                new = old + b' && (!(a && (a.id === "sidebar")))'
                sidebar_focus_replacements += data.count(old)
                data = data.replace(old, new)
            elif entry.filename.endswith("gjoa-drawer.uc.js"):
                old = b'    const state = {urlbar_api: null};'
                new = old + b"""
    document.addEventListener("keydown", (e) => {
      if (e.ctrlKey && e.altKey && !e.shiftKey && !e.metaKey &&
          e.key.toLowerCase() === "s" && compact.isCompactVertical()) {
        e.preventDefault();
        e.stopImmediatePropagation();
        if (sidebar_main.hasAttribute("gjoa-has-hover")) {
          sidebar_main.dispatchEvent(new CustomEvent("gjoa-dismiss"));
        } else {
          compact.pinSidebar();
        }
      }
    }, true);"""
                sidebar_shortcut_replacements += data.count(old)
                data = data.replace(old, new)
            elif entry.filename.endswith("browser/browser.xhtml"):
                old = b'<browser id="sidebar" autoscroll="false"'
                new = b'<browser id="sidebar" transparent="true" autoscroll="false"'
                sidebar_browser_replacements += data.count(old)
                data = data.replace(old, new)
            elif entry.filename.endswith("gjoa/styles/gjoa.uc.css"):
                data += chrome_overrides
                css_patches += 1
            elif entry.filename.endswith("defaults/preferences/firefox.js"):
                data += b'\n// UI-only Linux transparency prerequisites.\npref("browser.tabs.allow_transparent_browser", true);\npref("browser.tabs.inTitlebar", 1);\npref("gjoa.sidebar.compact", true);\n'
                preference_patches += 1
            target.writestr(entry, data)
if uri_replacements != 1:
    raise SystemExit(f"expected one CustomizableUI URI, found {uri_replacements}")
if sidebar_browser_replacements != 1:
    raise SystemExit(f"expected one sidebar browser element, found {sidebar_browser_replacements}")
if sidebar_focus_replacements != 1:
    raise SystemExit(f"expected one Gjoa sidebar focus guard, found {sidebar_focus_replacements}")
if sidebar_shortcut_replacements != 1:
    raise SystemExit(f"expected one Gjoa drawer shortcut target, found {sidebar_shortcut_replacements}")
if css_patches != 1:
    raise SystemExit(f"expected one Gjoa chrome stylesheet, found {css_patches}")
if preference_patches != 1:
    raise SystemExit(f"expected one Firefox default preference file, found {preference_patches}")
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
