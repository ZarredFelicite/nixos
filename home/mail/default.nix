{ lib, pkgs, inputs, config, osConfig, ... }: {
  disabledModules = [
    #"programs/himalaya.nix"
    #"services/imapnotify.nix"
    #"programs/neomutt.nix"
  ];
  imports = [
    ./frontends/aerc.nix
    ./frontends/neomutt.nix
    ./frontends/himalaya.nix
    #../../modules/imapnotify.nix
  ];
  accounts.email = {
    maildirBasePath = ".mail";
    accounts = {
      personal = {
        primary = true;
        address = "zarred.f@gmail.com";
        userName = "zarred.f@gmail.com";
        flavor = "gmail.com";
        passwordCommand = "${pkgs.coreutils}/bin/cat ${osConfig.sops.secrets.gmail-personal.path}";
        realName = "Zarred Felicite";
        maildir.path = "personal";
        folders = {
          #inbox = "INBOX";
          inbox = "inbox";
          drafts = "drafts";
          sent = "sent";
          trash = "trash";
        };
        imap.host = "imap.gmail.com";
        imap.tls.enable = true;
        #imap.port = null;
        smtp.host = "smtp.gmail.com";
        smtp.port = 465;
        smtp.tls.enable = true;
        signature = {
          delimiter = "\n";
          text = ''
            Kind Regards,
            Zarred
          '';
          showSignature = "append";
        };
        imapnotify = {
          enable = true;
          boxes = [ "[Gmail]/All Mail" ];
          onNotify = "${pkgs.isync}/bin/mbsync --all";
          onNotifyPost = "/home/zarred/scripts/mail/mail-notify.sh > /home/zarred/mail-notify-log 2>&1 &";
        };
        mbsync = {
          enable = true;
          create = "both";
          expunge = "both";
          flatten = ".";
          groups = {
            inbox.channels.personal-inbox = { nearPattern = "inbox"; farPattern = "[Gmail]/All Mail"; };
            sent.channels.personal-sent = { nearPattern = "sent"; farPattern = "[Gmail]/Sent Mail"; };
            drafts.channels.personal-drafts = { nearPattern = "drafts"; farPattern = "[Gmail]/Drafts"; };
            spam.channels.personal-spam = { nearPattern = "spam"; farPattern = "[Gmail]/Spam"; };
            trash.channels.personal-trash = { nearPattern = "trash"; farPattern = "[Gmail]/Trash"; };
          };
        };
        notmuch.enable = true;
      };
    };
  };
  services.imapnotify = {
    enable = true;
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.jq
      pkgs.libnotify
      pkgs.lynx
      pkgs.gnused
      pkgs.gawk
      pkgs.libiconv
      pkgs.glibc.bin
    ];
  };
  programs.mbsync = {
    enable = true;
    extraConfig = ''
      SyncState *
    '';
  };
  services.mbsync = {
    enable = false;
    #configFile = /home/zarred/.config/isync/mbsyncrc;
    frequency = "*:0/30";
    verbose = true;
  };
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-bin;
    profiles.primary.isDefault = true;
  };
  programs.notmuch = {
    enable = true;
    #hooks = {
    #  preNew = "mbsync --all";
    #  postInsert = "";
    #  postNew = "";
    #};
    maildir.synchronizeFlags = true;
    new = {
      tags = [ "new" ];
      ignore = [ ".mbsyncstate" ".uidvalidity" "hooks"];
    };
    search.excludeTags = [ "trash" "spam" ];
    extraConfig = {
      query = {
        asx-announcements = ''from:investorpa and (subject:"/[A-Z]{2,4}\\.ASX/" or subject:"/price sensitive/" or subject:"/(Quarterly|Appendix 5B|Trading Halt)/")'';
        finance = ''from:"/(Interactive Brokers|IB Trading Assistant|TradingView|Polymarket)/" or subject:"/(Account UXXX|Daily Activity Statement|Daily Trade Report)/"'';
        investing-news = ''from:"/(GoldFix|Mené|Menē)/" or subject:"/(Silver|Gold|Treasury Reserve|Market Tightens)/"'';
        orders = ''from:"/(Amazon.com.au|Australia Post|Framework)/" or subject:"/(Order Confirmation|Ordered:|Delivered:|parcel .* delivered|has been delivered|shipped|delivery)/"'';
        shopping = ''from:"/(JB Hi-Fi|Kickstarter|Kickstargogo|KickstarNow|LTT Store|Klarna|Afterpay|Amino Z|AllTrails|Tripadvisor)/"'';
        receipts = ''subject:"/(Your receipt|Receipt from|Order Receipt|Successful Payment|Thanks for your payment|Payment Notification|MyMacca.*Receipt)/" or from:"/(auto-confirm@amazon.com.au|service@paypal.com.au|googleplay-noreply@google.com)/"'';
        security = ''subject:"/(Security alert|password|Password|login|Login|sign.?in|new device|verification|Verify|2FA)/"'';
        university = ''from:"/(Monash University|Monash Information Technology|help@massive.org.au)/"'';
        career = ''from:"/(LinkedIn Job Alerts|SEEK Job Alerts|seek|indeed|leetcode|gradaustralia|blackbird|kaggle|prosple|angel.co|job email)/" or subject:"/(is hiring|are hiring|hiring a|role|Job|job|Robotics Engineer|Software Engineer|Machine Learning|AI Engineer|Data Scientist)/"'';
        ai-dev = ''(from:"/(OpenAI|Google Cloud|Google Developer|Firebase|Ultralytics|Roboflow|Inworld|Kimi)/" or subject:"/(Vertex AI|vision AI|API usage|model predictions|open-source coding)/") and not subject:"/(receipt|Receipt|payment|Payment)/"'';
        payslips = ''from:"/AccountRight@apps.myob.com/"'';
        news = ''from:"/(Substack|Second Thought|mailchimp|michaelwest|arkinvest|tinyml|newsletter|benchmarkminerals)/"'';
        updates = ''subject:"/(password|Password|new device|account|login|Login|sign.?in|verification|Verify|2FA)/" or from:"/(accounts|support)/"'';
        forum = "subject:forum";
        updates_uni = "query:university";
        spam-suspect = ''from:"/(Antivirus-Total-Protection|Cloud-Billing-Alert)/" or subject:"/(Protection Expires|blocked your account|Recover your memories)/"'';
        other = "tag:inbox -query:asx-announcements -query:finance -query:investing-news -query:orders -query:shopping -query:receipts -query:security -query:university -query:career -query:ai-dev -query:payslips -query:news -query:updates -query:spam-suspect";
        other_uni = "tag:inbox -query:updates_uni -query:forum";
      };
    };
  };
  home.packages = [
    pkgs.notmuch
    pkgs.lynx
  ];
  programs.msmtp.enable = false;
}
