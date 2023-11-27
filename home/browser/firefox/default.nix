{ pkgs, ... }:
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
      #    #"https://gitlab.com/magnolia1234/bpc-uploads/-/raw/master/bypass_paywalls_clean-3.3.1.0.xpi"
      #    # https://github.com/hensm/fx_cast
          "https://github.com/hensm/fx_cast/releases/download/v0.3.1/fx_cast-0.3.1.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/useragent-switcher/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/redirector/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/consent-o-matic/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/imagus/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/roseppuccin/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/bukubrow/latest.xpi"
      #    # https://github.com/browserpass/browserpass-extension
      #    #"https://addons.mozilla.org/firefox/downloads/latest/browserpass-ce/latest.xpi"
          "https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi"
      #    "https://tridactyl.cmcaine.co.uk/betas/tridactyl-latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi"
      #    #"https://addons.mozilla.org/firefox/downloads/latest/global-speed/latest.xpi"
      #    "https://addons.mozilla.org/firefox/downloads/latest/traduzir-paginas-web/latest.xpi"
          "https://addons.mozilla.org/firefox/downloads/latest/stylebot-web/latest.xpi"
        ];};
        #ExtensionSettings =
        #let common = { installation_mode = "force_installed"; }; in {
        #  "*".installation_mode = "allowed";
        #  "uBlock0@raymondhill.net" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";} // common;
        #  "addon@darkreader.org" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";} // common;
        #  "a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/useragent-switcher/latest.xpi";}//common;
        #  "redirector@einaregilsson.com" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/redirector/latest.xpi";}//common;
        #  "afda92c3-008d-4d08-8766-3f1571995071" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/tokyo-night-milav/latest.xpi";}//common;
        #  "firefox@tampermonkey.net" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/tampermonkey/latest.xpi";}//common;
        #  "gdpr@cavi.au.dka" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/consent-o-matic/latest.xpi";}//common;
        #  "jid1-BoFifL9Vbdl2zQ@jetpack" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";}//common;
        #  "45f2dc53-96cd-4c41-91f6-f4a73a8fb2b0" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/tab-manager-plus-for-firefox/latest.xpi";}//common;
        #  "00000f2a-7cde-4f20-83ed-434fcb420d71" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/imagus/latest.xpi";}//common;
        #  "magnolia@12.34" = { install_url = "https://gitlab.com/magnolia1234/bpc-uploads/-/raw/master/bypass_paywalls_clean-3.3.1.0.xpi";}//common;
        #  "eef1cbcd-40e9-44b5-aef1-0d7c4f97bbdd" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/roseppuccin/latest.xpi";}//common;
        #};
      };
      #extraPrefs = builtins.readFile(./mozilla.cfg);
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
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ];
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
