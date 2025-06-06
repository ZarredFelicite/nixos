{
  default = "Brave";
  force = true;
  engines = {
    "Brave" = {
      urls = [{ template = "https://search.brave.com/search?q={searchTerms}"; }];
      definedAliases = [ "b" ];
    };
    "Gooogle" = {
      urls = [{ template = "https://www.google.com/search?q={searchTerms}"; }];
      definedAliases = ["go"];
    };
    "Nix Packages" = {
      urls = [{
        template = "https://search.nixos.org/packages";
        params = [
          { name = "type"; value = "packages"; }
          { name = "query"; value = "{searchTerms}"; }
        ];
      }];
      definedAliases = [ "np" ];
    };
    "NixOS Wiki" = {
      urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
      definedAliases = [ "nw" ];
    };
    "NixOS Options" = {
      urls = [{ template = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}"; }];
      definedAliases = ["no"];
    };
    "NixOS HM Options" = {
      urls = [{ template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master"; }];
      definedAliases = ["nh"];
    };
    "Discogs" = {
      urls = [ { template = "https://www.discogs.com/search/?q={searchTerms}"; }];
      definedAliases = ["disc"];
      icon = "https://www.discogs.com/favicon.ico";
    };
    "GitHub" = {
      urls = [{ template = "https://github.com/search?utf8=%E2%9C%93&q={searchTerms}"; }];
      definedAliases = ["gh"];
    };
    "youtube" = {
      urls = [{ template = "https://www.youtube.com/results?search_query={searchTerms}"; }];
      definedAliases = ["yt"];
    };
    "GMaps" = {
      urls = [{ template = "https://google.com/maps?q={searchTerms}"; }];
      definedAliases = ["maps"];
    };
    "TradingView" = {
      urls = [{ template = "https://www.tradingview.com/chart/?symbol={searchTerms}"; }];
      definedAliases = ["tv"];
    };
    "OzBargain" = {
      urls = [{ template = "https://ozbargain.com.au/search/node/{searchTerms}"; }];
      definedAliases = ["ob"];
    };
    "HotCopper" = {
      urls = [{ template = "https://hotcopper.com.au/asx/{searchTerms}"; }];
      definedAliases = ["hc"];
    };
    "CMC Charts" = {
      urls = [{ template = "https://www.cmcmarketsstockbroking.com.au/net/UI/Chart/AdvancedChart.aspx?asxcode={searchTerms}"; }];
      definedAliases = ["cmc"];
    };
    "bing".metaData.hidden = true;
    "ddg".metaData.hidden = true;
  };
}
