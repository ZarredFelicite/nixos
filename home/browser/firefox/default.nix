{ pkgs, pkgs-unstable, inputs, ... }:
let
  onebar-css = builtins.readFile( builtins.fetchGit {
      # NOTE: UPDATE
      url = "https://git.gay/freeplay/Firefox-Onebar";
      rev = "78789cadd56cdf0d273ace47e3ac8b6f7db94eef";
    } + "/onebar.css" );
  # Touch focused css (outdated)
  alpha-css = builtins.readFile( builtins.fetchGit {
      url = "https://github.com/Tagggar/Firefox-Alpha";
      rev = "7d4ad9d7b052a25d4ea70b4e19a5da6359ea6b97";
    } + "/chrome/userChrome.css" );
  onefox-css = builtins.readFile( builtins.fetchGit {
      url = "https://github.com/Perseus333/One-Fox";
      rev = "41765dfdb5e0ba15d847585320ee70edb0c7b422";
    } + "/chrome/userChrome.css" );
in {
  imports = [
    ./tridactyl.nix
  ];
  stylix.targets.firefox.enable = false;
  programs.firefox = {
    enable = true;
    package = pkgs-unstable.firefox.override {
      nativeMessagingHosts = [
        pkgs-unstable.tridactyl-native
        pkgs-unstable.browserpass
        pkgs-unstable.fx-cast-bridge
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
          #  sha256 = "sha256-c9IWMgkpk21nItNpdscs+aCEzmvlrFSNeFr3MepV/c8=";
          #}; in [
          #bpc-pkg
          ublock-origin
          darkreader
          user-agent-string-switcher
          redirector
          #tampermonkey
          firemonkey
          tridactyl
          consent-o-matic
          decentraleyes
          canvasblocker
          browserpass
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
          rev = "42988c09080695802c4fdbe5d3d9fa1a01315c2a"; }
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
          #extraConfig = builtins.readFile(builtins.fetchGit {
          #  url = "https://codeberg.org/Narsil/user.js";
          #  rev = "42988c09080695802c4fdbe5d3d9fa1a01315c2a"; }
          #  + "/desktop/user.js") ;
      };
      onefox = {
        id = 4;
        bookmarks = {};
        userChrome = onefox-css;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
          #extraConfig = builtins.readFile(builtins.fetchGit {
          #  url = "https://codeberg.org/Narsil/user.js";
          #  rev = "42988c09080695802c4fdbe5d3d9fa1a01315c2a"; }
          #  + "/desktop/user.js") ;
      };
    };
  };
  home.packages = with pkgs-unstable; [
    buku # Private cmdline bookmark manager
    #(callPackage ./firefox_openwith/derivation.nix {})
  ];
  xdg.configFile."com.add0n.node.json" = {
    source = ./firefox_openwith/com.add0n.node.json;
    target = "./.mozilla/native-messaging-hosts/com.add0n.node.json";
  };
}
