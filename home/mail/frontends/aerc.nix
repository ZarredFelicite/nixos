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
    important=query:important
    updates=query:updates
    career=query:career
    receipts=query:receipts
    payslips=query:payslips
    news=query:news
    other=query:other
  '';
}
