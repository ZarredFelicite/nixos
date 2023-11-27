{ pkgs, ... }:
let
  mail-notify = pkgs.writeShellScriptBin "mail-notify" ''
    PATH=$PATH:${pkgs.jq}/bin/:${pkgs.busybox}/bin/:${pkgs.notmuch}/bin/:${pkgs.libnotify}/bin/

    last_check=$(cat ~/.cache/last_mail_check)
    notmuch new
    notmuch tag +inbox +unread -new -- tag:new
    notmuch tag -new -inbox +sent -- from:zarred.f@gmail.com
    notmuch show --format=json --include-html date:@$last_check.. | jq -c '.[]' | while read -r mail; do
      subject=$(echo $mail | jq -r '.[][0].headers.Subject')
      tags=$(echo $mail | jq -r '.[][0].tags.[]' | sed 's/^/[/;s/$/]/' | tr '\n' ' ')
      from=$(echo $mail | jq -r '.[][0].headers.From')
      date=$(echo $mail | jq -r '.[][0].date_relative')
      body=$(echo $mail | jq '.[][0].body[].content[0].content' | sed -E 's/https?:\/\/\S+|www\.\S+//g' | sed -e 's/&zwnj;//g' -e 's/\\n \\n \\n//g' -e 's/\\n \\n//g' -e 's/\\n\\n/\\n/g')
      notify-send "$subject" "$date | $tags\n$from\n$body"
    done
    date +%s > ~/.cache/last_mail_check
  '';
in {
  disabledModules = [
    "services/imapnotify.nix"
  ];
  imports = [ ../../modules/imapnotify.nix ];
  accounts.email.accounts.personal.imapnotify = {
    enable = true;
    boxes = [ "[Gmail]/All Mail" ];
    onNotify = "${pkgs.isync}/bin/mbsync --all";
    onNotifyPost = "${mail-notify}/bin/mail-notify";
  };
  services.imapnotify.enable = true;
}
