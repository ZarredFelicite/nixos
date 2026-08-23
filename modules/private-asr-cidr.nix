{ lib }:
let
  prefixRange = minimum: maximum:
    "(" + lib.concatStringsSep "|" (map toString (lib.range minimum maximum)) + ")";
  octet = "(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])";
  tail = "[.]${octet}[.]${octet}";
  patterns = [
    "127${tail}[.]${octet}/${prefixRange 8 32}"
    "10${tail}[.]${octet}/${prefixRange 8 32}"
    "172[.](1[6-9]|2[0-9]|3[01])[.]${octet}[.]${octet}/${prefixRange 12 32}"
    "192[.]168[.]${octet}[.]${octet}/${prefixRange 16 32}"
    "169[.]254[.]${octet}[.]${octet}/${prefixRange 16 32}"
    "100[.](6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])[.]${octet}[.]${octet}/${prefixRange 10 32}"
    "::1/128"
    "[fF][cCdD][0-9a-fA-F]{2}(:[0-9a-fA-F]{0,4}){1,7}/${prefixRange 7 128}"
    "[fF][eE][89aAbB][0-9a-fA-F](:[0-9a-fA-F]{0,4}){1,7}/${prefixRange 10 128}"
    "::[fF]{4}:127${tail}[.]${octet}/${prefixRange 104 128}"
    "::[fF]{4}:10${tail}[.]${octet}/${prefixRange 104 128}"
    "::[fF]{4}:172[.](1[6-9]|2[0-9]|3[01])[.]${octet}[.]${octet}/${prefixRange 108 128}"
    "::[fF]{4}:192[.]168[.]${octet}[.]${octet}/${prefixRange 112 128}"
    "::[fF]{4}:169[.]254[.]${octet}[.]${octet}/${prefixRange 112 128}"
    "::[fF]{4}:100[.](6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])[.]${octet}[.]${octet}/${prefixRange 106 128}"
  ];
in
cidr: lib.any (pattern: builtins.match pattern cidr != null) patterns
