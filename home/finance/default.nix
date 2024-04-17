{ pkgs, ... }: {
  #imports = [ ./wine-ibkr.nix ];
  home.packages = [ pkgs.ticker pkgs.tickrs ];
  xdg.configFile = {
    "tickrs/config.yml".text = builtins.toJSON {
      symbols = [
        "ADT.AX"
        "WHC.AX"
        "NHC.AX"
        "MLX.AX"
        "CTM.AX"
        "LLI.AX"
        "NC1.AX"
        "AFM.V"
        "FIL.TO"
        "BTC-USD"
        "ETH-USD"
        "GC=F"
        "SI=F"
        "ES=F"
        "^GSPC"
        "AUDUSD=X"
        "^AXJO"
      ];
      time_frame = "1D";
      update_interval = 60;
      hide_help = true;
      show_volumes = true;
      show_x_labels = true;
      summary = false;
    };
    "ticker/.ticker.yaml".text = builtins.toJSON {
      show-summary = true;
      show-tags = true;
      show-fundamentals = true;
      show-separator = true;
      show-holdings = true;
      interval = 5;
      currency = "AUD";
      currency-summary-only = false;
      watchlist = [
        "ADT.AX"
        "WHC.AX"
        "NHC.AX"
        "MLX.AX"
        "LLI.AX"
        "BSX.AX"
        "GBZ.AX"
        "MZZ.AX"
        "CTM.AX"
        "AFM.V"
        "FIL.TO"
        "NC1.AX"
      ];
      lots = [
        { symbol = "ADT.AX"; quantity = 9000; unit_cost = 3.602;}
        { symbol = "ADT.AX"; quantity = 3000; unit_cost = 0.791;}
        { symbol = "KRM.AX"; quantity = 21271; unit_cost = 0.071;}
        { symbol = "BSX.AX"; quantity = 7571; unit_cost = 0.157;}
        { symbol = "GBZ.AX"; quantity = 11904; unit_cost = 0.086;}
        { symbol = "MZZ.AX"; quantity = 1942; unit_cost = 0.275;}
        { symbol = "NHC.AX"; quantity = 500; unit_cost = 2.66;}
        { symbol = "IPB.AX"; quantity = 120000; unit_cost = 0.013;}
        { symbol = "MLX.AX"; quantity = 13200; unit_cost = 0.38;}
        { symbol = "CTM.AX"; quantity = 3700; unit_cost = 0.778;}
        { symbol = "AFM.V"; quantity = 5118; unit_cost = 0.88;}
        { symbol = "CEI.AX"; quantity = 7000; unit_cost = 0.241;}
        { symbol = "FIL.TO"; quantity = 120; unit_cost = 6.36;}
        { symbol = "LLI.AX"; quantity = 3000; unit_cost = 0.311;}
        { symbol = "NC1.AX"; quantity = 363; unit_cost = 0.00;}
        { symbol = "AUDUSD=X"; quantity = 12600; unit_cost = 1;}
        { symbol = "AUDUSD=X"; quantity = 1160; unit_cost = 1;}
      ];
      groups = [
        { name = "crypto";
          watchlist = [
            "BTC-USD"
            "ETH-USD"
            "XMR-USD"
          ];
        }
      ];
    };
  };
}
