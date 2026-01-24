{ pkgs, pkgs-unstable, osConfig, ... }:
#let
  #mpv-quality-menu = pkgs.callPackage ./plugins/mpv-quality-menu.nix { };
#in {
{
  disabledModules = [
    "programs/mpv.nix"
  ];
  imports = [
    ../../../modules/mpv.nix
  ];
  home.packages = [
    pkgs.mpvc # A mpc-like control interface for mpv
    pkgs.playerctl # Command-line utility and library for controlling media players that implement MPRIS
  ];
  stylix.targets.mpv.enable = false;
  xdg.configFile."mpv/script-opts/uosc.conf".source = ./plugins/uosc.conf;
  # TODO:add way to disable skipping before enabling. xdg.configFile."mpv/scripts/skip_chapters.lua".source = ./plugins/skip_chapters.lua;
  xdg.configFile."mpv/scripts/sponsorblock_minimal.lua".source = ./plugins/sponsorblock_minimal.lua;
  xdg.configFile."mpv/scripts/history.lua".source = ./plugins/mpvhistory.lua;
  xdg.configFile."mpv/scripts/jellyfin.lua".source = ./plugins/jellyfin.lua;
  xdg.configFile."mpv/scripts/easycrop.lua".source = ./plugins/easycrop.lua;
  xdg.configFile."mpv/scripts/clear-old-buffers.lua".source = ./plugins/clear-old-buffers.lua;
  programs.mpv = {
    enable = true;
    config = {
      #profile = "gpu-hq";
      osc = false;
      osd-bar = false;
      border = false;
      #video-sync= "display-resample"; # fix slow UI - more CPU/GPU
      osd-font = "IosevkaTerm NFM";
      osd-font-size = 16;
      osd-color = "#ebbcba";
      term-osd-bar = true;
      #term-osd-bar-chars = "▕▒█░▏";
      term-osd-bar-chars = "⣿⣿⣿⣉⣿";

      save-position-on-quit = false;
      watch-later-options-remove = [ "mute" "volume" "fullscreen" ];
      watch-later-directory = "~/sync/mpv/watch-state";
      write-filename-in-watch-later-config = true;

      force-window = "yes";
      msg-level = "cplayer=warn,ffmpeg/demuxer=warn,display-tags=warn,autoload=warn,auto_save_state=warn,osd/libass=warn";
      keep-open = true;
      keepaspect = true;
      autofit = "100%x100%";
      panscan = 1.0;
      hwdec = "auto-safe";
      vo = "gpu-next";
      gpu-api = "opengl";
      gpu-context = "wayland";
      hwdec-codecs = "all";

      # Deband;
      ## Debanding settings are divided into 3 modes: light, medium & heavy.;
      ##   Light: 1:35:16:5  |  Medium: 2:60:20:24  |  Heavy: 3:100:25:48;
      ## Light mode is used by default.;
      ## You can cycle through the deband modes with shift+b (see input.conf).;
      deband-iterations = 1;    # Higher: Reduce more banding but more GPU usage; >4 is redundant [Default: 1, <1..16>];
      deband-threshold = 35;    # Higher: Increase debanding strength [Default: 32, <0..4096>];
      deband-range = 16;        # Higher: Find more gradients; Lower: Smooth more aggressively [Default: 16, <1..64>];
      deband-grain = 5;         # Higher: Add more noise to cover up banding [Default: 48, <0..4096>];

      pause = false;
      volume = 100;
      volume-max = 125;
      mute = false;
      audio-file-auto = "fuzzy";
      embeddedfonts = false;
      sub-visibility = false;
      subs-with-matching-audio = false;
      sub-font = "IosevkaTerm NFM";
      sub-font-size = 24;
      sub-auto = "fuzzy";
      demuxer-mkv-subtitle-preroll = true;
      #demuxer-max-bytes = 419430400;
      #demuxer-max-back-bytes = 419430400;
      demuxer-max-bytes = "512MiB";
      demuxer-readahead-secs = 60;
      demuxer-max-back-bytes = "512MiB";
      prefetch-playlist = false;     # Don't preload next video (saves memory)
      demuxer-lavf-o = "extension_picky=0";
      slang = "eng,en";
      vlang = "eng,en";
      screenshot-template = "%X{~~desktop/}%F [%wH.%wM.%wS.%wT]";
      screenshot-format = "png";
      screenshot-tag-colorspace = true;       # Tag screenshots with the appropriate colorspace
      screenshot-png-compression = 5;
      msg-color = true;
      msg-module = true;
      script-opts = "ytdl_hook-try_ytdl_first=yes,ytdl_hook-exclude='%.webm$|%.ts$|%.mp3$|%.m3u8$|%.m3u$|%.mkv$|%.mp4$|%.VOB$',ytdl_hook-ytdl_path=/run/current-system/sw/bin/yt-dlp";
      #ytdl-format = "bestvideo[height<=?1080]+bestaudio";
    };
    profiles = {
      gpu-hq = {
        profile-restore = "copy";
        deband = false;
        gpu-api = "vulkan";
        glsl-shader = "~~/shaders/FSRCNNX_x2_8-0-4-1.glsl";
      };
      autocopy-fix = {
        profile-desc = "Fix abnormal stuttering when using auto-copy on >4K videos";
        profile-cond = "width >= 3840 and height >= 2160";
        profile-restore = "copy";
      };
    };
    scripts = with pkgs-unstable.mpvScripts; [
      #uosc
      mpris
      #mpv-playlistmanager
      webtorrent-mpv-hook
      quality-menu
      thumbfast
      acompressor
      #autocrop
    ];
    scriptOpts = {
      osc = {
        scalewindowed = 2.0;
        vidscale = false;
        visibility = "always";
      };
      quality-menu = {
        up_binding = "UP";
        down_binding = "DOWN";
        select_binding = "RIGHT ENTER MBTN_LEFT";
        close_menu_binding = "ESC LEFT";
        scale_playlist_by_window = true;
        style_ass_tags = "{\\fnIosevkaTerm NFM\\fs20}";
        text_padding_x = 30;
        text_padding_y = 30;
        curtain_opacity = 0.7;
        menu_timeout = 5;
        fetch_formats = false;
        #quality_strings_video = ''
        #  [ {"Best" : "best"}, {"1080p" : "bestvideo[height<=?1080]+bestaudio/best"}, {"2160p" : "bestvideo[height<=?2160]"}, {"1440p" : "bestvideo[height<=?1440]"}, {"1080p" : "bestvideo[height<=?1080]"}, {"720p" : "bestvideo[height<=?720]+ba"}]
        #'';
      };
      jellyfin = {
        url = "http://sankara:8096";
        username = "zarred";
        password = "${builtins.readFile osConfig.sops.secrets.jellyfin-zarred.path}";
        image_path = "/tmp/mpv-jellyfin";
        hide_images = "off";
        hide_spoilers = "off";
        show_by_default = "off";
          # Show the script's UI again once file playback has ended. Requires
          # mpv to be started with the --idle flag so that the window persists
          # after playback has finished.
          # Defaults to off
          # ex. on
        show_on_idle = "off";
        use_playlist = "on";
        # colour_default=FFFFFF
        # colour_selected=FF
        # colour_watched=A0A0A0
      };
    };
    bindings = {
      ENTER             = "cycle pause; script-binding uosc/flash-pause-indicator";
      SPACE             = "cycle pause; script-binding uosc/flash-pause-indicator";
      LEFT              = "seek -5; script-binding uosc/flash-timeline";
      RIGHT             = "seek 5; script-binding uosc/flash-timeline";
      DOWN              = "seek -5; script-binding uosc/flash-timeline";
      UP                = "seek 5; script-binding uosc/flash-timeline";
      "shift+LEFT"      = "seek -15; script-binding uosc/flash-timeline";
      "shift+RIGHT"     = "seek 15; script-binding uosc/flash-timeline";
      "shift+DOWN"      = "add chapter -1; script-binding uosc/flash-timeline";
      "shift+UP"        = "add chapter 1; script-binding uosc/flash-timeline";
      "Ctrl+UP"         = "no-osd sub-seek 1";
      "Ctrl+DOWN"       = "no-osd sub-seek -1";
      "["               = "script-binding uosc/prev; script-message-to uosc flash-elements top_bar,timeline     #! Navigation > Prev";
      "]"               = "script-binding uosc/next; script-message-to uosc flash-elements top_bar,timeline     #! Navigation > Next";
      WHEEL_UP          = "seek 5; script-binding uosc/flash-timeline";
      WHEEL_DOWN        = "seek -5; script-binding uosc/flash-timeline";
      WHEEL_LEFT        = "add speed -0.1; script-binding uosc/flash-speed";
      WHEEL_RIGHT       = "add speed 0.1; script-binding uosc/flash-speed";
      "Ctrl+WHEEL_UP"   = "add sub-scale 0.1";
      "Ctrl+WHEEL_DOWN" = "add sub-scale -0.1";
      "Alt+0"           = "set window-scale 0.5";
      e                 = "no-osd add speed -0.1; script-binding uosc/flash-speed";
      i                 = "no-osd add speed 0.1; script-binding uosc/flash-speed";
      h                 = "no-osd set speed 1.0; script-binding uosc/flash-speed";
      n                 = "seek -5; script-binding uosc/flash-timeline";
      o                 = "seek 5; script-binding uosc/flash-timeline";
      y                 = "cycle-values video-aspect '0' '-1' '16:9' '4:3' '2:1' '2.21:1' '1.6:1'";
      R                 = "cycle-values video-rotate '90' '180' '270' '0'";
      b                 = "cycle-values deband 'yes' 'no'";
      B                 = "cycle-values deband-iterations '1' '2' '3'; cycle-values deband-threshold '35' '60' '100'; cycle-values deband-range '16' '20' '25'; cycle-values deband-grain '5' '24' '48'; show-text 'Deband: \${deband-iterations}:\${deband-threshold}:\${deband-range}:\${deband-grain}'";
      #x                 = "apply-profile gpu-hq; show-text 'Profile: GPU-HQ'";
      g                 = "cycle-values hwdec 'auto' 'no'";
      X                 = "apply-profile hq restore; show-text 'Profile: Default'";
      Q                 = "set save-position-on-quit no; quit; delete-watch-later-config";
      "ctrl+i"          = "cycle-values vf 'lavfi=negate' ''";
      c                 = "script-binding easy_crop";
      "ctrl+c"          = "script-binding save_cropped_video";
      #C                 = "script-message-to toggle-acompressor toggle_acompressor";
      f                 = "no-osd set fs-screen 1; cycle fullscreen; cycle-values panscan 0.0 1.0";
      "ctrl+s"          = "async screenshot                       #! Utils > Screenshot";
      "ctrl+shift+s"    = "script-message toggle_sponsorblock";
      "ctrl+I"          = "no-osd cycle-values glsl-shaders '~~/shaders/invert.glsl' '' ; show-text 'Invert Shader'";
      "tab"             = "script-binding uosc/toggle-ui";
      esc               = "script-binding uosc/menu";
      a                 = "script-binding uosc/audio              #! Audio tracks";
      r                 = "script-binding uosc/items                                            #! Playlist";
      "ctrl+r"          = "script-binding playlistmanager/reverse";
      s                 = "script-binding uosc/chapters                                         #! Chapters";
      w                 = "script-binding uosc/stream-quality                                   #! Stream quality";
      p                 = "add panscan -0.1";
      P                 = "add panscan 0.1";
      q                 = "quit  #!";
      menu              = "script-binding uosc/menu";
      mbtn_right        = "script-binding uosc/menu";
      S                 = "script-binding uosc/subtitles          #! Subtitles";
      O                 = "script-binding uosc/show-in-directory  #! Utils > Show in directory";
      "#1"               = "script-binding uosc/open-file          #! Navigation > Open file";
      "#2"               = "set video-aspect-override '-1'         #! Utils > Aspect ratio > Default";
      "#3"               = "set video-aspect-override '16:9'       #! Utils > Aspect ratio > 16:9";
      "#4"               = "set video-aspect-override '4:3'        #! Utils > Aspect ratio > 4:3";
      "#5"               = "set video-aspect-override '2.35:1'     #! Utils > Aspect ratio > 2.35:1";
      "#6"               = "script-binding uosc/audio-device       #! Utils > Audio devices";
      "#7"               = "script-binding uosc/editions           #! Utils > Editions";
      "#8"               = "script-binding uosc/open-config-directory #! Utils > Open config directory";
    };
  };
}
