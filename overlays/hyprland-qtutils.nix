final: prev: 
let
  patchedQtUtils = prev.hyprland-qtutils.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      (final.fetchpatch {
        name = "Fix build with Qt 6.10";
        url = "https://github.com/hyprwm/hyprland-qtutils/commit/5ffdfc13ed03df1dae5084468d935f0a3f2c9a4c.patch";
        hash = "sha256-5nVj4AFJpmazX9o9tQD6mzBW9KtRYov4yRbGpUwFcgc=";
      })
    ];
  });
in
{
  hyprland-qtutils = patchedQtUtils;
  hyprland = prev.hyprland.override {
    hyprland-qtutils = patchedQtUtils;
  };
  xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.override {
    hyprland = final.hyprland;
  };
}
