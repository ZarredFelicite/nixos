{ osConfig, config, pkgs, lib, ... }:
{
  home.packages = [
    pkgs.mpc-cli # A minimalist command line interface to MPD
  ];
  services = {
    mpdris2 = {
      enable = true;
      mpd = {
        host = osConfig.services.mpd.network.listenAddress;
        #musicDirectory = osConfig.services.mpd.musicDirectory;
        musicDirectory = null;
        port = osConfig.services.mpd.network.port;
      };
      multimediaKeys = true;
    };
  };
  systemd.user.services.mpdris2.Unit.Requires = lib.mkForce "mpd.service";
  systemd.user.services.mpdris2.Unit.After = lib.mkForce "mpd.service";
  #systemd.user.services.mpd.Service.ExecStartPre = lib.mkForce "";
  #systemd.user.services.mpd.Unit.After = lib.mkForce "mnt-gargantua.automount";
  programs = {
    ncmpcpp = {
      enable = true;
      bindings = [
        { key = "e"; command = "scroll_down"; }
        { key = "i"; command = "scroll_up"; }
        { key = "right"; command = [ "next_column" "enter_directory" "run_action" "play_item" ]; }
        { key = "left"; command = "previous_column"; }
        { key = "o"; command = [ "next_column" "enter_directory" "run_action" "play_item" ]; }
        { key = "n"; command = "previous_column"; }

        { key = "ctrl-o"; command = "play_item"; }
        { key = "O"; command = "select_item"; }

        { key = "ctrl-e"; command = "volume_down"; }
        { key = "ctrl-i"; command = "volume_up"; }
        { key = "E"; command = "seek_backward"; }
        { key = "I"; command = "seek_forward"; }

        { key = "space"; command = "pause"; }
        { key = "h"; command = "next_found_item"; }
        { key = "k"; command = "previous_found_item"; }

        { key = "x"; command = "delete_playlist_items"; }
        { key = "p"; command = "show_playlist"; }
        { key = "b"; command = "show_browser"; }
        { key = "l"; command = "show_lyrics"; }
        { key = "/"; command = "find"; }
        { key = "?"; command = "show_help"; }
      ];
      mpdMusicDir = osConfig.services.mpd.musicDirectory;
      settings = {
        mpd_host = osConfig.services.mpd.network.listenAddress;
        mpd_port = osConfig.services.mpd.network.port;
        #lyrics_directory = osConfig.services.mpd.musicDirectory;
        store_lyrics_in_song_dir = "yes";
        lines_scrolled = 1;
        execute_on_song_change = "~/scripts/music/song_change.py & >/dev/null";
        #execute_on_player_state_change = "~/scripts/music/song_change.py & >/dev/null";
        song_columns_list_format = "(33)[]{t} (25f)[]{b} (10)[]{a}";
        song_status_format = "{{%a{ \"%b\"} - }{%t}}|{%f}";
        song_list_format = "{%t}|{%f}$R{%b}";
        song_library_format = "{%t}|{%f}";
        current_item_prefix = "$4 ⏽ ";
        current_item_suffix = "$(end)";
        now_playing_prefix = "$3";
        now_playing_suffix = "$(end)";
        current_item_inactive_column_prefix = "$3";
        current_item_inactive_column_suffix = "$(end)";
        media_library_primary_tag = "album_artist";
        media_library_albums_split_by_date = "no";
        media_library_hide_album_dates = "no";
        titles_visibility = "no";
        display_volume_level = "yes";
        visualizer_output_name = "PipeWire Sound Server";
        playlist_display_mode = "classic";
        browser_display_mode = "columns";
        search_engine_display_mode = "columns";
        playlist_editor_display_mode = "columns";
        autocenter_mode = "yes";
        centered_cursor = "yes";
        user_interface = "alternative";
        header_visibility = "no";
        header_text_scrolling = "yes";
        statusbar_visibility = "yes";
        connected_message_on_startup = "no";
        startup_screen = "media_library";
        screen_switcher_mode = "help, playlist, browser, search_engine, media_library, playlist_editor, tag_editor, outputs, clock, lyrics";
        jump_to_now_playing_song_at_start = "yes";
        seek_time = "5";
        progressbar_look = "▔▔▔";
        lastfm_preferred_language = "en";
        external_editor = "nvim";
        use_console_editor = "yes";
        colors_enabled = "yes";
        empty_tag_color = "blue";
        header_window_color = "blue";
        volume_color = "blue";
        state_line_color = "yellow";
        main_window_color = "blue";
        color1 = "yellow";
        color2 = "cyan";
        progressbar_color = "cyan";
        progressbar_elapsed_color = "blue";
        alternative_ui_separator_color = "cyan";
        window_border_color = "black";
        statusbar_color = "yellow";
        player_state_color = "cyan";
      };
    };
  };
}
