{ config, pkgs, lib, ... }: {
  programs.password-store = {
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
    ]);
    settings = {
      PASSWORD_STORE_DIR = "sync/password-store";
      PASSWORD_STORE_CLIP_TIME = "60";
      PASSWORD_STORE_GENERATED_LENGTH = "20";
    };
  };
  programs.gpg = {
    enable = true;
    settings = {
      default-key = "1504329BCE4AE308C2218F2CD276AC444633E146";
      default-recipient-self = true;
      auto-key-locate = "local,wkd,keyserver";
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
      auto-key-import = true;
      keyserver-options = "honor-keyserver-url";
    };
  };
  home.file.".pam-gnupg".text = "1504329BCE4AE308C2218F2CD276AC444633E146";
  services.gpg-agent = {
    enable = true;
    sshKeys = [
      "4AFAAA07700925FBEF6260C4862B0A3BC164D71F"
      "1504329BCE4AE308C2218F2CD276AC444633E146"
    ];
    enableSshSupport = true;
    enableScDaemon = false;
    enableZshIntegration = true;
    pinentryPackage = null;
    defaultCacheTtl = 60480000;
    defaultCacheTtlSsh = 60480000;
    maxCacheTtl = 60480000;
    maxCacheTtlSsh = 60480000;
    grabKeyboardAndMouse = false;
    verbose = true;
  };
  services.hypridle = {
    settings.general = {
      lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";       # avoid starting multiple hyprlock instances.
      before_sleep_cmd = "loginctl lock-session";    # lock before suspend.
      after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";  # to avoid having to press a key twice to turn on the display.
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
        on-timeout = "loginctl lock-session";            # lock screen when timeout has passed
      }
      {
        timeout = 330;
        on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";        # screen off when timeout has passed
        on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";          # screen on when activity is detected after timeout has fired.
      }
      {
        timeout = 900;
        on-timeout = "systemctl suspend";                # suspend pc
      }
    ];
  };
}
