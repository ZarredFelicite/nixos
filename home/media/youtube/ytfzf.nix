{ pkgs, ... }: {
  home.packages = [
    pkgs.ytfzf # A posix script to find and watch youtube videos from the terminal
  ];
  xdg.configFile."ytfzf/conf.sh".text = ''
    ytdl_pref="best"
    show_thumbnails=1
    thumbnail_viewer="wayland"
    thumbnail_quality="high"
    #fzf_preview_side="down"
    is_detach=1
    keep_cache=1
    is_loop=1
    async_thumbnails=1
    notify_playing=0
    fancy_subs=1
    max_thread_count=24
    search_region="AU"
    log_level=1
    #invidious_instance="https://yt.funami.tech"
    #url_handler_opts=
    #search_again=1

    linkhandler () {
	    /home/zarred/scripts/file-ops/linkhandler.sh "$@"
    }
    load_url_handler linkhandler
  '';
  xdg.configFile."ytfzf/subscriptions".source = ./subscriptions;
}
