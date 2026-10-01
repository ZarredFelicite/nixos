{ hyprlock-private, ... }:
final: prev: {
  hyprlock = prev.hyprlock.overrideAttrs (_: {
    version = "0.9.2";
    src = hyprlock-private;
  });
}
