{ ... }: {
  accounts.email.accounts.personal.himalaya = {
    enable = true;
    settings = {
      backend = "imap";
      imap-host = "imap.gmail.com";
      imap-port = 993;
      imap-login = "zarred.f@gmail.com";
      imap-auth = "passwd";
      imap-passwd.cmd = "pass show mail/gmail.com";
      sync = true;
      sync-dir = "/home/zarred/sync/mail";
      #sync-folders-strategy.include = lib.attrsets.attrValues config.accounts.email.accounts.personal.folders;
      sync-folders-strategy = "all";
      #sync-folders-strategy.include = lib.attrsets.attrValues config.accounts.email.accounts.personal.folders;
      imap-notify-cmd = "notify-send '📫 <sender>' '<subject>'";
      imap-notify-query = "NEW"; # “(RECENT UNSEEN)” "NOT SEEN"
      sender = "smtp";
      downloads-dir = "~/downloads/mail_attachments";
      email-listing-datetime-fmt = "%H:%M %a %d/%m/%y";
      email-listing-page-size = 20;
      email-listing-datetime-local-tz = true;
      email-reading-format.type = "auto"; # flowed, fixed/width, auto
      email-sending-save-copy = true;
      imap-watch-cmds = [
        "himalaya --account my-account --folder INBOX account sync"
        "notify-send 'himalaya' 'changes..' "
      ];
    };
};
  programs.himalaya = {
    enable = true;
  };
  services.himalaya-notify = {
    enable = false;
    settings.keepalive = 500;
  };
  services.himalaya-watch = {
    enable = false;
    settings.keepalive = 500;
  };

}
