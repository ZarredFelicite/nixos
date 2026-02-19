{ lib, pkgs, config, ... }: {
  nixpkgs.overlays = [(
    final: prev:
    {
      keyd = prev.keyd.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "rvaiya";
          repo = "keyd";
          rev = "v2.5.0"; # NOTE: UPDATE
          hash = "sha256-pylfQjTnXiSzKPRJh9Jli1hhin/MIGIkZxLKxqlReVo="; # NOTE: UPDATE
        };
        postPatch = ''
          substituteInPlace Makefile \
            --replace-fail /usr ""
          #substituteInPlace keyd.service.in \
          #  --replace-fail /usr/bin $out/bin
        '';
        installFlags = [ "DESTDIR=${placeholder "out"}" ];
        postInstall = ''
          rm -rf $out/etc
          mkdir $out/bin
          ln -sf $out/local/bin/keyd $out/bin/keyd
          ln -sf $out/local/bin/keyd-application-mapper $out/bin/keyd-application-mapper
        '';
      });
    }
  )];
  systemd.services.keyd.serviceConfig = {
    CapabilityBoundingSet = lib.mkForce [ "CAP_SYS_NICE" ];
    PrivateUsers = lib.mkForce false;
    SystemCallFilter = lib.mkForce [
      "nice"
      "@system-service"
      "~@privileged"
    ];
  };
  environment.systemPackages = [
    pkgs.keyd
    pkgs.warpd
  ];
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [
        "045E:09AE" "045e:09ae" "17ef:60ee" "046d:408a" "0001:0001"
        "046d:b369" "046D:B369" # MX Keys Mini (Bluetooth)
        "17EF:60E1" # trackpoint keyboard
        ];
        settings = {
          main = {
            w = "w";
            "," = ",";
            c = "c";
            q = "q";
            e = "f";
            "]" = "]";
            "/" = "/";
            "'" = "'";
            r = "p";
            t = "b";
            u = "l";
            "." = ".";
            p = ";";
            o = "y";
            z = "z";
            i = "u";
            "[" = "[";
            v = "d";
            m = "h";
            n = "k";
            x = "x";
            b = "v";
            y = "j";
            capslock = "overloadt(control, esc, 200)";
            a = "overloadt(mvnt, a, 200)";
            s = "overloadt(meta, r, 200)";
            d = "overloadt(control, s, 200)";
            f = "overloadt(shift, t, 200)";
            g = "overloadt(alt, g, 200)";
            h = "overloadt(alt, m, 200)";
            j = "overloadt(shift, n, 200)";
            k = "overloadt(control, e, 200)";
            l = "overloadt(meta, i, 200)";
            ";" = "overloadt(mvnt, o, 200)";
            "k+l" = "overloadt(control_meta, backspace, 200)";
            "s+d" = "overloadt(control_meta, enter, 200)";
          };
          #meta = {
          #  j = "C-l";
          #};
          "control_meta:C-M" = {};
          "mvnt+meta".j = "M-left";
          mvnt = {
            g = "overloadt(alt, g, 200)";
            s = "overloadt(meta, r, 200)";
            d = "overloadt(control, s, 200)";
            f = "overloadt(shift, t, 200)";
            u = "mute";
            i = "volumedown";
            o = "volumeup";
            e = "playpause";
            w = "prev";
            r = "next";
            j = "left";
            k = "down";
            l = "up";
            ";" = "right";
            p = "print";
          };
        };
      };
    };
  };
}
