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
        asx-announcements = ''from:investorpa or subject:"/[A-Z]{2,4}\\.ASX/" or subject:"/price sensitive/"'';
        career = ''from:"/(linkedin|LinkedIn|seek|SEEK|indeed|leetcode|gradaustralia|blackbird|kaggle|prosple|angel.co|job email|Job Alerts)/" or subject:"/(hiring|Hiring|role|Job|job|Robotics Engineer|Software Engineer|Machine Learning|AI Engineer|Data Scientist)/"'';
        finance = ''from:"/(Interactive Brokers|IB Trading Assistant|TradingView|Polymarket|GoldFix|Mené|Menē)/" or subject:"/(Account UXXX|Daily Activity Statement|Daily Trade Report|Silver|Gold|Treasury Reserve|Market)/"'';
        orders = ''from:"/(Amazon|eBay|JB Hi-Fi|Kickstarter|Kickstargogo|KickstarNow|LTT Store|Framework|Klarna|Afterpay|PayPal|Australia Post)/" or subject:"/(receipt|Receipt|order|Order|delivered|Delivered|parcel|payment|Payment|confirmation|Confirmation)/"'';
        security = ''from:"/(Google|OpenAI|Tangerine|McDonald)/" or subject:"/(Security alert|security alert|password|Password|login|Login|sign.?in|new device|verification|Verify|2FA)/"'';
        university = ''from:"/(Monash|massive.org.au)/" or subject:"/(Network-athon|submitted|invitation|cancelled event|notification)/"'';
        receipts = ''from:"/(auto-confirm@amazon.com.au|service@paypal.com.au|googleplay-noreply@google.com|PayPal|Klarna|Afterpay)/" or subject:"/(receipt|Receipt|payment|Payment)/"'';
        payslips = ''from:"/AccountRight@apps.myob.com/"'';
        news = ''from:"/(GoldFix|Substack|mailchimp|michaelwest|arkinvest|tinyml|newsletter|benchmarkminerals)/" or subject:"/(newsletter|Newsletter|market|Market|Silver|Gold)/"'';
        updates = ''subject:"/(sign|Sign|Password|payment|Payment|new device|account|login|Login|order|Order|confirmation|delivery|Delivery|verification|Verify)/" or from:"/(accounts|tracking|order|support|noreply|no-reply)/"'';
        forum = "subject:forum";
        updates_uni = "query:university";
        other = "tag:inbox -query:updates -query:career -query:receipts -query:news -query:payslips -query:asx-announcements -query:finance -query:orders -query:security -query:university";
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
