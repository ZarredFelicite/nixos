{ config, pkgs, lib, ... }: {
  programs = {
    password-store = {
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
    swaylock = {
      settings = lib.mkDefault {
        color = "0D1117";
        ring-color = "0D1117";
        daemonize = true;
        ignore-empty-password = true;
        font-size = 24;
        indicator-idle-visible = false;
        indicator-caps-lock = true;
        indicator-radius = 200;
        line-color = "ebbcba";
        show-failed-attempts = true;
        key-hl-color = "ebbcba";
        separator-color = "00000000";
        inside-color = "00000000";
        inside-clear-color = "ffd20400";
        inside-caps-lock-color = "009ddc00";
        inside-ver-color = "d9d8d800";
        inside-wrong-color = "ee2e2400";
        ring-clear-color = "231f20D9";
        ring-caps-lock-color = "231f20D9";
        ring-ver-color = "7dcfff99";
        ring-wrong-color = "231f20D9";
        line-clear-color = "ffd20400";
        line-caps-lock-color = "009ddc00";
        line-ver-color = "7dcfff00";
        line-wrong-color = "ee2e2400";
        text-color = "ffffffff";
        text-clear-color = "ffd20400";
        text-ver-color = "d9d8d800";
        text-wrong-color = "ee2e2400";
        bs-hl-color = "ee2e24FF";
        caps-lock-key-hl-color = "ffd204FF";
        caps-lock-bs-hl-color = "ee2e24FF";
        disable-caps-lock-text = true;
        text-caps-lock-color = "009ddc";
      };
    };
  };
  programs.gpg = {
    enable = true;
    settings = {
      default-key = "1504 329B CE4A E308 C221  8F2C D276 AC44 4633 E146";
      default-recipient-self = true;
      auto-key-locate = "local,wkd,keyserver";
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
      auto-key-import = true;
      keyserver-options = "honor-keyserver-url";
    };
  };
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    enableScDaemon = false;
    enableZshIntegration = true;
    pinentryFlavor = lib.mkDefault "curses";
    defaultCacheTtl = 60480000;
    defaultCacheTtlSsh = 60480000;
    maxCacheTtl = 60480000;
    maxCacheTtlSsh = 60480000;
    grabKeyboardAndMouse = true;
    verbose = true;
  };
  services.swayidle = {
    systemdTarget = "hyprland-session.target";
    timeouts = [
      { timeout = 180; command = "~/scripts/sys/idle_brightness.sh 1 &"; resumeCommand = "~/scripts/sys/idle_brightness.sh 1"; }
      { timeout = 190; command = "if [ $(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC/online) -eq 0 ]; then ${pkgs.hyprland}/bin/hyprctl dispatch dpms off eDP-1; fi "; }
      { timeout = 300; command = "if [ $(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC/online) -eq 0 ]; then ${pkgs.systemd}/bin/systemctl suspend; fi "; }
      { timeout = 590; command = "~/scripts/sys/idle_brightness.sh 0 &"; resumeCommand = "~/scripts/sys/idle_brightness.sh 0"; }
      { timeout = 600; command = "if [ $(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC/online) -eq 1 ]; then ${pkgs.hyprland}/bin/hyprctl dispatch dpms off eDP-1; ${pkgs.swaylock}/bin/swaylock; fi "; }
    ];
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock"; }
      { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock"; }
    ];
  };
}
