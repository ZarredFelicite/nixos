{ pkgs, inputs, ... }:
let
  onebar-css = builtins.readFile( builtins.fetchGit {
      url = "https://git.gay/freeplay/Firefox-Onebar";
      rev = "8237638270551b254a823c47bd9fa4d8b0b69fa9";
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
    inputs.textfox.homeManagerModules.default
  ];
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      nativeMessagingHosts = [
        pkgs.tridactyl-native
        pkgs.browserpass
        #pkgs.fx-cast-bridge
      ];
      extraPolicies = {
        Extensions = { Install = [
          #"https://github.com/hensm/fx_cast/releases/download/v0.3.1/fx_cast-0.3.1.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/imagus/latest.xpi"
          #"https://addons.mozilla.org/firefox/downloads/latest/roseppuccin/latest.xpi"
          #"https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi"
          #"https://tridactyl.cmcaine.co.uk/betas/tridactyl-latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/stylebot-web/latest.xpi"
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
        userChrome = (onebar-css + builtins.readFile ./firefox_css.css);
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          #bypass-paywalls-clean
          ublock-origin
          darkreader
          user-agent-string-switcher
          redirector
          #tampermonkey
          tridactyl
          firemonkey
          consent-o-matic
          decentraleyes
          canvasblocker
          browserpass
          videospeed
          firefox-translations
          adaptive-tab-bar-colour
        ];
      };
      private = {
        id = 1;
        userChrome = onebar-css;
        extraConfig = builtins.readFile(builtins.fetchGit {
          url = "https://codeberg.org/Narsil/user.js";
          rev = "42988c09080695802c4fdbe5d3d9fa1a01315c2a"; }
          + "/desktop/user.js") ;
      };
      tracking = {
        id = 2;
        settings = {
          "privacy.trackingprotection.enabled" = false;
        };
      };
      textfox.id = 3;
      alpha = {
        id = 4;
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
        id = 5;
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
  textfox = {
    enable = false;
    profile = "textfox";
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
