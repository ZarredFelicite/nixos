{ hyprgrass ? null, ... }:

(self: super: if hyprgrass != null then {
  hyprgrass = hyprgrass.packages."${self.system}".default.override {
    # override to use hyprland from nixpkgs instead of the flake one
    inherit (self) hyprland;
  };
} else {})
