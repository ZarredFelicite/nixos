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
      ".config/kdeconnect"
      ".config/BraveSoftware"
      ".config/PrusaSlicer"
      ".config/Caprine"
      ".config/cava"
      ".config/OpenRGB"
      ".config/keyboard"
      ".config/gh"
    ];
    files = [
      ".config/wtwitch/api.json"
      ".sops.yaml"
    ];
    allowOther = true;
  };
}
