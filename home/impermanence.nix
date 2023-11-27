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
      ".gnupg"
      ".ssh"
      ".nixops"
      ".local/share"
      ".cache"
      ".mozilla"
      ".config/kdeconnect"
      ".config/BraveSoftware"
      ".config/PrusaSlicer"
      ".config/Caprine"
      ".config/cava"
      ".config/syncthing"
    ];
    files = [
      ".config/wtwitch/api.json"
    ];
    allowOther = true;
  };
}
