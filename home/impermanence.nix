{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];
  home.persistence."/persist/home/zarred" = {
    directories = [
      # userDirs
      "downloads"
      "documents" # syncthing
      "pictures" # syncthing
      "videos" # syncthing
      "sync" # syncthing
      "scripts" # syncthing
      "nb"
      ".mail"
      "games"
      "dots"
      "dev" # syncthing
      ".gnupg"
      ".ssh"
      ".nixops"
      ".local/share"
      ".cache"
      ".mozilla"
      ".android"
      ".java"
      ".config/kdeconnect"
      ".config/BraveSoftware"
      ".config/PrusaSlicer"
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
    ];
    files = [
      ".config/wtwitch/api.json"
      ".sops.yaml"
    ];
    allowOther = true;
  };
}
