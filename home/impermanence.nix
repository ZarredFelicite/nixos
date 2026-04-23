{ ... }: {
  home.persistence."/persist" = {
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
      ".local/state"
      ".mozilla"
      ".thunderbird"
      ".tor project"
      ".android"
      ".java"
      ".vscode-oss"
      ".claude"
      ".cursor"
      ".opencode"
      ".gemini"
      ".codex"
      ".antigravity"
      ".openclaw"
      ".nanobot"
      ".ember"
      # PERSISTENT .CONF
      ".config/skills"
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
      ".config/Cursor"
      ".config/opencode"
      ".config/agent"
      ".config/pi"
      ".config/syncthing"
      ".config/ignis"
      ".config/ags"
      ".config/quickshell"
      ".config/Mullvad VPN"
      ".config/Upscayl"
      ".config/mpv"
      ".config/streamrip"
      ".config/comfy-ui"
      ".config/Antigravity"
      ".config/rncbc.org" # qpwgraph
      ".config/tasknotes-cli"
      ".config/qmd"
      # PERSISTENT .CACHE
      ".cache"
      ".cache/thunderbird"
    ];
    files = [
      ".config/wtwitch/api.json"
      ".sops.yaml"
      ".config/syncthingtray.ini"
      ".claude.json"
      ".config/nvtop/interface.ini"
      ".config/vicinae/settings.json"
    ];
  };
}
