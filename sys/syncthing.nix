{ lib, ... }: {
  #systemd.services.syncthing.unitConfig.After = lib.mkForce "multi-user.target";
  services.syncthing = {
    enable = true;
    user = "zarred";
    group = "users";
    guiAddress = "127.0.0.1:8384";
    #dataDir = "/home/zarred";
    configDir = "/var/lib/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      options.urAccepted = -1;
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
        "poco" = { id = "BEXXXN5-G6LNX4L-YLKH6TF-CIKE5V4-TIHJYAS-QBKIQTI-AFENRGH-PJ7GFA6"; };
        "surface" = { id = "Z5QGE5R-FKXHXQX-SU4BAID-L2JOSUL-WSSZQTB-3MO2LZA-5EPZFVD-KZO3MAK"; };
      };
      folders = {
        "scripts" = {
          path = "/home/zarred/scripts";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "sync" = {
	        path = "/home/zarred/sync";
	        devices = [ "web" "sankara" "nano" "poco" "surface" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        #"nb" = {
	      #  path = "/home/zarred/nb";
	      #  devices = [ "web" "sankara" "nano" "poco" "surface" ];
	      #  versioning = { type = "simple"; params = { keep = "10"; }; };
	      #};
        "documents" = {
	        path = "/home/zarred/documents";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "videos" = {
	        path = "/home/zarred/videos";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "pictures" = {
	        path = "/home/zarred/pictures";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "dev" = {
	        path = "/home/zarred/dev";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        #"mail" = {
	      #  path = "/home/zarred/mail";
	      #  devices = [ "web" "sankara" "nano" "surface" ];
	      #  versioning = { type = "simple"; params = { keep = "5"; }; };
	      #};
        "newsboat" = {
	        path = "/home/zarred/.local/share/newsboat";
	        devices = [ "web" "sankara" "nano" "surface" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
      };
    };
  };
}
