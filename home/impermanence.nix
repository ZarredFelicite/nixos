{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];
  home.persistence."/persist/home/zarred" = {
    directories = [
      "downloads"
      "music"
      "pictures"
      "documents"
      "videos"
      "sync"
      "scripts"
      "nb"
      "mail"
      "games"
      "dots"
      "dev"
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
    ];
    files = [
      ".config/wtwitch/api.json"
      ".sops.yaml"
    ];
    allowOther = true;
  };
}
