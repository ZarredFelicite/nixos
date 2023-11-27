[
 { map = [ "generic" "index" ]; key = "0"; action = "first-entry"; }
 { map = [ "generic" "index" ]; key = "$"; action = "last-entry"; }
 { map = [ "generic" "index" "pager" "index" ]; key = "Q"; action = "exit"; }
 { map = [ "generic" "index" ]; key = "<Return>"; action = "select-entry"; }
 { map = [ "generic" "index" ]; key = "<Right>"; action = "select-entry"; }
 { map = [ "generic" "index" ]; key = "l"; action = "select-entry"; }
 { map = [ "generic" "index" ]; key = "<Up>"; action = "previous-entry"; }
 { map = [ "generic" "index" ]; key = "<Down>"; action = "next-entry"; }
 { map = [ "generic" "index" ]; key = "k"; action = "previous-entry"; }
 { map = [ "generic" "index" ]; key = "j"; action = "next-entry"; }
 { map = [ "generic" "index" "pager" ]; key = "<PageUp>"; action = "previous-page"; }
 { map = [ "generic" "index" "pager" ]; key = "<PageDown>"; action = "next-page"; }
 { map = [ "generic" "index" "pager" ]; key = "/"; action = "search"; }
 { map = [ "generic" "index" "pager" ]; key = ":"; action = "enter-command"; }
 { map = [ "browser" ]; key = "<Space>"; action = "check-new"; }
 { map = [ "browser" ]; key = "N"; action = "select-new"; }
 { map = [ "index" ]; key = "c"; action = "change-folder"; }
 { map = [ "index" ]; key = "W"; action = "clear-flag"; }
 { map = [ "index" ]; key = "w"; action = "set-flag"; }
 { map = [ "index" ]; key = "P"; action = "previous-new-then-unread"; }
 { map = [ "index" ]; key = "N"; action = "next-new-then-unread"; }
 { map = [ "index" ]; key = "t"; action = "read-thread"; }
 { map = [ "index" ]; key = "m"; action = "mail"; }
 { map = [ "index" ]; key = "\Cr"; action = "reply"; }
 { map = [ "index" ]; key = "<Esc>r"; action = "group-reply"; } # Control-r
 { map = [ "index" ]; key = "R"; action = "list-reply"; }
 { map = [ "index" ]; key = "b"; action = "bounce-message"; }
 { map = [ "index" ]; key = "f"; action = "forward-message"; }
 { map = [ "index" ]; key = "d"; action = "delete-message"; }
 { map = [ "index" ]; key = "D"; action = "delete-thread"; }
 { map = [ "index" ]; key = "<Return>"; action = "display-message"; } # TODO: This might not be needed
 { map = [ "index" ]; key = "<Right>"; action = "display-message"; }
 { map = [ "index" ]; key = "l"; action = "display-message"; }
 { map = [ "index" ]; key = "@"; action = "display-address"; }
 { map = [ "index" ]; key = "x"; action = "toggle-read"; }
 { map = [ "index" ]; key = "a"; action = "create-alias"; }
 { map = [ "index" ]; key = "/"; action = "limit"; }
 { map = [ "index" ]; key = "o"; action = "sort-mailbox"; }
 { map = [ "index" ]; key = "p"; action = "print-message"; }
 { map = [ "index" ]; key = "s"; action = "save-message"; }
 { map = [ "index" ]; key = "|"; action = "pipe-message"; }
 { map = [ "index" ]; key = "u"; action = "undelete-message"; }
 { map = [ "index" ]; key = "n"; action = "next-unread"; }
 { map = [ "pager" ]; key = "<Up>"; action = "previous-line"; }
 { map = [ "pager" ]; key = "<Down>"; action = "next-line"; }
 { map = [ "pager" ]; key = "k"; action = "previous-line"; }
 { map = [ "pager" ]; key = "l"; action = "next-line"; }
 { map = [ "pager" ]; key = "m"; action = "mail"; }
 { map = [ "pager" ]; key = "\Cr"; action = "reply"; }
 { map = [ "pager" ]; key = "<Esc>r"; action = "group-reply"; } # Control-r
 { map = [ "pager" ]; key = "R"; action = "list-reply"; }
 { map = [ "pager" ]; key = "b"; action = "bounce-message"; }
 { map = [ "pager" ]; key = "f"; action = "forward-message"; }
 { map = [ "pager" ]; key = "d"; action = "delete-message"; }
 { map = [ "pager" ]; key = "@"; action = "display-address"; }
 { map = [ "pager" ]; key = "a"; action = "create-alias"; }
 { map = [ "pager" ]; key = "o"; action = "sort-mailbox"; }
 { map = [ "pager" ]; key = "p"; action = "print-message"; }
 { map = [ "pager" ]; key = "s"; action = "save-message"; }
 { map = [ "pager" ]; key = "|"; action = "pipe-message"; }
 { map = [ "pager" ]; key = "<Right>"; action = "view-attachments"; }
 { map = [ "pager" ]; key = "<Left>"; action = "exit"; }
 { map = [ "pager" ]; key = "l"; action = "view-attachments"; }
 { map = [ "pager" ]; key = "h"; action = "exit"; }
 { map = [ "pager" ]; key = "n"; action = "next-entry"; }
 { map = [ "pager" ]; key = "N"; action = "next-unread"; }
 { map = [ "pager" ]; key = "h"; action = "display-toggle-weed"; }
 { map = [ "attach" ]; key = "<Left>"; action = "exit"; }
 { map = [ "attach" ]; key = "<Right>"; action = "view-text"; }
]
