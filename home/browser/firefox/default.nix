{ pkgs, pkgs-unstable, inputs, ... }:
let
  onebar-css = builtins.readFile( builtins.fetchGit {
      url = "https://git.gay/freeplay/Firefox-Onebar";
      rev = "cf1ddf9ba1b2e417e1db8b7c5aac4bb0ef0c699a"; # NOTE: UPDATE
    } + "/onebar.css" );
  # Touch focused css (outdated)
  alpha-css = builtins.readFile( builtins.fetchGit {
      url = "https://github.com/Tagggar/Firefox-Alpha";
      rev = "78bf9a9ea57538b0a58212731e81dea80d490105"; # NOTE: UPDATE
    } + "/chrome/userChrome.css" );
  ff-ultima = pkgs.fetchFromGitHub {
    owner = "soulhotel";
    repo = "FF-ULTIMA";
    rev = "d5ce77f5948db13393939208757d08ae1fc4fb90";
    hash = "sha256-Cua5pPq55cTo7OSITUzPWpweZ5pqmSQ5DEsm1hQ/fuQ=";
  };
  ultima-prefs = ''
    // Zarred's minimal dark glass configuration. These follow upstream's
    // documented about:config settings and intentionally override user.js.
    user_pref("user.theme.0.default", false);
    user_pref("user.theme.transparent", true);
    user_pref("browser.tabs.allow_transparent_browser", true);

    user_pref("sidebar.revamp", true);
    user_pref("sidebar.verticalTabs", true);
    user_pref("sidebar.expandOnHover", false);
    user_pref("sidebar.visibility", "always-show");
    user_pref("ultima.tabs.tabbar.autohide", true);
    user_pref("ultima.tabs.tabbar.autohide+compact", true);
    user_pref("ultima.tabs.tabbar.hide.buttonstrip", true);
    user_pref("ultima.tabs.disable.scrollbar", true);
    user_pref("ultima.tabs.pinned.transparent.background", true);
    user_pref("ultima.tabs.tabCounter", false);
    user_pref("ultima.tabs.not.a.progress.bar", false);
    user_pref("ultima.sidebar.hide.header", true);

    user_pref("ultima.navbar.autohide", false);
    user_pref("ultima.navbar.float", true);
    user_pref("ultima.navbar.float.fullsize", false);
    user_pref("ultima.navbar.hide.buttons", true);
    user_pref("ultima.navbar.bookmarks.autohide", true);
    user_pref("ultima.urlbar.transparent", true);
    user_pref("ultima.urlbar.float", true);
    user_pref("ultima.urlbar.animate.open", false);
    user_pref("ultima.urlbar.hide.buttons", true);
    user_pref("ultima.urlbar.hide.searchsuggestions", true);
    user_pref("ultima.urlbar.focus.blur", true);
    user_pref("ultima.urlbar.focus.blur.all", false);

    user_pref("ultima.spacing.compact", false);
    user_pref("ultima.spacing.relaxed", false);
    user_pref("ultima.spacing.compact.contextmenu", true);
    user_pref("ultima.contextmenu.reduce.options", true);
    user_pref("ultima.navbar.theme.extensionspanel", true);
    user_pref("ultima.xstyle.private", true);
    user_pref("user.theme.xtension.newtab.rounded", true);
    user_pref("user.theme.xtension.newtab.compact", true);

    user_pref("browser.newtabpage.activity-stream.showSearch", false);
    user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
    user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
    user_pref("browser.newtabpage.activity-stream.showSponsored", false);
    user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
    user_pref("browser.newtabpage.activity-stream.showWeather", false);
    user_pref("browser.newtabpage.activity-stream.newtabWallpapers.customWallpaper.enabled", false);
    user_pref("browser.tabs.hoverPreview.enabled", false);
  '';
  ultima-glass-css = ''
    /* Dark navy glass overrides layered on FF Ultima's transparent scheme. */
    @media -moz-pref("user.theme.transparent") {
      :root {
        --uc-browser-color: rgba(5, 11, 21, 0.24) !important;
        --uc-layered-background: rgba(9, 20, 36, 0.48) !important;
        --uc-blur-layer: rgba(8, 18, 33, 0.34) !important;
        --uc-navbar-background: rgba(8, 17, 31, 0.54) !important;
        --uc-urlbar-background: rgba(13, 27, 46, 0.62) !important;
        --uc-sidebar-background: rgba(8, 18, 32, 0.58) !important;
        --uc-tab-selected: rgba(43, 74, 104, 0.58) !important;
        --uc-button-selected: rgba(45, 78, 108, 0.64) !important;
        --uc-panel-background: rgba(7, 15, 28, 0.90) !important;
        --uc-panel-border: rgba(151, 205, 235, 0.14) !important;
        --uc-accent-color-1: #9bd9f4 !important;
        --uc-accent-color-2: #527fa5 !important;
        --uc-accent-color-5: #a8def5 !important;
        --uc-all-border-radius: 16px !important;
        --uc-content-border-radius: 16px !important;
        --uc-sidebar-border-radius: 16px !important;
        --uc-button-border-radius: 11px !important;
        --uc-box-shadow: 0 16px 44px rgba(0, 0, 0, 0.34) !important;
        --uc-box-shadow-panel: 0 20px 54px rgba(0, 0, 0, 0.46) !important;
      }

      #main-window:not([lwtheme]) :is(#navigator-toolbox, #sidebar-main, #sidebar-box) {
        backdrop-filter: blur(32px) saturate(140%) !important;
      }

      #main-window:not([lwtheme]) #tabbrowser-tabbox {
        overflow: hidden !important;
        border: 1px solid rgba(151, 205, 235, 0.10) !important;
        box-shadow: 0 12px 38px rgba(0, 0, 0, 0.26) !important;
      }
    }
  '';
in {
  imports = [
    ./tridactyl.nix
  ];
  stylix.targets.firefox.enable = false;
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      nativeMessagingHosts = [
        pkgs.tridactyl-native
        pkgs.fx-cast-bridge
      ];
      extraPolicies = {
        Extensions = { Install = [
          #"https://addons.mozilla.org/firefox/downloads/latest/roseppuccin/latest.xpi"
          #"https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi"
          #"https://tridactyl.cmcaine.co.uk/betas/tridactyl-latest.xpi"
        ]; };
      };
    };
    profiles = {
      primary = {
        id = 0;
        isDefault = true;
        search = (import ./search.nix) ;
        settings = import ./settings.nix ;
        #bookmarks = import ./bookmarks.nix ;
        bookmarks = {};
        userChrome = (onebar-css + builtins.readFile ./firefox_css.css);
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          # INFO: bypass-paywalls-clean removed?
          #bpc-pkg = bypass-paywalls-clean.override rec {
          #  version = "4.0.7.0";
          #  url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/?file=bypass_paywalls_clean-${version}.xpi&branch=main";
          #  sha256 = "sha256-c9IWMgkpk21nItNpdscs+aCEzmvlrFSNeFr3MepV/c8="; # NOTE: UPDATE
          #}; in [
          #bpc-pkg
          ublock-origin
          darkreader
          redirector
          #tampermonkey
          firemonkey
          tridactyl
          #consent-o-matic
          #browserpass
          videospeed
          adaptive-tab-bar-colour
          # TODO: unavailable - video-downloadhelper
          imagus
          fx_cast
          rsspreview
          promnesia
          steam-database
          stylus
          simple-tab-groups
        ];
      };
      private = {
        id = 1;
        bookmarks = {};
        userChrome = onebar-css;
        extraConfig = builtins.readFile(builtins.fetchGit {
          url = "https://codeberg.org/Narsil/user.js";
          rev = "2f6ca400f65d947699e4b7f8e3234c5ca67fb00e"; # NOTE: UPDATE
        }
          + "/desktop/user.js") ;
      };
      tracking = {
        id = 2;
        bookmarks = {};
        settings = {
          "privacy.trackingprotection.enabled" = false;
        };
      };
      alpha = {
        id = 3;
        bookmarks = {};
        userChrome = alpha-css;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.urlbar.maxRichResults" = 0;
          "browser.urlbar.clickSelectsAll" = true;
        };
      };
      ultima = {
        id = 4;
        bookmarks = {};
        userChrome = builtins.readFile "${ff-ultima}/userChrome.css" + ultima-glass-css;
        userContent = builtins.readFile "${ff-ultima}/userContent.css";
        extraConfig = builtins.readFile "${ff-ultima}/user.js" + ultima-prefs;
      };
    };
  };
  home.file.".mozilla/firefox/ultima/chrome/theme".source = "${ff-ultima}/theme";
  xdg.desktopEntries.firefox-ultima = {
    name = "Firefox Ultima";
    comment = "Firefox with the FF Ultima theme";
    icon = "firefox";
    exec = "firefox --name firefox-ultima --no-remote -P ultima %U";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
  };
  home.packages = with pkgs; [
    buku # Private cmdline bookmark manager
    #(callPackage ./firefox_openwith/derivation.nix {})
  ];
  xdg.configFile."com.add0n.node.json" = {
    source = ./firefox_openwith/com.add0n.node.json;
    target = "./.mozilla/native-messaging-hosts/com.add0n.node.json";
  };
}
