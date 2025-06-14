{ pkgs, config, ... }: {
  #systemd.services.syncthing.unitConfig.After = lib.mkForce "graphical-session.target";
  #systemd.services.syncthing.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 120";
  environment.variables.SYNCTHING_CTL_URL = "http://localhost:8384";
  environment.systemPackages = [
    pkgs.syncthing
    pkgs.stc-cli
    pkgs.syncthingtray
  ];
  services.syncthing = {
    user = "zarred";
    group = "users";
    guiAddress = "127.0.0.1:8384";
    #dataDir = "/home/zarred";
    configDir = "/home/zarred/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    relay.enable = false;
    openDefaultPorts = true;
    extraFlags = [ "-gui-apikey=${builtins.readFile config.sops.secrets.syncthing-api.path}" ];
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
        "web" = { id = "FJPCMZP-BFNE27P-TFDPM26-X2TNVZC-BBKQX4B-4YQO7JZ-5NHRWER-X4YU6AD"; };
        "sankara" = { id = "HWHGCRQ-HYCPKIP-M62FMS6-GQGZDWH-GCNJMJA-QIBXEXY-FVT2COA-KJ3W6QT"; };
        "nano" = { id = "I3P5FM2-DOHDIM7-WOPMTTE-KOCGQ66-GVSONDW-NB4KY4N-SFHGPJO-ELM7XQZ"; };
        "p8p" = { id = "WJSCFJY-M5SXBE4-ZXUM2BX-PUQ3IYD-76KTVMQ-EVWD53T-OGVT3FG-A4W5MQR"; };
      };
      folders = {
        "sync" = {
          enable = true;
	        path = "/home/zarred/sync";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" "p8p" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "nb" = {
          enable = true;
	        path = "/home/zarred/nb";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" "p8p" ];
	        versioning = { type = "simple"; params = { keep = "10"; }; };
	      };
        "scripts" = {
          enable = true;
          path = "/home/zarred/scripts";
          type = "sendreceive"; # "sendreceive", "sendonly", "receiveonly", "receiveencrypted"
	        devices = [ "web" "sankara" "nano" ];
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
        "audio" = {
          enable = true;
	        path = "/home/zarred/audio";
          type = "sendreceive";
	        devices = [ "web" "sankara" "nano" "p8p" ];
	        versioning = { type = "simple"; params = { keep = "5"; }; };
	      };
        "dev" = {
          enable = false;
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
