{ pkgs, inputs, ... }:
let
  css = ( builtins.readFile( builtins.fetchGit {
      url = "https://codeberg.org/Freeplay/Firefox-Onebar";
      rev = "efc2ce9634f0cfc47e92535fa32b52aacf2d97da";
    } + "/userChrome.css" ) + builtins.readFile ./firefox_css.css);
in {
  imports = [
    ./tridactyl.nix
  ];
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override {
      nativeMessagingHosts = [
        pkgs.tridactyl-native
        pkgs.browserpass
        pkgs.fx-cast-bridge
      ];
      extraPolicies = {
        Extensions = { Install = [
          "https://github.com/hensm/fx_cast/releases/download/v0.3.1/fx_cast-0.3.1.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/imagus/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/roseppuccin/latest.xpi"
          "https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi"
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
        userChrome = css;
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          #bypass-paywalls-clean
          ublock-origin
          darkreader
          user-agent-string-switcher
          redirector
          #tampermonkey
          firemonkey
          consent-o-matic
          decentraleyes
          canvasblocker
          browserpass
          videospeed
          firefox-translations
        ];
      };
      private = {
        id = 1;
        userChrome = css;
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
    };
  };
  home.packages = with pkgs; [
    buku # Private cmdline bookmark manager
    #(callPackage ./firefox_openwith/derivation.nix {})
  ];
  xdg.configFile."com.add0n.node.json" = {
    source = ./firefox_openwith/com.add0n.node.json;
    target = "../.mozilla/native-messaging-hosts/com.add0n.node.json";
  };
}
