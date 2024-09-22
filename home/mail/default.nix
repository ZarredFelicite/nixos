{ lib, pkgs, inputs, config, osConfig, ... }: {
  disabledModules = [
    "programs/himalaya.nix"
    #"programs/neomutt.nix"
  ];
  imports = [
    ./frontends/aerc.nix
    ./frontends/alot.nix
    ./frontends/neomutt.nix
    ./imapnotify.nix
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
        career = "from:\"/(linkedin|seek|indeed|leetcode|gradaustralia|blackbird|kaggle|prosple|angel.co|job email)/\"";
        receipts = "from:\"/(auto-confirm@amazon.com.au|service@paypal.com.au|googleplay-noreply@google.com)/\"";
        payslips = "from:\"/AccountRight@apps.myob.com/\"";
        news = "from:\"/(mailchimp@michaelwest.com.au|ark@arkinvest.com|rosina@tinyml.org|newsletter@benchmarkminerals.com)/\"";
        updates = "subject:\"/(sign|Sign|Password|payment|Payment|new device|account|login|Login|order|Order|confirmation|delivery|Delivery)/\" or from:\"/(accounts|tracking|order|support)/\"";
        other = "tag:inbox -query:updates -query:career -query:receipts -query:news -query:products -query:payslips";
        forum = "subject:forum";
        updates_uni = "subject:\"/(You have submitted|updated invitation|cancelled event|notification)/\" or from:help@massive.org.au";
        other_uni = "tag:inbox -query:updates_uni -query:forum";
      };
    };
  };
  home.packages = [
    pkgs.notmuch
    #pkgs.evolution
    pkgs.lynx
  ];
  xdg.desktopEntries.Evolution = {
    name = "Evolution Mail and Calendar";
    genericName = "Groupware Suite";
    comment = "Manage your email, contacts and schedule";
    type = "Application";
    exec = "evolution %U";
    terminal = false;
    categories = [ "Office" "Email" "Calendar" "ContactManagement"];
    mimeType = [ "text/calendar" "text/x-vcard" "text/directory" "application/mbox" "message/rfc822" "x-scheme-handler/mailto" "x-scheme-handler/webcal" "x-scheme-handler/calendar" "x-scheme-handler/task" "x-scheme-handler/memo" ];
  };
  programs.msmtp.enable = false;
}
