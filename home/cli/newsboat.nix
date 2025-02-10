{ pkgs, ... }: {
  programs.newsboat = {
    enable = true;
    autoReload = true;
    reloadThreads = 100;
    reloadTime = 10;
    browser = "~/scripts/file-ops/linkhandler.sh";
    queries = {
      unread = "unread = \"yes\" and tags !# \"unixporn\" and tags !# \"no_unread\" and tags !# \"podcasts\" and tags !# \"\"";
      starred = "flags # \"s\"";
      later = "flags # \"L\"";
      youtube = "tags # \"yt\"";
      podcasts = "tags # \"podcasts\"";
      jobs = "tags # \"jobs\"";
      tech = "tags # \"tech\" and tags !# \"yt\"";
      news = "tags # \"news\"";
      ai = "tags # \"ai\"";
      shopping = "tags # \"shopping\"";
      linux = "tags # \"linux\"";
      football = "tags # \"football\"";
    };
    extraConfig = ''
      # -- misc ----------------------------------------------------------------------
      confirm-exit yes
      cleanup-on-quit no
      suppress-first-reload yes
      prepopulate-query-feeds yes
      scrolloff 10
      show-read-feeds yes
      text-width 200
      #user-agent "UniversalFeedParser/5.0.1 +http://feedparser.org/"

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
      highlight all "( ai|machine learning|artifical intelligence)" green default bold
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
      ignore-article "https://invidious.materialio.us/feed/channel/UC0jPwNs4B7yJySNewHan5hQ" "title !~ \"Highlights\""
      ignore-article "https://invidious.materialio.us/feed/channel/UCcBHr0HW8-Io2BcqaGN8KgQ" "title !~ \"Highlights\""
      ignore-article "https://invidious.materialio.us/feed/channel/UCsY7UM8d2sGHhWP_nj7WYjQ" "title !~ \"Highlights\""
      #ignore-article "http://192.168.86.200:85/makefulltextfeed.php?url=sec%3A%2F%2Fwww.theverge.com%2Frss%2Findex.xml&max=50&links=preserve&exc=&submit=Create+Feed" "title =~ \"Deal|deal|Sale|sale\""
      #ignore-article "http://192.168.86.200:85/makefulltextfeed.php?url=feeds.wired.com%2Fwired%2Findex&max=50&links=preserve&exc=&summary=1&submit=Create+Feed" "title =~ \"Deal|deal|Sale|sale\""
    '';
    urls = [
      #{ url = "http://rehoboam:8000/hotcopper.xml"; tags = [ "!" "~HotCopper" "no_unread" "stocks" ]; }
      #"exec:/home/zarred/.config/newsboat/parsers/webpage_parse.sh twitter" "~Twitter" stocks no_unread
      #{ url = "https://au.indeed.com/rss?q=Machine+Learning+Engineer&l=Victoria&radius=50&fromage=7&vjk=59ebb4fbfa450728"; tags = [ "~Indeed" "jobs" "no_unread" ]; }

      { url = "https://techcrunch.com/tag/daily-crunch/feed/"; tags = [ "!" "~TechCrunch" "tech" ]; }
      { url = "https://www.startupdaily.net/feed"; tags = [ "!" "~StartupsDaily" "tech" ]; }
      { url = "https://www.ycombinator.com/blog/rss"; tags = [ "!" "~YC" "tech" ]; }
      { url = "https://www.theverge.com/rss/index.xml"; tags = [ "!" "~Verge" "tech" ]; }

      #{ url = "https://www.sbs.com.au/news/topic/world/feed"; tags = [ "!" "~SBS-W" "news" ]; }
      # NOTE: broken { url = "http://www.monash.edu/_webservices/news/rss?num_ranks=5"; tags = [ "!" "~Monash" "news" ]; }
      { url = "http://jacobinmag.com/feed/"; tags = [ "!" "~Jacobin" "news" ]; }
      { url = "https://www.propublica.org/feeds/propublica/main"; tags = [ "!" "~ProPublica" "news" ]; }
      { url = "https://theintercept.com/feed/?lang=en"; tags = [ "!" "~TheIntercept" "news" ]; }
      #{ url = "http://feeds.bbci.co.uk/news/world/rss.xml"; tags = [ "!" "~BBC" "news" ]; }
      #{ url = "https://rss.nytimes.com/services/xml/rss/nyt/World.xml"; tags = [ "!" "~NYTimes" "news" ]; }
      #{ url = "https://news.google.com/rss"; tags = [ "!" "~GoogleNews" "news" ]; }
      { url = "https://kill-the-newsletter.com/feeds/kfwpslhaa3o1l0u8l4nz.xml"; tags = [ "!" "~ABC" "news" ]; }
      { url = "https://www.dropsitenews.com/feed"; tags = [ "!" "~DropSite" "news" ]; }
      { url = "https://reddit.com/r/worldnews/top/.rss?t=week"; tags = [ "!" "~r/world-news" "reddit" "news" ]; }
      { url = "https://reddit.com/r/news/top/.rss?t=week"; tags = [ "!" "~r/us-news" "reddit" "news" ]; }

      { url = "http://googleresearch.blogspot.com/atom.xml"; tags = [ "!" "~GoogleAI" "ai" ]; }
      { url = "https://www.theverge.com/ai-artificial-intelligence/rss/index.xml"; tags = [ "!" "~Verge-AI" "ai" ]; }
      { url = "https://towardsdatascience.com/feed/tagged/editors-pick"; tags = [ "!" "~TDS" "ai" ]; }
      { url = "https://medium.com/feed/towards-artificial-intelligence"; tags = [ "!" "~TAI" "ai" ]; }
      { url = "https://openai.com/news/rss.xml"; tags = [ "!" "~OpenAI" "ai" ]; }
      { url = "https://reddit.com/r/MachineLearning/top/.rss?t=month"; tags = [ "!" "~r/ML" "ai" ]; }
      { url = "https://reddit.com/r/computervision/top/.rss?t=month"; tags = [ "!" "~r/CV" "ai" ]; }
      { url = "https://reddit.com/r/LocalLLaMA/top/.rss?t=month"; tags = [ "!" "~r/LocalLLaMA" "ai" "reddit" ]; }
      { url = "https://hf.co/blog/feed.xml"; tags = [ "!" "~HuggingFace-Blog" "ai" ]; }
      { url = "https://blog.comma.ai/feed.xml"; tags = [ "!" "~Comma-AI" "ai" ]; }
      #{ url = "#http://rehoboam:8000/thebatch.xml"; tags = [ "!" "~The-Batch" "ai" ]; }
      { url = "https://simonwillison.net/atom/everything"; tags = [ "!" "~Simon-Willison-Blog" "ai" ]; }
      { url = "https://feeds.simplecast.com/OB5FkIl8"; tags = [ "!" "~PyTorch-Podcast" "ai" ]; }
      { url = "https://spectrum.ieee.org/feeds/topic/artificial-intelligence.rss"; tags = [ "!" "~Spectrum-IEEE-AI" "ai" ]; }
      { url = "https://anchor.fm/s/1e4a0eac/podcast/rss"; tags = [ "!" "~ML-Street-Talk-(MLST)" "ai" ]; }
      { url = "https://feeds.megaphone.fm/MLN2155636147"; tags = [ "!" "~The-TWIML-AI-Podcast" "ai" ]; }
      { url = "#https://feeds.soundcloud.com/users/soundcloud:users:264034133/sounds.rss"; tags = [ "!" "~The-AI-Podcast" "ai" ]; }
      { url = "https://practicalai.fm/rss"; tags = [ "!" "~PracticalAI" "ai" ]; }
      { url = "https://www.lastweekinai.com/feed.xml"; tags = [ "!" "~LWiAI" "ai" ]; }

      { url = "http://www.ozbargain.com.au/feed"; tags = [ "!" "~general" "no_unread" "shopping" ]; }
      { url = "https://www.ozbargain.com.au/tag/hard-drive/feed"; tags = [ "!" "~hard-drive" "no_unread" "shopping" ]; }
      { url = "https://www.ozbargain.com.au/product/asus-zenfone-9/feed"; tags = [ "!" "~asus-zenfone-9" "no_unread" "shopping" ]; }

      { url = "https://frame.work/blog.rss"; tags = [ "!" "~Framework" "linux" ]; }
      { url = "https://reddit.com/r/linux/top/.rss?t=month"; tags = [ "!" "~r/linux" "linux" "reddit" ]; }
      { url = "https://reddit.com/r/unixporn/top/.rss?t=month"; tags = [ "!" "~r/unixporn" "linux" "reddit" "unixporn" ]; }
      { url = "https://reddit.com/r/nixos/top/.rss?t=month"; tags = [ "!" "~r/NixOS" "linux" "reddit" ]; }
      { url = "https://reddit.com/r/ErgoMechKeyboards/top/.rss?t=month"; tags = [ "!" "~r/ErgoMechKB" "linux" "reddit" ]; }
      { url = "https://reddit.com/r/selfhosted/top/.rss?t=month"; tags = [ "!" "~r/selfhosted" "linux" "reddit" ]; }

      { url = "https://feeds.megaphone.fm/darknetdiaries"; tags = [ "!" "podcasts" ]; }
      { url = "https://feeds.buzzsprout.com/1890340.rss"; tags = [ "!" "podcasts" "socialism" ]; }
      { url = "https://pod.link/1097417804.rss"; tags = [ "!" "podcasts" "socialism" ]; }
      { url = "https://feed.podbean.com/redflag/feed.xml"; tags = [ "!" "podcasts" "socialism" ]; }
      { url = "https://feeds.soundcloud.com/users/soundcloud:users:672423809/sounds.rss"; tags = [ "!" "podcasts" "socialism" ]; }
      { url = "https://rss.art19.com/the-problem-with-jon-stewart"; tags = [ "!" "podcasts" ]; }
      { url = "http://feeds.libsyn.com/102225/rss"; tags = [ "!" "podcasts" ]; }
      { url = "https://feeds.megaphone.fm/recodedecode"; tags = [ "!" "podcasts" ]; }
      { url = "https://feeds.megaphone.fm/WWO6655869236"; tags = [ "!" "podcasts" ]; }
      { url = "https://feeds.megaphone.fm/pivot"; tags = [ "!" "podcasts" ]; }
      { url = "https://feeds.redcircle.com/e30b9f10-8c86-432e-9fa0-ba287fb94e7f"; tags = [ "!" "podcasts" "socialism" ]; }

      #{ url = "https://invidious.materialio.us/feed/channel/UC0jPwNs4B7yJySNewHan5hQ"; tags = [ "!" "~OptusSport" "football" ]; }
      #{ url = "https://invidious.materialio.us/feed/channel/UCcBHr0HW8-Io2BcqaGN8KgQ"; tags = [ "!" "~ChampionsTV" "football" ]; }
      #{ url = "https://invidious.materialio.us/feed/channel/UCsY7UM8d2sGHhWP_nj7WYjQ"; tags = [ "!" "~beIN SPORTS" "football" ]; }
    ];
  };
}
