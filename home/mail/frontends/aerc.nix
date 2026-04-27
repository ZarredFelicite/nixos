{ pkgs, ... }: {
  accounts.email.accounts.personal.aerc = {
    enable = true;
    extraAccounts = {
      source = "notmuch:///home/zarred/.mail";
      query-map = "~/.config/aerc/notmuch-query-map";
      exclude-tags = "trash,spam";
      enable-maildir = true;
      maildir-account-path = "personal";
      check-mail-cmd = "mbsync --all && notmuch new";
      check-mail-timeout = "2m";
    };
  };

  home.packages = with pkgs; [
    bat
    chafa
    w3m
    xdg-utils
  ];

  programs.aerc = {
    enable = true;
    extraConfig = {
      general = {
        unsafe-accounts-conf = true;
        default-save-path = "~/downloads/mail_attachments";
      };
      ui = {
        border-char-vertical = "│";
        border-char-horizontal = "─";
        styleset-name = "catppuccin-mocha";
        sidebar-width = 25;
        sort = "-r date";
        threading-enabled = true;
        index-columns = "flags:4,name<22%,subject,date>=";
      };
      viewer = {
        pager = "less -SRc";
        alternatives = "text/plain,text/html";
        header-layout = "From|To,Cc|Bcc,Date,Subject";
        parse-http-links = true;
      };
      filters = ''
        text/plain=colorize
        text/calendar=calendar
        message/delivery-status=colorize
        message/rfc822=colorize
        text/html=! html
        application/x-sh=bat -fP -l sh
        text/*=bat -fP --file-name="$AERC_FILENAME"
        image/*=chafa -f symbols -s $(tput cols)x$(tput lines) -
        .headers=colorize
      '';
      openers = {
        "x-scheme-handler/http*" = "xdg-open {}";
        "text/html" = "xdg-open {}";
        "application/pdf" = "xdg-open {}";
        "image/*" = "xdg-open {}";
      };
    };
    extraBinds = {
      global = {
        "<C-p>" = ":prev-tab<Enter>";
        "<C-n>" = ":next-tab<Enter>";
        "\\[t" = ":prev-tab<Enter>";
        "\\]t" = ":next-tab<Enter>";
        "?" = ":help keys<Enter>";
        "<C-q>" = ":prompt 'Quit?' quit<Enter>";
      };
      messages = {
        q = ":prompt 'Quit?' quit<Enter>";
        j = ":next<Enter>";
        "<Down>" = ":next<Enter>";
        k = ":prev<Enter>";
        "<Up>" = ":prev<Enter>";
        "<C-d>" = ":next 50%<Enter>";
        "<C-u>" = ":prev 50%<Enter>";
        "<C-f>" = ":next 100%<Enter>";
        "<C-b>" = ":prev 100%<Enter>";
        g = ":select 0<Enter>";
        G = ":select -1<Enter>";
        J = ":next-folder<Enter>";
        "<C-Down>" = ":next-folder<Enter>";
        K = ":prev-folder<Enter>";
        "<C-Up>" = ":prev-folder<Enter>";
        h = ":collapse-folder<Enter>";
        "<Left>" = ":collapse-folder<Enter>";
        l = ":expand-folder<Enter>";
        "<Right>" = ":expand-folder<Enter>";
        "<Enter>" = ":view<Enter>";
        v = ":mark -t<Enter>";
        "<Space>" = ":mark -t<Enter>:next<Enter>";
        V = ":mark -v<Enter>";
        d = ":choose -o y 'Really delete this message?' delete-message<Enter>";
        a = ":archive flat<Enter>";
        m = ":compose<Enter>";
        C = ":compose<Enter>";
        rr = ":reply -a<Enter>";
        rq = ":reply -aq<Enter>";
        Rr = ":reply<Enter>";
        Rq = ":reply -q<Enter>";
        f = ":forward<Enter>";
        c = ":cf<space>";
        "/" = ":search<space>";
        "\\" = ":filter<space>";
        n = ":next-result<Enter>";
        N = ":prev-result<Enter>";
        "<Esc>" = ":clear<Enter>";
        s = ":split<Enter>";
        S = ":vsplit<Enter>";
      };
      "messages:folder=Drafts" = {
        "<Enter>" = ":recall<Enter>";
      };
      view = {
        q = ":close<Enter>";
        h = ":prev<Enter>";
        "<Left>" = ":prev<Enter>";
        l = ":next<Enter>";
        "<Right>" = ":next<Enter>";
        J = ":next<Enter>";
        K = ":prev<Enter>";
        H = ":toggle-headers<Enter>";
        O = ":open<Enter>";
        o = ":open<Enter>";
        S = ":save<space>";
        "|" = ":pipe<space>";
        D = ":delete<Enter>";
        A = ":archive flat<Enter>";
        f = ":forward<Enter>";
        rr = ":reply -a<Enter>";
        rq = ":reply -aq<Enter>";
        Rr = ":reply<Enter>";
        Rq = ":reply -q<Enter>";
        "<C-k>" = ":prev-part<Enter>";
        "<C-j>" = ":next-part<Enter>";
        "<C-y>" = ":copy-link <space>";
        "<C-l>" = ":open-link <space>";
        "/" = ":toggle-key-passthrough<Enter>/";
      };
      "view::passthrough" = {
        "$noinherit" = true;
        "$ex" = "<C-x>";
        "<Esc>" = ":toggle-key-passthrough<Enter>";
      };
      compose = {
        "$noinherit" = true;
        "$ex" = "<C-x>";
        "$complete" = "<C-o>";
        "<C-k>" = ":prev-field<Enter>";
        "<C-j>" = ":next-field<Enter>";
        "<Up>" = ":prev-field<Enter>";
        "<Down>" = ":next-field<Enter>";
        "<Tab>" = ":next-field<Enter>";
        "<Backtab>" = ":prev-field<Enter>";
      };
      "compose::review" = {
        y = ":send<Enter>";
        n = ":abort<Enter>";
        q = ":choose -o d discard abort -o p postpone postpone<Enter>";
        e = ":edit<Enter>";
        a = ":attach<space>";
        d = ":detach<space>";
        p = ":postpone<Enter>";
        v = ":preview<Enter>";
      };
    };
  };
  xdg.configFile."aerc/stylesets/catppuccin-mocha".source = ./catppuccin-mocha;
  xdg.configFile."aerc/notmuch-query-map".text = ''
    inbox=tag:inbox
    important=tag:flagged
    asx-announcements=from:investorpa and (subject:"/[A-Z]{2,4}\\.ASX/" or subject:"/price sensitive/" or subject:"/(Quarterly|Appendix 5B|Trading Halt)/")
    finance=from:"/(Interactive Brokers|IB Trading Assistant|TradingView|Polymarket)/" or subject:"/(Account UXXX|Daily Activity Statement|Daily Trade Report)/"
    investing-news=from:"/(GoldFix|Mené|Menē)/" or subject:"/(Silver|Gold|Treasury Reserve|Market Tightens)/"
    orders=from:"/(Amazon.com.au|Australia Post|Framework)/" or subject:"/(Order Confirmation|Ordered:|Delivered:|parcel .* delivered|has been delivered|shipped|delivery)/"
    shopping=from:"/(JB Hi-Fi|Kickstarter|Kickstargogo|KickstarNow|LTT Store|Klarna|Afterpay|Amino Z|AllTrails|Tripadvisor)/"
    receipts=subject:"/(Your receipt|Receipt from|Order Receipt|Successful Payment|Thanks for your payment|Payment Notification|MyMacca.*Receipt)/" or from:"/(auto-confirm@amazon.com.au|service@paypal.com.au|googleplay-noreply@google.com)/"
    security=subject:"/(Security alert|password|Password|login|Login|sign.?in|new device|verification|Verify|2FA)/"
    university=from:"/(Monash University|Monash Information Technology|help@massive.org.au)/"
    career=from:"/(LinkedIn Job Alerts|SEEK Job Alerts|seek|indeed|leetcode|gradaustralia|blackbird|kaggle|prosple|angel.co|job email)/" or subject:"/(is hiring|are hiring|hiring a|role|Job|job|Robotics Engineer|Software Engineer|Machine Learning|AI Engineer|Data Scientist)/"
    ai-dev=(from:"/(OpenAI|Google Cloud|Google Developer|Firebase|Ultralytics|Roboflow|Inworld|Kimi)/" or subject:"/(Vertex AI|vision AI|API usage|model predictions|open-source coding)/") and not subject:"/(receipt|Receipt|payment|Payment)/"
    payslips=from:"/AccountRight@apps.myob.com/"
    news=from:"/(Substack|Second Thought|mailchimp|michaelwest|arkinvest|tinyml|newsletter|benchmarkminerals)/"
    updates=subject:"/(password|Password|new device|account|login|Login|sign.?in|verification|Verify|2FA)/" or from:"/(accounts|support)/"
    spam-suspect=from:"/(Antivirus-Total-Protection|Cloud-Billing-Alert)/" or subject:"/(Protection Expires|blocked your account|Recover your memories)/"
    other=tag:inbox and not (from:investorpa and (subject:"/[A-Z]{2,4}\\.ASX/" or subject:"/price sensitive/" or subject:"/(Quarterly|Appendix 5B|Trading Halt)/")) and not (from:"/(Interactive Brokers|IB Trading Assistant|TradingView|Polymarket)/" or subject:"/(Account UXXX|Daily Activity Statement|Daily Trade Report)/") and not (from:"/(GoldFix|Mené|Menē)/" or subject:"/(Silver|Gold|Treasury Reserve|Market Tightens)/") and not (from:"/(Amazon.com.au|Australia Post|Framework)/" or subject:"/(Order Confirmation|Ordered:|Delivered:|parcel .* delivered|has been delivered|shipped|delivery)/") and not from:"/(JB Hi-Fi|Kickstarter|Kickstargogo|KickstarNow|LTT Store|Klarna|Afterpay|Amino Z|AllTrails|Tripadvisor)/" and not (subject:"/(Your receipt|Receipt from|Order Receipt|Successful Payment|Thanks for your payment|Payment Notification|MyMacca.*Receipt)/" or from:"/(auto-confirm@amazon.com.au|service@paypal.com.au|googleplay-noreply@google.com)/") and not subject:"/(Security alert|password|Password|login|Login|sign.?in|new device|verification|Verify|2FA)/" and not from:"/(Monash University|Monash Information Technology|help@massive.org.au)/" and not (from:"/(LinkedIn Job Alerts|SEEK Job Alerts|seek|indeed|leetcode|gradaustralia|blackbird|kaggle|prosple|angel.co|job email)/" or subject:"/(is hiring|are hiring|hiring a|role|Job|job|Robotics Engineer|Software Engineer|Machine Learning|AI Engineer|Data Scientist)/") and not ((from:"/(OpenAI|Google Cloud|Google Developer|Firebase|Ultralytics|Roboflow|Inworld|Kimi)/" or subject:"/(Vertex AI|vision AI|API usage|model predictions|open-source coding)/") and not subject:"/(receipt|Receipt|payment|Payment)/") and not from:"/AccountRight@apps.myob.com/" and not from:"/(Substack|Second Thought|mailchimp|michaelwest|arkinvest|tinyml|newsletter|benchmarkminerals)/" and not (from:"/(Antivirus-Total-Protection|Cloud-Billing-Alert)/" or subject:"/(Protection Expires|blocked your account|Recover your memories)/")
  '';
}
