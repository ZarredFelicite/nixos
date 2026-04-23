{ pkgs, ... }: {
  xdg.configFile."newsboat/urls".text = ''
    "query:ai:tags # \"ai\""
    "query:finance:tags # \"finance\""
    "query:football:tags # \"football\""
    "query:jobs:tags # \"jobs\""
    "query:later:flags # \"L\""
    "query:linux:tags # \"linux\""
    "query:news:tags # \"news\""
    "query:podcasts:tags # \"podcasts\""
    "query:shopping:tags # \"shopping\""
    "query:software:tags # \"software\""
    "query:starred:flags # \"s\""
    "query:stocks:tags # \"stocks\""
    "query:tech:tags # \"tech\" and tags !# \"yt\""
    "query:unread:unread = \"yes\" and tags !# \"unixporn\" and tags !# \"no_unread\" and tags !# \"podcasts\" and tags !# \"\""
    "query:youtube:tags # \"yt\""
  '';
  programs.newsboat = {
    enable = true;
    autoReload = true;
    reloadThreads = 100;
    reloadTime = 10;
    browser = "~/scripts/file-ops/linkhandler.sh";
    extraConfig = ''
      # -- misc ----------------------------------------------------------------------
      confirm-exit yes
      cleanup-on-quit no
      suppress-first-reload yes
      prepopulate-query-feeds yes
      scrolloff 10
      show-read-feeds yes
      text-width 200

      urls-source "freshrss"
      freshrss-url "https://freshrss.zar.red/api/greader.php"
      freshrss-login "admin"
      freshrss-passwordeval "gpg -d sync/password-store/server/freshrss-api.gpg"
      freshrss-min-items 100
      freshrss-flag-star "s"
      freshrss-show-special-feeds "true"

      external-url-viewer "/home/zarred/scripts/file-ops/urlview fzf"

      macro ENTER set browser "/home/zarred/scripts/file-ops/linkhandler.sh '%u' &"; one; open-in-browser; toggle-article-read "read"; prev; prev; set browser firefox
      macro l set browser "/home/zarred/scripts/nova/bookmark_add.sh %u"; open-in-browser; set browser firefox
      macro p set pager "/home/zarred/scripts/images/kitty-img-pager.sh 2>~/err"; open; set pager internal; open;
      macro r set browser "readable %u 2> /dev/null | w3m -T 'text/html'" ; open-in-browser ; edit-flags ; set browser firefox
      macro a set browser "python /home/zarred/.config/newsboat/read_aloud.py -u %u 2> /dev/null" ; open-in-browser ; set browser firefox
      macro z set browser "readable 'http://webcache.googleusercontent.com/search?q=cache:%u' 2> /dev/null | w3m -T 'text/html' | fold -sw 200" ; open-in-browser ; set browser firefox
      #macro ; set html-renderer "pandoc -f html -t commonmark-raw_html --wrap none > /tmp/newsboat_markdown.md"; open; set browser "kitty @ launch --type=tab --tab-title '%u' zsh -c '~/scripts/pagers/newsboat_markdown.sh'"; open-in-browser ; set browser firefox; set html-renderer internal
      macro v set browser "readable '%u' | pandoc -f html -t commonmark-raw_html --wrap none > /tmp/newsboat_markdown.md; kitty @ launch --type=tab --tab-title '%u' zsh -c '~/scripts/pagers/newsboat_markdown.sh'"; open-in-browser ; set browser firefox

      feedlist-format "%n %11u %t%d"
      articlelist-format "%-1n%-1d%-1F %D %?T?%-12T ? %t"
      datetime-format "%d/%m %H:%M"

      color info                green   default
      color listnormal          green   default
      color listnormal_unread   cyan    default
      color listfocus           yellow  default   bold
      color listfocus_unread    yellow  default   bold
      color article             cyan    default

      # Searches
      highlight all "( ai |machine learning|artifical intelligence)" green default bold
      highlight all "(Steam)" blue default bold
      highlight articlelist \bai green default bold

      # Syntax
      highlight article "^(Title):.*$" blue default bold
      highlight article "^(Feed):.*$" blue default bold
      highlight article "^(Author):.*$" blue default bold
      highlight article "(^Link:.*|^Date:.*)" green default
      highlight article "https?://[^ ]+" green default bold
      highlight article "\\[[0-9][0-9]*\\]" magenta default
      highlight article "\\[image\\ [0-9]+\\]" green default bold
      highlight article "\\[embedded flash: [0-9][0-9]*\\]" green default bold
      highlight article ":.*\\(link\\)$" green default
      highlight article ":.*\\(image\\)$" green default
      highlight article ":.*\\(embedded flash\\)$" green default
      #highlight-article "flags # \"L\"" yellow default

      unbind-key RIGHT
      unbind-key SPACE
      unbind-key LEFT
      unbind-key LEFT feedlist
      unbind-key ^D
      unbind-key Q
      unbind-key p
      unbind-key ^K
      unbind-key ^B
      unbind-key ^E
      unbind-key ^V
      unbind-key V
      unbind-key ^G

      bind-key SPACE macro-prefix
      bind-key RIGHT open
      bind-key LEFT quit
      bind-key q hard-quit
      bind-key r reload-all all
      bind-key o open-in-browser-and-mark-read
      bind-key n toggle-article-read
      bind-key b bookmark
      bind-key e edit-flags
      bind-key v view-dialogs
      bind-key u show-urls
      goto-next-feed no

      # -- bookmarks -----------------------------------------------------------------
      #bookmark-cmd ~/.config/newsboat/bookmark.sh
      bookmark-cmd ~/scripts/nova/_bookmark_add
      bookmark-interactive yes
      bookmark-autopilot no

      # -- save -----------------------------------------------------------------
      save-path ~/obsidian/saved_articles

      # -- Feed filters ------------------------
      ignore-mode "download"
    '';
  };
}
