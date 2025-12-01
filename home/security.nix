{ config, osConfig, pkgs, pkgs-unstable, lib, ... }:
let
  pinentryRofi = pkgs.writeShellApplication {
    name= "pinentry-rofi-with-env";
    text = ''
      set -eu
      PINENTRY_TERMINAL="${pkgs.pinentry-curses}/bin/pinentry-curses"
      if [ -n "''${DISPLAY-}" ]; then
        #exec "$PINENTRY_GNOME" "$@"
        PATH="$PATH:${pkgs.coreutils}/bin:${pkgs.rofi}/bin"
        "${pkgs.pinentry-rofi}/bin/pinentry-rofi" "$@"
      else
        exec "$PINENTRY_TERMINAL" "$@"
      fi
    '';
  };
in {
  home.packages = [
    pkgs.proton-pass
    pkgs.protonvpn-gui
    pkgs.protonmail-desktop
    pkgs-unstable.proton-authenticator
  ];
  programs.password-store = {
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
    ]);
    settings = {
      PASSWORD_STORE_DIR = "/home/zarred/sync/password-store";
      PASSWORD_STORE_CLIP_TIME = "60";
      PASSWORD_STORE_GENERATED_LENGTH = "20";
    };
  };
  programs.gpg = {
    enable = true;
    settings = {
      #default-key = "BEF3920E6B79FF4A4F817838844F26D1BCAE35C9";
      default-recipient-self = true;
      auto-key-locate = "local,wkd,keyserver";
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
      auto-key-import = true;
      keyserver-options = "honor-keyserver-url";
    };
  };
  #home.file.".pam-gnupg".text = "1504329BCE4AE308C2218F2CD276AC444633E146";
  home.file.".pam-gnupg".text = "BEF3920E6B79FF4A4F817838844F26D1BCAE35C9";
  services.gpg-agent = {
    enable = true;
    sshKeys = [
      "BEF3920E6B79FF4A4F817838844F26D1BCAE35C9"
      #"4AFAAA07700925FBEF6260C4862B0A3BC164D71F"
      #"1504329BCE4AE308C2218F2CD276AC444633E146"
    ];
    enableSshSupport = true;
    enableScDaemon = false;
    enableZshIntegration = true;
    pinentry.package = null;
    defaultCacheTtl = 60480000;
    defaultCacheTtlSsh = 60480000;
    maxCacheTtl = 60480000;
    maxCacheTtlSsh = 60480000;
    grabKeyboardAndMouse = false;
    verbose = true;
    extraConfig = ''
      pinentry-program ${pinentryRofi}/bin/pinentry-rofi-with-env
      allow-preset-passphrase
      no-allow-external-cache
    '';
  };
    #systemd.user.services.lock-target = {
    #  Unit.Description = "Lock using hyprlock with loginctl lock-session";
    #  Unit.PartOf = [ "lock.target" ];
    #  Unit.OnSuccess = [ "unlock.target" ];
    #  Unit.After = [ "lock.target" ];
    #  Install.WantedBy = [ "lock.target" ];
    #  #Service.ExecStart = "${pkgs.hyprlock}/bin/hyprlock --immediate-render --no-fade-in";
    #  Service.ExecStart = "/home/zarred/scripts/sys/lock.sh";
    #  Service.Type = "forking";
    #  Service.Restart = "on-failure";
    #  Service.RestartSec = "0";
    #};
    #systemd.user.services.suspend-target = {
    #  Unit.Description = "Lock using loginctl before suspend";
    #  Unit.PartOf = [ "sleep.target" ];
    #  Install.RequiredBy = [ "sleep.target" ];
    #  Service.ExecStart = "loginctl lock-session";
    #  #Service.Type = "forking";
    #};
  systemd.user.services.suspend-delay = {
    Unit.Description = "Wait 1s before suspend";
    Unit.Before = [ "sleep.target" ];
    Install.WantedBy = [ "sleep.target" ];
    #Service.ExecStartPre = "/run/current-system/sw/bin/sleep 1";
    Service.ExecStartPre = "/home/zarred/scripts/sys/pre-suspend.sh";
    Service.ExecStart = "/run/current-system/sw/bin/true";
    Service.Type = "simple";
  };
  services.hypridle = {
    settings.general = {
      lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock --immediate --immediate-render --no-fade-in -q"; # avoid starting multiple hyprlock instances.
      before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
      #after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
      after_sleep_cmd = "/home/zarred/scripts/sys/post-suspend.sh"; # to avoid having to press a key twice to turn on the display.
    };
    settings.listener = [
      {
        timeout = 150;
        on-timeout = "${pkgs.brillo}/bin/brillo -O; ${pkgs.brillo}/bin/brillo -S 10 -u 10000000";
        on-resume = "${pkgs.procps}/bin/pkill brillo; ${pkgs.brillo}/bin/brillo -I -u 500000";
      }
      {
        timeout = 150;
        on-timeout = "${pkgs.brillo}/bin/brillo -k -s tpacpi::kbd_backlight -S 50 -u 10000000";
        on-resume = "${pkgs.brillo}/bin/brillo -k -s tpacpi::kbd_backlight -S 100 -u 10000000";
      }
      {
        timeout = 300;
        on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
      }
      {
        timeout = 330;
        on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"; # screen off when timeout has passed
        on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired.
      }
      {
        timeout = 900;
        on-timeout = "systemctl suspend"; # suspend pc
      }
    ];
  };
}
