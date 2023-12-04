{ ... }: {
  accounts.email.accounts.personal.notmuch.neomutt.enable = true;
  accounts.email.accounts.personal.neomutt = {
    enable = true;
    extraConfig = ''
      virtual-mailboxes "important" "notmuch://?query=query:important"
      virtual-mailboxes "updates" "notmuch://?query=query:updates"
      virtual-mailboxes "career" "notmuch://?query=query:career"
      virtual-mailboxes "receipts" "notmuch://?query=query:receipts"
      virtual-mailboxes "payslips" "notmuch://?query=query:payslips"
      virtual-mailboxes "news" "notmuch://?query=query:news"
      virtual-mailboxes "other" "notmuch://?query=query:other"
      '';
  };
  programs.neomutt = {
    enable = true;
    sort = "date-received";
    binds = (import ./neomutt/mutt_keybinds_clear.nix) ++ (import ./neomutt/mutt_keybinds.nix );
    macros = import ./neomutt/mutt_macros.nix;
    settings = {
      rfc2047_parameters = "yes";
      mailcap_path = "/home/zarred/.config/neomutt/mailcap";
      abort_key = "<Esc>";
      #date_format = "%d/%m %H:%M";
      #index_format = "%Z%?X?A& ? %D %-15.15F %s";
      sleep_time = "0";		# Pause 0 seconds for informational messages
      markers = "no";		# Disables the `+` displayed at line wraps
      mark_old = "no";		# Unread mail stay unread until read
      pager_read_delay = "3";
      mime_forward = "yes";		# attachments are forwarded with mail
      wait_key = "no";		# mutt won't ask "press key to continue"
      fast_reply = "yes";			# skip to compose when replying
      fcc_attach = "yes";			# save attachments with the body
      #forward_format = "Fwd: %s";	# format of subject when forwarding
      forward_quote = "yes";		# include message in forwards
      reverse_name = "yes";		# reply as whomever it was to
      include = "yes";			# include message in replies
      pager_index_lines = "10";
      pipe_decode = "yes";
      allow_ansi = "yes";
      pager_context = "3";
      pager_stop = "yes";
      menu_scroll = "yes";
      smart_wrap = "yes";
      wrap = "90";
      quote_regexp = "\"^( {0,4}[>|:#%]| {0,4}[a-z0-9]+[>|]+)+\"";
      reply_regexp = "\"^(([Rr][Ee]?(\[[0-9]+\])?: *)?(\[[^]]+\] *)?)*\"";
      display_filter = "~/scripts/mail/neomutt_display_filter";
      count_alternatives = "yes";    # recurse into text/multipart when looking for attachement types

      nm_query_type = "threads";           # bring in the whole thread instead of just the matched message, really useful
      nm_default_url = "notmuch:///home/zarred/.local/share/mail";
      nm_record_tags = "sent";           # default 'sent' tag
      virtual_spoolfile = "yes";

      #### Thread ordering
      use_threads = "reverse";
      #sort = "last-date";
      collapse_all = "yes";
      uncollapse_new = "no";
      thread_received = "yes";
      narrow_tree = "no";
    };
    sidebar = {
      enable = true;
      format = "%D%* %?N?%N?";
      shortPath = true;
      width = 15;
    };
    extraConfig = ( builtins.readFile ./neomutt/neomutt-dracula.conf ) + ''
        #### Header Options
        ignore *                                # ignore all headers
        unignore to: cc:                        # ..then selectively show only these headers
        unhdr_order *                           # some distros order things by default
        hdr_order from: to: cc: date: subject:  # header item ordering

        unauto_view  *
        unalternative_order *
        auto_view text/html text/calendar application/ics # view html automatically
        alternative_order text/html text/plain text/enriched text/*

        set index_format=" %zs %zc %zt %{!%d %b} . %-28.28L  %?M?(%1M)&  ? %?X?&·? %s"
        set pager_format=" %n %zc  %T %s%*  %{!%d %b · %H:%M} %?X?  %X ? %P  "
        set status_format = " %f%?r? %r?   %m %?n? 󰛮 %n ?  %?d?  %d ?%?t?  %t ?%?F?  %F? %> %?p?   %p ?"
        set vfolder_format = " %N %?n?%3n&   ?  %8m  · %f"
        set attach_format = "%u%D  %T%-75.75d %?T?%&   ? %5s · %m/%M"

        # no addressed to me, to me, group, cc, sent by me, mailing list
        set to_chars=""
        # unchanged mailbox, changed, read only, attach mode
        set status_chars = " "
        ifdef crypt_chars set crypt_chars = " "
        set flag_chars = "      "

        set hidden_tags = "unread,draft,flagged,passed,replied,attachment,signed,encrypted"
        tag-transforms "replied" "↻ "  \
                       "encrytpted" "" \
                       "signed" "" \
                       "attachment" "" \

        # The formats must start with 'G' and the entire sequence is case sensitive.
        tag-formats "replied" "GR" \
                    "encrypted" "GE" \
                    "signed" "GS" \
                    "attachment" "GA" \

        color status white color19
        color status color2 color19 '󰛮'
        color status yellow color19 ''
        color status red color19 ''
        color status white color6 '(.*)' 1
        color status color6 default '.*()' 1
        color status white color6 '\s* [0-9]+\s*'
        color status color6 color19 '().*$' 1
        color status color6 white '()\s*\s*[0-9]+\s*' 1
        color status white color6 '\s*\s*[0-9]+\s*[0-9]+%|all|end \s*'
        color status color6 white '() ([0-9]+%|all|end) \s*' 1
        color status color6 white ' ([0-9]+%|all|end) \s*'
        color status yellow black '()\s*' 1
        color status default color19 ''

    '';
  };
  xdg.configFile."neomutt/mailcap".text = ''
      # open html emails in browser (or whatever GUI program is used to render HTML)
      text/html; firefox %s ; nametemplate=%s.html
      # render html emails inline using magic (uncomment the line below to use lynx instead)
      text/html; lynx -assume_charset=%{charset} -display_charset=utf-8 -collapse_br_tags -dump %s; nametemplate=%s.html; copiousoutput
      #text/html; beautiful_html_render %s 2>~/mailcap_err; nametemplate=%s.html; copiousoutput;

      # show calendar invites
      text/calendar; render-calendar-attachment.py %s; copiousoutput;
      application/ics; mutt-viewical; copiousoutput;

      # open images externally
      image/*; openfile %s ;

      # open videos in mpv
      video/*; mpv --autofit-larger=90\%x90\% %s; needsterminal;
      video/*; setsid mpv --quiet %s &; copiousoutput

      # open spreadsheets in sc-im
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; sc-im %s; needsterminal

      # open anything else externally
      application/pdf; openfile %s;
  '';
}
