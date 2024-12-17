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
        { symbol = "ADT.AX"; quantity = 7700; unit_cost = 3.910;}
        { symbol = "MM8.AX"; quantity = 50000; unit_cost = 0.06;}
        { symbol = "AWJ.AX"; quantity = 14389; unit_cost = 0.314;}
        { symbol = "AAR.AX"; quantity = 30000; unit_cost = 0.066;}
        { symbol = "AUC.AX"; quantity = 8000; unit_cost = 0.356;}
        { symbol = "USL.AX"; quantity = 13954; unit_cost = 0.178;}
        { symbol = "KRM.AX"; quantity = 21271; unit_cost = 0.071;}
        { symbol = "BSX.AX"; quantity = 7571; unit_cost = 0.157;}
        { symbol = "GBZ.AX"; quantity = 11904; unit_cost = 0.086;}
        { symbol = "NHC.AX"; quantity = 500; unit_cost = 2.66;}
        { symbol = "AZY.AX"; quantity = 75714; unit_cost = 0.027;}
        { symbol = "VTX.AX"; quantity = 10000; unit_cost = 0.161;}
        { symbol = "HRZ.AX"; quantity = 43478; unit_cost = 0.046;}
        { symbol = "TAM.AX"; quantity = 53571; unit_cost = 0.028;}
        #{ symbol = "GWR.AX"; quantity = 16853; unit_cost = 0.09;}
        { symbol = "NXM.AX"; quantity = 25000; unit_cost = 0.06;}
        { symbol = "POL.AX"; quantity = 1379; unit_cost = 0.729;}
        { symbol = "WIN.AX"; quantity = 50000; unit_cost = 0.042;}
        { symbol = "BRX.AX"; quantity = 5882; unit_cost = 0.171;}
        { symbol = "IPB.AX"; quantity = 120000; unit_cost = 0.013;}
        { symbol = "MLX.AX"; quantity = 13200; unit_cost = 0.38;}
        { symbol = "CTM.AX"; quantity = 3700; unit_cost = 0.778;}
        { symbol = "AFM.V"; quantity = 5118; unit_cost = 0.88;}
        { symbol = "LLI.AX"; quantity = 3000; unit_cost = 0.311;}
        { symbol = "NC1.AX"; quantity = 363; unit_cost = 0.00;}
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
