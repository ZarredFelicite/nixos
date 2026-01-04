# Hyprland v0.53 Update Guide & Configuration Changes

Based on the [Hyprland 0.53 Release](https://hypr.land/news/update53), significant breaking changes were introduced. Below is a detailed list of changes required for your NixOS/Home-Manager configuration.

## ⚠️ Breaking Changes (Immediate Action Required)

### 1. Window & Layer Rule Syntax Overhaul
The old comma-separated string syntax (`"effect, match"`) is deprecated and has been replaced by a property-based matching system. All rules in `home/desktop/hyprland/rules.nix` must be converted.

*   **Old Format:** `"float, class:^(nova)$"`
*   **New Format:** `windowrule = match:class ^(nova)$, float`
*   **Key Property Changes:**
    *   `class` -> `match:class`
    *   `title` -> `match:title`
    *   `initialTitle` -> `match:initial_title`
    *   `initialClass` -> `match:initial_class`
    *   `onworkspace` -> `match:workspace`
    *   `floating:1` -> `match:float true`

**Layer Rules Example:**
*   **Old:** `"blur, waybar"`
*   **New:** `layerrule = match:namespace waybar, blur`

### 2. Fullscreen Focus Logic
The options `misc:new_window_takes_over_fullscreen` and `master:inherit_fullscreen` have been consolidated.
*   **Change in `default.nix`:** Replace `new_window_takes_over_fullscreen = 2;` with `on_focus_under_fullscreen = 2;`.

### 3. Launch Wrapper
Hyprland should now be launched using the `start-hyprland` wrapper to enable crash recovery and safe mode features.
*   **Change in `roles/desktop.nix`:** Update lines 154 and 162 to use `${hyprland}/bin/start-hyprland` instead of `${hyprland}/bin/Hyprland`.

### 4. Hyprpaper v0.8.0 Syntax
If updating `hyprpaper` to 0.8.0, the flat list syntax is replaced by configuration blocks.
*   **New Block Style:**
    ```nix
    wallpaper {
        monitor = eDP-1
        path = ~/pictures/wallpapers/nasa-eye-nano-wallpaper.jpg
    }
    ```

---

## ✨ New Features to Leverage

### 1. Groupbar Blurring
You can now blur the groupbar (tabs for grouped windows).
*   **Implementation:** Add `group.groupbar.blur = true;` in `home/desktop/hyprland/default.nix`.

### 2. Tablet Improvements (Surface Host)
A new option to hide the cursor after tablet input is available.
*   **Implementation:** Add `cursor.hide_on_tablet = true;` in `home/desktop/hyprland/default.nix`.

### 3. Safe Mode
The new safe mode relies on `hyprland-guiutils`. Ensure this is added to your system packages to allow for recovery if the configuration fails to load.

---

## 🔗 Relevant Documentation
*   [Update 53 News](https://hypr.land/news/update53)
*   [New Window Rule Wiki](https://wiki.hypr.land/Configuring/Window-Rules/)
*   [Hyprpaper Wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/)
