{ pkgs, lib, ... }: {
  systemd.services.syncthing.unitConfig.After = lib.mkForce "graphical-session.target";
  environment.systemPackages = [ pkgs.syncthing ];
  services.syncthing = {
    enable = true;
    user = "zarred";
    group = "users";
    guiAddress = "127.0.0.1:8384";
    #dataDir = "/home/zarred";
    configDir = "/var/lib/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    relay.enable = false;
    openDefaultPorts = true;
    settings = {
      options.urAccepted = -1;
      options.relaysEnabled = false;
      gui = {
        tls = "true";
        theme = "black";
        user = "";
        password = "";
      };
      devices = {
        "web" = { id = "GJZKNJ4-FLQ7WC4-5H5CN2X-BTFXWIQ-MXQ545G-MUNEPZ4-FPTRVSL-QG43FA5"; };
        "sankara" = { id = "HWHGCRQ-HYCPKIP-M62FMS6-GQGZDWH-GCNJMJA-QIBXEXY-FVT2COA-KJ3W6QT"; };
        "nano" = { id = "YTLUJQP-TJR7PTR-5SWYZRK-7K7WLLS-VDPEK6V-UU7DQX3-CKUCWYX-P3EJ2QF"; };
        "phone" = { id = "BEXXXN5-G6LNX4L-YLKH6TF-CIKE5V4-TIHJYAS-QBKIQTI-AFENRGH-PJ7GFA6"; };
      };
      folders = {
        "scripts" = {
          enable = true;
          path = "/home/zarred/scripts";
          type = "sendreceive"; # "sendreceive", "sendonly", "receiveonly", "receiveencrypted"
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "sync" = {
          enable = true;
	        path = "/home/zarred/sync";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" "phone" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "documents" = {
          enable = true;
	        path = "/home/zarred/documents";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "videos" = {
          enable = true;
	        path = "/home/zarred/videos";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "pictures" = {
          enable = true;
	        path = "/home/zarred/pictures";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "dev" = {
          enable = true;
	        path = "/home/zarred/dev";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "newsboat" = {
	        path = "/home/zarred/.local/share/newsboat";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
      };
    };
  };
}
