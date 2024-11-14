{ ... }: {
  #nixpkgs.overlays = [(
  #  final: prev: {
  #    tridactyl-native = prev.tridactyl-native.overrideAttrs (old: {
  #      version = "0.4.0";
  #      src = prev.fetchFromGitHub {
  #        owner = "tridactyl";
  #        repo = "native_messenger";
  #        rev = "6e0d2cd3bc7dab02e8e87aaaa60b52c20131db42";
  #        sha256 = "";
  #      };
  #    });
  #  }
  #)];
  xdg.configFile = {
      "tridactyl/tridactylrc".text = ''
        set findcase insensitive
        set smoothscroll true
        set scrollduration 150
        set editorcmd kitty -c "nvim"
        set hintfiltermode simple
        set hintchars eiorsnta
        set hintnames short
        set modeindicatorshowkeys true

        set completionfuzziness 0.5
        set statusstylepretty true

        " command tradingview_max fillcmdline hint -Jc HTML > BODY:nth-of-type(1) > DIV:nth-of-type(2) > DIV:nth-of-type(3) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(3) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(16) > DIV:nth-of-type(1) > BUTTON:nth-of-type(1)
        " autocmd DocLoad https://www.tradingview.com/chart* composite tradingview_max | mode ignore
        autocmd DocLoad https://www.tradingview.com/chart* mode ignore
        autocmd DocLoad https://cad.onshape.com* mode ignore
        autocmd DocLoad https://www.youtube.com/watch?v=* mode ignore
        autocmd DocLoad https://hotcopper.com.au* mode ignore
        autocmd DocLoad https://monkeytype.com mode ignore
        autocmd DocLoad https://web.tabliss.io fillcmdline open


        unbind <C-f>
        bind --mode=ignore , mode normal
        unbind <C-e>
        unbind >
        unbind <

        bind <ArrowUp> scrollline -5
        bind <ArrowDown> scrollline 5
        bind a hint
        bind A hint -b
        bind <C-A> hint -t
        bind e tabprev
        bind i tabnext
        bind c tabclose
        bind n back
        bind N forward
        bind u undo tab
        bind U undo window
        bind t fillcmdline taball
        bind o fillcmdline open
        bind O fillcmdline tabopen
        bind <C-t> fillcmdline tabopen

        bind / fillcmdline find
        bind ? fillcmdline find -?
        bind h findnext --search-from-view
        bind k findnext --search-from-view --reverse

        unbind --mode=ex <ArrowDown>
        unbind --mode=ex <ArrowUp>
        unbind --mode=ex <ArrowLeft>
        unbind --mode=ex <ArrowRight>
        unbind --mode=ex <Tab>

        bind --mode=ex <Tab> ex.prev_history
        bind --mode=ex <S-Tab> ex.next_history
        bind --mode=ex <C-Tab> ex.insert_completion
        bind --mode=ex <ArrowDown> ex.next_completion
        bind --mode=ex <ArrowUp> ex.prev_completion

        "bind ;c hint -Jc [class*="expand"],[class="togg"],[class="comment_folder"]
        "bind ;t hint -Jc HTML > BODY:nth-of-type(1) > DIV:nth-of-type(2) > DIV:nth-of-type(3) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(3) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(1) > DIV:nth-of-type(16) > DIV:nth-of-type(1) > BUTTON:nth-of-type(1)
        "bind ;g composite js (new URLSearchParams((new URL(document.location.href)).search)).get('q') | fillcmdline_notrail open g
        "jsb ["--mode=insert", "--mode=input", "--mode=normal"].forEach(mode => { tri.excmds.bind(mode, `<A-H>`, `tabmove -1`) ; tri.excmds.bind(mode, `<A-L>`, `tabmove +1`) ; })

        bind w composite hint -pipe a href | js -p tri.excmds.shellescape(JS_ARG) | exclaim_quiet linkhandler.sh
        bind W composite get_current_url | exclaim_quiet ~/scripts/file-ops/linkhandler.sh
        "bind ;v composite hint -qpipe a href | js -p JS_ARG.map(h => `'$\{h}'`).join(" ") | ! mpv
        "bind e hint -W js -p tri.native.run(`\$HOME/bin/add-magnet '\$\{JS_ARG}'`)

        bindurl youtu((\.be)|(be\.com)) a hint -J

        bindurl google(\.[a-zA-Z0-9]+){1,2}/search a hint -Jc #top_nav a, #search a, .card-section a, a.fl, #pnnext, #pnprev
        bindurl google(\.[a-zA-Z0-9]+){1,2}/search A hint -Jbc #top_nav a, #search a, .card-section a, a.fl, #pnnext, #pnprev
        bindurl google(\.[a-zA-Z0-9]+){1,2}/search gA hint -Jqbc #top_nav a, #search a, .card-section a, a.fl, #pnnext, #pnprev

        bindurl youtube.com/feed a hint -Jc .yt-simple-endpoint:not(.ytd-thumbnail)
        bindurl youtube.com/feed A hint -Jbc .yt-simple-endpoint:not(.ytd-thumbnail)
        bindurl youtube.com/channel a hint -Jc .yt-simple-endpoint:not(.ytd-thumbnail)
        bindurl youtube.com/channel A hint -Jc .yt-simple-endpoint:not(.ytd-thumbnail)

        "alias playAllVideos js tri.native.run("mpv --really-quiet --ontop --keepaspect-window --profile=protocol.http " + Array.from(document.querySelectorAll("a, iframe, video")).reduce((s, e) => {let r=(/^https?:\/\/((www.)?youtu((\.be\/)|(be\.com\/((embed\/)|(watch\?v=))))[^ ]+)|(.+\.webm)\$/);let l="";if(e.tagName=="IFRAME")l=e.src.match(r);else if(e.tagName=="A")l=e.href.match(r)||e.innerText.match(r);else if(e.tagName=="VIDEO")l=[e.currentSrc?e.currentSrc:e.src];console.log(l);return s+(l && l.length > 0 && s.indexOf(l[0])<0?"'"+l[0]+"' ":"")},""))
        "alias rsssave jsb -p tri.native.run('cat >> ~/.config/newsboat/urls', JS_ARG + "\n")

        " Disable all searchurls
        jsb Object.keys(tri.config.get("searchurls")).reduce((prev, u) => prev.catch(()=>{}).then(_ => tri.excmds.setnull("searchurls." + u)), Promise.resolve())

        " Add our own
        set searchengine b
        set searchurls.b https://search.brave.com/search?q=%s
        set searchurls.g https://google.com/search?q=%s
        set searchurls.ddg https://duckduckgo.com/html?q=%s
        set searchurls.qwant https://qwant.com/?q=%s
        set searchurls.searxme https://searx.me/?q=%s&categories=general&language=en-US

        set searchurls.w https://en.wikipedia.org/wiki/Special:Search?search=%s
        set searchurls.wi https://en.wiktionary.org/w/index.php?search=%s&title=Special%3ASearch&go=Go
        set searchurls.wa https://www.wolframalpha.com/input/?i=%s

        set searchurls.r https://reddit.com/search?q=%s

        set searchurls.gh https://github.com/search?utf8=%E2%9C%93&q=%s
        set searchurls.crates https://crates.io/search?q=%s
        set searchurls.fdroid https://search.f-droid.org/?q=%s

        set searchurls.ozb https://ozbargain.com.au/search/node/%s
        set searchurls.amz https://amazon.com.au/s?k=%s
        set searchurls.ebay https://www.ebay.com.au/sch/items/?_nkw=%s
        set searchurls.steam https://store.steampowered.com/search/?term=%s

        set searchurls.bc https://bandcamp.com/search?q=%s
        set searchurls.imdb https://imdb.com/find?s=all&q=%s

        set searchurls.yt https://youtube.com/results?search_query=%s
        set searchurls.ytm https://music.youtube.com/search?q=%s
        set searchurls.tw https://www.twitch.tv/search?term=%s

        set searchurls.gi https://google.com/search?q=%s&tbm=isch&tbs=imgo:1
        set searchurls.gmaps https://google.com/maps?q=%s
        set searchurls.gtr https://translate.google.com/#auto/en/%s
        set searchurls.gn https://news.google.com/news/search/section/q/%s
        set searchurls.gs http://www.google.com/products?q=%s&sa=N&tab=pf
        set searchurls.gf http://finance.google.com/?q=%s&sa=N&tab=fe

        set searchurls.tv https://www.tradingview.com/chart/?symbol=%s
        set searchurls.hc https://hotcopper.com.au/asx/%s
        set searchurls.cmc https://www.cmcmarketsstockbroking.com.au/net/UI/Chart/AdvancedChart.aspx?asxcode=%s

        set searchurls.osm https://openstreetmap.org/search?query=%s

        set searchurls.np https://nixos.org/nixos/packages.html?query=%s
        set searchurls.no https://nixos.org/nixos/options.html#%s
        set searchurls.nw https://nixos.wiki/index.php?search=%s
        set searchurls.nh https://mipmip.github.io/home-manager-option-search/?query=%s

        set searchurls.arch https://wiki.archlinux.org/index.php?title=Special%3ASearch&search=%s
        set searchurls.pydoc https://docs.python.org/3/search.html?q=%s
        set searchurls.rustdoc https://doc.rust-lang.org/std/index.html?search=%s

        set searchurls.torrentz https://torrentz2.eu/search?f=%s
        set searchurls.tpb https://piratebay.live/search/%s
        set searchurls.1337x https://1337x.to/search/%s/1/
        set searchurls.ru https://rutracker.org/forum/tracker.php?nm=%s

        set searchurls.seerr https://jellyseerr.zar.red/search?query=%s

        set searchurls.th https://www.thingiverse.com/type=things&sort=popular&search?q=%s

        colourscheme rose-pine
  '';
  "tridactyl/themes/dracula-custom.css".source = ./base16-dracula.css;
  "tridactyl/themes/rose-pine.css".text = ''
    :root {
        --background: #181825;
        --surface: #1f1d2e;
        --overlay: #26233a;
        --foreground: #ebbcba;
        --pine: #31748f;
        --iris: #c4a7e7;
        --love: #eb6f92;
        --muted: #6e6a86;

        /* Generic */
        --tridactyl-font-family: Iosevka Nerd Font;
        --tridactyl-font-family-sans: Iosevka Nerd Font;
        --tridactyl-font-size: 20;
        --tridactyl-small-font-size: 14;
        --tridactyl-logo: url("moz-extension://__MSG_@@extension_id__/static/logo/Tridactyl_64px.png");

        --tridactyl-bg: var(--background);
        --tridactyl-fg: var(--foreground);
        --tridactyl-scrollbar-color: auto;

        /* Mode indicator */
        --tridactyl-status-font-family: var(--tridactyl-font-family);
        --tridactyl-status-font-size: var(--tridactyl-small-font-size);
        --tridactyl-status-bg: var(--tridactyl-bg);
        --tridactyl-status-fg: var(--tridactyl-fg);
        --tridactyl-status-border: 1px var(--pine) solid;
        --tridactyl-status-border-radius: 6px;

        /* Search highlight */
        --tridactyl-search-highlight-color: var(--iris);

        /* Hinting */

        /* Hint character tags */
        --tridactyl-hintspan-font-family: var(--tridactyl-font-family-sans);
        --tridactyl-hintspan-font-size: var(--tridactyl-small-font-size);
        --tridactyl-hintspan-font-weight: bold;
        --tridactyl-hintspan-fg: var(--foreground);
        --tridactyl-hintspan-bg: var(--overlay);
        --tridactyl-hintspan-border-color: ButtonShadow;
        --tridactyl-hintspan-border-width: 1px;
        --tridactyl-hintspan-border-style: solid;
        --tridactyl-hintspan-js-background: hsla(0, 0%, 65%);

        /* Element highlights */
        --tridactyl-hint-active-fg: var(--foreground);
        --tridactyl-hint-active-bg: var(--love);
        --tridactyl-hint-active-outline: 1px solid var(--pine);
        --tridactyl-hint-outline: 1px solid var(--muted);

        /* :viewsource */
        --tridactyl-vs-bg: var(--tridactyl-bg);
        --tridactyl-vs-fg: var(--tridactyl-fg);
        --tridactyl-vs-font-family: var(--tridactyl-font-family);

        /*commandline*/

        --tridactyl-cmdl-bg: var(--background);
        --tridactyl-cmdl-fg: var(--foreground);
        --tridactyl-cmdl-line-height: 1;
        --tridactyl-cmdl-font-family: var(--tridactyl-font-family);
        --tridactyl-cmdl-font-size: var(--tridactyl-small-font-size);

        /*completions*/

        --tridactyl-cmplt-option-height: 1.4em;
        --tridactyl-cmplt-fg: var(--tridactyl-fg);
        --tridactyl-cmplt-bg: var(--tridactyl-bg);
        --tridactyl-cmplt-font-size: var(--tridactyl-small-font-size);
        --tridactyl-cmplt-font-family: var(--tridactyl-font-family);
        --tridactyl-cmplt-border-top: 0px solid var(--pine);

        /* need a better way for naming variables
         *
            - .Properties for .HistoryCompletionSource table
            - .Properties for .BmarkCompletionSource table

        */

        /*sectionHeader*/

        --tridactyl-header-first-bg: var(--background);
        --tridactyl-header-second-bg: var(--surface);
        --tridactyl-header-third-bg: var(--overlay);
        .sectionHeader { background: var(--pine); }

        --tridactyl-header-font-size: inherit;
        --tridactyl-header-font-weight: bold;
        --tridactyl-header-border-bottom: 0px solid bottom;

        /*url style*/

        --tridactyl-url-text-decoration: none;
        --tridactyl-url-fg: var(--iris);
        --tridactyl-url-bg: var(--tridactyl-bg);
        --tridactyl-url-cursor: pointer;

        /*option focused*/

        --tridactyl-of-fg: var(--tridactyl-fg);
        --tridactyl-of-bg: var(--overlay);

        /*new tab spoiler box*/
        --tridactyl-highlight-box-bg: rgba(0, 0, 0, 0.07);
        --tridactyl-highlight-box-fg: var(--tridactyl-fg);

        --tridactyl-private-window-icon-url: url("chrome://browser/skin/privatebrowsing/private-browsing.svg");

        --tridactyl-container-fingerprint-url: url("resource://usercontext-content/fingerprint.svg");
        --tridactyl-container-briefcase-url: url("resource://usercontext-content/briefcase.svg");
        --tridactyl-container-dollar-url: url("resource://usercontext-content/dollar.svg");
        --tridactyl-container-cart-url: url("resource://usercontext-content/cart.svg");
        --tridactyl-container-circle-url: url("resource://usercontext-content/circle.svg");
        --tridactyl-container-gift-url: url("resource://usercontext-content/gift.svg");
        --tridactyl-container-vacation-url: url("resource://usercontext-content/vacation.svg");
        --tridactyl-container-food-url: url("resource://usercontext-content/food.svg");
        --tridactyl-container-fruit-url: url("resource://usercontext-content/fruit.svg");
        --tridactyl-container-pet-url: url("resource://usercontext-content/pet.svg");
        --tridactyl-container-tree-url: url("resource://usercontext-content/tree.svg");
        --tridactyl-container-chill-url: url("resource://usercontext-content/chill.svg");

        --tridactyl-container-color-blue: #37adff;
        --tridactyl-container-color-turquoise: #00c79a;
        --tridactyl-container-color-green: #51cd00;
        --tridactyl-container-color-yellow: #ffcb00;
        --tridactyl-container-color-orange: #ff9f00;
        --tridactyl-container-color-red: #ff613d;
        --tridactyl-container-color-pink: #ff4bda;
        --tridactyl-container-color-purple: #af51f5;

        --tridactyl-externaledit-bg: var(--tridactyl-logo) no-repeat center;
    }
    #command-line-holder {    order: 1;
        border: 2px solid var(--surface);
        color: var(--tridactyl-bg);
    }
    '';
  };
}
