{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];
  home.persistence."/persist/home/zarred" = {
    directories = [
      # VISIBLE
      "documents" # syncthing
      "pictures" # syncthing
      "videos" # syncthing
      "audio" # syncthing
      "sync" # syncthing
      "scripts" # syncthing
      "notes" # syncthing
      "downloads"
      "misc"
      "dev"
      "games"
      "dots"
      # HIDDEN
      ".mail"
      ".gnupg"
      ".ssh"
      ".nixops"
      ".local/share"
      ".cache"
      ".mozilla"
      ".thunderbird"
      ".android"
      ".java"
      ".vscode-oss"
      ".claude"
      ".cursor"
      # PERSISTENT .CONF
      ".config/kdeconnect"
      ".config/BraveSoftware"
      ".config/PrusaSlicer"
      ".config/OrcaSlicer"
      ".config/BambuStudio"
      ".config/Caprine"
      ".config/cava"
      ".config/OpenRGB"
      ".config/polychromatic"
      ".config/keyboard"
      ".config/gh"
      ".config/matlab"
      ".config/gcloud"
      ".config/lutris"
      ".config/android-studio"
      ".config/sunshine"
      ".config/spotify"
      ".config/GIMP"
      ".config/discord"
      ".config/Vencord"
      ".config/obsidian"
      ".config/VSCodium"
      ".config/Claude"
      ".config/syncthing"
    ];
    files = [
      ".config/wtwitch/api.json"
      ".sops.yaml"
      ".config/syncthingtray.ini"
      ".claude.json"
    ];
    allowOther = true;
  };
}
